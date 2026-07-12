#!/usr/bin/env bash
set -euo pipefail

MAX_TICKETS=1
ISSUE_NUM=""
MODEL="${AIDER_MODEL:-deepseek/deepseek-v4-pro}"
PROCESSED_ISSUES=""

usage() {
  echo "Usage: ./run_ticket.sh [--max N] [--issue NUMBER]"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --max)
      MAX_TICKETS="$2"
      shift 2
      ;;
    --issue)
      ISSUE_NUM="$2"
      MAX_TICKETS=1
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

if ! [[ "$MAX_TICKETS" =~ ^[0-9]+$ ]] || [[ "$MAX_TICKETS" -lt 1 ]]; then
  echo "--max must be a positive integer."
  exit 1
fi

require_clean_tree() {
  if [[ -n "$(git status --porcelain)" ]]; then
    echo "Refusing to start: worktree is not clean."
    git status --short
    exit 1
  fi
}

slugify() {
  echo "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9]/-/g' \
    | sed 's/-\{2,\}/-/g' \
    | sed 's/^-//;s/-$//' \
    | cut -c 1-48 \
    | sed 's/-$//'
}

open_pr_issue_numbers() {
  gh pr list \
    --state open \
    --base develop \
    --limit 100 \
    --json title,body \
    --jq '.[] | .title, .body' \
    | grep -Eo '#[0-9]+' \
    | tr -d '#' \
    | sort -u || true
}

number_in_list() {
  local needle="$1"
  local haystack="$2"

  grep -qx "$needle" <<<"$haystack"
}

pick_next_issue() {
	local open_pr_refs candidates issue
	open_pr_refs="$(open_pr_issue_numbers)"

	candidates="$(gh issue list \
			--state open \
			--limit 100 \
			--json number,title,labels \
			--jq '
				[
					.[] |
					select(.title | startswith("Spec:") | not) |
					select(([.labels[].name] | any(. == "ready-for-agent"))) |
					select(([.labels[].name] | any(. == "status: blocked" or . == "blocked")) | not)
				] |
				sort_by(.number) |
				.[].number
			')"

  while read -r issue; do
    [[ -z "$issue" ]] && continue
    if number_in_list "$issue" "$open_pr_refs"; then
      continue
    fi
    if number_in_list "$issue" "$PROCESSED_ISSUES"; then
      continue
    fi
    echo "$issue"
    return
  done <<<"$candidates"
}

remote_branch_exists() {
  git ls-remote --exit-code --heads origin "$1" >/dev/null 2>&1
}

create_or_reuse_linked_branch() {
  local issue="$1"
  local branch="$2"

  if remote_branch_exists "$branch"; then
    echo "Remote branch already exists; reusing $branch."
    return
  fi

  create_linked_branch "$issue" "$branch"
}

copy_issue_labels_to_pr() {
  local issue="$1"
  local pr_url="$2"
  local labels label

  labels="$(gh issue view "$issue" --json labels --jq '.labels[].name')"

  while read -r label; do
    [[ -z "$label" ]] && continue
    gh pr edit "$pr_url" --add-label "$label" >/dev/null
  done <<<"$labels"
}

issue_type() {
  gh issue view "$1" --json labels --jq '
    [.labels[].name] as $labels |
    if $labels | any(. == "type: bugfix") then "bugfix"
    elif $labels | any(. == "type: docs") then "docs"
    elif $labels | any(. == "type: refactor") then "refactor"
    elif $labels | any(. == "type: chore") then "chore"
    else "feature" end'
}

create_linked_branch() {
  local issue="$1"
  local branch="$2"
  local repo_id issue_id base_oid

  repo_id="$(gh repo view --json id --jq '.id')"
  issue_id="$(gh issue view "$issue" --json id --jq '.id')"
  base_oid="$(git rev-parse origin/develop)"

  gh api graphql \
    -f query='mutation($issueId:ID!, $repositoryId:ID!, $oid:GitObjectID!, $name:String!) { createLinkedBranch(input:{issueId:$issueId, repositoryId:$repositoryId, oid:$oid, name:$name}) { linkedBranch { ref { name } } } }' \
    -f issueId="$issue_id" \
    -f repositoryId="$repo_id" \
    -f oid="$base_oid" \
    -f name="$branch" >/dev/null
}

build_prompt() {
  local issue="$1"
  local title="$2"
  local body="$3"
  local prompt_file="$4"

  cat >"$prompt_file" <<PROMPT
Implement GitHub issue #$issue: $title

Rules:
- Keep the change tightly scoped to this issue.
- Prefer editing only files named or strongly implied by the issue.
- Do not create verifier/test scripts in squared-2/scripts/tests.
- Do not merge PRs, approve PRs, close issues, change branch protection, or push to main/develop.
- Do not create release branches.
- Do not run broad refactors or rename unrelated concepts.
- If the issue is ambiguous, make the smallest reasonable implementation and document assumptions in the commit/PR.

Issue body:
$body
PROMPT
}

run_one_ticket() {
  local issue="$1"
  local title body kind slug branch prompt_file pr_body pr_url

  title="$(gh issue view "$issue" --json title --jq '.title')"
  body="$(gh issue view "$issue" --json body --jq '.body')"
  kind="$(issue_type "$issue")"
  slug="$(slugify "$title")"
  branch="feature/codex_agent/$kind-$issue-$slug"

  echo "Ticket #$issue: $title"
  echo "Branch: $branch"

  git fetch origin develop
  git checkout develop
  git merge --ff-only origin/develop
  create_or_reuse_linked_branch "$issue" "$branch"

  if remote_branch_exists "$branch"; then
    git fetch origin "$branch"
    git checkout -B "$branch" "origin/$branch"
  else
    echo "Remote branch was not created yet; creating local branch from origin/develop."
    git checkout -B "$branch" origin/develop
  fi

  prompt_file="$(mktemp)"
  build_prompt "$issue" "$title" "$body" "$prompt_file"

  aider --model "$MODEL" --yes-always --no-auto-commits --message-file "$prompt_file"

  if [[ -z "$(git status --porcelain)" ]]; then
    echo "No changes for #$issue; skipping PR."
    return
  fi

  git add -A
  git commit -m "$kind: $title" -m "Refs #$issue"
  git push origin "$branch"

  pr_body="$(mktemp)"
  cat >"$pr_body" <<PRBODY
## Summary
Automated implementation for #$issue via Aider + $MODEL.

Refs #$issue

## Verification
- Human playtesting required.
- No committed verifier scripts were added.

## Deploy impact
none; develop does not trigger the current itch.io deploy.
PRBODY

  pr_url="$(gh pr create \
    --base develop \
    --head "$branch" \
    --title "$kind: $title" \
    --body-file "$pr_body")"

  copy_issue_labels_to_pr "$issue" "$pr_url"
  echo "$pr_url"
  PROCESSED_ISSUES="${PROCESSED_ISSUES}${issue}
"
}

require_clean_tree

for ((i = 1; i <= MAX_TICKETS; i++)); do
  next_issue="$ISSUE_NUM"
  if [[ -z "$next_issue" ]]; then
    next_issue="$(pick_next_issue)"
  fi

  if [[ -z "$next_issue" ]]; then
    echo "No open unblocked tickets found."
    exit 0
  fi

  run_one_ticket "$next_issue"
  ISSUE_NUM=""
done
