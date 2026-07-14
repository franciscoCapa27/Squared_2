# Squared² — Technical Documentation

## 1. Project Summary

**Squared²** is a Godot 4.6 incremental / trait purchase game built around a grid of Squares.

The player:

1. Clicks Squares to gain `Squares`.
2. Spends `Squares` on:

   * Grid expansion.
   * Run upgrades.
   * Passive generator levels.
3. Buy Traits to:

   * Spend the current Buy Trait cost.
   * Gain cost-based `Vertices`.
   * Roll one random Trait onto an existing Square.
   * Keep all other run state intact.
4. Spends `Vertices` on permanent upgrades.
5. Unlocks additional mechanics through Vertex upgrades, achievements, grid expansion, and run progression.

The game architecture is intentionally resource-driven. Most content is defined through `.tres` resources, while systems operate on those definitions.

---

## 2. Design Layers

### 2.1 Run Layer

The run layer persists through Buy Trait. It resets only on a new game; a future Condensation system will own the deeper reset.

Includes:

* Current `Squares`.
* Passive generator levels.
* Run upgrade levels.
* Run stat multipliers.
* Run stat additions.
* Current passive generator pulse timers.
* Current run generated Squares / click counts on Squares.

Owned by:

```text
GameState
PassiveSystem
RunUpgradeSystem
SquareData
PassiveGeneratorInstance
```

---

### 2.2 Permanent Layer

The permanent layer persists through Buy Trait.

Includes:

* `Vertices`.
* Buy Trait count.
* Grid size.
* Existing Squares.
* Traits applied to Squares.
* Vertex upgrade purchases.
* Permanent stat multipliers.
* Permanent stat additions.
* Achievement unlocks.
* Permanently unlocked passive generators.

Owned by:

```text
GameState
PassiveSystem
AchievementSystem
SquareData
TraitInstance
```

---

### 2.3 Content Definition Layer

Definitions are `.tres` resources.

Includes:

* Trait definitions.
* Vertex upgrade definitions.
* Passive generator definitions.
* Achievement definitions.
* Run upgrade definitions.
* Theme definitions.

Owned by database autoloads:

```text
TraitDatabase
VertexUpgradeDatabase
PassiveGeneratorDatabase
AchievementDatabase
RunUpgradeDatabase
ThemeSystem
```

---

## 3. Autoloads

Recommended autoload order:

```text
EventBus
ThemeSystem
TraitDatabase
VertexUpgradeDatabase
PassiveGeneratorDatabase
AchievementDatabase
RunUpgradeDatabase
GameState
PassiveSystem
RunUpgradeSystem
AchievementSystem
SaveSystem
```

The order matters because some systems depend on definitions loaded by databases.

---

# 4. Autoload Scripts

---

## 4.1 `event_bus.gd`

Path:

```text
res://scripts/autoload/event_bus.gd
```

Class:

```gdscript
extends Node
```

### Purpose

Central signal bus for cross-system communication.

This avoids direct references between unrelated UI and gameplay systems.

### Signals

```gdscript
signal squares_changed(value: float)
```

Emitted when current Squares change.

Used by:

* Main resource label.
* Passive panel.
* Run upgrades panel.
* Grid upgrade button.
* Buy Trait panel.

---

```gdscript
signal vertices_changed(value: int)
```

Emitted when Vertices change.

Used by:

* Main resource label.
* Vertex shop.
* Buy Trait panel.

---

```gdscript
signal trait_purchase_changed(value: int)
```

Emitted when trait purchase count changes.

Used by:

* Buy Trait label.
* Run upgrades panel.
* Achievements.

---

```gdscript
signal grid_changed()
```

Emitted when the grid should be rebuilt or refreshed.

Used by:

* GridPage.
* Square details.
* Run upgrade unlock checks.
* Achievements.

---

```gdscript
signal grid_upgraded(new_grid_size: int)
```

Emitted when the player expands the grid.

Used by:

* Achievements.
* Future stats.
* UI refresh.

---

```gdscript
signal square_selected(square_id: String)
```

Emitted when a Square is clicked or selected.

Used by:

* SquareDetailsPanel.
* Main UI.

---

```gdscript
signal story_message(message: String)
```

Emitted when a narrative/status message should be shown.

Used by:

* Main story label/top bar.

---

## 4.2 `theme_system.gd`

Path:

```text
res://scripts/autoload/theme_system.gd
```

Class:

```gdscript
extends Node
```

### Purpose

Owns the currently active UI theme.

Provides:

* Color lookup.
* Spacing lookup.
* StyleBox generation.
* Panel/card/button style creation.
* `theme_changed` signal for runtime theme updates.

### Constants

```gdscript
const DEFAULT_THEME_PATH := "res://data/themes/void_dark.tres"
```

Default theme loaded at startup.

### Variables

```gdscript
var active_theme: UIThemeDefinition
```

Currently loaded UI theme resource.

### Signals

```gdscript
signal theme_changed()
```

Emitted when a new theme is loaded.

### Functions

```gdscript
func _ready() -> void
```

Loads the default theme.

---

```gdscript
func load_theme(theme_path: String) -> void
```

Loads a `UIThemeDefinition` resource from disk.

Validates:

* Resource exists.
* Resource is `UIThemeDefinition`.

Sets `active_theme`.

Emits `theme_changed`.

---

```gdscript
func get_theme_id() -> String
```

Returns the active theme ID.

Returns empty string if no theme is loaded.

---

```gdscript
func get_color(color_id: String) -> Color
```

Returns a named color from `active_theme`.

Supported IDs:

```text
background
background_subtle
surface
surface_soft
surface_strong
border
border_soft
border_strong
text_primary
text_secondary
text_muted
accent_primary
accent_secondary
success
warning
danger
```

Unknown IDs push a warning and return white.

---

```gdscript
func get_spacing(spacing_id: String) -> int
```

Returns spacing values from the active theme.

Supported IDs:

```text
screen_margin
panel_gap
section_gap
card_gap
inner_margin
grid_gap
trait_purchase_gap
```

---

```gdscript
func make_background_style() -> StyleBoxFlat
```

Creates a full background style using the theme background color.

---

```gdscript
func make_panel_style() -> StyleBoxFlat
```

Creates a standard large panel style.

Used for:

* Top bar.
* Side panels.
* Square details panel.
* Run upgrades panel.
* Achievement summary panel.

---

```gdscript
func make_elevated_panel_style() -> StyleBoxFlat
```

Creates a slightly stronger panel style.

Used for:

* Buy Trait panel.
* Important containers.

---

```gdscript
func make_card_style() -> StyleBoxFlat
```

Creates a card style.

Used for:

* Passive generator cards.
* Run upgrade cards.
* Vertex upgrade cards.
* Achievement cards.
* Square buttons.

---

```gdscript
func make_selected_card_style() -> StyleBoxFlat
```

Creates a highlighted card style.

Used for:

* Hovered square buttons.
* Selected square button state.
* Important card highlight states.

---

```gdscript
func make_button_style() -> StyleBoxFlat
func make_button_hover_style() -> StyleBoxFlat
func make_button_pressed_style() -> StyleBoxFlat
func make_button_disabled_style() -> StyleBoxFlat
```

Creates button styles for each interaction state.

---

```gdscript
func make_style_box(
    background_color: Color,
    border_color: Color,
    corner_radius: int,
    border_width: int
) -> StyleBoxFlat
```

Low-level helper for creating `StyleBoxFlat` resources.

Applies:

* Background color.
* Border color.
* Border width.
* Corner radius.
* Content margins.

---

## 4.3 `trait_database.gd`

Path:

```text
res://scripts/autoload/trait_database.gd
```

Class:

```gdscript
extends Node
```

### Purpose

Loads all Trait definitions and provides Trait roll logic.

### Constants

```gdscript
const TRAIT_ROOT_PATH := "res://data/traits"
```

Root folder for Trait resources.

### Variables

```gdscript
var traits_by_id: Dictionary = {}
```

Maps Trait ID to `TraitDefinition`.

---

```gdscript
var all_traits: Array[TraitDefinition] = []
```

Flat list of all loaded Traits.

---

```gdscript
var traits_by_rarity: Dictionary = {}
```

Maps rarity enum value to all Traits of that rarity.

---

```gdscript
const DEBUG_TRAIT_ROLLS := false
```

Enables debug logging for Trait rolls.

### Functions

```gdscript
func _ready() -> void
```

Loads Trait resources on startup.

---

```gdscript
func load_traits() -> void
```

Clears all Trait collections and recursively loads all Trait resources.

---

```gdscript
func get_trait(trait_id: String) -> TraitDefinition
```

Returns Trait by ID.

---

```gdscript
func get_random_trait(current_grid_size: int) -> TraitDefinition
```

Main Trait roll entry point.

Flow:

1. Rolls rarity using current grid size.
2. Gets eligible Traits of that rarity.
3. Falls back to all eligible Traits if rarity has no candidates.
4. Rolls weighted Trait by `TraitDefinition.weight`.

---

```gdscript
func get_eligible_traits(current_grid_size: int) -> Array[TraitDefinition]
```

Returns all Traits eligible at current grid size.

---

```gdscript
func get_eligible_traits_for_rarity(
    rarity: int,
    current_grid_size: int
) -> Array[TraitDefinition]
```

Returns eligible Traits of one rarity at the given grid size.

---

```gdscript
func get_rarity_weights_for_grid(current_grid_size: int) -> Dictionary
```

Returns rarity weights after applying current `GameState` Trait Luck.

Example at 2x2:

```text
Common 85
Uncommon 15
```

With +10 Trait Luck:

```text
Common 75
Uncommon 25
```

---

```gdscript
func get_rarity_weights_for_grid_with_luck(
    current_grid_size: int,
    trait_luck: float
) -> Dictionary
```

Returns rarity weights for a specific Trait Luck value. This exists so Trait roll rules can be verified deterministically without mutating `GameState`.

Important rule:

Trait Luck only shifts weights among already-unlocked rarities. It does not make Uncommon possible before 2x2 or Rare possible before 3x3.

---

```gdscript
func get_roll_candidates_for_rarity(
    selected_rarity: int,
    current_grid_size: int
) -> Array[TraitDefinition]
```

Returns the candidates for a selected rarity. If no Trait is eligible for the selected rarity, this falls back to all Traits eligible at the current grid size.

This is the explicit fallback path used by trait purchase Trait rolls.

---

```gdscript
func get_weighted_trait_for_roll(
    candidates: Array[TraitDefinition],
    roll_normalized: float
) -> TraitDefinition
```

Selects one Trait from candidates using `TraitDefinition.weight` and a normalized roll value from `0.0` to less than `1.0`.

This is the deterministic form of weighted Trait selection. Random trait purchase rolls call it with `randf()`.

---

```gdscript
func _load_traits_recursive(path: String) -> void
```

Recursively scans folders for `.tres` and `.res` files.

---

```gdscript
func _load_trait_resource(path: String) -> void
```

Loads one Trait resource.

Validates:

* Resource exists.
* Resource is `TraitDefinition`.
* Trait ID is not empty.
* Trait ID is unique.

---

```gdscript
func _rebuild_traits_by_rarity() -> void
```

Groups loaded Traits by rarity.

---

```gdscript
func _get_eligible_traits(current_grid_size: int) -> Array[TraitDefinition]
```

Internal eligibility filter.

---

```gdscript
func _get_eligible_traits_for_rarity(
    rarity: int,
    current_grid_size: int
) -> Array[TraitDefinition]
```

Internal implementation for `get_eligible_traits_for_rarity`.

---

```gdscript
func _is_trait_eligible(
    trait_definition: TraitDefinition,
    current_grid_size: int
) -> bool
```

Checks:

* Trait is not null.
* Grid size is at least `min_grid_tier`.
* Grid size does not exceed `max_grid_tier`, if set.
* Rarity is unlocked for grid size.

---

```gdscript
func _is_rarity_unlocked_for_grid(rarity: int, current_grid_size: int) -> bool
```

Checks whether a rarity can appear at a grid size.

---

```gdscript
func _get_min_grid_size_for_rarity(rarity: int) -> int
```

Rarity gates:

```text
Common    -> 1
Uncommon  -> 2
Rare      -> 3
Epic      -> 4
Legendary -> 5
Cosmic    -> 6
```

---

```gdscript
func _roll_rarity(current_grid_size: int) -> int
```

Rolls a rarity from the weighted rarity pool.

---

```gdscript
func _get_base_rarity_weights(current_grid_size: int) -> Dictionary
```

Returns base rarity weights before luck.

---

```gdscript
func _apply_luck_to_rarity_weights(
    base_weights: Dictionary,
    trait_luck: float
) -> Dictionary
```

Applies additive Trait Luck.

Important rule:

Trait Luck only shifts weights among already-unlocked rarities. It does not make Rare possible before 3x3.

---

```gdscript
func _apply_cascading_luck_step(weights: Dictionary, scale: float) -> void
```

Applies one luck step.

Current behavior:

```text
Common -> Uncommon
Uncommon -> Rare
Rare -> Epic
Epic -> Legendary
Legendary -> Cosmic
```

Only applies transfers where both rarities exist in current weight table.

---

```gdscript
func _apply_luck_transfer(
    weights: Dictionary,
    transfer: Dictionary,
    scale: float
) -> void
```

Moves weight from one rarity bucket to another.

---

```gdscript
godot --headless --path squared-2 --script res://scripts/tests/verify_trait_roll_foundation.gd
```

Runs the deterministic Trait Roll Foundation verification script.

It checks:

* 1x1 never unlocks Uncommon or Rare, even with Trait Luck.
* 2x2 unlocks Uncommon but not Rare.
* Trait Luck shifts weight only among already-unlocked rarity buckets.
* `TraitDefinition.weight` affects deterministic Trait selection.
* Empty selected-rarity buckets fall back to eligible Traits at the current grid size.

---

## 4.4 `vertex_upgrade_database.gd`

Path:

```text
res://scripts/autoload/vertex_upgrade_database.gd
```

### Purpose

Loads all Vertex upgrade resources.

### Expected Variables

```gdscript
var upgrades_by_id: Dictionary = {}
```

Maps Vertex upgrade ID to `VertexUpgradeDefinition`.

---

```gdscript
var all_upgrades: Array[VertexUpgradeDefinition] = []
```

Flat sorted list of all upgrades.

### Main Functions

```gdscript
func load_vertex_upgrades() -> void
```

Loads all upgrades from `res://data/vertex_upgrades`.

---

```gdscript
func get_upgrade(upgrade_id: String) -> VertexUpgradeDefinition
```

Returns upgrade by ID.

---

```gdscript
func get_all_upgrades() -> Array[VertexUpgradeDefinition]
```

Returns all loaded upgrades.

---

## 4.5 `passive_generator_database.gd`

Path:

```text
res://scripts/autoload/passive_generator_database.gd
```

### Purpose

Loads passive generator definitions.

### Variables

```gdscript
var generators_by_id: Dictionary = {}
```

Maps generator ID to `PassiveGeneratorDefinition`.

---

```gdscript
var all_generators: Array[PassiveGeneratorDefinition] = []
```

Flat sorted list of generator definitions.

### Functions

```gdscript
func get_generator(generator_id: String) -> PassiveGeneratorDefinition
```

Returns generator definition by ID.

---

```gdscript
func get_all_generators() -> Array[PassiveGeneratorDefinition]
```

Returns all generator definitions.

---

## 4.6 `achievement_database.gd`

Path:

```text
res://scripts/autoload/achievement_database.gd
```

### Purpose

Loads achievement definitions.

### Variables

```gdscript
var achievements_by_id: Dictionary = {}
```

Maps achievement ID to `AchievementDefinition`.

---

```gdscript
var all_achievements: Array[AchievementDefinition] = []
```

Flat sorted list of achievements.

### Functions

```gdscript
func get_achievement(achievement_id: String) -> AchievementDefinition
```

Returns achievement by ID.

---

```gdscript
func get_all_achievements() -> Array[AchievementDefinition]
```

Returns all achievements.

---

## 4.7 `run_upgrade_database.gd`

Path:

```text
res://scripts/autoload/run_upgrade_database.gd
```

Class:

```gdscript
extends Node
```

### Purpose

Loads run upgrade definitions.

### Constants

```gdscript
const RUN_UPGRADE_ROOT_PATH := "res://data/run_upgrades"
```

Resource folder for run upgrades.

### Variables

```gdscript
var upgrades_by_id: Dictionary = {}
```

Maps run upgrade ID to `RunUpgradeDefinition`.

---

```gdscript
var all_upgrades: Array[RunUpgradeDefinition] = []
```

Flat sorted list of all run upgrades.

### Functions

```gdscript
func _ready() -> void
```

Loads run upgrades on startup.

---

```gdscript
func load_run_upgrades() -> void
```

Clears and reloads all run upgrade resources.

---

```gdscript
func get_upgrade(upgrade_id: String) -> RunUpgradeDefinition
```

Returns run upgrade by ID.

---

```gdscript
func get_all_upgrades() -> Array[RunUpgradeDefinition]
```

Returns all loaded run upgrades.

---

```gdscript
func _load_run_upgrades_recursive(path: String) -> void
```

Recursively scans folders for run upgrade resources.

---

```gdscript
func _load_run_upgrade_resource(path: String) -> void
```

Loads one resource and validates:

* Resource exists.
* Resource is `RunUpgradeDefinition`.
* ID is valid.
* ID is unique.

---

## 4.8 `game_state.gd`

Path:

```text
res://scripts/autoload/game_state.gd
```

Class:

```gdscript
extends Node
```

### Purpose

Owns core game state.

GameState should own:

* Core currencies.
* Grid state.
* Square data.
* Buy Trait.
* Vertex upgrades.
* Permanent stats.

GameState should not own:

* Passive generator runtime state.
* Run upgrade runtime state.
* Achievement state.
* UI state.

### Constants

```gdscript
const INITIAL_GRID_SIZE := 1
```

Starting grid size.

---

```gdscript
const INITIAL_SQUARE_ID := "A1"
```

Starting Square ID.

---

```gdscript
const MAX_GRID_SIZE := 6
```

Maximum grid size currently supported.

---

```gdscript
const GRID_UPGRADE_BASE_COST := 25.0
```

Base Square cost for first grid upgrade.

---

```gdscript
const GRID_UPGRADE_COST_MULTIPLIER := 6.0
```

Grid upgrade cost multiplier per grid tier.

---

```gdscript
const TRAIT_PURCHASE_COST_BASE := 15.0
const TRAIT_PURCHASE_COST_MULTIPLIER := 1.75
const TRAIT_PURCHASE_VERTEX_GAIN_DIVISOR := 25.0
```

Base cost and scaling for Buy Trait.

---

```gdscript
const VERTEX_GAIN_DIVISOR := 100.0
```

Controls Vertex gain curve.

---

```gdscript
const DEBUG_VERTEX_UPGRADES := false
const DEBUG_PERMANENT_STATS := false
```

Debug flags.

### Variables

```gdscript
var squares: float = 0.0
```

Current run currency.

Persists through Buy Trait.

---

```gdscript
var vertices: int = 0
```

Permanent currency earned by buying Traits.

Persists through Buy Trait.

---

```gdscript
var trait_purchase_count: int = 0
```

Total number of trait purchases.

Persists through trait purchase.

---

```gdscript
var grid_size: int = INITIAL_GRID_SIZE
```

Current grid dimension.

Example:

```text
1 = 1x1
2 = 2x2
3 = 3x3
```

---

```gdscript
var square_ids: Array[String] = [INITIAL_SQUARE_ID]
```

Ordered list of active Square IDs.

Used to build the grid UI.

---

```gdscript
var squares_by_id: Dictionary = {}
```

Maps Square ID to `SquareData`.

---

```gdscript
var unlocked_vertex_upgrades: Dictionary = {}
```

Maps Vertex upgrade ID to purchase count.

Supports repeatable upgrades.

---

```gdscript
var permanent_stat_multipliers: Dictionary = {}
```

Permanent multiplicative stats.

Default multiplier is `1.0`.

Example:

```text
square_base_value -> 1.10
```

---

```gdscript
var permanent_stat_additions: Dictionary = {}
```

Permanent additive stats.

Default addition is `0.0`.

Example:

```text
trait_luck -> 10.0
```

### Core Functions

```gdscript
func _ready() -> void
```

Creates initial grid.

---

```gdscript
func get_square(square_id: String) -> SquareData
```

Returns SquareData by ID.

---

```gdscript
func click_square(square_id: String) -> void
```

Handles manual square click.

Flow:

1. Get SquareData.
2. Calculate manual payout.
3. Record manual click on SquareData.
4. Add Squares.
5. Emit square selected event.

---

```gdscript
func add_squares(amount: float) -> void
```

Adds to current Squares.

Ignores non-positive amounts.

Emits:

```gdscript
EventBus.squares_changed
```

---

```gdscript
func spend_squares(amount: float) -> bool
```

Attempts to spend Squares.

Returns `true` if successful.

---

```gdscript
func can_buy_trait() -> bool
```

Returns whether the player has enough Squares for the current Buy Trait cost.

---

```gdscript
func calculate_trait_purchase_vertices_gain() -> int
```

Calculates Vertex gain from the current Buy Trait cost.

Current formula:

```text
max(1, floor(sqrt(trait_purchase_cost / TRAIT_PURCHASE_VERTEX_GAIN_DIVISOR)))
```

Buy Trait clamps this to at least `1`.

---

```gdscript
func buy_trait() -> void
```

Performs trait purchase.

Current behavior:

1. Check `can_buy_trait`.
2. Spend exactly the current Buy Trait cost from Squares.
3. Calculate and add cost-based Vertices.
4. Increment `trait_purchase_count`.
5. Apply one random Trait to one random Square using the current grid size.
6. Emit core state changes, the reveal, and grid changed.
7. Save game.

Buy Trait does **not** reset Squares, run upgrades, passive levels, timers, or square run state. It does **not** expand the grid.

---

### Grid Functions

```gdscript
func can_upgrade_grid() -> bool
```

Returns whether current grid can be upgraded.

Requires:

* Grid size below max.
* Enough Squares.

---

```gdscript
func get_grid_upgrade_cost() -> float
```

Calculates current grid upgrade cost.

Formula:

```text
GRID_UPGRADE_BASE_COST * pow(GRID_UPGRADE_COST_MULTIPLIER, grid_size - 1)
```

---

```gdscript
func get_next_grid_size() -> int
```

Returns next grid size, capped by `MAX_GRID_SIZE`.

---

```gdscript
func upgrade_grid() -> bool
```

Attempts to expand grid.

Flow:

1. Check `can_upgrade_grid`.
2. Spend Squares.
3. Set new grid size.
4. Emit `grid_upgraded`.
5. Emit `grid_changed`.
6. Emit story message.

---

```gdscript
func _create_initial_grid() -> void
```

Creates initial `A1` square.

---

```gdscript
func _set_grid_size(new_grid_size: int) -> void
```

Rebuilds active grid to target size.

Preserves existing SquareData where Square IDs already exist.

Creates new SquareData for newly added positions.

---

```gdscript
func _get_square_id_from_position(x: int, y: int) -> String
```

Converts grid coordinates to Square ID.

Examples:

```text
0,0 -> A1
1,0 -> A2
0,1 -> B1
```

---

### Trait Functions

```gdscript
func _apply_random_trait_to_random_square(trait_roll_grid_size: int) -> void
```

Rolls one Trait and applies it to a random existing Square.

Uses `TraitDatabase.get_random_trait(trait_roll_grid_size)`.

---

### Vertex Upgrade Functions

```gdscript
func has_vertex_upgrade(upgrade_id: String) -> bool
```

Returns whether upgrade has at least one purchase.

---

```gdscript
func get_vertex_upgrade_purchase_count(upgrade_id: String) -> int
```

Returns purchase count.

Supports old bool-style saves by interpreting `true` as 1.

---

```gdscript
func can_buy_vertex_upgrade(upgrade_id: String) -> bool
```

Checks:

* Upgrade exists.
* Enough Vertices.
* Requirements met.
* Repeat/max purchases valid.

---

```gdscript
func buy_vertex_upgrade(upgrade_id: String) -> bool
```

Buys a Vertex upgrade.

Flow:

1. Check `can_buy_vertex_upgrade`.
2. Load definition.
3. Spend Vertices.
4. Apply effects.
5. Record purchase count.
6. Emit Vertices changed.
7. Emit Vertex upgrade purchased.
8. Emit story message.

---

```gdscript
func _record_vertex_upgrade_purchase(upgrade_id: String) -> void
```

Increments purchase count.

---

```gdscript
func _apply_vertex_upgrade_effects(upgrade: VertexUpgradeDefinition) -> void
```

Applies each effect resource.

---

```gdscript
func _apply_vertex_upgrade_effect(effect_iter: VertexUpgradeEffect) -> void
```

Dispatches effect by type.

---

```gdscript
func _apply_unlock_passive_generator_effect(effect_iter: VertexUpgradeEffect) -> void
```

Unlocks a passive generator using `PassiveSystem.unlock_generator`.

Uses:

```gdscript
effect_iter.target_id
```

---

```gdscript
func _apply_global_stat_multiplier_effect(effect_iter: VertexUpgradeEffect) -> void
```

Applies permanent multiplier.

Uses:

```gdscript
effect_iter.target_stat
effect_iter.value
```

---

```gdscript
func _apply_add_permanent_stat_effect(effect_iter: VertexUpgradeEffect) -> void
```

Applies permanent additive stat.

Used for Trait Luck.

---

### Permanent Stat Functions

```gdscript
func get_permanent_stat_multiplier(stat_id: String) -> float
```

Returns multiplier or `1.0`.

---

```gdscript
func multiply_permanent_stat(stat_id: String, multiplier: float) -> void
```

Multiplies permanent stat.

---

```gdscript
func get_permanent_stat_addition(stat_id: String) -> float
```

Returns addition or `0.0`.

---

```gdscript
func add_permanent_stat(stat_id: String, amount: float) -> void
```

Adds to permanent stat.

---

### Save Functions

```gdscript
func to_save_dict() -> Dictionary
```

Serializes core game state.

Includes:

```text
squares
vertices
trait_purchase_count
grid_size
square_ids
squares_by_id
unlocked_vertex_upgrades
permanent_stat_multipliers
permanent_stat_additions
```

---

```gdscript
func from_save_dict(data: Dictionary) -> void
```

Loads core game state from save dictionary.

---

```gdscript
func reset_to_new_game() -> void
```

Resets GameState for hard reset.

Does not directly reset every other system. SaveSystem should coordinate full reset.

---

## 4.9 `passive_system.gd`

Path:

```text
res://scripts/autoload/passive_system.gd
```

### Purpose

Owns runtime passive generator state.

### Signals

```gdscript
signal passive_state_changed()
```

Emitted when generator levels/unlocks/pulses change.

---

```gdscript
signal passive_pulsed(generator_id: String, square_id: String, payout: float)
```

Emitted when a passive generator produces Squares.

### Variables

```gdscript
var generators_by_id: Dictionary = {}
```

Maps generator ID to `PassiveGeneratorInstance`.

---

```gdscript
var generator_order: Array[String] = []
```

Sorted list of generator IDs for UI display.

### Functions

```gdscript
func _ready() -> void
```

Initializes generator instances from database definitions.

---

```gdscript
func _process(delta: float) -> void
```

Ticks active generators.

---

```gdscript
func _initialize_generators() -> void
```

Creates one `PassiveGeneratorInstance` per definition.

---

```gdscript
func get_generator_instance(generator_id: String) -> PassiveGeneratorInstance
```

Returns runtime generator instance.

---

```gdscript
func get_all_generator_instances() -> Array[PassiveGeneratorInstance]
```

Returns all generator instances.

---

```gdscript
func get_unlocked_generator_instances() -> Array[PassiveGeneratorInstance]
```

Returns unlocked generators.

---

```gdscript
func unlock_generator(generator_id: String) -> void
```

Permanently unlocks generator.

---

There is no Buy Trait reset hook. Run state is cleared only by `reset_to_new_game()`; future Condensation work may add a separate reset boundary.

---

```gdscript
func can_upgrade_generator(generator_id: String) -> bool
```

Checks if player can buy next passive generator level.

---

```gdscript
func upgrade_generator(generator_id: String) -> bool
```

Buys one level of passive generator.

Costs Squares.

---

```gdscript
func _pulse_generator(generator_instance: PassiveGeneratorInstance) -> void
```

Processes one passive pulse.

Flow:

1. Pick target Square.
2. Calculate base payout from SquareCalculator.
3. Multiply by generator extraction rate.
4. Apply run passive click multiplier/addition.
5. Record passive click on SquareData.
6. Add Squares.
7. Record pulse on generator.
8. Emit pulse/state signals.

---

```gdscript
func to_save_dict() -> Dictionary
func from_save_dict(data: Dictionary) -> void
func reset_to_new_game() -> void
```

Save/load/reset passive system state.

---

## 4.10 `run_upgrade_system.gd`

Path:

```text
res://scripts/autoload/run_upgrade_system.gd
```

### Purpose

Owns current-run upgrade state.

### Signals

```gdscript
signal run_upgrades_changed()
signal run_upgrade_bought(upgrade_id: String)
```

### Variables

```gdscript
var run_upgrade_levels: Dictionary = {}
```

Maps run upgrade ID to current level.

Persists through Buy Trait; cleared only by a new game.

---

```gdscript
var run_stat_multipliers: Dictionary = {}
```

Run-only multiplicative stats.

Default multiplier is `1.0`.

---

```gdscript
var run_stat_additions: Dictionary = {}
```

Run-only additive stats.

Default addition is `0.0`.

### Functions

```gdscript
func get_run_stat_multiplier(stat_id: String) -> float
```

Returns run multiplier.

---

```gdscript
func multiply_run_stat(stat_id: String, multiplier: float) -> void
```

Multiplies run stat.

---

```gdscript
func get_run_stat_addition(stat_id: String) -> float
```

Returns run addition.

---

```gdscript
func add_run_stat(stat_id: String, amount: float) -> void
```

Adds to run stat.

---

```gdscript
func get_run_upgrade_level(upgrade_id: String) -> int
```

Returns current run upgrade level.

---

```gdscript
func is_run_upgrade_unlocked(upgrade_id: String) -> bool
```

Checks unlock conditions on definition.

---

```gdscript
func can_buy_run_upgrade(upgrade_id: String) -> bool
```

Checks:

* Definition exists.
* Upgrade is unlocked.
* Not maxed.
* Enough Squares.

---

```gdscript
func buy_run_upgrade(upgrade_id: String) -> bool
```

Buys one run upgrade level.

Flow:

1. Check `can_buy_run_upgrade`.
2. Spend Squares.
3. Apply effects.
4. Increment level.
5. Emit story message.
6. Emit `run_upgrade_bought`.
7. Emit `run_upgrades_changed`.

---

Run upgrade state persists through Buy Trait and is cleared only by a new game.

---

```gdscript
func reset_to_new_game() -> void
```

Clears all run upgrades for a new game.

---

```gdscript
func to_save_dict() -> Dictionary
```

Saves:

```text
run_upgrade_levels
run_stat_multipliers
run_stat_additions
```

---

```gdscript
func from_save_dict(data: Dictionary) -> void
```

Loads run upgrade state.

---

```gdscript
func _apply_run_upgrade_effects(upgrade: RunUpgradeDefinition) -> void
```

Applies all effects for one purchased level.

---

```gdscript
func _apply_run_upgrade_effect(effect_iter: RunUpgradeEffect) -> void
```

Dispatches run upgrade effect.

---

## 4.11 `achievement_system.gd`

Path:

```text
res://scripts/autoload/achievement_system.gd
```

### Purpose

Owns achievement unlock state.

### Signals

```gdscript
signal achievements_changed()
signal achievement_unlocked(achievement_id: String)
```

### Expected Variables

```gdscript
var unlocked_achievements: Dictionary = {}
```

Maps achievement ID to `true`.

### Main Functions

```gdscript
func check_all_achievements() -> void
```

Checks all loaded achievements.

---

```gdscript
func is_achievement_unlocked(achievement_id: String) -> bool
```

Returns unlock state.

---

```gdscript
func get_unlocked_count() -> int
```

Returns number of unlocked achievements.

---

```gdscript
func unlock_achievement(achievement: AchievementDefinition) -> void
```

Marks achievement unlocked and applies rewards.

---

```gdscript
func _apply_reward(reward: AchievementReward) -> void
```

Dispatches reward.

Rewards can affect permanent stats.

---

```gdscript
func to_save_dict() -> Dictionary
func from_save_dict(data: Dictionary) -> void
func reset_to_new_game() -> void
```

Save/load/reset achievement state.

---

## 4.12 `save_system.gd`

Path:

```text
res://scripts/autoload/save_system.gd
```

### Purpose

Owns persistence.

### Constants

```gdscript
const SAVE_VERSION := 1
const SAVE_PATH := "user://savegame.json"
const MIN_AUTOSAVE_INTERVAL_SECONDS := 5.0
const DEFAULT_AUTOSAVE_INTERVAL_SECONDS := 60.0
```

### Signals

```gdscript
signal save_loaded()
signal save_saved()
signal save_failed(message: String)
signal save_settings_changed()
```

### Variables

```gdscript
var autosave_enabled: bool = true
var autosave_interval_seconds: float = DEFAULT_AUTOSAVE_INTERVAL_SECONDS
var autosave_elapsed_seconds: float = 0.0
var is_applying_save_data: bool = false
```

### Functions

```gdscript
func _process(delta: float) -> void
```

Runs autosave timer.

---

```gdscript
func save_game() -> bool
```

Writes save JSON to disk.

---

```gdscript
func load_game() -> bool
```

Reads save from disk and applies it.

---

```gdscript
func export_save_to_string() -> String
```

Exports compressed/base64 save string.

---

```gdscript
func import_save_from_string(save_string: String) -> bool
```

Imports save from string.

---

```gdscript
func hard_reset() -> void
```

Resets all systems and saves fresh game.

---

```gdscript
func _build_save_data() -> Dictionary
```

Builds full save dictionary.

Includes:

```text
version
settings
game_state
passive_system
achievement_system
run_upgrade_system
```

---

```gdscript
func _apply_save_data(save_data: Dictionary) -> void
```

Applies full save data to systems.

---

```gdscript
func _apply_settings_save_data(settings_data: Dictionary) -> void
```

Loads settings.

Current settings:

```text
autosave_enabled
autosave_interval_seconds
```

Future settings:

```text
selected_theme_id
```

---

# 5. Core Runtime Classes

---

## 5.1 `square_data.gd`

Path:

```text
res://scripts/core/square_data.gd
```

Class:

```gdscript
class_name SquareData
```

### Purpose

Runtime state for one Square.

### Important Variables

```gdscript
var id: String
```

Square ID, e.g. `A1`.

---

```gdscript
var coordinate: String
```

Human-readable coordinate.

---

```gdscript
var grid_x: int
var grid_y: int
```

Grid position.

---

```gdscript
var display_name: String
```

Generated display name.

Can become long when Traits stack.

---

```gdscript
var base_value: float
```

Base Square value before modifiers.

---

```gdscript
var base_respawn_time: float
```

Base respawn time.

---

```gdscript
var base_manual_multiplier: float
```

Square-specific manual multiplier.

---

```gdscript
var temporary_value_multiplier: float
```

Temporary multiplier for future effects.

---

```gdscript
var traits: Array[TraitInstance]
```

Traits applied to this Square.

---

```gdscript
var run_squares_generated: float
var lifetime_squares_generated: float
```

Generated Squares counters.

---

```gdscript
var run_manual_clicks: int
var lifetime_manual_clicks: int
```

Manual click counters.

---

```gdscript
var run_passive_clicks: int
var lifetime_passive_clicks: int
```

Passive click counters.

---

```gdscript
var times_traited: int
```

Number of times this Square received a Trait.

---

```gdscript
var highest_single_payout: float
```

Highest payout this Square has generated.

---

```gdscript
var created_at_trait_purchase: int
var created_at_grid_tier: int
```

Creation metadata.

---

```gdscript
var permanent_tags: Array[String]
var temporary_tags: Array[String]
```

Tags for future mechanics.

### Important Functions

```gdscript
func add_trait(trait_instance: TraitInstance) -> void
```

Adds Trait instance, increments counters, updates display name/visuals.

---

```gdscript
func record_manual_click(payout: float) -> void
```

Records manual click stats.

---

```gdscript
func record_passive_click(payout: float) -> void
```

Records passive click stats.

---

```gdscript
func get_trait_stack_display_text() -> String
```

Returns readable list of Traits.

---

```gdscript
func get_trait_effect_summary_text() -> String
```

Returns readable Trait effect summary.

---

```gdscript
func to_save_dict() -> Dictionary
func from_save_dict(data: Dictionary) -> SquareData
```

Serialize/deserialize Square state.

---

## 5.2 `trait_instance.gd`

Path:

```text
res://scripts/core/trait_instance.gd
```

Class:

```gdscript
class_name TraitInstance
```

### Purpose

Runtime instance of a TraitDefinition.

Each instance stores its own rolled values.

### Variables

```gdscript
var definition_id: String
```

Trait definition ID.

---

```gdscript
var definition: TraitDefinition
```

Loaded definition reference.

---

```gdscript
var applied_at_trait_purchase: int
```

Buy Trait count when applied.

---

```gdscript
var applied_at_grid_tier: int
```

Grid tier used for roll.

---

```gdscript
var rolled_values: Dictionary
```

Stores rolled effect values by `roll_key`.

Example:

```text
square_value_multiplier -> 1.314
respawn_time_multiplier -> 1.127
```

### Functions

```gdscript
func get_effect_value(effect_component: EffectComponent) -> float
```

Returns rolled value if available.

Otherwise returns component static value.

---

```gdscript
func to_save_dict() -> Dictionary
func from_save_dict(data: Dictionary) -> TraitInstance
```

Serialize/deserialize Trait instance.

---

## 5.3 `passive_generator_instance.gd`

Path:

```text
res://scripts/core/passive_generator_instance.gd
```

Class:

```gdscript
class_name PassiveGeneratorInstance
```

### Purpose

Runtime state for one passive generator.

### Variables

```gdscript
var definition: PassiveGeneratorDefinition
```

Definition resource.

---

```gdscript
var is_unlocked: bool
```

Permanent unlock state.

---

```gdscript
var level: int
```

Run level.

Persists through Buy Trait; cleared only by a new game.

---

```gdscript
var self_condensation_level: int
var can_self_condensation: bool
```

Reserved for future passive Condensation behavior.

---

```gdscript
var elapsed_seconds: float
```

Pulse timer.

---

```gdscript
var last_target_square_id: String
var last_payout: float
```

Last pulse display data.

---

```gdscript
var lifetime_squares_generated: float
var lifetime_pulses: int
```

Current run passive stats.

### Functions

```gdscript
func get_id() -> String
func get_display_name() -> String
```

Definition accessors.

---

```gdscript
func unlock_permanently() -> void
```

Unlocks generator.

---

```gdscript
func reset_run_state() -> void
```

Resets level/timer/run pulse data.

---

```gdscript
func is_active() -> bool
```

Returns true if unlocked and level > 0.

---

```gdscript
func get_current_interval_seconds() -> float
```

Calculates pulse interval.

Includes:

* Definition interval scaling.
* Run passive interval multiplier/addition.

---

```gdscript
func get_current_extraction_rate() -> float
```

Calculates extraction rate.

Includes:

* Definition base extraction.
* Level scaling.
* Run passive extraction multiplier/addition.

---

```gdscript
func get_next_level_cost() -> int
```

Calculates next level cost.

---

```gdscript
func can_level_up(current_squares: float) -> bool
```

Checks level/cost.

---

```gdscript
func level_up() -> bool
```

Increments level.

---

```gdscript
func get_progress_ratio() -> float
```

Returns timer progress 0 to 1.

---

```gdscript
func record_pulse(target_square_id: String, payout: float) -> void
```

Stores last pulse and run pulse stats.

---

```gdscript
func to_save_dict() -> Dictionary
func apply_save_dict(data: Dictionary) -> void
func reset_to_new_game() -> void
```

Persistence functions.

---

# 6. Resource Classes

---

## 6.1 `trait_definition.gd`

Path:

```text
res://scripts/resources/trait_definition.gd
```

Defines Trait content.

Important exported variables:

```gdscript
@export var id: String
@export var display_name: String
@export var family_id: String
@export var family_display_name: String
@export_multiline var description: String
@export var rarity: Rarity
@export var tags: Array[String]
@export var weight: float
@export var min_grid_tier: int
@export var max_grid_tier: int
@export var max_stack_count: int
@export var can_duplicate: bool
@export var effect_components: Array[EffectComponent]
@export var name_prefixes: Array[String]
@export var name_suffixes: Array[String]
@export var visual_glow_weight: int
@export var visual_edge_complexity_weight: int
@export var visual_gloss_weight: int
@export var visual_distortion_weight: int
@export var script_hook_id: String
```

---

## 6.2 `effect_component.gd`

Path:

```text
res://scripts/resources/effect_component.gd
```

Defines one stat effect.

Important variables:

```gdscript
@export var target_stat: String
@export var operation
@export var value: float
@export var use_value_range: bool
@export var value_min: float
@export var value_max: float
@export var roll_key: String
@export var roll_decimals: int
```

Used by Traits.

---

## 6.3 `visual_profile.gd`

Path:

```text
res://scripts/resources/visual_profile.gd
```

Defines future visual identity data for Squares/Traits.

Used for eventual:

* Glow.
* Edge style.
* Distortion.
* Gloss.
* Rarity presentation.

---

## 6.4 `vertex_upgrade_definition.gd`

Path:

```text
res://scripts/resources/vertex_upgrade_definition.gd
```

Important variables:

```gdscript
@export var id: String
@export var display_name: String
@export_multiline var description: String
@export var category: UpgradeCategory
@export var cost_vertices: int
@export var is_visible_by_default: bool
@export var sort_order: int
@export var required_trait_purchase_count: int
@export var required_grid_size: int
@export var required_upgrade_ids: Array[String]
@export var hidden_until_requirements_met: bool
@export var is_repeatable: bool
@export var max_purchases: int
@export var effects: Array[VertexUpgradeEffect]
```

Important functions:

```gdscript
func requirements_are_met(
    trait_purchase_count: int,
    grid_size: int,
    unlocked_vertex_upgrades: Dictionary
) -> bool
```

Checks upgrade requirements.

---

```gdscript
func get_category_name() -> String
```

Returns display category name.

---

## 6.5 `vertex_upgrade_effect.gd`

Path:

```text
res://scripts/resources/vertex_upgrade_effect.gd
```

Important variables:

```gdscript
@export var effect_type: EffectType
@export var target_id: String
@export var target_stat: String
@export var mechanic_id: String
@export var script_hook_id: String
@export var value: float
```

Effect types:

```gdscript
UNLOCK_PASSIVE_GENERATOR
GLOBAL_STAT_MULTIPLIER
ADD_PERMANENT_STAT
UNLOCK_MECHANIC
ADD_STARTING_SQUARES
UNLOCK_TAB
SCRIPT_HOOK
```

---

## 6.6 `passive_generator_definition.gd`

Path:

```text
res://scripts/resources/passive_generator_definition.gd
```

Important variables:

```gdscript
@export var id: String
@export var display_name: String
@export_multiline var description: String
@export var sort_order: int
@export var max_level: int
@export var base_interval_seconds: float
@export var minimum_interval_seconds: float
@export var interval_level_multiplier: float
@export var base_extraction_rate: float
@export var extraction_per_level: float
@export var maximum_extraction_rate: float
@export var base_level_cost: float
@export var level_cost_multiplier: float
@export var targeting_mode: TargetingMode
@export var self_condensation_is_permanent: bool
@export var self_condensation_unlock_level: int
```

Targeting modes:

```gdscript
RANDOM_SQUARE
HIGHEST_PAYOUT
LOWEST_RESPAWN
SELECTED_SQUARE
```

---

## 6.7 `run_upgrade_definition.gd`

Path:

```text
res://scripts/resources/run_upgrade_definition.gd
```

Important variables:

```gdscript
@export var id: String
@export var display_name: String
@export_multiline var description: String
@export var category: UpgradeCategory
@export var sort_order: int
@export var base_cost: float
@export var cost_multiplier: float
@export var max_level: int
@export var is_visible_by_default: bool
@export var hidden_until_unlocked: bool
@export var unlock_conditions: Array[RunUpgradeUnlockCondition]
@export var effects_per_level: Array[RunUpgradeEffect]
```

Important functions:

```gdscript
func is_valid_definition() -> bool
func get_category_name() -> String
func get_cost_for_next_level(current_level: int) -> float
func is_unlocked_by_conditions() -> bool
```

---

## 6.8 `run_upgrade_unlock_condition.gd`

Path:

```text
res://scripts/resources/run_upgrade_unlock_condition.gd
```

Variables:

```gdscript
@export var condition_type: ConditionType
@export var threshold: float
@export var target_id: String
```

Condition types:

```gdscript
ALWAYS
CURRENT_SQUARES
TRAIT_PURCHASE_COUNT
GRID_SIZE
ACHIEVEMENT_UNLOCKED
PASSIVE_GENERATOR_LEVEL
VERTEX_UPGRADE_PURCHASED
TOTAL_MANUAL_CLICKS
TOTAL_PASSIVE_CLICKS
```

Functions:

```gdscript
func is_met() -> bool
func get_display_text() -> String
```

---

## 6.9 `run_upgrade_effect.gd`

Path:

```text
res://scripts/resources/run_upgrade_effect.gd
```

Variables:

```gdscript
@export var effect_type: EffectType
@export var target_stat: String
@export var value: float
```

Effect types:

```gdscript
GLOBAL_RUN_STAT_MULTIPLIER
GLOBAL_RUN_STAT_ADDITION
```

---

## 6.10 `ui_theme_definition.gd`

Path:

```text
res://scripts/resources/ui_theme_definition.gd
```

Defines a UI theme.

Variables include:

```gdscript
@export var id: String
@export var display_name: String
```

Colors:

```gdscript
background
background_subtle
surface
surface_soft
surface_strong
border
border_soft
border_strong
text_primary
text_secondary
text_muted
accent_primary
accent_secondary
success
warning
danger
```

Shape:

```gdscript
panel_corner_radius
card_corner_radius
button_corner_radius
panel_border_width
card_border_width
button_border_width
```

Spacing:

```gdscript
screen_margin
panel_gap
section_gap
card_gap
inner_margin
grid_gap
trait_purchase_gap
```

---

# 7. Systems

---

## 7.1 `square_calculator.gd`

Path:

```text
res://scripts/systems/square_calculator.gd
```

Class:

```gdscript
class_name SquareCalculator
```

### Purpose

Pure calculation helper for Square payout and respawn.

### Functions

```gdscript
static func calculate_manual_payout(square_data: SquareData) -> float
```

Calculates manual click payout.

Applies:

* Square base value.
* Permanent base value multiplier.
* Run square base value multiplier.
* Run manual click multiplier.
* Run additions.
* Square-specific multipliers.
* Trait effects.

---

```gdscript
static func calculate_respawn_time(square_data: SquareData) -> float
```

Calculates respawn time.

Applies:

* Base respawn time.
* Run respawn multipliers/additions.
* Trait effects.

---

```gdscript
static func _apply_trait_to_stat(
    base_value: float,
    trait_iter: TraitInstance,
    target_stat: String
) -> float
```

Applies Trait effects matching a target stat.

Important: use `trait_iter`, not `trait`.

---

## 7.2 `number_formatter.gd`

Path:

```text
res://scripts/systems/number_formatter.gd
```

Class:

```gdscript
class_name NumberFormatter
```

### Purpose

Central formatting helper for numbers.

### Functions

```gdscript
static func amount(value: float) -> String
```

Formats currency-like values.

Examples:

```text
1 -> 1
1.25 -> 1.25
1234 -> 1.23K
```

---

```gdscript
static func integer_amount(value: int) -> String
```

Formats integer resources.

---

```gdscript
static func cost(value: float) -> String
```

Formats upgrade costs.

---

```gdscript
static func multiplier(value: float) -> String
```

Formats multiplier values.

Example:

```text
x1.003
```

---

```gdscript
static func percent(value: float) -> String
```

Formats ratio as percent.

---

```gdscript
static func signed_percent(value: float) -> String
```

Formats signed percent.

---

```gdscript
static func percent_from_multiplier(value: float) -> String
```

Formats multiplier delta as percent.

---

```gdscript
static func precise_percent_from_multiplier(value: float) -> String
```

Used for small effects.

Example:

```text
+0.10%
```

---

```gdscript
static func seconds(value: float) -> String
```

Formats seconds.

---

```gdscript
static func signed_amount(value: float) -> String
```

Formats additive values with sign.

---

# 8. UI Scripts

---

## 8.1 `main.gd`

Path:

```text
res://scripts/main/main.gd
```

### Purpose

Coordinates main UI.

Main responsibilities:

* Connect global game signals.
* Connect UI button signals.
* Switch center pages.
* Refresh labels.
* Refresh panels.
* Apply global theme to major layout nodes.
* Handle trait purchase button.
* Handle top/navigation buttons.
* Handle story messages.

### Important References

Common onready vars:

```gdscript
@onready var squares_label: Label
@onready var vertices_label: Label
@onready var trait_purchase_label: Label
@onready var story_label: Label
@onready var trait_purchase_button: Button
```

Page refs:

```gdscript
@onready var grid_page: GridPage
@onready var vertex_shop_page: VertexShopPage
@onready var options_page: OptionsPage
@onready var achievements_page: AchievementsPage
@onready var stats_page: Control
```

Panel refs:

```gdscript
@onready var passive_panel: PassivePanel
@onready var square_details_panel: SquareDetailsPanel
@onready var run_upgrades_panel: RunUpgradesPanel
```

Layout refs:

```gdscript
@onready var root_margin: MarginContainer
@onready var main_v_box: VBoxContainer
@onready var top_bar: PanelContainer
@onready var body_h_box: HBoxContainer
@onready var left_panel: VBoxContainer
@onready var right_panel: VBoxContainer
@onready var center_page_root: Control
@onready var trait_purchase_panel: PanelContainer
@onready var trait_purchase_details: Label
```

### Important Functions

```gdscript
func _ready() -> void
```

Initializes UI:

1. Connect signals.
2. Apply theme.
3. Show grid page.
4. Load save.
5. Refresh UI.

---

```gdscript
func _connect_global_signals() -> void
```

Connects EventBus/system signals.

---

```gdscript
func _connect_ui_signals() -> void
```

Connects buttons.

---

```gdscript
func _connect_page_signals() -> void
```

Connects page-level signals.

---

```gdscript
func _apply_theme() -> void
```

Applies theme to main layout controls and buttons.

---

```gdscript
func _refresh_all_ui() -> void
```

Refreshes all visible systems.

---

```gdscript
func _show_center_page(page_id: String) -> void
```

Switches center page stack.

Supported pages:

```text
grid
vertex_shop
stats
options
achievements
```

---

```gdscript
func _refresh_trait_purchase_panel() -> void
```

Updates trait purchase button/detail text.

---

```gdscript
func _refresh_achievement_summary() -> void
```

Updates achievement summary panel.

---

## 8.2 `grid_page.gd`

Path:

```text
res://scripts/ui/grid_page.gd
```

Class:

```gdscript
class_name GridPage
```

### Purpose

Owns grid UI.

Responsibilities:

* Build Square buttons.
* Refresh Square buttons.
* Emit square selection.
* Emit grid upgrade request.
* Update grid upgrade button.

### Signals

```gdscript
signal square_selected(square_id: String)
signal grid_upgrade_requested()
```

### Variables

```gdscript
@onready var grid_root: GridContainer
@onready var upgrade_grid_button: Button
@onready var grid_v_box: VBoxContainer
```

---

```gdscript
var square_button_scene: PackedScene
```

Scene used to instantiate Square buttons.

---

```gdscript
var square_buttons_by_id: Dictionary
```

Maps Square ID to button instance.

### Functions

```gdscript
func rebuild() -> void
```

Clears and recreates grid buttons based on `GameState.square_ids`.

---

```gdscript
func refresh_buttons() -> void
```

Refreshes all existing buttons.

---

```gdscript
func _refresh_upgrade_button() -> void
```

Updates grid upgrade button text/disabled state/tooltip.

---

```gdscript
func _get_rarity_unlock_text(next_grid_size: int) -> String
```

Returns rarity unlocked by next grid upgrade.

---

## 8.3 `square_button.gd`

Path:

```text
res://scripts/squares/square_button.gd
```

Class:

```gdscript
class_name SquareButton
```

### Purpose

Visual button for one Square.

Responsibilities:

* Display Square state.
* Emit clicked signal.
* Apply square visuals.
* Apply theme.

### Signals

```gdscript
signal square_clicked(square_id: String)
```

### Important Variables

```gdscript
var square_id: String
var square_data: SquareData
```

### Important Functions

```gdscript
func setup(square_id: String, display_text: String) -> void
```

Initializes button.

---

```gdscript
func set_square_data(p_square_data: SquareData) -> void
```

Updates runtime data and visuals.

---

```gdscript
func _apply_square_visuals() -> void
```

Applies color/visuals based on Square data.

---

```gdscript
func _apply_theme() -> void
```

Applies base themed button/card styles.

---

## 8.4 `square_details_panel.gd`

Path:

```text
res://scripts/ui/square_details_panel.gd
```

Class:

```gdscript
class_name SquareDetailsPanel
```

### Purpose

Displays selected Square information.

Should be concise. Debug/lifetime details belong in Stats page.

### Variables

```gdscript
@onready var selected_square_title: Label
@onready var selected_square_details: RichTextLabel
```

---

```gdscript
var selected_square_id: String
```

Currently inspected Square.

### Functions

```gdscript
func show_square(square_id: String) -> void
```

Selects and displays Square.

---

```gdscript
func refresh() -> void
```

Refreshes current selected Square.

---

```gdscript
func refresh_if_selected(square_id: String) -> void
```

Refreshes only if matching selected Square.

---

```gdscript
func clear() -> void
```

Clears panel.

---

```gdscript
func _build_square_details_text(square_data: SquareData) -> String
```

Builds display text.

Currently intended to show:

```text
Base Value
Manual Value
Respawn Time
Traits
Main Effects
```

---

## 8.5 `passive_panel.gd`

Path:

```text
res://scripts/ui/passive_panel.gd
```

Class:

```gdscript
class_name PassivePanel
```

### Purpose

Displays passive generator cards.

### Signals

```gdscript
signal passive_generator_upgraded(generator_id: String)
```

### Variables

```gdscript
@onready var passive_generator_list: VBoxContainer
var passive_generator_card_scene: PackedScene
var passive_generator_cards: Dictionary
```

### Functions

```gdscript
func refresh() -> void
```

Refreshes passive cards.

---

```gdscript
func _rebuild_list() -> void
```

Recreates visible passive generator cards.

---

```gdscript
func _on_upgrade_requested(generator_id: String) -> void
```

Calls `PassiveSystem.upgrade_generator`.

---

## 8.6 `passive_generator_card.gd`

Path:

```text
res://scripts/ui/passive_generator_card.gd
```

Class:

```gdscript
class_name PassiveGeneratorCard
```

### Purpose

Displays one passive generator instance.

Responsibilities:

* Show generator name.
* Show level.
* Show production details.
* Show upgrade button.
* Show progress.
* Emit upgrade request.

### Signals

```gdscript
signal upgrade_requested(generator_id: String)
```

### Important Variables

```gdscript
var generator_instance: PassiveGeneratorInstance
```

### Important Functions

```gdscript
func setup(instance: PassiveGeneratorInstance) -> void
func refresh() -> void
```

---

## 8.7 `run_upgrades_panel.gd`

Path:

```text
res://scripts/ui/run_upgrades_panel.gd
```

Class:

```gdscript
class_name RunUpgradesPanel
```

### Purpose

Displays current run upgrades.

### Variables

```gdscript
@onready var run_upgrade_list: VBoxContainer
var run_upgrade_card_scene: PackedScene
var run_upgrade_cards: Dictionary
```

### Functions

```gdscript
func refresh() -> void
```

Refreshes cards.

---

```gdscript
func _rebuild_if_needed() -> void
```

Checks whether visible upgrade set changed.

---

```gdscript
func _rebuild_list() -> void
```

Recreates visible cards.

---

```gdscript
func _get_visible_upgrades() -> Array[RunUpgradeDefinition]
```

Applies visibility rules.

---

```gdscript
func _on_buy_requested(upgrade_id: String) -> void
```

Calls `RunUpgradeSystem.buy_run_upgrade`.

---

## 8.8 `run_upgrade_card.gd`

Path:

```text
res://scripts/ui/run_upgrade_card.gd
```

Class:

```gdscript
class_name RunUpgradeCard
```

### Purpose

Displays one run upgrade.

### Signals

```gdscript
signal buy_requested(upgrade_id: String)
```

### Variables

```gdscript
var upgrade_definition: RunUpgradeDefinition
```

### Functions

```gdscript
func setup(upgrade: RunUpgradeDefinition) -> void
func refresh() -> void
func _get_detail_text() -> String
func _get_requirement_text() -> String
func _get_effect_text() -> String
func _format_effect(effect_iter: RunUpgradeEffect) -> String
func _format_stat_name(stat_id: String) -> String
```

---

## 8.9 `vertex_shop_page.gd`

Path:

```text
res://scripts/ui/vertex_shop_page.gd
```

Class:

```gdscript
class_name VertexShopPage
```

### Purpose

Displays Vertex upgrades.

### Signals

```gdscript
signal vertex_upgrade_purchased(upgrade_id: String)
```

### Variables

```gdscript
@onready var vertex_upgrade_list: VBoxContainer
var vertex_upgrade_card_scene: PackedScene
var vertex_upgrade_cards: Dictionary
```

### Functions

```gdscript
func refresh() -> void
func _rebuild_list() -> void
func _on_buy_requested(upgrade_id: String) -> void
```

---

## 8.10 `vertex_upgrade_card.gd`

Path:

```text
res://scripts/ui/vertex_upgrade_card.gd
```

Class:

```gdscript
class_name VertexUpgradeCard
```

### Purpose

Displays one Vertex upgrade.

### Signals

```gdscript
signal buy_requested(upgrade_id: String)
```

### Variables

```gdscript
var upgrade_definition: VertexUpgradeDefinition
```

### Functions

```gdscript
func setup(upgrade: VertexUpgradeDefinition) -> void
func refresh() -> void
func _get_detail_text() -> String
func _get_requirement_text() -> String
func _get_effects_text() -> String
func _format_effect(effect_iter: VertexUpgradeEffect) -> String
```

---

## 8.11 `options_page.gd`

Path:

```text
res://scripts/ui/options_page.gd
```

Class:

```gdscript
class_name OptionsPage
```

### Purpose

Owns options UI.

Current responsibilities:

* Manual save.
* Export save.
* Import save.
* Hard reset.
* Autosave enabled/disabled.
* Autosave interval.

### Signals

```gdscript
signal save_imported()
signal hard_reset_completed()
```

Future responsibility:

* Theme selector.

---

## 8.12 `achievements_page.gd`

Path:

```text
res://scripts/ui/achievements_page.gd
```

Class:

```gdscript
class_name AchievementsPage
```

### Purpose

Displays all achievements.

### Variables

```gdscript
@onready var achievement_list: VBoxContainer
var achievement_card_scene: PackedScene
var achievement_cards: Dictionary
```

### Functions

```gdscript
func refresh() -> void
func _rebuild_list() -> void
```

---

## 8.13 `achievement_card.gd`

Path:

```text
res://scripts/ui/achievement_card.gd
```

Class:

```gdscript
class_name AchievementCard
```

### Purpose

Displays one achievement.

Shows:

* Name.
* Description.
* Unlock state.
* Progress.
* Reward.

---

## 8.14 Theme UI Helpers

### `themed_panel.gd`

Path:

```text
res://scripts/ui/theme/themed_panel.gd
```

Reusable themed `PanelContainer`.

---

### `themed_background.gd`

Path:

```text
res://scripts/ui/theme/themed_background.gd
```

Applies background theme to root background panel.

---

### `theme_button_helper.gd`

Path:

```text
res://scripts/ui/theme/theme_button_helper.gd
```

Applies button theme styles.

---

### `theme_text_helper.gd`

Path:

```text
res://scripts/ui/theme/theme_text_helper.gd
```

Applies text colors to Labels/RichTextLabels.

---

### `theme_layout_helper.gd`

Path:

```text
res://scripts/ui/theme/theme_layout_helper.gd
```

Applies margins and separations from ThemeSystem.

---

# 9. Current Known UI Issues

The UI is currently functional but visually heavy.

Known issues:

```text
Cards are too tall.
Panels feel too massive.
Passive cards can show horizontal scrolling.
Run upgrade cards are too verbose.
Square details title can grow vertically.
Center grid needs more visual focus.
Side panels should feel lighter.
Top bar needs polish.
```

Next recommended UI task:

```text
UI-5 — Reduce dashboard visual density
```

Scope:

```text
Compact passive cards.
Compact run upgrade cards.
Reduce theme spacing.
Reduce card padding.
Fix title shrink/clip behavior.
Remove horizontal scrollbars.
Make grid visually dominant.
```

---

# 10. Commit Messages

Recent / relevant commits:

```bash
git commit -m "Add trait luck rarity weighting"
git commit -m "Add trait luck vertex upgrade"
git commit -m "Decouple grid expansion from trait purchase"
git commit -m "Add run-based square upgrades"
git commit -m "Add UI theme system foundation"
git commit -m "Apply theme to cards and buttons"
git commit -m "Refine themed UI spacing"
git commit -m "Restructure main dashboard layout"
```

Suggested next commit:

```bash
git commit -m "Update technical documentation"
```

Then next UI pass:

```bash
git commit -m "Reduce dashboard visual density"
```
