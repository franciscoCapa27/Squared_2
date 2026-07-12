#!/usr/bin/env bash
set -euo pipefail

MAX_TICKETS=1
ISSUE_NUM=""
MODEL="${AIDER_MODEL:-deepseek/deepseek-v4-pro}"
PROCESSED_ISSUES=""
SESSION_SLUG=""
SESSION_BRANCH=""

usage() {
  echo "Usage: ./run_ticket.sh [--max N] [--issue NUMBER] [--session SLUG]"
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
    --session)
      SESSION_SLUG="$2"
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
  local base_ref="$3"

  if remote_branch_exists "$branch"; then
    echo "Remote branch already exists; reusing $branch."
    return
  fi

  create_linked_branch "$issue" "$branch" "$base_ref"
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
  local base_ref="$3"
  local repo_id issue_id base_oid

  repo_id="$(gh repo view --json id --jq '.id')"
  issue_id="$(gh issue view "$issue" --json id --jq '.id')"
  base_oid="$(git rev-parse "origin/$base_ref")"

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
- Godot/GDScript: avoid reserved keywords as identifiers. In particular, do not use "trait" as a variable name; use "trait_iter" for TraitInstance loops.
- Follow the repo's typed GDScript style and existing scene/resource patterns.
- Preserve Godot .tres syntax and existing exported field names.
- Prefer existing resource fields such as TraitDefinition.name_prefixes/name_suffixes before hardcoding content in scripts.
- Do not edit .godot editor cache files or create new .uid files by hand.

Issue body:
$body
PROMPT
}

target_branch() {
  if [[ -n "$SESSION_BRANCH" ]]; then
    echo "$SESSION_BRANCH"
  else
    echo "develop"
  fi
}

ensure_session_branch() {
  if [[ -z "$SESSION_SLUG" ]]; then
    return
  fi

  local session_slug
  session_slug="$(slugify "$SESSION_SLUG")"

  if [[ -z "$session_slug" ]]; then
    echo "--session must produce a non-empty slug."
    exit 1
  fi

  SESSION_BRANCH="session/aider/$(date +%F)-$session_slug"

  git fetch origin develop

  if remote_branch_exists "$SESSION_BRANCH"; then
    echo "Reusing session branch $SESSION_BRANCH."
    git fetch origin "$SESSION_BRANCH"
    git checkout -B "$SESSION_BRANCH" "origin/$SESSION_BRANCH"
  else
    echo "Creating session branch $SESSION_BRANCH from origin/develop."
    git checkout -B "$SESSION_BRANCH" origin/develop
    git push -u origin "$SESSION_BRANCH"
  fi
}

sync_target_branch() {
  local base_ref="$1"

  git fetch origin "$base_ref"
  git checkout -B "$base_ref" "origin/$base_ref"
}

unblock_ready_issues() {
  local candidates issue

  candidates="$(gh issue list \
    --state open \
    --label ready-for-agent \
    --limit 100 \
    --json number,labels,blockedBy \
    --jq '
      .[] |
      select(.blockedBy.totalCount > 0) |
      select(([.labels[].name] | any(. == "status: blocked" or . == "blocked"))) |
      select(.blockedBy.nodes | all(.state == "CLOSED")) |
      .number
    ')"

  while read -r issue; do
    [[ -z "$issue" ]] && continue
    echo "Unblocking issue #$issue; all native blockers are closed."
    gh issue edit "$issue" --remove-label "status: blocked" >/dev/null || true
    gh issue edit "$issue" --remove-label "blocked" >/dev/null || true
  done <<<"$candidates"
}

close_issue_after_session_merge() {
  local issue="$1"
  local pr_url="$2"

  if [[ "$(gh issue view "$issue" --json state --jq '.state')" == "CLOSED" ]]; then
    return
  fi

  gh issue close "$issue" \
    --comment "Closed after $pr_url merged into session branch $SESSION_BRANCH. Final develop integration will happen through the session PR." >/dev/null
}

merge_ticket_pr_into_session() {
  local issue="$1"
  local pr_url="$2"
  local title="$3"
  local kind="$4"

  echo "Session mode: merging ticket PR into $SESSION_BRANCH."
  gh pr merge "$pr_url" \
    --squash \
    --delete-branch \
    --subject "$kind: $title" \
    --body "Refs #$issue" >/dev/null

  git fetch origin "$SESSION_BRANCH"
  git checkout -B "$SESSION_BRANCH" "origin/$SESSION_BRANCH"

  close_issue_after_session_merge "$issue" "$pr_url"
  unblock_ready_issues
}

create_session_pr() {
  if [[ -z "$SESSION_BRANCH" ]]; then
    return
  fi

  if [[ -z "$PROCESSED_ISSUES" ]]; then
    echo "No tickets processed; skipping session PR."
    return
  fi

  git fetch origin develop
  git fetch origin "$SESSION_BRANCH"

  if [[ -z "$(git log --oneline "origin/develop..origin/$SESSION_BRANCH")" ]]; then
    echo "Session branch has no changes beyond develop; skipping session PR."
    return
  fi

  local existing_pr pr_body pr_url issue_lines
  existing_pr="$(gh pr list \
    --state open \
    --base develop \
    --head "$SESSION_BRANCH" \
    --json url \
    --jq '.[0].url // ""')"

  if [[ -n "$existing_pr" ]]; then
    echo "Session PR already exists: $existing_pr"
    return
  fi

  issue_lines="$(sed '/^$/d; s/^/- #/' <<<"$PROCESSED_ISSUES")"
  pr_body="$(mktemp)"

  cat >"$pr_body" <<PRBODY
## Summary
Automated Aider session branch for:
$issue_lines

Ticket PRs were merged into the session branch only. Review this PR before integrating into develop.

## Verification
- Human playtesting required.
- No committed verifier scripts were added by the wrapper.

## Deploy impact
none; develop does not trigger the current itch.io deploy.
PRBODY

  pr_url="$(gh pr create \
    --base develop \
    --head "$SESSION_BRANCH" \
    --title "session: ${SESSION_BRANCH#session/aider/}" \
    --body-file "$pr_body")"

  echo "$pr_url"
}

run_one_ticket() {
  local issue="$1"
  local title body kind slug branch prompt_file pr_body pr_url base_ref deploy_impact

  title="$(gh issue view "$issue" --json title --jq '.title')"
  body="$(gh issue view "$issue" --json body --jq '.body')"
  kind="$(issue_type "$issue")"
  slug="$(slugify "$title")"
  branch="feature/codex_agent/$kind-$issue-$slug"
  base_ref="$(target_branch)"
  deploy_impact="none; develop does not trigger the current itch.io deploy."

  if [[ -n "$SESSION_BRANCH" ]]; then
    deploy_impact="none; session branches do not trigger deploys and require a final PR into develop."
  fi

  echo "Ticket #$issue: $title"
  echo "Branch: $branch"
  echo "Base: $base_ref"

  sync_target_branch "$base_ref"
  create_or_reuse_linked_branch "$issue" "$branch" "$base_ref"

  if remote_branch_exists "$branch"; then
    git fetch origin "$branch"
    git checkout -B "$branch" "origin/$branch"
  else
    echo "Remote branch was not created yet; creating local branch from origin/$base_ref."
    git checkout -B "$branch" "origin/$base_ref"
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
$deploy_impact
PRBODY

  pr_url="$(gh pr create \
    --base "$base_ref" \
    --head "$branch" \
    --title "$kind: $title" \
    --body-file "$pr_body")"

  copy_issue_labels_to_pr "$issue" "$pr_url"
  echo "$pr_url"

  if [[ -n "$SESSION_BRANCH" ]]; then
    merge_ticket_pr_into_session "$issue" "$pr_url" "$title" "$kind"
  fi

  PROCESSED_ISSUES="${PROCESSED_ISSUES}${issue}
"
}

require_clean_tree
ensure_session_branch
unblock_ready_issues

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

create_session_pr
