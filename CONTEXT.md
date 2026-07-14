# Squared²

Domain language for Squared², a fast Buy Trait incremental Godot game about a single square becoming a personal geometric universe.

## Language

**First Fun Pass**:
The next development slice after the First 2x2 Grid Era baseline, focused on making the existing loop satisfying moment-to-moment before adding more systems or content. It improves click feedback, trait purchase drama, Trait reveal, square readability, unlock anticipation, and basic UI feel without changing the core progression structure.
_Avoid_: UI polish, flavour pass, content pass, juice pass

**First Fun Pass Order**:
The implementation order for the First Fun Pass: build the reusable Square Body first, then add click feedback, then Affix Square Naming and Grouped Square Details, then Buy Trait Reveal Echo, then Family-Rarity-Rank Visuals. The Square Body is the stage for later feedback and identity work.
_Avoid_: Trait visuals before square body, bundled mega-ticket, layout redesign first

**Opening Curiosity**:
The intended first-minute feeling that the player wants to discover what the square is becoming. Early feedback should create small questions and visible transformation rather than immediately centering raw power, optimization, or full system explanation.
_Avoid_: Power fantasy, tutorial clarity, number chasing, solved opener

**Square-First Feedback**:
The First Fun Pass rule that curiosity should come primarily from the square itself: its click reaction, visible state, name, color, Trait marks, and Buy Trait transformation. Story, panels, and shop text should support the square's change rather than carry the whole experience.
_Avoid_: Panel-first feedback, text-only discovery, shop-driven curiosity

**Square Body**:
The player-facing square should become a Godot-native visual body rather than remaining primarily a text button. During the First Fun Pass, the square can become a simple rectangular visual surface that supports material changes, click reactions, trait purchase reactions, glow, outline, and later shader-based effects while still behaving as the clickable game object.
_Avoid_: Text-button square, text inside the clickable body, web-style card tile, non-clickable decoration

**Square Body Boundary**:
The Square Body should own only its clickable object behavior and local visual reactions, such as click compression, material changes, trait marks, glow, and trait purchase pulses. Square titles, details panels, reveal text, shop UI, and story UI should live outside the Square Body so the same object can be reused across 1x1, 2x2, and larger grids.
_Avoid_: Panel logic inside the square, text owned by the clickable body, separate square implementations per grid size

**Quiet Tactile Feedback**:
The click-feedback style for Squared²: small physical square reactions, readable floating gains, and subtle Trait-accent responses. It should make clicking feel alive without screen shake, loud particles, combo noise, or arcade-style spectacle.
_Avoid_: Juicy arcade feedback, explosive particles, screen shake, clicker chaos

**Floating Gain Feedback**:
The First Fun Pass click-feedback element where each manual click can spawn a small readable number near the clicked square, then rise and fade out. It should make gained Squares visible moment-to-moment without adding combo mechanics, noisy particles, or permanent UI clutter.
_Avoid_: Combo popups, unreadable number spam, screen-wide click effects

**Buy Trait Reveal Ritual**:
The short emotional beat after pressing Buy Trait where Squares are spent, the chosen square briefly becomes the focus, the new Trait is revealed by name, and the square visibly changes. It should feel like the square changed, not like a plain purchase confirmation.
_Avoid_: Instant silent reset, modal reward screen, long ceremony, text-only reveal

**Trait Identity First**:
The Buy Trait Reveal Ritual should foreground the Trait Family and rarity before exact mechanics. Rarity is part of the gamble and should be visible in the reveal because it can make a large difference; detailed numbers belong in square details after the emotional reveal lands.
_Avoid_: Numbers-first reward, hidden rarity, spreadsheet reveal

**Family Visual Identity**:
Trait Family owns a square's main visual and naming identity, while rarity owns intensity behind the scenes and in presentation hierarchy. A Quick square should still read as Quick across rarities; Uncommon or later rarities should make that identity feel brighter, sharper, heavier, stranger, or more intense rather than visually unrelated.
_Avoid_: Rarity-as-family, unrelated rarity skins, hidden intensity

**Visual Trait Marks**:
Persistent square-local visual changes earned from Traits, such as color shifts, glow, outline changes, tiny marks, inner weight, or light accents. These marks are part of the gamble: the player should wonder what the next Trait, rarity, or stack rank will make the square look like. Early marks should be restrained, while rarer or higher-rank outcomes can unlock more noticeable effects.
_Avoid_: Purely numerical Traits, full visual randomness, loud effects on every common stack

**Family-Rarity-Rank Visuals**:
The Visual Trait Marks rule where Trait Family chooses the visual language, rarity controls intensity or unlocks a more noticeable effect type, and Roman Trait Stack rank strengthens the mark. A Quick square should keep a Quick visual identity across rarities and ranks, but higher rarity or rank can make that identity brighter, sharper, more animated, or more elaborate.
_Avoid_: Random visual soup, rarity replacing family identity, stack rank with no visible growth

**Authored Early Family Visuals**:
The First Fun Pass scope for Visual Trait Marks: current early Trait Families should receive specific authored visual identities, while future or unknown families use a restrained neutral fallback so they never render blank. The fallback is not a creative substitute for future family design.
_Avoid_: Designing every future family now, blank future traits, generic-only visuals

**Patient Family Identity**:
The intended identity for the Patient Trait Family: stored time, slow accumulation, waiting power, and delayed payoff. Patient should not read as a weaker Dense; its visuals, naming, and eventual mechanics should imply patience becoming valuable rather than raw mass or plain value increase.
_Avoid_: Weaker Dense, generic value boost, passive duplicate

**Quick Family Identity**:
The intended identity for the Quick Trait Family: sharpness, speed, angular motion, and bright responsiveness. Quick should make a square feel more reactive and precise.
_Avoid_: Generic click boost, smooth softness, heavy visuals

**Dense Family Identity**:
The intended identity for the Dense Trait Family: weight, compactness, thick edges, depth, and concentrated value. Dense should make a square feel heavier and more materially substantial.
_Avoid_: Patient-style waiting, speed language, plain bigger number

**Glimmer Family Identity**:
The intended identity for the Glimmer Trait Family: luminous curiosity, small light points, sparkle, and discovery. Glimmer should make a square feel like it is catching or revealing light.
_Avoid_: Generic value shine, loud glitter spam, Dense-style weight

**Material-First Trait Visuals**:
The visual priority for early square identity: Traits should first change the square's apparent material, such as color, outline, glow, fill weight, sharpness, or shimmer, before adding symbolic marks. Small marks can appear at higher rarity or Roman Trait Stack ranks, but the square should feel transformed rather than stickered.
_Avoid_: Sticker-like badges, glyph-first identity, disconnected decorations

**Affix Square Naming**:
The naming model where a square's title hints at its Trait mixture through a readable prefix + base + suffix structure. The title should not list every Trait; it should summarize the square's history while the details panel carries the full Trait stack.
_Avoid_: Dominant-only title, raw Trait concatenation, full Trait list as title

**Rarity-Off Title**:
The Affix Square Naming rule that rarity words should not appear in the square's main title. A title should read like Swift Square of First Light, not Uncommon Swift Square of Common First Light. Rarity belongs in the Buy Trait Reveal Echo and Grouped Square Details.
_Avoid_: Rarity-prefixed title, raw display-name title, title as mechanics summary

**Family-Authored Affixes**:
The first Affix Square Naming rule: Trait Families provide their own possible prefixes and suffixes, such as Quick contributing haste language or Patient contributing long-wait language. Mix-authored names can come later, but early naming should come from family identity and stack weight.
_Avoid_: Random poetic names, system-invented mix titles, rarity-only affixes

**Early Family Affix Pools**:
The First Fun Pass affix vocabulary for current early Trait Families. Quick prefixes are Sharp, Swift, and Keen; Quick suffixes are of Haste, of Motion, and of the First Click. Dense prefixes are Heavy, Deep, and Compact; Dense suffixes are of Weight, of Mass, and of the Core. Glimmer prefixes are Glimmering, Bright, and Luminous; Glimmer suffixes are of First Light, of Sparks, and of Wonder. Patient prefixes are Patient, Slow, and Still; Patient suffixes are of the Long Wait, of Stored Time, and of the Quiet Pulse.
_Avoid_: Inventing affixes during implementation, rarity-only names, raw display names in square titles

**Deterministic Affix Words**:
The Affix Square Naming rule that once the winning prefix and suffix families are chosen, the exact word should be selected deterministically from that family's affix pool using Roman Trait Stack rank. The trait roll is random, but the resulting title should be stable and explainable for the square's history.
_Avoid_: Random title rerolls, unstable names, opaque affix choice

**Stack-First Affix Selection**:
The Affix Square Naming rule where prefix and suffix winners are chosen by family stack count first, highest rarity in that family second, and latest gained third. Prefix should represent the strongest identity family; suffix should represent the strongest different family. The base word can later vary beyond "Square", but the First Fun Pass can keep "Square" as the default base.
_Avoid_: Rarity-dominant naming, latest-only naming, listing every family in the title

**Mixed-Family Suffix**:
The Affix Square Naming rule that a suffix should appear only when the square has a second Trait Family to express. Single-family squares use prefix + base, such as Sharp Square; mixed-family squares use prefix + base + suffix, such as Swift Square of First Light.
_Avoid_: Same-family suffix filler, suffix as decoration, hiding mixed identity

**Evolving Square Title**:
The rule that a square's main title should update immediately when a newly gained Trait changes the square's stack identity. Name changes are part of discovery and should make the player feel the square evolved; details can explain why the new title was chosen.
_Avoid_: Stale titles, locked first trait name, hidden title changes

**Roman Trait Stack**:
The square-details convention where repeated Traits are shown as family names with roman numerals, such as Quick II or Quick VI, instead of raw counts like Quick x2. This should make stacking feel like an identity rank while still remaining factual and readable.
_Avoid_: Spreadsheet counts, raw trait list, hidden stack count

**Grouped Square Details**:
The square-details rule that the full Trait stack should be grouped by Trait Family for scanning, with each family showing its Roman Trait Stack, rarity information, and mechanical summary. The square title can stay poetic and compressed because the details panel carries the factual history.
_Avoid_: Title-as-full-history, chronological-only details, vague flavor-only details

**Buy Trait Reveal Echo**:
The auto-disappearing in-game feedback after a Buy Trait Reveal Ritual that highlights which Trait Family was upgraded, using an ethereal fade-out and a subtle square-local glow. It should show identity and rarity first, such as Uncommon Quick and Quick II, then secondarily show the new Evolving Square Title; detailed mechanical effects stay in Grouped Square Details.
_Avoid_: Modal reward screen, noisy toast spam, text-only confirmation, numbers-first pop-up

**First 2x2 Grid Era**:
The next development slice for the game: a fresh save through the first several trait purchases, first permanent Traits, first automation unlocks, and the first expansion to a 2x2 grid. This slice should make roughly the first 20 minutes feel coherent and replayable.
_Avoid_: Early game, first chapter, tutorial, content pass

**First Square Era**:
The opening 1x1 portion of a fresh save, where the player buys a small number of Traits on the original square, sees a few common Trait Families if lucky, and is then strongly encouraged to expand to 2x2. This era should make Buy Trait understandable, but should not be the main long-term decision space.
_Avoid_: Tutorial, starter phase, single-square game

**Buy Trait Tension**:
The early-game question of whether to Buy Trait now for one more Trait roll or keep pushing the current run toward a larger goal, especially grid expansion that may unlock rarer and cooler Traits. This tension should make "one more Trait" and "save for expansion" both feel tempting.
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
A grid-tier milestone where future trait purchase rolls can include stronger rarity variants and, when appropriate, additional Trait Families. The 2x2 expansion should clearly communicate that uncommon variants and more family variety can now appear.
_Avoid_: Trait shop, trait choice, rarity upgrade

**Enticing Mystery**:
The unlock communication style where the game makes it obvious that something exciting can happen next, while keeping exact outcomes partially hidden. Buttons and unlock text should create anticipation for future gambles rather than expose the full reward table.
_Avoid_: Full odds display, hidden unlock, dry feature text

**Soft Push**:
A progression pressure that makes the next milestone feel clearly desirable without forbidding alternate play. The First Square Era should strongly encourage expanding to 2x2 after a few trait purchases, but should not hard-stop continued 1x1 trait stacking.
_Avoid_: Hard gate, forced tutorial, optimal-only path

**Condensation**:
A future second-layer reset idea where the player collapses a developed grid back into one special square, starting over with no ordinary resources but preserving some fraction or expression of the grid's accumulated Traits. This is not part of the First 2x2 Grid Era, but it explains why long-term one-square stacking can eventually become valid.
_Avoid_: Calling this Buy Trait, ascension, or a generic reset

**Condensation Foreshadowing**:
Light story-message atmosphere hinting that a grid might someday fold back into one square. During the First 2x2 Grid Era, this should have no mechanical hooks and should not promise timing; the actual system belongs hours later, if the game needs it.
_Avoid_: Condensation tutorial, second-layer unlock, mechanical preview

**Active-First Automation**:
The early balance where manual clicking remains the fastest and clearest way to progress, while passive generators provide relief, curiosity, and a feeling that the board is waking up. During the First 2x2 Grid Era, automation should support the trait purchase loop without replacing active play.
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
