# Squared² — Technical Overview

Last updated: 2026-06-09

## 1. Project Summary

**Squared²** is a 2D incremental / prestige game built in **Godot 4.6**.

The core fantasy is that the player starts with a single square in empty space. Clicking the square generates **Squares**, the base currency. After reaching a threshold, the player can **prestige**, resetting run-based progress in exchange for **Vertices**, the meta currency. Prestiging also expands the grid and gives a random square a persistent **Trait**, slowly turning the board into a unique, history-bearing system.

The project direction is:

* fast early prestige loops;
* permanent square identity;
* random Trait assignment;
* data-driven systems;
* scalable passive generation;
* permanent Vertex upgrades;
* exportable save files;
* UI built from reusable components rather than hardcoded one-off logic.

The current focus is technical foundation and gameplay systems. Visual polish is intentionally secondary.

---

## 2. Project Structure

Current high-level structure:

```text
res://
  data/
    passive_generators/
      first_generator.tres
      value_harvester.tres

    traits/
      common/
        common_dense.tres
        common_quick.tres

    vertex_upgrades/
      unlock_first_generator.tres
      unlock_value_harvester.tres
      sharpened_origin.tres

  scenes/
    main/
      Main.tscn

    squares/
      SquareButton.tscn

    ui/
      PassiveGeneratorCard.tscn
      VertexUpgradeCard.tscn

  scripts/
    autoload/
      event_bus.gd
      game_state.gd
      passive_generator_database.gd
      passive_system.gd
      save_system.gd
      trait_database.gd
      vertex_upgrade_database.gd

    core/
      passive_generator_instance.gd
      square_data.gd
      trait_instance.gd

    main/
      main.gd

    resources/
      effect_component.gd
      passive_generator_definition.gd
      trait_definition.gd
      vertex_upgrade_definition.gd
      vertex_upgrade_effect.gd
      visual_profile.gd

    squares/
      square_button.gd

    systems/
      square_calculator.gd

    ui/
      passive_generator_card.gd
      vertex_upgrade_card.gd
```

---

## 3. Autoloads

The project uses several autoload singletons.

Recommended autoload order:

```text
EventBus
TraitDatabase
VertexUpgradeDatabase
PassiveGeneratorDatabase
GameState
PassiveSystem
SaveSystem
```

### 3.1 EventBus

Path:

```text
res://scripts/autoload/event_bus.gd
```

Purpose:

Global signal hub for UI and systems.

Current responsibilities:

* currency updates;
* prestige count updates;
* grid rebuild notifications;
* selected square notifications;
* story/status messages.

Typical signals:

```gdscript
signal squares_changed(value: float)
signal vertices_changed(value: int)
signal prestige_changed(value: int)
signal grid_changed()
signal square_selected(square_id: String)
signal story_message(message: String)
```

---

### 3.2 TraitDatabase

Path:

```text
res://scripts/autoload/trait_database.gd
```

Purpose:

Loads all Trait resources from:

```text
res://data/traits/
```

Responsibilities:

* recursively load `.tres` / `.res` Trait definitions;
* store traits by ID;
* provide random weighted Trait selection;
* filter Traits by grid tier;
* provide Trait lookups during save load.

Important design note:

`TraitDatabase` is an autoload singleton and should not also use `class_name TraitDatabase`, to avoid name conflicts with the autoload.

---

### 3.3 VertexUpgradeDatabase

Path:

```text
res://scripts/autoload/vertex_upgrade_database.gd
```

Purpose:

Loads all permanent Vertex upgrade resources from:

```text
res://data/vertex_upgrades/
```

Responsibilities:

* recursively load `VertexUpgradeDefinition` resources;
* store upgrades by ID;
* sort upgrades by `sort_order`;
* expose visible upgrades for the Vertex Shop;
* support dependency-based visibility.

This enables tree-like upgrade progression.

Example:

```text
Unlock First Generator
        ↓
Sharpened Origin
        ↓
future upgrades
```

An upgrade can require one dependency or many dependencies through:

```gdscript
required_upgrade_ids: Array[String]
```

Visibility is controlled with:

```gdscript
hidden_until_requirements_met: bool
```

---

### 3.4 PassiveGeneratorDatabase

Path:

```text
res://scripts/autoload/passive_generator_database.gd
```

Purpose:

Loads passive generator definitions from:

```text
res://data/passive_generators/
```

Responsibilities:

* recursively load `PassiveGeneratorDefinition` resources;
* store passive generator definitions by ID;
* expose all generator definitions to `PassiveSystem`;
* allow new passive generators to be added without changing code.

Current passive generator resources:

```text
first_generator.tres
value_harvester.tres
```

---

### 3.5 GameState

Path:

```text
res://scripts/autoload/game_state.gd
```

Purpose:

Main runtime game state.

Responsibilities:

* hold current currency values;
* hold prestige count;
* hold grid size;
* own square data;
* handle square clicks;
* handle prestige;
* handle Vertex upgrade purchases;
* apply permanent Vertex upgrade effects;
* expose save/load serialization.

Important state includes:

```gdscript
var squares: float
var vertices: int
var prestige_count: int
var grid_size: int

var square_ids: Array[String]
var squares_by_id: Dictionary

var unlocked_vertex_upgrades: Dictionary
var permanent_stat_multipliers: Dictionary
```

`unlocked_vertex_upgrades` stores permanent meta-upgrade purchase counts.

Example:

```gdscript
{
  "unlock_first_generator": 1,
  "sharpened_origin": 1
}
```

`permanent_stat_multipliers` stores permanent economy modifiers.

Example:

```gdscript
{
  "square_base_value": 1.1
}
```

---

### 3.6 PassiveSystem

Path:

```text
res://scripts/autoload/passive_system.gd
```

Purpose:

Runtime passive generator manager.

Responsibilities:

* create runtime `PassiveGeneratorInstance` objects from data definitions;
* unlock generators permanently;
* tick active generators;
* select target squares;
* generate passive Squares;
* handle run-based passive levels;
* reset run-based passive state on prestige;
* expose save/load serialization.

Important design:

Passive generators have two layers of progression:

```text
Permanent unlock:
  Bought with Vertices.
  Survives prestige.

Run-based level:
  Bought with Squares.
  Resets to 0 on prestige.
```

Example:

```text
Unlock First Generator with Vertices.
It remains permanently available.
Each run it starts at Level 0.
Buy Level 1 with Squares to activate it.
Prestige resets it back to Level 0.
```

---

### 3.7 SaveSystem

Path:

```text
res://scripts/autoload/save_system.gd
```

Purpose:

Centralized save/load/export/import/hard-reset manager.

Responsibilities:

* save game data to disk;
* load game data from disk;
* export save data as a compressed Base64 string;
* import save data from a compressed Base64 string;
* hard reset the game;
* emit save/load status signals.

Save path:

```text
user://savegame.json
```

Export format:

```text
Save dictionary
  -> JSON
  -> UTF-8 bytes
  -> GZIP compression
  -> Base64 string
```

This makes export/import compatible with the typical incremental-game save pattern without requiring a separate save structure.

Current save policy:

* Manual save exists in Options.
* Export/import exists in Options.
* Hard reset exists in Options.
* Prestige triggers an automatic save because it is an irreversible milestone.
* Normal upgrades and Vertex purchases do not currently force-save.
* A configurable timed autosave should be added later through Options.

Intended future autosave behavior:

```text
Autosave every X seconds/minutes, configurable by the player.
0 or disabled = no timed autosave.
Prestige still force-saves.
Manual save remains available.
```

---

## 4. Core Runtime Data

### 4.1 SquareData

Path:

```text
res://scripts/core/square_data.gd
```

Purpose:

Represents the real runtime state of a square. It is not a UI node.

Responsibilities:

* square identity;
* coordinate;
* display name;
* grid position;
* Traits;
* tags;
* visual profile;
* base stats;
* run stats;
* lifetime stats;
* save/load serialization.

Important distinction:

```text
SquareData = gameplay state
SquareButton = visual UI representation
```

A square can survive across many prestiges and accumulate history.

Important fields include:

```gdscript
var id: String
var coordinate: String
var display_name: String

var grid_x: int
var grid_y: int

var traits: Array[TraitInstance]

var base_value: float
var base_respawn_time: float

var run_squares_generated: float
var run_manual_clicks: int
var run_passive_clicks: int

var lifetime_squares_generated: float
var lifetime_manual_clicks: int
var lifetime_passive_clicks: int

var times_traited: int
var times_selected_for_prestige: int
```

SquareData supports:

```gdscript
to_save_dict()
from_save_dict(data)
```

---

### 4.2 TraitInstance

Path:

```text
res://scripts/core/trait_instance.gd
```

Purpose:

Runtime instance of a Trait on a specific square.

`TraitDefinition` is the blueprint. `TraitInstance` is the actual rolled instance.

Responsibilities:

* reference the Trait definition;
* store rolled effect values;
* store acquisition metadata;
* store stack index;
* store copy/absorb metadata for future mechanics;
* expose effect summary text;
* save/load serialization.

Important design:

Trait values are rolled once when acquired, then stored.

Example:

```text
Common Dense
+37.2% square value
+8.4% respawn time
```

Those rolls should persist after save/load.

This is why `TraitInstance` stores:

```gdscript
var rolled_values: Dictionary
```

Save/load behavior:

* On load, the Trait definition is looked up by `definition_id`.
* A new TraitInstance is created.
* Its `rolled_values` are overwritten from save data.
* This prevents Traits from rerolling after load.

Important naming note:

Do not use `trait` as a variable name in GDScript because it is reserved. Use names like:

```gdscript
trait_iter
trait_instance
trait_definition
```

---

### 4.3 PassiveGeneratorInstance

Path:

```text
res://scripts/core/passive_generator_instance.gd
```

Purpose:

Runtime state of a passive generator.

`PassiveGeneratorDefinition` is the data resource. `PassiveGeneratorInstance` is the runtime state.

Responsibilities:

* store unlock state;
* store current run level;
* store current progress timer;
* store self-prestige state for future use;
* track lifetime/run pulses;
* calculate current interval;
* calculate current extraction rate;
* calculate next level cost;
* save/load serialization.

Important fields:

```gdscript
var definition: PassiveGeneratorDefinition

var is_unlocked: bool
var level: int

var self_prestige_level: int
var can_self_prestige: bool

var elapsed_seconds: float
var last_target_square_id: String
var last_payout: float
var lifetime_squares_generated: float
var lifetime_pulses: int
```

Important behavior:

```text
is_unlocked = permanent
level = run-based
level 0 = unlocked but inactive
level > 0 = active
```

---

## 5. Resource Definitions

### 5.1 TraitDefinition

Path:

```text
res://scripts/resources/trait_definition.gd
```

Purpose:

Data blueprint for a Trait.

A TraitDefinition stores:

* ID;
* display name;
* family ID;
* rarity;
* tags;
* weight;
* grid requirements;
* stack rules;
* effect components;
* naming components;
* visual influence.

Traits are stored as resources in:

```text
res://data/traits/
```

Current Traits:

```text
common_dense
common_quick
```

Current direction:

Rarities should be represented as separate TraitDefinition resources.

Example:

```text
common_dense.tres
rare_dense.tres
legendary_dense.tres
```

All can share:

```gdscript
family_id = "dense"
```

but have different exact IDs and tuning.

---

### 5.2 EffectComponent

Path:

```text
res://scripts/resources/effect_component.gd
```

Purpose:

Generic effect data used by Traits.

Currently used for stat modifiers such as:

```text
square_value
respawn_time
```

Supports rolled values through:

```gdscript
use_value_range
value_min
value_max
roll_key
roll_decimals
```

`roll_key` is important because multiple effects can affect the same target stat. It gives each rolled value a stable save key.

Example:

```text
square_value_multiplier
respawn_time_multiplier
```

---

### 5.3 VertexUpgradeDefinition

Path:

```text
res://scripts/resources/vertex_upgrade_definition.gd
```

Purpose:

Data blueprint for a permanent Vertex upgrade.

Stored in:

```text
res://data/vertex_upgrades/
```

Important fields:

```gdscript
id
display_name
description
category
cost_vertices
sort_order

required_prestige_count
required_grid_size
required_upgrade_ids
hidden_until_requirements_met

is_repeatable
max_purchases

effects
```

This allows upgrade trees.

Example:

```text
unlock_value_harvester requires unlock_first_generator
sharpened_origin requires unlock_first_generator
```

---

### 5.4 VertexUpgradeEffect

Path:

```text
res://scripts/resources/vertex_upgrade_effect.gd
```

Purpose:

Generic effect attached to a VertexUpgradeDefinition.

Current effect types include:

```gdscript
UNLOCK_PASSIVE_GENERATOR
GLOBAL_STAT_MULTIPLIER
UNLOCK_MECHANIC
ADD_STARTING_SQUARES
UNLOCK_TAB
SCRIPT_HOOK
```

Currently implemented effects:

```text
UNLOCK_PASSIVE_GENERATOR
GLOBAL_STAT_MULTIPLIER
```

Examples:

```text
Unlock First Generator:
  effect_type = UNLOCK_PASSIVE_GENERATOR
  target_id = first_generator

Sharpened Origin:
  effect_type = GLOBAL_STAT_MULTIPLIER
  target_stat = square_base_value
  value = 1.10
```

---

### 5.5 PassiveGeneratorDefinition

Path:

```text
res://scripts/resources/passive_generator_definition.gd
```

Purpose:

Data blueprint for a passive generator.

Stored in:

```text
res://data/passive_generators/
```

Important fields:

```gdscript
id
display_name
description
sort_order

max_level

base_interval_seconds
minimum_interval_seconds
interval_level_multiplier

base_extraction_rate
extraction_per_level
maximum_extraction_rate

base_level_cost
level_cost_multiplier

targeting_mode

self_prestige_is_permanent
self_prestige_unlock_level
```

Current passive generators:

```text
first_generator
value_harvester
```

Example identities:

```text
First Generator:
  random target
  faster
  lower extraction

Value Harvester:
  highest-payout target
  slower
  higher extraction
```

---

## 6. Systems

### 6.1 SquareCalculator

Path:

```text
res://scripts/systems/square_calculator.gd
```

Purpose:

Central calculation system for square payouts and respawn time.

Responsibilities:

* calculate manual payout;
* calculate respawn time;
* apply Trait effects;
* apply permanent stat multipliers.

Current manual payout flow:

```text
square base value
x permanent square_base_value multiplier
x square manual multiplier
x temporary value multiplier
x Trait modifiers
```

Example:

```text
base value = 1.0
Sharpened Origin = x1.10
Dense roll = x1.35

final payout = 1.0 * 1.10 * 1.35 = 1.485
```

Important:

Permanent modifiers such as `square_base_value` are stored in `GameState.permanent_stat_multipliers`.

---

### 6.2 Prestige System

Current prestige behavior:

* requires enough Squares;
* grants Vertices;
* increments prestige count;
* resets current Squares;
* resets run-based passive generator levels;
* expands grid when applicable;
* applies one random Trait to one random square;
* emits UI update signals;
* saves the game after prestige.

Current dev-tuned threshold:

```text
10 Squares
```

Current Vertex gain formula:

```gdscript
floor(sqrt(squares / 10.0))
```

This is intentionally low for development testing.

Important design:

Prestige should be an irreversible milestone, so it triggers a forced save.

---

### 6.3 Vertex Upgrade System

Permanent Vertex upgrades are data-driven.

Flow:

```text
VertexUpgradeDatabase loads resources
Vertex Shop renders visible upgrade cards
Player buys upgrade
GameState validates requirements/cost
GameState applies upgrade effects
Purchased upgrade count is stored
UI refreshes
```

Current upgrades:

```text
unlock_first_generator
unlock_value_harvester
sharpened_origin
```

Current dependency example:

```text
unlock_first_generator
   ├── sharpened_origin
   └── unlock_value_harvester
```

`sharpened_origin`:

* hidden until `unlock_first_generator` is purchased;
* costs 5 Vertices;
* permanently multiplies all square base value by 1.10.

---

### 6.4 Passive Generator System

Passive generators are data-driven.

Flow:

```text
PassiveGeneratorDatabase loads generator definitions
PassiveSystem creates runtime instances
Vertex upgrades unlock generators permanently
Unlocked generators appear in the passive UI
Player buys run-based levels with Squares
Active generators tick independently
Prestige resets levels to 0
Permanent unlocks remain
```

Current passive generators:

```text
First Generator
Value Harvester
```

First Generator:

```text
Targeting: random square
Base interval: 2.5s
Base extraction: 25%
Level 1 cost: 10 Squares
```

Value Harvester:

```text
Targeting: highest payout square
Base interval: 4.0s
Base extraction: 50%
Level 1 cost: 50 Squares
```

Important behavior:

```text
Unlocked but Level 0 = visible but inactive.
Level 1+ = active.
Levels reset on prestige.
Unlock state does not reset on prestige.
```

---

## 7. UI Architecture

### 7.1 Main Scene

Main scene:

```text
res://scenes/main/Main.tscn
```

The main UI currently contains:

```text
Resources
Center tab banner
Left passive panel
Center page area
Right square details panel
Story/status label
```

Center pages currently include:

```text
Grid
Vertex Shop
Options
```

Future pages may include:

```text
Achievements
Statistics
Settings
Debug
```

---

### 7.2 Center Tabs

The center tab banner sits below the resource display.

Current intended tabs:

```text
Grid
Vertex Shop
Options
Achievements
```

The tab system switches which center page is visible.

This is deliberately more scalable than having everything inside `main.gd` as one static layout.

---

### 7.3 VertexUpgradeCard

Scene:

```text
res://scenes/ui/VertexUpgradeCard.tscn
```

Script:

```text
res://scripts/ui/vertex_upgrade_card.gd
```

Purpose:

Reusable UI component for one Vertex upgrade.

Responsibilities:

* display upgrade title;
* display category and cost;
* display description;
* display requirements;
* display purchased/locked/available state;
* emit `buy_requested(upgrade_id)`.

The Vertex Shop dynamically creates one card per visible upgrade.

---

### 7.4 PassiveGeneratorCard

Scene:

```text
res://scenes/ui/PassiveGeneratorCard.tscn
```

Script:

```text
res://scripts/ui/passive_generator_card.gd
```

Purpose:

Reusable UI component for one unlocked passive generator.

Responsibilities:

* display generator name;
* display level;
* display interval;
* display extraction;
* display targeting mode;
* display progress bar;
* display last pulse;
* display run totals;
* display next level cost;
* emit `upgrade_requested(generator_id)`.

The passive panel dynamically creates one card per unlocked passive generator.

---

### 7.5 Options Page

The Options page currently contains save-management actions.

Current options:

```text
Save Game
Export Save
Import Save
Hard Reset
```

Save export/import uses a compressed Base64 string.

Future Options work:

```text
Autosave enabled/disabled
Autosave interval
Confirm hard reset
UI scale
Number formatting
Accessibility settings
Debug tools
```

---

## 8. Save / Load System

### 8.1 Save Philosophy

The save system should preserve meaningful progression without forcing a save on every minor change.

Current design:

```text
Manual Save:
  Player-triggered from Options.

Auto-save on prestige:
  Forced because prestige is irreversible and meaningful.

Export:
  Player-triggered from Options.

Import:
  Player-triggered from Options.

Hard Reset:
  Player-triggered from Options.
```

Current non-goals:

```text
Do not force-save every passive level purchase.
Do not force-save every Vertex upgrade purchase.
Do not force-save every click.
Do not save every frame.
```

Planned:

```text
Configurable autosave interval from Options.
```

---

### 8.2 Save Data Contents

Top-level save structure:

```json
{
  "version": 1,
  "game_state": {},
  "passive_system": {}
}
```

`game_state` includes:

```text
Squares
Vertices
Prestige count
Grid size
Square IDs
Square data
Unlocked Vertex upgrades
Permanent stat multipliers
```

`passive_system` includes:

```text
Passive generator unlock states
Current run levels
Progress timers
Self-prestige state
Last pulse info
Run generated totals
```

---

### 8.3 Export / Import

Export converts the save dictionary into a portable text string.

Pipeline:

```text
Dictionary
  -> JSON
  -> UTF-8 buffer
  -> GZIP-compressed bytes
  -> Base64 string
```

Import reverses the process.

This allows players to copy/paste their save string and restore progress later.

---

### 8.4 Hard Reset

Hard reset should clear:

```text
Squares
Vertices
Prestige count
Grid progress
Square Traits
Vertex upgrades
Permanent stat multipliers
Passive unlocks
Passive levels
Save file
```

After hard reset, the game should return to:

```text
1x1 grid
single untraited square
0 Squares
0 Vertices
0 Prestiges
no passive systems
no permanent upgrades
```

---

## 9. Current Gameplay Loop

Current loop:

```text
Click square
Gain Squares
Reach prestige threshold
Prestige
Gain Vertices
Grid expands
Random square gains random Trait
Spend Vertices on permanent upgrades
Unlock passive generators
Buy run-based passive levels with Squares
Gain more Squares
Prestige again
```

Current early progression:

```text
Start:
  1 square

First prestige:
  gain 1 Vertex
  grid becomes 2x2
  one random square gains one random Trait

Vertex Shop:
  unlock First Generator

After unlocking First Generator:
  buy Level 1 with Squares each run

Later:
  unlock Value Harvester
  buy Sharpened Origin
```

---

## 10. Current Data Content

### Traits

Current Trait resources:

```text
common_dense
common_quick
```

Common Dense:

```text
Increases square value.
Increases respawn time.
```

Common Quick:

```text
Reduces respawn time.
Slightly reduces square value.
```

Both use rolled effect values.

---

### Vertex Upgrades

Current Vertex upgrades:

```text
unlock_first_generator
unlock_value_harvester
sharpened_origin
```

`unlock_first_generator`:

```text
Cost: 1 Vertex
Effect: permanently unlocks First Generator
```

`unlock_value_harvester`:

```text
Cost: 2 Vertices
Requires: unlock_first_generator
Effect: permanently unlocks Value Harvester
```

`sharpened_origin`:

```text
Cost: 5 Vertices
Requires: unlock_first_generator
Effect: permanent x1.10 square_base_value multiplier
```

---

### Passive Generators

Current passive generators:

```text
first_generator
value_harvester
```

`first_generator`:

```text
Targets random square.
Faster and cheaper.
Lower extraction.
```

`value_harvester`:

```text
Targets highest-payout square.
Slower and more expensive.
Higher extraction.
```

---

## 11. Technical Principles

### 11.1 Data-driven first

New content should usually be added through `.tres` resources, not hardcoded matches.

Current data-driven systems:

```text
Traits
Vertex upgrades
Passive generators
```

Preferred future pattern:

```text
Definition resource
Runtime instance if needed
Database autoload
Reusable UI card/page
System-level effect application
```

---

### 11.2 Runtime state separate from definitions

Blueprint data and runtime state should stay separate.

Examples:

```text
TraitDefinition vs TraitInstance
PassiveGeneratorDefinition vs PassiveGeneratorInstance
VertexUpgradeDefinition vs purchased upgrade count
```

This makes save/load clearer and avoids mutating design-time resources.

---

### 11.3 UI components should be reusable

Avoid building every UI interaction directly inside `main.gd`.

Current reusable UI components:

```text
VertexUpgradeCard
PassiveGeneratorCard
```

Future UI work should continue moving logic into page/card scripts.

Likely future components:

```text
OptionsPage
GridPage
SquareDetailsPanel
AchievementCard
StatRow
ConfirmationDialog
```

---

### 11.4 Avoid reserved names in GDScript

Do not use:

```gdscript
trait
```

as a variable name.

Use:

```gdscript
trait_iter
trait_instance
trait_definition
```

This avoids GDScript reserved keyword issues.

---

### 11.5 Warnings-as-errors compatibility

The project should remain clean with warnings-as-errors enabled.

Preferred style:

```gdscript
var loaded: bool = SaveSystem.load_game()
var square_data: SquareData = GameState.get_square(square_id)
var card: PassiveGeneratorCard = passive_generator_card_scene.instantiate() as PassiveGeneratorCard
```

Avoid ambiguous `Variant` inference where Godot complains.

---

## 12. Milestone History

This section consolidates the work done so far. Daily changelog entries were not maintained continuously, so this is a reconstructed milestone log.

### Milestone 1 — Initial Godot Project Setup

Completed:

* Created Godot 4.6 project.
* Set up main scene.
* Set up base UI.
* Added basic square clicking.
* Added base currency: Squares.
* Added first square.
* Added grid rebuild foundation.

---

### Milestone 2 — Prestige and Traits Foundation

Completed:

* Added Vertices as prestige currency.
* Added prestige count.
* Added early prestige formula.
* Added grid expansion.
* Added random Trait assignment on prestige.
* Added TraitDefinition resources.
* Added TraitDatabase.
* Added SquareData and TraitInstance separation.
* Added SquareCalculator.

---

### Milestone 3A — Rarity-aware Trait Stacking and Naming

Completed:

* Added Trait rarity enum.
* Added Trait family concepts.
* Added stack-aware square naming.
* Added readable Trait stack summaries.
* Fixed duplicate naming behavior.
* Moved generated square naming into SquareData.

Important design decision:

```text
Different rarity versions of the same family should be separate TraitDefinition resources.
```

Example:

```text
common_dense
rare_dense
legendary_dense
```

---

### Milestone 3B — Rolled Trait Values

Completed:

* Added value ranges to EffectComponent.
* Added `roll_key`.
* Added rolled values to TraitInstance.
* Added effect summary display.
* Ensured each Trait instance can have unique rolled values.
* Prepared rolled values for save/load persistence.

Example:

```text
Common Dense can roll x1.20 to x1.50 square value.
Common Quick can roll x0.75 to x0.90 respawn time.
```

---

### Milestone 4A — Passive Generator Progression

Completed:

* Added first passive generator system.
* Added permanent unlock vs run-based level distinction.
* Added Level 0 inactive state.
* Added Square-cost level purchases.
* Added passive ticking.
* Added passive-generated Squares.
* Added passive click tracking.
* Added run-based passive reset on prestige.

Important design decision:

```text
Vertex Shop unlocks passive generators permanently.
Squares buy passive levels during the current run.
Prestige resets passive levels to 0.
```

---

### Milestone 4B — Data-driven Vertex Upgrades

Completed:

* Added VertexUpgradeDefinition.
* Added VertexUpgradeEffect.
* Added VertexUpgradeDatabase.
* Added dynamic Vertex Shop cards.
* Removed one-off hardcoded Vertex Shop UI.
* Added dependency-based upgrade visibility.
* Added support for hidden upgrades.
* Added generic effect handling.

Current tested effects:

```text
UNLOCK_PASSIVE_GENERATOR
GLOBAL_STAT_MULTIPLIER
```

---

### Milestone 4B.1 — Dependent Vertex Upgrade Test

Completed:

* Added `sharpened_origin`.
* Made it depend on `unlock_first_generator`.
* Made it hidden until dependency is met.
* Added permanent `square_base_value` multiplier.
* Verified that square payout increases after purchase.

This proved:

```text
Vertex upgrade dependencies work.
Hidden upgrades work.
Permanent stat multiplier effects work.
Dynamic Vertex Shop refresh works.
```

---

### Milestone 4C — Data-driven Passive Generators

Completed:

* Added PassiveGeneratorDefinition.
* Added PassiveGeneratorInstance.
* Added PassiveGeneratorDatabase.
* Refactored PassiveSystem to own multiple generator instances.
* Replaced hardcoded `first_generator`.
* Added dynamic PassiveGeneratorCard UI.
* Left passive panel now renders unlocked generators dynamically.

---

### Milestone 4C.1 — Second Passive Generator Test

Completed:

* Added `value_harvester`.
* Added Vertex upgrade to unlock it.
* Made it depend on `unlock_first_generator`.
* Gave it different targeting behavior.
* Verified multiple passive generators work at the same time.

This proved:

```text
Multiple passive generator resources load correctly.
Multiple passive cards render correctly.
Different targeting modes work.
Vertex upgrades can unlock arbitrary passive generators by ID.
```

---

### Milestone 5 — Save, Load, Export, Import, Hard Reset

Completed:

* Added SaveSystem.
* Added disk save/load.
* Added save data versioning.
* Added export save string.
* Added import save string.
* Added hard reset.
* Added Options page save controls.
* Added serialization for:

  * GameState;
  * SquareData;
  * TraitInstance;
  * PassiveSystem;
  * PassiveGeneratorInstance.
* Added forced save on prestige.
* Confirmed current save/load flow works.

Current save policy:

```text
Prestige force-saves.
Manual Save exists.
Export/import exists.
Hard reset exists.
Upgrade purchases do not currently force-save.
Autosave timer is planned but not implemented yet.
```

---

## 13. Known Technical Debt / Next Work

### 13.1 Configurable autosave

Add to Options:

```text
Autosave enabled
Autosave interval value
Autosave interval unit or seconds
```

Suggested implementation:

```text
SaveSystem owns timer.
Options page edits SaveSystem settings.
SaveSystem settings are included in save data or separate user settings.
```

Important:

Autosave should not run every frame and should not trigger during import/hard reset operations.

---

### 13.2 Options page should become its own script

Currently, main UI logic is still too centralized in `main.gd`.

Move Options logic into:

```text
res://scripts/ui/options_page.gd
```

Eventually:

```text
GridPage.gd
VertexShopPage.gd
OptionsPage.gd
PassivePanel.gd
SquareDetailsPanel.gd
```

---

### 13.3 Confirmation for hard reset

Current hard reset is immediate.

Future behavior should be safer:

```text
Click HARD RESET
Show confirmation
Require second confirmation
Then reset
```

Possible implementation:

```text
ConfirmationDialog
or double-click within 5 seconds
or type RESET
```

---

### 13.4 Save migrations

Save versioning exists, but migration logic is not yet implemented.

Future:

```gdscript
if version == 1:
    migrate_v1_to_v2()
```

This will matter when save schema changes.

---

### 13.5 Better Vertex Shop tree UI

Current Vertex Shop is card-based and dependency-aware but not visually tree-shaped.

Future:

```text
node graph
dependency lines
tier columns
locked hidden branches
category filters
```

Current data already supports this through `required_upgrade_ids`.

---

### 13.6 Passive generator balance

Current passive values are prototype values.

Need balancing later:

```text
cost curves
interval scaling
extraction scaling
max level
self-prestige behavior
interaction with permanent multipliers
```

---

### 13.7 Passive self-prestige

Fields already exist:

```gdscript
self_prestige_level
can_self_prestige
self_prestige_is_permanent
self_prestige_unlock_level
```

But actual self-prestige behavior is not implemented.

Need decide:

```text
Does self-prestige persist across normal prestige?
Does it reset the generator level?
What does it boost?
Does it cost anything?
```

---

### 13.8 Save timing policy

Current policy is intentional:

```text
Forced save on prestige only.
Manual save available.
```

Need add:

```text
configurable autosave timer
```

Open question:

```text
Should Vertex upgrade purchases force-save because they are permanent?
```

Current answer:

```text
No, not for now.
Manual save and autosave should cover it.
```

---

### 13.9 More square stats in UI

Square details should eventually show more derived stats clearly:

```text
Base value
Permanent multiplier
Trait multiplier
Current manual payout
Passive targeting priority
Lifetime passive clicks
Lifetime manual clicks
```

---

### 13.10 Save integrity / validation

Import currently validates basic structure.

Future improvements:

```text
checksum
save version warning
corrupted save recovery
backup save file
import preview before applying
```

---

## 14. Current Commit Suggestions

Recent completed commits should roughly correspond to:

```bash
git commit -m "Add run-based passive generator progression"
git commit -m "Add data-driven vertex upgrades and shop cards"
git commit -m "Add dependent vertex upgrade for square value multiplier"
git commit -m "Add data-driven passive generators"
git commit -m "Add second passive generator resource"
git commit -m "Add save load export import and hard reset"
```

Current documentation update commit:

```bash
git add docs/TECHNICAL_OVERVIEW.md
git commit -m "Update technical overview documentation"
git push
```

---

## 15. Development Direction

Immediate likely next steps:

1. Add configurable autosave timer.
2. Extract Options page logic out of `main.gd`.
3. Extract Vertex Shop page logic out of `main.gd`.
4. Extract Passive Panel logic out of `main.gd`.
5. Add hard reset confirmation.
6. Add more Vertex upgrades.
7. Add more passive generators.
8. Add basic achievements page.
9. Improve number formatting.
10. Begin balancing the early game loop.

The project is now past the initial prototype stage. The important systems are moving toward reusable, data-driven architecture:

```text
Traits = data-driven
Vertex upgrades = data-driven
Passive generators = data-driven
Save/load = versioned and exportable
UI = starting to become component-based
```

The next architectural priority is reducing `main.gd` responsibility by moving page-specific logic into dedicated scripts.
