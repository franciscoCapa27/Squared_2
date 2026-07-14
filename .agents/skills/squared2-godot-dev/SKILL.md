---
name: squared2-godot-dev
description: Use for Squared² Godot development tasks in this repository: gameplay systems, GDScript, scenes, UI, `.tres` content, economy tuning, Traits, Buy Trait progression, passive generators, achievements, save/load, Godot export/deploy concerns, or planning implementation issues. Applies the project's resource-driven architecture, minimal cosmic UI direction, incremental-game pacing, and safety checks.
---

# Squared² Godot Dev

## Start Here

- Use `.agents/skills/squared2-git-flow/SKILL.md` for issues, branches, labels, PRs, releases, and deploy impact.
- Read `squared_2_game_design_document.md` before changing gameplay feel, economy, progression, naming, or tone.
- Read `docs/TECHNICAL_OVERVIEW.md` before changing systems, autoloads, save/load, or resource contracts.
- Inspect nearby scripts/scenes/resources before editing. Prefer existing patterns over new abstractions.

## Project Shape

- Godot project root: `squared-2/`
- Main scene: `squared-2/scenes/main/Main.tscn`
- Core scripts: `squared-2/scripts/core/`
- Autoload systems: `squared-2/scripts/autoload/`
- Resource definitions: `squared-2/scripts/resources/`
- Content resources: `squared-2/data/`
- UI scripts: `squared-2/scripts/ui/`
- Square interaction: `squared-2/scripts/squares/`
- Calculators/formatters: `squared-2/scripts/systems/`

## Design Intent

Preserve the core fantasy:

- A single square in the void becomes a personal geometric universe.
- Buying Traits should be fast, especially early. It is a permanent mutation action, not a run reset.
- Condensation is the future reset layer; do not implement it as part of Buy Trait work.
- Permanent square identity matters. Traits should make squares feel remembered.
- Active and idle play should both feel viable.
- Tone should be lonely, ethereal, geometric, cosmic, quiet, minimal, mysterious, and gradually alive.

Avoid turning the UI into a generic dashboard or loud mobile-idle game. The experience can become richer, but should keep its quiet abstract identity.

## Architecture Rules

- Keep content resource-driven when practical. Add traits, upgrades, generators, achievements, and themes as `.tres` resources backed by existing definition classes.
- Keep run-layer state separate from permanent-layer state.
- Route cross-system updates through `EventBus` or existing system signals instead of direct UI-to-system tangles.
- Respect autoload responsibilities:
  - `GameState`: currencies, grid, Buy Trait count, and permanent square state.
  - `PassiveSystem`: passive generators and pulses.
  - `RunUpgradeSystem`: run-limited upgrade levels and run stats.
  - `VertexUpgradeSystem`: permanent vertex upgrades.
  - `AchievementSystem`: achievement checks and rewards.
  - `SaveSystem`: serialization, autosave, import/export, hard reset.
- Add new effect types only when existing resource effect components cannot express the behavior cleanly.
- Avoid broad refactors while adding content or tuning values.

## GDScript And Godot Conventions

- Follow the current typed GDScript style: explicit types, `class_name` where already used, and small helper methods.
- Treat Godot/GDScript reserved words as forbidden identifiers. In Godot 4.x, do not use `trait` as a variable name; use `trait_iter` for `TraitInstance` loop variables.
- Prefer Godot signals and scene/resource APIs over ad hoc global lookups.
- Do not edit `.godot/` editor cache files as part of normal work.
- Be careful with `.uid` files: preserve them when editing existing scripts/resources; only create new ones through Godot/editor import flows when needed.
- For `.tres` changes, preserve Godot resource syntax and existing exported field names.
- Keep comments rare and useful; explain non-obvious game rules or save compatibility concerns.

## UI Direction

- Keep the UI minimal, readable, and workmanlike, but not sterile.
- Improve feedback where it clarifies the loop: square click, Buy Trait readiness, Trait gained, passive pulse, unlocks, and save/import state.
- Keep feature visibility progressive. Do not show every panel before the player has context.
- Reuse `ThemeSystem`, `ThemeTextHelper`, `ThemeButtonHelper`, and `ThemeLayoutHelper` instead of styling one-off controls.
- Avoid large decorative UI unless it supports the geometric/cosmic tone and real gameplay readability.

## Economy And Content

- Treat first-session pacing as sacred: the first Buy Trait should arrive within a few minutes.
- Tune active clicks, run upgrades, passive generators, Buy Trait cost, Vertex gain, and grid costs together.
- When adding content, prefer a small coherent pack over one isolated resource.
- Give each new content item a clear role: faster play, bigger payouts, passive support, trait identity, grid progression, or quality of life.
- Watch for multiplicative stacking. Note expected early/mid impact in PRs when changing economy values.

## Save/Load Safety

- Be conservative with saved field names and save schema changes.
- If adding persistent data, update `to_save_dict()` and `from_save_dict()` together.
- Provide defaults for older saves.
- Test or reason through hard reset, save import/export, and the rule that Buy Trait does not reset run state. Condensation will own future reset behavior.

## Verification

Use the lightest verification that meaningfully covers the change:

- For docs/skills/gitignore changes: read files back and check `git status`.
- For content resources: inspect loaded database patterns and verify IDs, requirements, costs, and field names.
- For gameplay systems: run Godot headless import/export checks when available, or document why they were not run.
- For save changes: verify new-game, load with missing fields, export/import, and hard reset paths.
- For UI changes: inspect scene/script wiring and, when possible, run the project or capture screenshots.

Always report verification in the PR body. If Godot is unavailable locally, say so plainly and include static checks performed.

## Godot CLI Setup And Checks

The project currently targets Godot 4.6. Install the matching Godot 4.6 stable macOS application from the official Godot download or with Homebrew:

```bash
brew install --cask godot
```

The CLI is included inside the application bundle. If `godot` is not already on `PATH`, expose it for Codex, Aider, and terminal sessions:

```bash
mkdir -p "$HOME/.local/bin"
ln -sf "/Applications/Godot.app/Contents/MacOS/Godot" "$HOME/.local/bin/godot"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zprofile"
source "$HOME/.zprofile"
godot --version
```

Run these checks from the repository root after gameplay, scene, or GDScript changes:

```bash
godot --headless --path squared-2 --editor --quit
git diff --check
```

The headless editor boot imports project resources and parses referenced scenes/scripts without launching the interactive game. Do not add committed verifier scripts just to replace this check. Use actual Godot playtesting for interaction, timing, layout, and game-feel validation.

## Planning Issues

Good Squared² development issues should include:

- Player-facing goal.
- Finalized design decision. Do not leave Aider/DeepSeek to invent mechanics, economy roles, trait identities, stat targets, or UI behavior.
- Exact changes when possible: resource ids, stat names, value ranges, target scripts/scenes, and copy constraints.
- Unsupported paths to avoid, especially new stats/effects/systems that the current architecture does not consume.
- System/content files likely touched.
- Acceptance criteria tied to the core loop.
- Verification plan.
- Deploy impact.

Prefer issues that are small enough to merge independently: one bug fix, one content pack, one UI feedback improvement, or one architecture seam.

Before marking a ticket `ready-for-agent`, ask: "Could a cheap executor implement this without making a game-design decision?" If not, keep the ticket in Codex/user design until the mechanic and constraints are explicit.

## Aider/DeepSeek Executor Prompt Notes

When `run_ticket.sh` delegates to Aider/DeepSeek, it should remind the executor:

- Aider is an executor, not the game designer; follow the ticket exactly.
- Avoid reserved keywords as local variable names, especially `trait`.
- Prefer `trait_iter`, `square_data`, `trait_definition`, and other existing local naming patterns.
- Keep content resource-driven. If existing `.tres` fields such as `name_prefixes`, `name_suffixes`, visual weights, costs, or effect components can express the change, prefer those over hardcoded dictionaries.
- Do not invent new stats, currencies, effect types, systems, or resource fields unless the ticket explicitly asks for that architecture.
- Do not add committed verifier scripts by default; report static checks and leave real validation to Godot playtesting.
