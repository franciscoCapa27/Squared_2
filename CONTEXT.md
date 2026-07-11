# Squared²

Domain language for Squared², a fast-prestige incremental Godot game about a single square becoming a personal geometric universe.

## Language

**First 2x2 Grid Era**:
The next development slice for the game: a fresh save through the first several prestiges, first permanent Traits, first automation unlocks, and the first expansion to a 2x2 grid. This slice should make roughly the first 20 minutes feel coherent and replayable.
_Avoid_: Early game, first chapter, tutorial, content pass

**First Square Era**:
The opening 1x1 portion of a fresh save, where the player prestiges a small number of times on the original square, sees a few common Trait Families if lucky, and is then strongly encouraged to expand to 2x2. This era should make prestige understandable, but should not be the main long-term decision space.
_Avoid_: Tutorial, starter phase, single-square game

**Prestige Tension**:
The early-game question of whether to prestige now for one more Trait roll or keep pushing the current run toward a larger goal, especially grid expansion that may unlock rarer and cooler Traits. This tension should make "one more prestige" and "save for expansion" both feel tempting.
_Avoid_: Reset loop, optimal timing, progression choice

**Reactive Luck**:
The early Trait experience where random rolls shape the player's first board and the player mostly adapts to what appears. Decisions exist, but they should be light steering rather than direct build drafting during the First 2x2 Grid Era.
_Avoid_: Trait drafting, build planning, deterministic progression

**Fix Before Content**:
The development rule that content should be added only after the supporting systems behave correctly. For the First 2x2 Grid Era, trait rolling, unlock requirements, and tuning hooks should be fixed before adding larger trait, upgrade, generator, or achievement packs.
_Avoid_: Content dump, balance pass first, data-only expansion

**Trait Family**:
A memorable category of related Traits, such as Quick or Dense, that can appear across multiple rarities. Rarity changes the strength, strangeness, or expression of the family; it does not usually create a separate family.
_Avoid_: Modifier type, rarity bucket, stat variant

**Rare Family**:
A Trait Family that is itself unlocked later than the early families, such as after the 3x3 grid era. Rare Families are distinct from rare variants of common families.
_Avoid_: Rare Trait, uncommon variant, family rarity

**Trait Luck**:
A permanent or run-based stat that shifts Trait roll weight toward higher unlocked rarity buckets. Trait Luck does not unlock future rarities early and is distinct from a Trait Family's base `weight`.
_Avoid_: Family luck, trait value boost, future-rarity unlock

**Trait Pool Expansion**:
A grid-tier milestone where future prestige rolls can include stronger rarity variants and, when appropriate, additional Trait Families. The 2x2 expansion should clearly communicate that uncommon variants and more family variety can now appear.
_Avoid_: Trait shop, trait choice, rarity upgrade

**Enticing Mystery**:
The unlock communication style where the game makes it obvious that something exciting can happen next, while keeping exact outcomes partially hidden. Buttons and unlock text should create anticipation for future gambles rather than expose the full reward table.
_Avoid_: Full odds display, hidden unlock, dry feature text

**Soft Push**:
A progression pressure that makes the next milestone feel clearly desirable without forbidding alternate play. The First Square Era should strongly encourage expanding to 2x2 after a few prestiges, but should not hard-stop continued 1x1 trait stacking.
_Avoid_: Hard gate, forced tutorial, optimal-only path

**Condensation**:
A future second-layer prestige idea where the player collapses a developed grid back into one special square, starting over with no ordinary resources but preserving some fraction or expression of the grid's accumulated Traits. This is not part of the First 2x2 Grid Era, but it explains why long-term one-square stacking can eventually become valid.
_Avoid_: Second prestige, ascension, reset

**Condensation Foreshadowing**:
Light story-message atmosphere hinting that a grid might someday fold back into one square. During the First 2x2 Grid Era, this should have no mechanical hooks and should not promise timing; the actual system belongs hours later, if the game needs it.
_Avoid_: Condensation tutorial, second-layer unlock, mechanical preview

**Active-First Automation**:
The early balance where manual clicking remains the fastest and clearest way to progress, while passive generators provide relief, curiosity, and a feeling that the board is waking up. During the First 2x2 Grid Era, automation should support the prestige loop without replacing active play.
_Avoid_: Idle-first, full automation, passive-only progression

**Post-Expansion Automation**:
The rule that passive generators should not appear during the First Square Era. The first passive generator should become available only after the player reaches 2x2, so automation feels like the board opening up rather than part of the initial one-square lesson.
_Avoid_: Starter automation, pre-expansion passive, free generator

**Vertex Choice**:
The early permanent-upgrade tension between buying raw lasting power and unlocking new functionality or steering. Vertex spending should not be linear; the player should choose whether to accelerate known loops or open new possibilities.
_Avoid_: Upgrade path, mandatory unlock order, permanent multiplier shop

**Order Choice**:
A choice where the player can eventually get every option, but the timing and opportunity cost matter. During the First 2x2 Grid Era, Vertex choices should be Order Choices rather than mutually exclusive commitments.
_Avoid_: Exclusive branch, lockout, class choice

**Pre-Expansion Vertex Lane**:
The Vertex spending space before 2x2, focused on permanent manual power and trait curiosity rather than automation. These upgrades may smooth the First Square Era, but manual clicking should remain the main action until the board expands.
_Avoid_: Passive unlock, idle opener, linear tutorial upgrade

**Square Identity**:
The early-game focus that individual squares become memorable through their own Traits, names, colors, and histories. During the First 2x2 Grid Era, Square Identity should matter more than grid or adjacency synergies.
_Avoid_: Tile stats, board synergy, adjacency build
