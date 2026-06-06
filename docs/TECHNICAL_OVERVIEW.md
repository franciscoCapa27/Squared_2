\# Squared² — Technical Overview



\*Last updated: 2026-06-07\*



\## 1. Project Summary



\*\*Squared²\*\* is a Godot 4.6 incremental game built around fast prestige loops, persistent square identity, randomized Traits, and grid-based progression.



The current prototype implements the first playable technical foundation:



\* one clickable square;

\* `Squares` as the normal currency;

\* `Vertices` as the prestige currency;

\* real square respawn timing;

\* prestige into a 2x2 grid;

\* resource-based Traits loaded from `.tres` files;

\* random Trait assignment on prestige;

\* Trait effects applied to gameplay calculations;

\* square visuals derived from square data, not hardcoded directly in the button;

\* square details shown in the side panel.



The current goal is not polish. The current goal is to prove the core architecture and the first version of the core loop:



> Click square → earn Squares → prestige → gain Vertices → one random square gains a persistent Trait → square behavior changes.



\---



\## 2. Current Project Structure



Current recommended structure:



```text

res://

&#x20; data/

&#x20;   traits/

&#x20;     common/

&#x20;       dense.tres

&#x20;       quick.tres



&#x20; scenes/

&#x20;   main/

&#x20;     Main.tscn

&#x20;   squares/

&#x20;     SquareButton.tscn



&#x20; scripts/

&#x20;   autoload/

&#x20;     event\_bus.gd

&#x20;     game\_state.gd

&#x20;     trait\_database.gd



&#x20;   core/

&#x20;     square\_data.gd

&#x20;     trait\_instance.gd



&#x20;   main/

&#x20;     main.gd



&#x20;   resources/

&#x20;     effect\_component.gd

&#x20;     trait\_definition.gd

&#x20;     visual\_profile.gd



&#x20;   squares/

&#x20;     square\_button.gd



&#x20;   systems/

&#x20;     square\_calculator.gd

```



\---



\## 3. Autoloads



The project currently uses three singleton autoloads.



Autoload order should be:



```text

EventBus

TraitDatabase

GameState

```



This order matters because `GameState` depends on both `EventBus` and `TraitDatabase`.



\---



\### 3.1 `EventBus`



Path:



```text

res://scripts/autoload/event\_bus.gd

```



Purpose:



`EventBus` is a signal hub used to decouple systems from UI.



Current signals:



```gdscript

signal squares\_changed(value: float)

signal vertices\_changed(value: int)

signal prestige\_changed(value: int)

signal grid\_changed()

signal square\_selected(square\_id: String)

signal story\_message(message: String)

```



Current usage:



\* `GameState` emits signals when currency, prestige, or grid state changes.

\* `Main` listens to those signals and updates UI.

\* Story messages are emitted through this bus.



Design note:



`EventBus` should stay simple. It should not hold game state or business logic.



\---



\### 3.2 `TraitDatabase`



Path:



```text

res://scripts/autoload/trait\_database.gd

```



Purpose:



`TraitDatabase` loads all `TraitDefinition` resources from:



```text

res://data/traits/

```



It recursively scans folders and loads `.tres` / `.res` files that are valid `TraitDefinition` resources.



Current responsibilities:



\* load Trait resources;

\* validate Trait IDs;

\* detect duplicate Trait IDs;

\* provide Traits by ID;

\* provide available Traits by grid tier;

\* return a weighted random Trait.



Important architectural decision:



`TraitDatabase` is an autoload singleton and should \*\*not\*\* have:



```gdscript

class\_name TraitDatabase

```



Reason:



Godot would then have both a global class named `TraitDatabase` and an autoload singleton named `TraitDatabase`, which causes a naming conflict.



Correct pattern:



```gdscript

extends Node

```



Access globally via the autoload name:



```gdscript

TraitDatabase.get\_random\_trait(grid\_size)

```



\---



\### 3.3 `GameState`



Path:



```text

res://scripts/autoload/game\_state.gd

```



Purpose:



`GameState` stores the current runtime game state.



Current state includes:



```gdscript

var squares: float

var vertices: int

var prestige\_count: int



var grid\_size: int

var square\_ids: Array\[String]

var squares\_by\_id: Dictionary

```



Current responsibilities:



\* initialize the first grid;

\* store and retrieve `SquareData`;

\* handle square clicks;

\* calculate prestige availability;

\* calculate Vertex gain;

\* execute prestige;

\* unlock the 2x2 grid on first prestige;

\* apply a random Trait to a random square on prestige;

\* emit relevant events through `EventBus`.



Current development tuning:



Prestige is currently tuned for testing, using a low threshold:



```gdscript

func can\_prestige() -> bool:

&#x20;   return squares >= 10.0



func calculate\_vertices\_gain() -> int:

&#x20;   return int(floor(sqrt(squares / 10.0)))

```



This should later be replaced with the real early-game tuning.



\---



\## 4. Core Runtime Data



\---



\### 4.1 `SquareData`



Path:



```text

res://scripts/core/square\_data.gd

```



Type:



```gdscript

extends RefCounted

class\_name SquareData

```



Purpose:



`SquareData` represents the actual game-state version of a square.



This is \*\*not\*\* the visual button. It is the persistent runtime data behind the square.



Current responsibilities:



\* store square identity;

\* store grid position;

\* store Traits;

\* store base stats;

\* store run stats;

\* store lifetime stats;

\* track tags;

\* rebuild the square’s visual profile;

\* record manual/passive click stats.



Important fields include:



```gdscript

var id: String

var coordinate: String

var display\_name: String



var grid\_x: int

var grid\_y: int



var traits: Array\[TraitInstance]



var base\_value: float = 1.0

var base\_respawn\_time: float = 1.0

var base\_manual\_multiplier: float = 1.0

var base\_passive\_multiplier: float = 0.2



var lifetime\_squares\_generated: float

var lifetime\_manual\_clicks: int

var lifetime\_passive\_clicks: int



var visual\_profile: VisualProfile

```



Current naming behavior:



When a square gains Traits, it receives a generated name based on its Traits.



Current examples:



```text

Dense Square

Quick Square

Dense Square of Dense

Quick Square of Dense

```



Known issue:



Repeated Traits currently duplicate in the generated name. This should be improved so duplicate Traits are shown as levels or stacks instead of repeated name components.



Example desired future behavior:



```text

Dense Square II

Dense Square III

Quick Square of Dense II

```



\---



\### 4.2 `TraitInstance`



Path:



```text

res://scripts/core/trait\_instance.gd

```



Type:



```gdscript

extends RefCounted

class\_name TraitInstance

```



Purpose:



`TraitInstance` represents a specific runtime copy of a Trait attached to a square.



It references a `TraitDefinition`, but it is not the same thing as the definition.



Why this distinction matters:



\* `TraitDefinition` = designed blueprint.

\* `TraitInstance` = actual Trait on an actual square.



Current fields include:



```gdscript

var instance\_id: String

var definition: TraitDefinition

var rolled\_values: Dictionary



var source: String = "prestige"

var acquired\_at\_prestige: int

var acquired\_at\_grid\_tier: int

var stack\_index: int = 1



var is\_absorbed\_copy: bool = false

var copied\_from\_square\_id: String

var copied\_from\_trait\_instance\_id: String



var effectiveness\_multiplier: float = 1.0

```



Current state:



`rolled\_values` exists but is not yet used. Trait values are currently fixed from the `TraitDefinition` effect components.



Planned change:



Trait effects should support rolled ranges. For example, a Common Dense Trait should not always be exactly:



```text

+50% Squares

+15% respawn time

```



Instead, it should roll within a range, such as:



```text

+20% to +50% Squares

+5% to +15% respawn time

```



Those actual rolled values should live in `TraitInstance.rolled\_values`.



\---



\## 5. Resource Definitions



\---



\### 5.1 `TraitDefinition`



Path:



```text

res://scripts/resources/trait\_definition.gd

```



Type:



```gdscript

extends Resource

class\_name TraitDefinition

```



Purpose:



`TraitDefinition` is a reusable Trait blueprint saved as a `.tres` resource.



Current examples:



```text

res://data/traits/common/dense.tres

res://data/traits/common/quick.tres

```



Current fields include:



```gdscript

@export var id: String

@export var display\_name: String

@export\_multiline var description: String



@export var rarity: Rarity

@export var tags: Array\[String]



@export var weight: float

@export var min\_grid\_tier: int

@export var max\_stack\_count: int

@export var can\_duplicate: bool



@export var effect\_components: Array\[EffectComponent]



@export var name\_prefixes: Array\[String]

@export var name\_suffixes: Array\[String]



@export var visual\_glow\_weight: int

@export var visual\_edge\_complexity\_weight: int

@export var visual\_gloss\_weight: int

@export var visual\_distortion\_weight: int



@export var script\_hook\_id: String

```



Current rarity enum:



```gdscript

enum Rarity {

&#x20;   COMMON,

&#x20;   UNCOMMON,

&#x20;   RARE,

&#x20;   EPIC,

&#x20;   LEGENDARY,

&#x20;   COSMIC

}

```



Design note:



Traits are designed as data resources instead of being hardcoded in the database.



Correct approach:



```text

TraitDatabase loads TraitDefinition resources.

GameState creates TraitInstance objects from TraitDefinition resources.

SquareCalculator applies EffectComponents from TraitInstance.definition.

```



\---



\### 5.2 `EffectComponent`



Path:



```text

res://scripts/resources/effect\_component.gd

```



Type:



```gdscript

extends Resource

class\_name EffectComponent

```



Purpose:



`EffectComponent` defines a composable gameplay effect.



Current effect types:



```gdscript

enum EffectType {

&#x20;   STAT\_MODIFIER,

&#x20;   POSITIONAL\_MODIFIER,

&#x20;   TRIGGER\_EFFECT,

&#x20;   RESOURCE\_CONVERSION,

&#x20;   TRAIT\_COPY,

&#x20;   TRAIT\_ABSORB,

&#x20;   STATUS\_APPLIER,

&#x20;   VISUAL\_INFLUENCE

}

```



Current operations:



```gdscript

enum Operation {

&#x20;   ADD,

&#x20;   SUBTRACT,

&#x20;   MULTIPLY,

&#x20;   DIVIDE,

&#x20;   OVERRIDE

}

```



Current scopes:



```gdscript

enum Scope {

&#x20;   SELF,

&#x20;   ADJACENT\_ORTHOGONAL,

&#x20;   ADJACENT\_DIAGONAL,

&#x20;   ALL\_ADJACENT,

&#x20;   SAME\_ROW,

&#x20;   SAME\_COLUMN,

&#x20;   SAME\_DIAGONAL,

&#x20;   ENTIRE\_GRID,

&#x20;   CORNERS,

&#x20;   EDGES,

&#x20;   CENTER,

&#x20;   RANDOM\_SQUARE,

&#x20;   RANDOM\_TRAITED\_SQUARE,

&#x20;   RANDOM\_UNTRAITED\_SQUARE,

&#x20;   STRONGEST\_SQUARE,

&#x20;   WEAKEST\_SQUARE

}

```



Current use:



Only `STAT\_MODIFIER` is currently applied by `SquareCalculator`.



Current Dense effects:



```text

square\_value MULTIPLY 1.5

respawn\_time MULTIPLY 1.15

```



Current Quick effects:



```text

respawn\_time MULTIPLY 0.75

square\_value MULTIPLY 0.9

```



Future use:



The structure already anticipates effects like:



\* adjacency buffs;

\* row buffs;

\* column buffs;

\* copy effects;

\* absorb effects;

\* status effects;

\* trigger effects;

\* resource conversion;

\* visual influence.



\---



\### 5.3 `VisualProfile`



Path:



```text

res://scripts/resources/visual\_profile.gd

```



Type:



```gdscript

extends Resource

class\_name VisualProfile

```



Purpose:



`VisualProfile` stores aggregate square visual identity.



The goal is to avoid one unique visual effect per Trait, because the game may eventually have hundreds of Traits and dozens of Traits on one square.



Current fields include:



```gdscript

@export var base\_color: Color

@export var accent\_color: Color



@export\_range(0, 10) var glow\_level: int

@export\_range(0, 10) var edge\_complexity: int

@export\_range(0, 10) var gloss\_level: int

@export\_range(0, 10) var distortion\_level: int



@export var dominant\_tag: String

@export var secondary\_tag: String



@export var pulse\_style: String

@export var particle\_style: String

@export var pattern\_style: String

```



Current visual logic:



`SquareData` rebuilds the `VisualProfile` from the square’s Traits.



The square’s dominant tag is currently used to determine `base\_color`.



`SquareButton` only reads:



```gdscript

normal\_modulate = square\_data.visual\_profile.base\_color

```



This is intentional. The visual button should not directly know that `"speed"` means blue or `"value"` means orange.



Current limitation:



The visual system is still very basic and low polish. It currently only applies a simple color tint through `modulate`.



Future direction:



Add a real visual system using:



\* color;

\* accent color;

\* gloss;

\* edge complexity;

\* border style;

\* pulse;

\* particles;

\* distortion;

\* patterns;

\* rarity influence;

\* dominant/secondary tags.



\---



\## 6. Systems



\---



\### 6.1 `SquareCalculator`



Path:



```text

res://scripts/systems/square\_calculator.gd

```



Type:



```gdscript

extends Node

class\_name SquareCalculator

```



Purpose:



`SquareCalculator` calculates derived square values.



Current calculations:



```gdscript

calculate\_manual\_payout(square\_data: SquareData) -> float

calculate\_respawn\_time(square\_data: SquareData) -> float

```



Current behavior:



\* starts from square base stats;

\* applies self Trait `STAT\_MODIFIER` effects;

\* returns effective payout or respawn time.



Current supported Trait effect target stats:



```text

square\_value

respawn\_time

```



Current copied/absorbed effect handling:



There is partial support for `effectiveness\_multiplier`.



For multiplicative effects, the logic uses interpolation toward neutral value:



```gdscript

effect\_value = lerp(1.0, effect.value, trait.effectiveness\_multiplier)

```



This is important for future absorbed/copy effects.



Example:



If Dense is `1.5x` and copied at `20%` effectiveness:



```text

lerp(1.0, 1.5, 0.2) = 1.1

```



So the absorbed effect becomes `1.1x`, not `0.3x`.



\---



\## 7. Scenes and UI



\---



\### 7.1 `Main.tscn`



Path:



```text

res://scenes/main/Main.tscn

```



Script:



```text

res://scripts/main/main.gd

```



Purpose:



Main UI scene.



Current responsibilities:



\* display Squares;

\* display Vertices;

\* display prestige count;

\* show grid;

\* show selected square details;

\* show upgrade area placeholder;

\* show prestige button;

\* show story text;

\* rebuild grid UI when grid changes.



Current important nodes:



```text

SquaresLabel

VerticesLabel

PrestigeLabel

GridRoot

SelectedSquareTitle

SelectedSquareDetails

PrestigeButton

StoryLabel

```



These nodes are accessed through Godot unique names using `%NodeName`.



Known issue:



The current square detail panel is plain text in a `RichTextLabel`. It works technically, but is not good enough long-term.



Planned UI improvements:



\* better layout;

\* conditional formatting;

\* positive values in green;

\* negative values in red;

\* rarity colors;

\* Trait grouping;

\* stack levels;

\* better stat formatting;

\* visual separation between base values and effective values;

\* clearer explanation of why a value changed;

\* better name display;

\* possibly icons/tags/badges.



\---



\### 7.2 `SquareButton.tscn`



Path:



```text

res://scenes/squares/SquareButton.tscn

```



Script:



```text

res://scripts/squares/square\_button.gd

```



Purpose:



Visual clickable representation of a square.



Important distinction:



`SquareButton` is not the real square data.



```text

SquareData = actual game state

SquareButton = visual UI representation

```



Current behavior:



\* emits `square\_clicked(square\_id)` when clicked;

\* gets respawn time from `SquareCalculator`;

\* disables itself during respawn;

\* visually fades during respawn;

\* returns after cooldown;

\* uses `VisualProfile.base\_color` for its normal color.



Current respawn behavior:



Manual clicking consumes the square temporarily.



Current visual behavior:



```text

available square = visible square

respawning square = faded, disabled, text changed to "·"

```



Future design:



Manual clicks and passive clicks should behave differently.



Current intended direction:



```text

Manual click = full payout, square must respawn.

Passive click = partial payout, square does not fully despawn.

```



\---



\## 8. Current Gameplay Behavior



Current prototype flow:



1\. Player starts with one square.

2\. Clicking the square grants `1 Square`.

3\. The square enters a 1-second respawn.

4\. At the current development threshold, `10 Squares`, prestige becomes available.

5\. Pressing prestige:



&#x20;  \* grants Vertices;

&#x20;  \* resets Squares to 0;

&#x20;  \* unlocks 2x2 grid on first prestige;

&#x20;  \* assigns one random Trait to one random square;

&#x20;  \* rebuilds grid UI;

&#x20;  \* emits a story message.

6\. Clicking a traited square uses its effective payout and respawn time.



Current Traits:



| Trait |                                    Effect | Tags             |

| ----- | ----------------------------------------: | ---------------- |

| Dense | `square\_value x1.5`, `respawn\_time x1.15` | `value`, `heavy` |

| Quick | `respawn\_time x0.75`, `square\_value x0.9` | `speed`          |



\---



\## 9. Known Design / Technical Issues



These are already noticed and should be addressed later.



\---



\### 9.1 Better UI in General



The current UI is functional but low polish.



Needed improvements:



\* better spacing;

\* better panel styling;

\* improved typography;

\* better color palette;

\* better square visuals;

\* improved prestige screen;

\* clearer progression feedback;

\* better story/unlock presentation.



\---



\### 9.2 Square Details Panel Needs Redesign



Current state:



The square details panel is mostly plain text in a scrolling area.



Problems:



\* too raw/debug-like;

\* poor hierarchy;

\* no conditional formatting;

\* no visual distinction between positive and negative changes;

\* hard to read when Traits grow;

\* not emotionally satisfying.



Desired direction:



\* use conditional formatting;

\* positive values in green;

\* negative values in red;

\* neutral values in grey/white;

\* Trait names with rarity colors;

\* tags as badges;

\* effective values visually compared to base values;

\* show stack levels;

\* show current name/title more prominently;

\* add small visual effects or symbols for weird square states.



Example future display:



```text

Dense Square II



Traits

\[Common] Dense II

&#x20; +42% Squares

&#x20; -12% Respawn Efficiency



Stats

Base Value: 1.00

Effective Value: 1.42  (+42%)

Base Respawn: 1.00s

Effective Respawn: 1.12s  (-12%)

```



\---



\### 9.3 Square Naming Needs Improvement



Current examples can become awkward:



```text

Dense Square of Dense

Quick Square of Quick

Dense Square of Dense of Dense

```



Desired behavior:



Repeated Traits should stack visually and semantically.



Examples:



```text

Dense Square II

Dense Square III

Quick Square of Dense II

Dense Square of Quick II

```



Potential naming rules:



\* If the same Trait appears multiple times, display stack level.

\* Do not duplicate the same Trait name in the generated title.

\* Use strongest or most recent Trait as primary name.

\* Use oldest, rarest, or dominant Trait as suffix.

\* Allow player rename later.

\* Preserve generated subtitle even if player renames square.



Possible model:



```text

display\_name = player-facing custom name or generated name

generated\_title = system-generated title

trait\_title\_components = derived from unique Traits + stack levels

```



\---



\### 9.4 Trait Values Should Roll Within Ranges



Current state:



Traits have fixed effect values.



Example:



```text

Dense always gives:

+50% Squares

+15% respawn time

```



This should change.



Desired behavior:



Traits should roll values when a `TraitInstance` is created.



Example future Dense Common range:



```text

square\_value multiplier: 1.20x to 1.50x

respawn\_time multiplier: 1.05x to 1.15x

```



A low-roll Dense might be:



```text

+22% Squares

+14% respawn time

```



A high-roll Dense might be:



```text

+49% Squares

+6% respawn time

```



This creates more attachment and loot-like interest.



Technical implication:



`EffectComponent` needs min/max or roll settings.



Possible future structure:



```gdscript

@export var value\_min: float

@export var value\_max: float

@export var roll\_precision: float

@export var roll\_key: String

```



Then `TraitInstance.rolled\_values` stores the actual values.



Example:



```gdscript

rolled\_values = {

&#x20;   "square\_value\_multiplier": 1.42,

&#x20;   "respawn\_time\_multiplier": 1.09

}

```



`SquareCalculator` should then use instance rolled values instead of only definition values.



\---



\### 9.5 First Prestige Timing Needs Tuning



Current threshold is development-only:



```text

10 Squares

```



This is intentionally low for testing.



The real game needs careful tuning.



Open question:



> How long should the first prestige take?



Initial design direction:



\* first prestige should happen quickly;

\* player should see the core mechanic within a few minutes;

\* waiting too long before the first Trait is dangerous;

\* the player needs to understand that prestige is the main rhythm, not a distant endgame system.



Potential target:



```text

First prestige: 2–5 minutes

```



This needs playtesting.



\---



\### 9.6 Engagement Across the First Four Traits



The first 2x2 grid requires all 4 squares to receive at least one Trait before the next grid upgrade.



Current progression risk:



If the player needs multiple prestiges to fill all 4 squares, the game must stay engaging across those first few prestiges.



Design questions:



\* How long should it take to get all 4 first traited squares?

\* Should duplicate hits on already-traited squares be possible immediately?

\* Should empty squares have higher selection weight?

\* Should the player get some agency before 3x3?

\* Should the first 4 Traits be guaranteed to hit empty squares?

\* Should duplicate Traits be allowed before all first 4 squares are traited?



Current design says randomness is important, but early frustration could hurt onboarding.



Possible future approaches:



1\. \*\*Pure random\*\*



&#x20;  \* More chaotic.

&#x20;  \* Can create early lucky/sad stories.

&#x20;  \* Risk of frustration.



2\. \*\*Weighted toward empty squares\*\*



&#x20;  \* Still random.

&#x20;  \* Less frustrating.

&#x20;  \* Good compromise.



3\. \*\*Guaranteed fill before duplicates\*\*



&#x20;  \* Best onboarding.

&#x20;  \* Less chaotic.

&#x20;  \* Might reduce the “weird board” feeling early.



Current likely best direction:



> For the first 2x2 tier, heavily weight untraited squares, or guarantee that the first 4 Trait applications hit different squares. Later tiers can become more random.



This needs design testing.



\---



\## 10. Current Technical Design Principles



Current principles to preserve:



\### 10.1 Separate Data from View



Do not put game logic inside the UI button.



Correct:



```text

SquareData handles square state.

SquareButton displays and forwards input.

SquareCalculator calculates derived values.

GameState coordinates global actions.

```



\### 10.2 Traits Should Be Resource-Based



Traits should live as `.tres` resources.



Do not hardcode Traits in `TraitDatabase`.



Correct:



```text

res://data/traits/common/dense.tres

res://data/traits/common/quick.tres

```



\### 10.3 Trait Instances Should Store Runtime Rolls



Trait definitions describe possible behavior.



Trait instances should eventually store actual rolled behavior.



This is needed for loot-like variability.



\### 10.4 Visuals Should Be Derived from Data



Square visuals should not be hardcoded directly in `SquareButton`.



Correct direction:



```text

Traits/tags/history → VisualProfile → SquareButton render

```



\### 10.5 Keep Warnings as Errors



Warnings are currently treated as errors.



This should stay enabled if possible.



It forces explicit typing and prevents sloppy Variant-heavy code.



Common fix:



```gdscript

var target\_square\_id: String = square\_ids.pick\_random() as String

```



instead of:



```gdscript

var target\_square\_id := square\_ids.pick\_random()

```



\---



\## 11. Changelog



\---



\### 2026-06-07 — Initial Godot Prototype Foundation



Added:



\* Created Godot 4.6 project.

\* Configured scalable UI viewport behavior.

\* Created main scene with:



&#x20; \* top resource bar;

&#x20; \* central grid panel;

&#x20; \* side details panel;

&#x20; \* story label;

&#x20; \* prestige button.

\* Created `SquareButton` scene.

\* Added real manual click respawn behavior.

\* Added `Squares` currency.

\* Added `Vertices` prestige currency.

\* Added first prestige logic.

\* Added 2x2 grid unlock on first prestige.

\* Added `EventBus` autoload.

\* Added `GameState` autoload.

\* Added `TraitDatabase` autoload.

\* Added `SquareData` runtime model.

\* Added `TraitInstance` runtime model.

\* Added `TraitDefinition` resource model.

\* Added `EffectComponent` resource model.

\* Added `VisualProfile` resource model.

\* Added `SquareCalculator`.

\* Added resource-based Traits:



&#x20; \* `Dense`

&#x20; \* `Quick`

\* Added recursive Trait loading from `res://data/traits/`.

\* Added random Trait assignment on prestige.

\* Added Trait effects to:



&#x20; \* manual square payout;

&#x20; \* respawn time.

\* Added basic square color changes through `VisualProfile.base\_color`.

\* Added side-panel display of selected square information.

\* Fixed autoload/global class conflict by removing `class\_name` from singleton autoload scripts.

\* Kept warnings-as-errors and fixed Variant inference issues through explicit casting.



Current playable loop:



```text

Click square → earn Squares → wait for respawn → prestige → unlock 2x2 grid → random square gains random Trait → traited square behaves differently.

```



\---



\## 12. Next Recommended Milestones



\### Milestone 3 — Rolled Trait Values



Implement min/max ranges for Trait effects.



Goal:



```text

Dense Common can roll between low and high values instead of always being fixed.

```



Technical work:



\* add roll fields to `EffectComponent`;

\* generate rolled values in `TraitInstance`;

\* store rolled values in `TraitInstance.rolled\_values`;

\* update `SquareCalculator` to use rolled values.



\---



\### Milestone 4 — Better Square Detail UI



Replace the raw text details with a clearer formatted layout.



Goal:



\* show effective stats;

\* show base vs modified values;

\* show positives/negatives with colors;

\* show Trait stacks;

\* show rarity;

\* show tags;

\* improve readability and polish.



\---



\### Milestone 5 — First 2x2 Progression Tuning



Decide how the first 4 Traits should be distributed.



Design questions:



\* pure random or weighted random?

\* guaranteed first fill?

\* time target for first prestige?

\* time target for completing first 2x2 grid?

\* when should the player see the next grid upgrade?



\---



\### Milestone 6 — Basic Run Upgrades



Add temporary run upgrades bought with Squares.



Possible first upgrades:



\* increase square value;

\* reduce respawn time;

\* unlock passive clicker;

\* improve passive clicker;

\* unlock prestige.



These should reset on prestige.



\---



\### Milestone 7 — Save/Load



Add proper save/load to preserve:



\* currencies;

\* grid state;

\* square data;

\* Trait instances;

\* rolled Trait values;

\* prestige count;

\* unlocked upgrades;

\* story flags.



Use `user://` for player save data.



\---



\## 13. Current State Summary



The prototype now has a valid technical foundation.



The most important design promise is already represented in code:



> Prestiging permanently changes the board.



The current version is still very low polish, but the architecture is pointing in the right direction:



```text

Resource-based Traits

Runtime Trait instances

Persistent SquareData

VisualProfile-based rendering

Centralized calculations

Autoload-driven game state

```



Next work should focus on making Traits feel more like loot:



```text

rolled values, stack display, better UI, better square naming, and tuned early prestige pacing.

```



