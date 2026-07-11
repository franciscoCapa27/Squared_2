---
name: squared2-git-flow
description: Use for the Squared² Godot repository when planning or performing GitHub work: creating issues, labels, branches, commits, pull requests, releases, hotfixes, or checking deploy-safe workflow rules. Enforces the repo's develop/main flow, Codex branch naming, PR targets, label taxonomy, and production deploy constraints.
---

# Squared² Git Flow

## Core Rules

- Treat `main` as production. A push or merge to `main` triggers the itch.io web deploy through `.github/workflows/deploy-itch-web.yml`.
- Treat `develop` as the integration branch for normal work. Feature and bugfix PRs target `develop`.
- Do not push directly to `main` or `develop`. Both branches are protected by GitHub rulesets and should only receive PR merges.
- Do not merge PRs unless the user explicitly asks. Codex may create documented PRs for user review.
- Keep release promotion explicit: `develop` should not go directly to `main`; create a `release/*` or `hotfix/*` branch in between.

## Branches

Create Codex work branches from `develop` unless the user asks for a production hotfix.

Normal branch format:

```text
feature/codex_agent/<type>-<issue-number>-<short-slug>
```

Examples:

```text
feature/codex_agent/feature-12-trait-luck
feature/codex_agent/bugfix-18-passive-generator-cost
feature/codex_agent/chore-22-ci-cleanup
feature/codex_agent/docs-25-technical-overview
feature/codex_agent/refactor-30-save-system-boundaries
```

Release branch format:

```text
release/v0.2.0
release/v0.3.0
```

Hotfix branch format:

```text
hotfix/codex_agent/hotfix-31-save-import-crash
```

## PR Targets

- Feature, bugfix, chore, docs, and refactor branches target `develop`.
- Release branches are created from `develop` and target `main`.
- Hotfix branches are created from `main` and target `main`.
- After a hotfix reaches `main`, create or recommend a back-merge PR from `main` to `develop`.

Use this flow:

```text
feature/codex_agent/type-123-short-slug
  -> PR to develop
develop
  -> release/vX.Y.Z
release/vX.Y.Z
  -> PR to main
main
  -> deploys to itch.io
```

Hotfix flow:

```text
hotfix/codex_agent/hotfix-123-short-slug
  -> PR to main
main
  -> deploys to itch.io
main
  -> PR back to develop
```

## PR Content

Every Codex-created PR should include:

- Summary of changes.
- Linked issue, when one exists.
- Labels that classify release impact, type, area, and priority.
- Verification performed, including commands run or why testing was not possible.
- Deploy impact, especially whether the PR can reach `main`.

For PRs targeting `develop`, state:

```text
Deploy impact: none; develop does not trigger the current itch.io deploy.
```

For PRs targeting `main`, state:

```text
Deploy impact: merging to main triggers the itch.io web deploy.
```

## Labels

Use these labels for issues and PRs.

Release impact:

```text
release: major
release: minor
release: patch
release: hotfix
```

Work type:

```text
type: feature
type: bugfix
type: hotfix
type: chore
type: docs
type: refactor
```

Area:

```text
area: godot
area: gameplay
area: economy
area: ui
area: save-system
area: ci
area: content
```

Priority:

```text
priority: p0
priority: p1
priority: p2
```

Prefer one release label, one type label, one or more area labels, and one priority label.

## Issue Planning

When creating tickets, keep each issue scoped to one mergeable change. Prefer issue titles that can become branch slugs.

Suggested issue format:

```markdown
## Goal

## Scope

## Acceptance Criteria

## Verification
```

Apply labels at creation time when possible.

## Safety Checks

Before creating a branch or PR:

1. Confirm the current branch and working tree.
2. Do not overwrite uncommitted user changes.
3. Start normal work from up-to-date `develop`.
4. Start hotfix work from up-to-date `main`.
5. Confirm PR target matches the branch purpose.

Before touching deployment workflow:

1. Read `.github/workflows/deploy-itch-web.yml`.
2. Remember that current deploy triggers are `push` to `main` and `workflow_dispatch`.
3. Avoid adding a `develop` deploy unless the user explicitly asks.
