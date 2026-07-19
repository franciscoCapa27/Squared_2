# Squared² — Game Design Document

## 1. High-Level Concept

**Squared²** is a fast Buy Trait incremental game about a lonely square in empty space slowly becoming a universe of interconnected squares, Traits, geometry, and emergent systems.

The player begins with a single square. They click it to gain **Squares**, buy upgrades, automate collection, and buy Traits. Buying a Trait spends the current Squares cost, awards cost-based **Vertices**, and permanently changes one square without resetting the run. Over time, the board expands from one square into a grid, and every player’s board becomes a unique geometric history of Trait purchases, choices, luck, and strategy. A later **Condensation** system will provide the deeper reset layer.

The core emotional fantasy is:

> A single square in the void slowly becomes something vast, personal, and alive.

The core mechanical fantasy is:

> Fast Buy Trait decisions, permanent square evolution, randomized Traits, and grid-based synergies.

---

## 2. Core Pillars

### 2.1 Fast Buy Trait

Buying Traits should happen quickly, especially early. The first Buy Trait should happen within a few minutes.

Buy Trait is not a rare endgame event. It is the central rhythm of the game.

The player should think:

> “One more reset. Maybe this time I get something strange.”

### 2.2 Permanent Square Identity

Squares are not generic tiles forever. They accumulate history.

A square may eventually have many Traits. Some squares will become lucky, cursed, powerful, weird, unstable, or central to a build.

The player should feel attachment to individual squares.

Examples:

- Quick Square
- Dense Square
- Quick Square of Fire
- Hungry Square of the Outer Edge
- King Square of the First Grid
- Square of the Andals and the First Men

Squares should eventually be renameable.

### 2.3 Every Board Is Different

The game should create different boards for different players through randomized Traits, limited choices, trait purchase timing, square placement, and later board manipulation.

The player should feel:

> “This is my board. Nobody else has exactly this.”

### 2.4 Active and Idle Playstyles

The game supports both active and idle play.

Manual clicking should be bursty and intentional. Passive clicking should be steadier and automation-based.

These styles should exist early but should not fully fork until later.

### 2.5 Ethereal Geometry Tone

The game should feel lonely, abstract, cosmic, and gradually alive.

The square begins as a primitive shape in the void. Through repetition, trait purchase, and accumulation, it becomes the seed of a larger geometric universe.

Tone keywords:

- lonely
- ethereal
- geometric
- cosmic
- quiet
- mysterious
- emergent
- minimal
- ancient/future
- abstract but alive

---

## 3. Title

# Squared²

Pronunciation can be “Squared Squared” or “Squared Two.”

The title implies recursion, multiplication, geometry, escalation, and a square becoming more than itself.

---

## 4. Core Naming System

### 4.1 Normal Currency: Squares

The normal run currency is called **Squares**.

Example:

> Click a square → gain Squares.

This is intentionally simple and slightly funny. It also makes the game language recursive:

> Use squares to upgrade squares so squares make more Squares.

### 4.2 Permanent Currency: Vertices

The permanent currency earned by buying Traits is called **Vertices**.

Example:

> Buy Trait → gain Vertices.

Vertices are used for permanent upgrades, increased control, stronger starts, and later systems.

### 4.3 Permanent Modifiers: Traits

Permanent square modifiers are called **Traits**.

Example:

> This square gained the Quick Trait.

Traits should support cool square names and identity.

Examples:

- Quick Square
- Dense Square
- Patient Square
- Quick Square of Fire
- Hungry Square of the Third Row
- Crowned Square of the First Plane

### 4.4 Buy Trait Action Name

For now, use **Buy Trait** for clarity.

Later, the button/action could be renamed if a better thematic word emerges.

Possible future names:

- Collapse
- Reform
- Re-square
- Reframe
- Fold
- Redraw
- Recompose

Potential final phrasing:

> Buy a Trait. Gain Vertices. Keep the run.

---

## 5. Core Game Loop

### 5.1 Moment-to-Moment Loop

1. Player clicks an available square.
2. Square grants **Squares**.
3. Square temporarily disappears, dims, or enters cooldown.
4. Square respawns after a delay.
5. Player buys run upgrades.
6. Player generates Squares faster.
7. Buy Trait becomes available.

### 5.2 Buy Trait Loop

1. Player can afford the current Buy Trait cost.
2. Player decides whether to Buy Trait now or save for expansion.
3. Player spends the cost and gains cost-based Vertices.
4. The purchase count increases, raising the next cost.
5. One square gains a permanent randomized Trait.
6. Squares, upgrades, passives, timers, and other run state remain intact.
7. The board becomes stronger and more unique.
8. Player continues the current run.

### 5.3 Long-Term Loop

1. Fill current grid tier with traited squares.
2. Unlock next grid size.
3. Unlock better Trait rarities.
4. Unlock more player choice during trait purchase.
5. Unlock limited board manipulation.
6. Continue building a personal geometric universe.

---

## 6. Early Progression Structure

### 6.1 Tier 0 — The First Square

Grid size: **1x1**

The player starts with a single square in empty space.

Available mechanics:

- manual clicking
- square value upgrades
- respawn speed upgrades
- passive clickers
- passive clicker upgrades
- first trait purchase unlock

Goal:

Teach the player the basic loop and reach trait purchase quickly.

### 6.2 Tier 1 — The First Grid

Grid size: **2x2**

Opened by the Squares cost curve after the First Square Era; Trait purchases are not a hard gate.

New mechanics:

- multiple clickable squares
- first permanent Traits
- basic grid synergies
- adjacency, row, and column concepts
- first Vertex upgrades

Goal:

Teach the player that squares now have identity and position matters.

### 6.3 Tier 2 — The Growing Grid

Grid size: **3x3**

Opened by a substantially larger Squares cost after the 2x2 board has had time to develop. Trait placement remains random, so this is a pacing target rather than a per-square guarantee.

New mechanics:

- Uncommon Traits
- stronger positional effects
- more meaningful board patterns
- first limited square swapping
- more trait purchase choice

Goal:

Introduce strategic board manipulation without overwhelming the player.

### 6.4 Tier 3 — Future Expansion

Grid size: **4x4** or beyond

Possible future mechanics:

- Rare Traits
- build-defining square identities
- square families
- shape bonuses
- geometric patterns
- larger trait purchase layers
- automation specialization
- active/idle path separation

---

## 7. Buy Trait Timing and Decision

Buy Trait should always involve a meaningful decision.

The player should ask:

> “Do I buy a Trait now, or do I push longer to afford expansion and a stronger next purchase?”

### 7.1 Buy Trait Reward Components

Buy Trait grants:

1. **Vertices** — permanent currency based on the current Buy Trait cost.
2. **A new Trait** — permanent modifier added to a square.
3. Potential grid progression if requirements are met.

### 7.2 Example Buy Trait Formula

Current formula:

```text
Buy Trait cost = ceil(15 * 1.5 ^ buy_trait_count)
Vertices gained = max(1, floor(sqrt(buy_trait_cost / 25)))
```

Example values:

| Total Squares Earned | Vertices Gained |
|---:|---:|
| 1,000 | 1 |
| 4,000 | 2 |
| 9,000 | 3 |
| 25,000 | 5 |
| 100,000 | 10 |
| 1,000,000 | 31 |

The cost curve makes each purchase progressively harder, while the cost-based Vertex formula increases the permanent reward as the player commits to later purchases.

This formula is only a starting point and will require tuning.

---

## 8. Buy Trait Choice Evolution

Early trait purchase should be simple and random.

Later trait purchase should introduce controlled randomness.

### 8.1 Early Buy Trait

At first:

- Trait is randomly selected.
- Affected square is randomly selected.

This creates surprise and teaches the system.

### 8.2 Trait Choice

Later Vertex upgrade:

> Choose 1 Trait from 2 random options.

Later still:

> Choose 1 Trait from 3 random options.

This gives agency without eliminating randomness.

### 8.3 Square Choice

Later Vertex upgrade:

> Choose affected square from 2 or 3 randomly selected squares.

This prevents total control but allows strategic influence.

### 8.4 Design Rule

The game should preserve uncertainty.

The player should almost never have full control over both:

- exact Trait
- exact square

At least in the early and midgame, the fun comes from guided randomness.

---

## 9. Square Movement and Board Manipulation

Squares should eventually be movable, but not early.

Early game should avoid movement because it adds cognitive load before the player understands square identity, grid position, and Traits.

### 9.1 Movement Unlock Timing

Square movement should begin around the **3x3 grid tier**.

This is when the player has enough board complexity for movement to matter.

### 9.2 First Movement Mechanic

Initial movement should be very limited:

> Swap 2 squares once.

This may be unlocked as a permanent upgrade, trait purchase reward, or special action.

### 9.3 Future Movement Options

Possible later mechanics:

- one swap per trait purchase
- swap two adjacent squares only
- rotate a 2x2 block
- lock one square in place
- mark one square as preferred for future Traits
- shift an entire row
- shift an entire column
- mirror the board
- transpose the board

### 9.4 Design Rule

Movement should feel powerful and rare.

The player should not be able to freely rearrange the entire board at will, especially not early.

Position should matter because randomness placed things imperfectly.

---

## 10. Square Visual Identity

The game needs visual progression, but individual Traits should not each have unique visual effects if there will eventually be hundreds of Traits and dozens per square.

That would become unreadable and visually messy.

### 10.1 Visual Design Goal

Each square should visually communicate:

- it has history
- it has power
- it has personality
- it belongs to this specific board
- it has evolved

But the visuals should stay clean.

### 10.2 Avoid Trait-Specific Visual Clutter

Do not give every single Trait a unique visible effect directly on the square.

Specific Trait information should live in the square detail panel.

Square visuals should instead be generated from aggregate visual data.

### 10.3 Proposed Visual System

Each square has multiple visual channels.

Possible visual channels:

1. **Base color** — dominant Trait family, square archetype, or current alignment.
2. **Secondary color / accent** — highest rarity, special status, or secondary family.
3. **Glow intensity** — total power, total generated Squares, or Trait count.
4. **Gloss / material** — rarity tier, trait purchase depth, or special evolution stage.
5. **Edge complexity** — number of Traits, age, or square importance.
6. **Border thickness** — total modifier strength or defensive/stability theme.
7. **Inner pattern** — dominant category such as active, passive, row, column, chance, growth.
8. **Pulse rhythm** — active vs idle orientation, charge state, or cooldown behavior.
9. **Particle behavior** — unstable, cosmic, corrupted, overflow, or high-tier effects.
10. **Distortion** — late-game rule-breaking or reality-bending Traits.

This allows every square to look different without rendering every Trait individually.

### 10.4 Visuals as Data

A square should not have one single visual value.

It should have a generated **visual profile** made from multiple fields.

Example visual profile:

```text
base_color_family = "speed"
accent_color_family = "chance"
glow_level = 3
edge_complexity = 5
gloss_level = 1
pulse_style = "fast"
pattern_style = "diagonal_lines"
particle_style = "sparks"
distortion_level = 0
```

This profile can be recalculated from the square’s Traits, stats, tags, rarity, and history.

### 10.5 Avoid Identical End-State Boards

If color only represents total power, every late-game board may converge visually.

To avoid this, visuals should combine:

- total Trait count
- highest Trait rarity
- dominant Trait family
- second dominant Trait family
- square role
- square history
- special tags
- current status effects
- position-based effects
- player decisions

### 10.6 Trait Families for Visuals and Aggregation

Traits should have tags/families that influence both gameplay and visuals.

Possible families:

- value
- speed
- passive
- active
- adjacency
- row
- column
- diagonal
- chance
- storage
- growth
- conversion
- trait purchase
- movement
- copy
- absorb
- corruption
- cosmic
- fire
- void
- light
- mechanical
- organic

These families allow future aggregation, achievements, visual logic, synergies, and build detection.

Examples:

- A square with mostly speed Traits becomes visually sharp, fast-pulsing, and bright.
- A square with mostly passive Traits becomes smooth, mechanical, and stable.
- A square with adjacency Traits glows outward.
- A square with row Traits develops horizontal patterns.
- A square with column Traits develops vertical patterns.
- A square with chance Traits flickers or shimmers.
- A square with corruption Traits distorts.

### 10.7 Square Detail Panel

Clicking or hovering a square should show exact details:

- square name
- coordinate
- total generated Squares
- total Traits
- Trait list
- Trait tags/families
- dominant family
- current effective multipliers
- active status effects
- manual clicks
- passive clicks
- trait purchase history

This preserves readability while still allowing deep complexity.

---

## 11. Active and Idle Mechanics

### 11.1 Manual Clicking

Manual clicks grant full payout but consume the square temporarily.

Example:

- Player clicks square.
- Player gains 100% of square payout.
- Square enters cooldown.
- Square respawns after its respawn timer.

This makes active play bursty and timing-based.

### 11.2 Passive Clicking

Passive clickers extract value without consuming the square in the same way.

Example:

- Passive clicker extracts 20% of square payout.
- Square does not fully despawn.
- Passive clicker has its own rate and strength.

This creates a real mechanical distinction between active and idle play.

### 11.3 Future Playstyle Forking

Late game may allow explicit specialization.

Possible future paths:

- active clicking build
- passive automation build
- burst trait purchase build
- long-run scaling build
- row/column synergy build
- chance/gambling build
- square mutation build
- cosmic/corruption build

Do not force this too early.

---

## 12. Trait System

### 12.1 Trait Definition

A Trait is a permanent modifier attached to a square.

A square can have multiple Traits.

Traits can stack.

Traits may affect:

- square value
- base value
- respawn speed
- passive clicker strength
- manual click strength
- adjacent squares
- rows
- columns
- diagonals
- trait purchase currency gain
- chance effects
- temporary states
- square movement
- square growth
- future Traits
- visual profile
- other Trait effects

### 12.2 Rarity Tiers

Possible rarity tiers:

| Tier | Rarity | Role |
|---:|---|---|
| 1 | Common | Simple numerical and positional effects |
| 2 | Uncommon | Conditional effects and stronger synergies |
| 3 | Rare | Build-defining effects |
| 4 | Epic | Rule-bending effects |
| 5 | Legendary | Identity-defining effects |
| 6 | Cosmic / Impossible | Late-game reality-breaking effects |

### 12.3 Trait Design Rule

Higher rarity should not merely mean larger numbers.

Higher rarity should introduce new behavior.

Examples:

- copying part of adjacent Trait effects
- absorbing adjacent modifiers at partial strength
- converting Squares into Vertices
- storing overkill payout
- creating chain reactions
- modifying trait purchase formulas
- changing passive clicker behavior
- growing stronger across trait purchases
- unlocking new square states

---

## 13. Future-Proof Data Model

This section is intentionally more technical because the game will need a flexible data structure if Traits can become strange, stacked, copied, absorbed, tagged, visualized, and aggregated.

The goal is to avoid hardcoding every Trait as a unique script unless absolutely necessary.

### 13.1 Core Principle

Use a hybrid system:

1. **Data-driven effects** for most Traits.
2. **Tags/families** for aggregation and visual identity.
3. **Effect components** for composable behavior.
4. **Optional script hooks** for rare/weird Traits.

This allows simple Traits to be created from data while still supporting special late-game mechanics.

---

## 14. Square Data Structure

Each square should be an entity with identity, position, stats, Traits, tags, visual data, and history.

Example conceptual structure:

```text
Square
- id
- display_name
- base_name
- coordinate
- grid_position
- created_at_trait_purchase
- created_at_grid_tier
- traits[]
- permanent_tags[]
- temporary_tags[]
- status_effects[]
- base_stats
- run_stats
- lifetime_stats
- visual_profile
- locks / flags
```

### 14.1 Square Identity Fields

```text
id: unique identifier
base_name: generated name, e.g. "Quick Square"
display_name: player rename, optional
coordinate: A1, A2, B1, etc.
created_at_trait_purchase: trait purchase count when created
created_at_grid_tier: grid tier when created
```

### 14.2 Square Trait Fields

```text
traits: list of TraitInstance objects
permanent_tags: tags gained permanently
temporary_tags: tags active only this run/status
status_effects: temporary effects like charged, frozen, overloaded, corrupted
```

### 14.3 Square Base Stats

```text
base_value
base_respawn_time
base_manual_multiplier
base_passive_multiplier
base_crit_chance
base_crit_multiplier
```

### 14.4 Square Run Stats

```text
current_cooldown
current_charge
temporary_value_multiplier
temporary_speed_multiplier
run_squares_generated
run_manual_clicks
run_passive_clicks
```

### 14.5 Square Lifetime Stats

```text
lifetime_squares_generated
lifetime_manual_clicks
lifetime_passive_clicks
times_traited
times_selected_for_trait_purchase
highest_single_payout
```

### 14.6 Square Flags / Locks

```text
can_receive_traits
is_locked_from_random_trait
is_favored_for_trait
can_be_swapped
is_anchored
is_corrupted
```

---

## 15. Trait Data Structure

Traits should be defined separately from Trait instances.

A **TraitDefinition** describes what the Trait can do.

A **TraitInstance** is the actual Trait attached to a specific square, with rolled values.

This distinction is important because the same Trait can roll different values.

### 15.1 TraitDefinition

Example conceptual structure:

```text
TraitDefinition
- id
- name
- rarity
- description_template
- tags[]
- weight
- min_grid_tier
- max_stack_count
- can_duplicate
- effect_components[]
- visual_influence
- name_fragments
- script_hook_id
```

### 15.2 TraitInstance

Example conceptual structure:

```text
TraitInstance
- definition_id
- instance_id
- rolled_values
- source
- acquired_at_trait_purchase
- acquired_at_grid_tier
- stack_index
- is_absorbed_copy
- copied_from_square_id
- copied_from_trait_id
- effectiveness_multiplier
```

This allows a Trait like **Absorb** to create partial copied Trait instances from adjacent squares.

---

## 16. Effect Component System

Traits should be built from effect components.

Instead of hardcoding every Trait, each Trait can contain one or more effects.

Example:

```text
Dense Trait
- Effect: StatModifier
  target_stat: square_value
  operation: multiply
  value: 1.5
- Effect: StatModifier
  target_stat: respawn_time
  operation: multiply
  value: 1.15
```

### 16.1 Common Effect Component Types

#### StatModifier

Changes a stat.

Fields:

```text
target_stat
operation: add / multiply / subtract / divide / override
value
scope
condition
```

Examples:

- +50% square value
- -20% respawn time
- +25% passive clicker efficiency

#### PositionalModifier

Applies to squares based on position.

Fields:

```text
target_pattern: self / adjacent / row / column / diagonal / all / corners / edges
stat
operation
value
condition
```

Examples:

- adjacent squares gain +15% value
- row gains +10% value
- column gains +10% passive extraction

#### TriggerEffect

Runs when an event happens.

Fields:

```text
trigger_event
chance
cooldown
condition
effects[]
```

Trigger events could include:

- on_manual_click
- on_passive_click
- on_square_respawn
- on_trait_purchase
- on_trait_gained
- on_adjacent_clicked
- on_row_clicked
- on_column_clicked
- on_run_start
- on_threshold_reached

#### ResourceConversion

Converts one resource into another.

Fields:

```text
from_resource
to_resource
rate
cap
trigger_event
condition
```

Examples:

- convert 0.1% of Squares earned into bonus Vertices
- convert passive clicks into charge

#### TraitCopy

Copies Traits from other squares at reduced strength.

Fields:

```text
source_pattern: adjacent / row / column / diagonal / random / strongest / weakest
trait_filter_tags[]
rarity_filter
copy_limit
effectiveness_multiplier
copy_mode: temporary / permanent / run_only
include_visual_influence: true/false
```

Example:

> Copy one adjacent Trait at 20% effectiveness.

#### TraitAbsorb

Absorbs effects from other Traits, possibly destroying, copying, or partially inheriting them.

Fields:

```text
source_pattern
trait_filter_tags[]
rarity_filter
absorb_limit
absorb_percentage_min
absorb_percentage_max
absorb_mode: copy / steal / consume / mirror / temporary
selection_rule: random / strongest / newest / oldest / matching_tag
include_tags: true/false
include_visual_influence: true/false
```

Example:

> Absorb one adjacent modifier at 20% effectiveness.

This could create a TraitInstance flagged as:

```text
is_absorbed_copy = true
effectiveness_multiplier = 0.2
copied_from_square_id = "B2"
```

#### StatusApplier

Applies a temporary state.

Fields:

```text
status_id
duration
stacking_rule
trigger_event
chance
```

Examples:

- charged
- overloaded
- frozen
- corrupted
- resonating

#### VisualInfluence

Adds visual weight to a square.

Fields:

```text
visual_channel
value
weight
condition
```

Examples:

- increase glow
- add speed color weight
- increase edge complexity
- add corruption distortion

---

## 17. Scope System

Many future Traits depend on targeting patterns.

The game should define reusable scopes.

### 17.1 Basic Scopes

```text
self
adjacent_orthogonal
adjacent_diagonal
all_adjacent
same_row
same_column
same_diagonal
entire_grid
corners
edges
center
random_square
random_traited_square
random_untraited_square
strongest_square
weakest_square
```

### 17.2 Future Scopes

```text
same_tag
same_dominant_family
same_color_family
same_rarity_trait
within_distance_n
connected_component
shape_pattern
2x2_block
outer_ring
inner_ring
```

Scopes should be reusable for gameplay, visuals, achievements, and UI explanation.

---

## 18. Tag System

Tags are essential for future-proofing.

Tags should exist at several levels:

1. Trait tags
2. Square tags
3. Effect tags
4. Visual tags
5. Build tags

### 18.1 Trait Tags

Examples:

```text
value
speed
passive
active
adjacency
row
column
chance
growth
trait purchase
copy
absorb
corruption
cosmic
fire
void
mechanical
organic
```

### 18.2 Square Tags

Square tags can be derived from Traits or granted directly.

Examples:

```text
speed_square
passive_square
support_square
corrupted_square
corner_square
ancient_square
high_value_square
unstable_square
```

### 18.3 Why Tags Matter

Tags allow future systems like:

- “All fire squares gain +10%.”
- “Squares with 3+ speed Traits pulse faster.”
- “Copy a random passive Trait from an adjacent square.”
- “Unlock achievement: create a square with 5 chance Traits.”
- “Apply a visual distortion to corrupted squares.”
- “Detect player build archetype.”

---

## 19. Visual Profile Data Structure

Square visuals should be generated from a structured visual profile.

### 19.1 VisualProfile

Example conceptual structure:

```text
VisualProfile
- base_color
- accent_color
- color_weights
- glow_level
- glow_color
- edge_complexity
- edge_style
- border_thickness
- gloss_level
- material_style
- inner_pattern
- pulse_style
- pulse_speed
- particle_style
- particle_density
- distortion_level
- distortion_style
- scale_modifier
- rotation_behavior
```

### 19.2 Generated From Data

The visual profile should be generated from:

- Trait count
- Trait rarities
- Trait tags
- square lifetime stats
- dominant family
- secondary family
- square status effects
- special flags
- grid tier

### 19.3 Example Visual Aggregation

```text
if dominant_tag == "speed":
    base_color_family = speed_color
    pulse_speed += 1
    edge_style = sharp

if dominant_tag == "passive":
    material_style = smooth
    pulse_style = steady

if has_tag("corruption"):
    distortion_level += 1
    particle_style = unstable

edge_complexity = min(10, total_traits)
glow_level = rarity_score + log(lifetime_squares_generated)
gloss_level = highest_rarity_tier
```

The exact implementation can change, but the key idea is that visual identity is derived from multiple data points, not one modifier = one visual.

---

## 20. Calculation Pipeline

Because Traits can affect other Traits, adjacent squares, rows, columns, and visuals, the game needs a clean calculation pipeline.

### 20.1 Suggested Calculation Order

When calculating a square payout:

1. Start with square base stats.
2. Apply permanent player upgrades.
3. Apply self Trait stat modifiers.
4. Apply positional modifiers from other squares.
5. Apply copied/absorbed Trait effects.
6. Apply temporary status effects.
7. Apply active/passive context multiplier.
8. Apply chance/trigger effects.
9. Generate final payout.
10. Update run and lifetime stats.

### 20.2 Avoid Infinite Loops

Traits like copy/absorb can create recursion problems.

Rules needed:

- copied Traits should not copy other copied Traits unless explicitly allowed
- absorbed copies should have effectiveness multipliers
- effect calculation should have a maximum depth
- circular references should be prevented or resolved safely
- visual influence from copied Traits may be optional

Example rule:

> Absorbed or copied Traits do not trigger additional copy/absorb effects by default.

This prevents infinite chains.

---

## 21. Early Common Trait Examples

These names are placeholders and should be revised to fit final tone.

### 21.1 Dense

Effect:

- +50% Squares from this square
- +15% respawn time

Tags:

- value
- heavy

### 21.2 Quick

Effect:

- -25% respawn time
- -10% Squares from this square

Tags:

- speed

### 21.3 Neighboring

Effect:

- adjacent squares gain +15% Squares

Tags:

- adjacency
- support

### 21.4 Horizontal

Effect:

- squares in the same row gain +10% Squares

Tags:

- row
- support

### 21.5 Vertical

Effect:

- squares in the same column gain +10% Squares

Tags:

- column
- support

### 21.6 Patient

Effect:

- if this square is not manually clicked for 5 seconds, its next manual click gives +100% Squares

Tags:

- active
- timing

### 21.7 Repeating

Effect:

- 10% chance to repeat its payout

Tags:

- chance

### 21.8 Mechanical

Effect:

- passive clickers targeting this square are 25% stronger

Tags:

- passive
- mechanical

### 21.9 Hungry

Effect:

- gains +1% temporary Squares when adjacent squares are clicked
- temporary bonus resets on new game or future Condensation

Tags:

- growth
- adjacency

### 21.10 Split

Effect:

- 15% chance to grant 25% of payout to a random adjacent square

Tags:

- chance
- adjacency

---

## 22. Future Trait Examples

### 22.1 Absorbing

Effect:

- absorb one adjacent Trait at 20% effectiveness

Possible implementation:

```text
TraitAbsorb
source_pattern = adjacent_orthogonal
absorb_limit = 1
absorb_percentage_min = 0.2
absorb_percentage_max = 0.2
absorb_mode = copy
selection_rule = random
include_tags = true
include_visual_influence = false
```

Tags:

- absorb
- adjacency
- rare

### 22.2 Mirroring

Effect:

- copy the strongest adjacent value Trait at 30% effectiveness for this run

Tags:

- copy
- adjacency
- temporary

### 22.3 Crowned

Effect:

- this square gains +5% Squares for each other square in the grid with fewer Traits than it

Tags:

- value
- hierarchy
- scaling

### 22.4 Gravitational

Effect:

- adjacent squares contribute 5% of their payout to this square

Tags:

- adjacency
- cosmic
- conversion

### 22.5 Vertex-Bound

Effect:

- this square slightly increases Vertices gained on trait purchase

Tags:

- trait purchase
- conversion

---

## 23. Permanent Upgrade System

Permanent upgrades are bought with Vertices.

### 23.1 Upgrade Goals

Permanent upgrades should:

- make future runs faster
- increase player agency
- unlock quality-of-life
- create new strategic options
- improve trait purchase rewards
- modify randomness carefully

### 23.2 Early Vertex Upgrade Examples

#### Larger Origin

Start each run with +1 base Squares per square.

#### Sharper Edges

All squares grant +10% Squares.

#### Faster Return

All squares respawn 5% faster.

#### First Automation

Start each run with passive clickers unlocked.

#### Better Instruments

Passive clickers are 10% stronger.

#### Choose Trait I

On trait purchase, choose 1 Trait from 2 random options.

#### Choose Trait II

On trait purchase, choose 1 Trait from 3 random options.

#### Choose Square I

On trait purchase, choose the affected square from 2 random squares.

#### Choose Square II

On trait purchase, choose the affected square from 3 random squares.

#### Favor the Empty

Squares without Traits are more likely to be selected.

#### First Swap

Unlock one square swap per trait purchase, starting at 3x3 grid tier.

---

## 24. Grid Progression Requirements

### 24.1 Tier Unlock Rule

To unlock the next grid tier:

> Every square in the current grid must have at least one Trait.

Example:

- 1x1 → 2x2 after first trait purchase.
- 2x2 → 3x3 after all four squares have at least one Trait.
- 3x3 → 4x4 after all nine squares have at least one Trait.

### 24.2 Duplicate Traits on Same Square

Buy Trait may hit a square that already has a Trait.

This is allowed.

This creates:

- chance
- attachment
- frustration
- lucky super-squares
- uneven boards
- player stories

### 24.3 Mercy / Agency Systems

Because random selection can delay progression, later upgrades can reduce frustration.

Possible systems:

- empty squares have higher selection weight
- choose from random candidate squares
- lock one square from receiving new Traits
- mark one square as preferred
- spend Vertices to force an empty square

Do not add too much control too early.

---

## 25. Story and Atmosphere

The game should include fast, minimal storytelling.

The story should not interrupt the incremental flow. It should appear as short lines, unlock messages, trait purchase text, and atmospheric fragments.

### 25.1 Story Premise

At first, there is only a square.

The square produces Squares.

Through repeated collapse and reformation, the square begins to remember.

Memory becomes shape.

Shape becomes grid.

Grid becomes space.

Space becomes life.

Life becomes thought.

Thought becomes universe.

### 25.2 Story Delivery

Story should be delivered through:

- first-time unlock messages
- trait purchase messages
- tier transition text
- square inspection flavor
- rare event text
- subtle background changes
- title changes

### 25.3 Example Early Story Beats

Start:

> There is a square.

First click:

> It responds.

First upgrade:

> Repetition becomes structure.

First passive clicker:

> The square learns to continue without you.

First trait purchase unlock:

> Collapse is not an ending.

First trait purchase:

> Something remains.

2x2 unlock:

> One became four. The void has corners now.

First Trait:

> The square remembers differently.

All 2x2 squares modified:

> The first plane is complete.

3x3 unlock:

> Space deepens.

First swap unlock:

> Position is no longer fate.

### 25.4 Tone of Writing

Short. Sparse. Slightly poetic. No lore dumps.

The text should feel like discovering cosmic geometry, not reading a fantasy novel.

---

## 26. MVP Scope

The first playable version should prove the core hook only.

### 26.1 MVP Must Include

- One starting square
- Manual clicking
- Square cooldown / respawn
- Squares currency
- Basic run upgrades
- Passive clicker
- Buy Trait button
- Vertices currency
- 2x2 grid unlock
- Random Traits
- Traits persist after trait purchase
- Basic visual evolution from aggregate square data
- Square detail panel
- Basic trait purchase screen
- Save/load

### 26.2 MVP Should Not Include Yet

- 3x3 grid
- Uncommon rarity
- square movement
- complex story system
- hundreds of Traits
- late-game trait purchase layers
- active/idle specialization trees
- offline progress
- mobile UI
- complex animations

### 26.3 MVP Success Test

The MVP is successful if the player wants to trait purchase again to see what happens to the board.

Core question:

> Does receiving a permanent random Trait make the player want another run?

---

## 27. Godot Implementation Notes

### 27.1 Suggested Scene Structure

#### Main Scene

Contains:

- Squares display
- Vertices display
- grid container
- upgrade panel
- square detail panel
- story/unlock message area

#### Square Scene

Each square should be its own reusable scene.

Properties:

- square_id
- display_name
- grid_position
- base stats
- current state
- Trait instances
- tags
- visual profile
- lifetime stats

#### Upgrade Panel

Handles normal run upgrades:

- value upgrades
- respawn upgrades
- passive clicker upgrades
- trait purchase unlock

#### Buy Trait Screen

Shows:

- Vertices gained now
- next Vertex thresholds
- Trait options when unlocked
- square options when unlocked
- confirmation button

### 27.2 Use Resources for Data

Godot Resources are a good fit for definitions like:

- TraitDefinition
- EffectComponentDefinition
- UpgradeDefinition
- VisualRuleDefinition
- StoryTriggerDefinition

Runtime instances should be separate from definitions.

For example:

- `TraitDefinition` = the designed Trait data.
- `TraitInstance` = this specific rolled Trait on this specific square.

### 27.3 Save Data

Save file should include:

- current Squares
- total Squares this run
- lifetime Squares
- current Vertices
- lifetime Vertices
- trait purchase count
- grid tier
- grid size
- square data
- Trait instances per square
- permanent upgrades purchased
- normal upgrades purchased
- story flags triggered

---

## 28. Design Risks

### 28.1 Too Much Randomness

If the player has no agency, trait purchase may feel frustrating.

Solution:

Introduce controlled choice gradually.

### 28.2 Too Much Visual Noise

If every Trait has its own visual effect, late-game squares become unreadable.

Solution:

Use aggregate visual channels and detail panels.

### 28.3 Too Slow Early Game

If the first trait purchase takes too long, the player never sees the real hook.

Solution:

First trait purchase should happen quickly.

### 28.4 Generic Incremental Feel

If upgrades are only numerical, the game may feel like any other idle game.

Solution:

Use grid synergies, square identity, and trait purchase mutation as the central hook.

### 28.5 Board Convergence

If all squares eventually become visually or mechanically similar, the “unique board” fantasy fails.

Solution:

Use Trait families, uneven random growth, limited movement, and choices that preserve variation.

### 28.6 Data Model Rigidity

If every Trait is hardcoded, future weird modifiers become painful to add.

Solution:

Use data-driven Trait definitions, composable effect components, tags, scopes, and optional script hooks.

---

## 29. Immediate Next Design Tasks

1. Confirm final terminology:
   - normal currency: Squares
   - trait purchase currency: Vertices
   - modifiers: Traits

2. Define the first 8 normal upgrades.

3. Define the first 10 Common Traits.

4. Define first 6 Vertex upgrades.

5. Define the first version of the Trait data schema in Godot terms.

6. Define the first version of the Square data schema in Godot terms.

7. Define the first visual profile fields.

8. Decide first trait purchase timing target.

9. Prototype the 1x1 clicking loop in Godot.

10. Add Buy Trait and 2x2 grid unlock.

11. Add random Trait assignment.

12. Add basic aggregate visual evolution system.

13. Test whether the trait purchase loop feels addictive.

---

## 30. Current Design Summary

**Squared²** is a fast Buy Trait incremental game where the player begins with one square in the void. By clicking, upgrading, automating, and repeatedly buying Traits, the square evolves into a grid. Each purchase permanently gives a square a randomized Trait while preserving the current run, creating an evolving board full of history, luck, strategy, and identity. Future Condensation will be the deeper reset layer.

The game should feel minimal and ethereal at first, then increasingly alive and cosmic.

The unique hook is:

> Your board is not just upgraded. It is remembered.
