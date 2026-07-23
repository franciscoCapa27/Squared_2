## Agent skills

### Issue tracker

Issues and PRDs live in GitHub Issues. See `docs/agents/issue-tracker.md`.

### Triage labels

Use the default `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, and `wontfix` labels. See `docs/agents/triage-labels.md`.

### Domain docs

This is a single-context repository using root `CONTEXT.md` and `docs/adr/`. See `docs/agents/domain.md`.

## Git workflow (mandatory)

Always use the `squared2-git-flow` skill for GitHub work in this repository.

- Start each working session from an up-to-date `develop` branch.
- Create a session branch for the work, make the requested changes, commit them, and open a pull request from that session branch to `develop`.
- Do not push directly to `develop` or `main`.
- Do not merge the session PR unless the user explicitly approves it, or explicitly delegates approval to Codex for that situation.
- For a release, create `release/vX.Y.Z` from `develop` and open a pull request to `main`. Do not merge it without the user's approval unless the user explicitly delegates that approval to Codex.
- Treat `main` as production; merging to it triggers the itch.io web deploy.
- After a release reaches `main`, create or recommend a sync PR from `main` back to `develop`.
