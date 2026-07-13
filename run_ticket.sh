#!/usr/bin/env bash
set -euo pipefail

MAX_TICKETS=1
ISSUE_NUM=""
MODEL="${AIDER_MODEL:-deepseek/deepseek-v4-pro}"
PROCESSED_ISSUES=""
SESSION_SLUG=""
SESSION_BRANCH=""
SESSION_BRANCH_OVERRIDE=""
AUTO_MERGE_SESSION=1
CREATE_FINAL_SESSION_PR=1
DRY_RUN=0
LIST_READY=0
FINALIZE_ONLY=0

usage() {
  cat <<'USAGE'
Usage:
  ./run_ticket.sh [options]

Common modes:
  ./run_ticket.sh --max 1
      Pick the oldest ready-for-agent issue and open a PR to develop.

  ./run_ticket.sh --issue 123
      Run exactly one issue, even if older ready issues exist.

  ./run_ticket.sh --max 10 --session overnight-ui-pass
      Create/reuse session/aider/YYYY-MM-DD-overnight-ui-pass, merge ticket PRs
      into that session branch only, then open one final PR to develop.

  ./run_ticket.sh --finalize-session session/aider/YYYY-MM-DD-name
      Open the final session -> develop PR without running more tickets.

Options:
  --max N
      Maximum number of ready issues to attempt. If fewer are available, session
      mode still creates the final PR before exiting.

  --issue NUMBER
      Run one specific issue. This overrides --max to 1.

  --session SLUG
      Enable overnight session mode. The wrapper creates/reuses a branch named
      session/aider/YYYY-MM-DD-SLUG from origin/develop.

  --session-branch BRANCH
      Resume an exact existing session branch instead of deriving it from date
      and slug. Must start with session/aider/.

  --finalize-session BRANCH
      Create the final PR from an existing session branch into develop and exit.

  --model MODEL
      Override the Aider model. Defaults to AIDER_MODEL or deepseek/deepseek-v4-pro.

  --dry-run
      Show which issues would be picked and which branch mode would be used.

  --list-ready
      List unblocked ready-for-agent issues that are eligible for pickup.

  --no-auto-merge-session
      In session mode, create ticket PRs but do not merge them into the session
      branch, close issues, or unblock dependents.

  --no-final-session-pr
      In session mode, do not open the final session -> develop PR.

Safety:
  - Never pushes directly to develop, main, release/*, or hotfix/*.
  - Auto-merge is only allowed into session/aider/* branches.
  - Skips Spec: issues, blocked issues, and issues already referenced by open PRs.
USAGE
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
    --session-branch)
      SESSION_BRANCH_OVERRIDE="$2"
      shift 2
      ;;
    --finalize-session)
      SESSION_BRANCH_OVERRIDE="$2"
      FINALIZE_ONLY=1
      shift 2
      ;;
    --model)
      MODEL="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --list-ready)
      LIST_READY=1
      shift
      ;;
    --no-auto-merge-session)
      AUTO_MERGE_SESSION=0
      shift
      ;;
    --no-final-session-pr)
      CREATE_FINAL_SESSION_PR=0
      shift
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

if [[ -n "$SESSION_SLUG" && -n "$SESSION_BRANCH_OVERRIDE" ]]; then
  echo "Use either --session or --session-branch/--finalize-session, not both."
  exit 1
fi

if [[ -n "$SESSION_BRANCH_OVERRIDE" && "$SESSION_BRANCH_OVERRIDE" != session/aider/* ]]; then
  echo "--session-branch and --finalize-session must use a session/aider/* branch."
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

ready_issue_numbers() {
  gh issue list \
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
    '
}

pick_next_issue() {
  local open_pr_refs candidates issue
  open_pr_refs="$(open_pr_issue_numbers)"
  candidates="$(ready_issue_numbers)"

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

list_eligible_issues() {
  local open_pr_refs candidates issue title
  open_pr_refs="$(open_pr_issue_numbers)"
  candidates="$(ready_issue_numbers)"

  while read -r issue; do
    [[ -z "$issue" ]] && continue
    if number_in_list "$issue" "$open_pr_refs"; then
      continue
    fi
    title="$(gh issue view "$issue" --json title --jq '.title')"
    echo "#$issue $title"
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
  if [[ -n "$SESSION_BRANCH_OVERRIDE" ]]; then
    SESSION_BRANCH="$SESSION_BRANCH_OVERRIDE"

    git fetch origin "$SESSION_BRANCH"
    git checkout -B "$SESSION_BRANCH" "origin/$SESSION_BRANCH"
    return
  fi

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

  if [[ "$AUTO_MERGE_SESSION" -ne 1 ]]; then
    echo "Session auto-merge disabled; leaving ticket PR open: $pr_url"
    return
  fi

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

  if [[ "$CREATE_FINAL_SESSION_PR" -ne 1 ]]; then
    echo "Final session PR disabled."
    return
  fi

  if [[ -z "$PROCESSED_ISSUES" && "$FINALIZE_ONLY" -ne 1 ]]; then
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

  if [[ -n "$PROCESSED_ISSUES" ]]; then
    issue_lines="$(sed '/^$/d; s/^/- #/' <<<"$PROCESSED_ISSUES")"
  else
    issue_lines="- Existing session branch ${SESSION_BRANCH}"
  fi
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

dry_run_plan() {
  local shown=0 issue branch_preview session_preview title kind slug

  if [[ -n "$SESSION_BRANCH_OVERRIDE" ]]; then
    session_preview="$SESSION_BRANCH_OVERRIDE"
  elif [[ -n "$SESSION_SLUG" ]]; then
    session_preview="session/aider/$(date +%F)-$(slugify "$SESSION_SLUG")"
  else
    session_preview="develop"
  fi

  echo "Dry run only; no branches, commits, PRs, or issue edits will be made."
  echo "Model: $MODEL"
  echo "Target: $session_preview"
  echo

  if [[ -n "$ISSUE_NUM" ]]; then
    title="$(gh issue view "$ISSUE_NUM" --json title --jq '.title')"
    kind="$(issue_type "$ISSUE_NUM")"
    slug="$(slugify "$title")"
    branch_preview="feature/codex_agent/$kind-$ISSUE_NUM-$slug"
    echo "Would run #$ISSUE_NUM $title"
    echo "Would use branch $branch_preview"
    return
  fi

  while read -r issue; do
    [[ -z "$issue" ]] && continue
    title="$(gh issue view "$issue" --json title --jq '.title')"
    kind="$(issue_type "$issue")"
    slug="$(slugify "$title")"
    branch_preview="feature/codex_agent/$kind-$issue-$slug"
    echo "Would run #$issue $title"
    echo "  branch: $branch_preview"
    shown=$((shown + 1))
    if [[ "$shown" -ge "$MAX_TICKETS" ]]; then
      return
    fi
  done <<<"$(list_eligible_issues | sed 's/^#//; s/ .*//')"

  if [[ "$shown" -eq 0 ]]; then
    echo "No open unblocked tickets found."
  fi
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

if [[ "$LIST_READY" -eq 1 ]]; then
  list_eligible_issues
  exit 0
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  dry_run_plan
  exit 0
fi

require_clean_tree
ensure_session_branch
unblock_ready_issues

if [[ "$FINALIZE_ONLY" -eq 1 ]]; then
  create_session_pr
  exit 0
fi

for ((i = 1; i <= MAX_TICKETS; i++)); do
  next_issue="$ISSUE_NUM"
  if [[ -z "$next_issue" ]]; then
    next_issue="$(pick_next_issue)"
  fi

  if [[ -z "$next_issue" ]]; then
    echo "No open unblocked tickets found."
    break
  fi

  run_one_ticket "$next_issue"
  ISSUE_NUM=""
done

create_session_pr
