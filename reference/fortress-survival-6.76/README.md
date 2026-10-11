# Fortress Survival (WC3) — reference & learnings

**Inspiration, not replication.** This folder documents the original Warcraft III custom map
*Fortress Survival Alpha 6.76P*, by Maddawg101 & Nevo for WC3 1.27a. We use it to understand
what made the game work. We don't copy its numbers, names or content. Our design decisions live
in [/ROADMAP.md](../../ROADMAP.md).

## Contents

| Path | What |
|---|---|
| `README.md` | Learnings and takeaways (this file) |
| `units-buildings-overview.md` | Readable tables: builder, walls, towers, statues, economy, repair, mercenaries, heroes, enemies |
| `data/units_buildings.{json,csv}` | **Every** unit and building object (1142), with all fields merged with WC3 defaults, plus a `category` column |
| `data/abilities.json` | Every ability (1233) with general fields and a `per_level` array |
| `data/abilities.csv` | Same, one row per ability level (wide) |
| `data/abilities_long.csv` | Same, one row per ability / level / field (long, easy to filter) |
| `data/auras.{json,csv}` | Aura abilities per unit or building, including auras the **script** adds (statues) |
| `data/buffs_effects.{json,csv}` | Buffs and effects (217) |
| `data/upgrades_research.json`, `upgrades_research_long.csv` | Command Center research (95) |
| `map/` | Map layout: `layout.png` render, `layout.json` (districts, spawns, regions), minimap, preview, README |
| `tools/` | The Python extractors that produced all of this |

**Data notes**
- Units are in WC3 units: 1 build cell = 128, a footman's speed is about 270, and melee range
  is about 100.
- Costs are mostly **lumber**. Gold is a rare second currency.
- `category` is a heuristic:
  - `builder`: the Survivor plus about 280 cosmetic skins
  - `building`
  - `hero`: the Command Center hero picks
  - `enemy`: spawned for the hostile player in the script
  - `mercenary`
  - `trainable_unit`
  - `dummy`: script helper units
  - `other`: alt-tab building variants, summons, quest NPCs
- Enemy HP and damage are **base** values. Difficulty multiplies them while the game runs (see
  below).
- Many effects are scripted, not in object data. Tower specials, statue auras and the Gravity
  homing behaviour come from triggers. `script_added_ability_ids` captures auras and abilities
  that triggers add on construct/upgrade. Other trigger logic isn't extracted.

## How the original game works

### Core loop
- You are a **Survivor**, a weak builder unit with a repair ability and a spellbook. The base
  is what has to survive. A **Base Command** NPC narrates, and in the finale "blows up the
  Fortress".
- Enemies come from the hostile player (Player 12) in timed waves. The map script names many
  unique enemy families, and **bosses** drop in on a schedule:
  - Vice line: Vice → Alpha → Malevolent
  - Skrassh
  - Baby Trojan
  - **The Trojan**, the final boss with 155k base HP
- **Boss mode** is chosen at the start: Normal / Double / Triple / Quadruple bosses.
- **Difficulty** is chosen at the start and multiplies creep HP and damage:

| Mode | Creep HP | Creep damage |
|---|---|---|
| Easy | 75% | −25% |
| Normal | 100% | +25% |
| Mad | 200% | +50% |
| Impossible | 400% | +75% |
| Nightmare | 600% | +125% |

- After a win there are **Endless waves**, and permanent save-code achievements (e.g. "Trojan's
  Roar").
- **Side events** keep the middle of the game interesting: "protect Mr Saunders and the Vault for
  10 minutes", "protect the Pirates", "protect Cidiaus the Wizard", "Military Garrison". There are
  also global events such as a drought that cuts hero mana regen for 5 minutes.

### Map (see `map/`)
- **The map is a ruined city**, 160×160 cells, on the Dalaran Ruins tileset.
  - Wide avenues form a **plus (+)** meeting at a central plaza.
  - A street grid splits the rest into about 40 walled **city blocks**.
- **Everyone starts in the centre plaza.** The centre is also the busiest enemy spawn. The other
  4 main spawns are at the ends of the avenues (N/E/S/W map edges). So the opening is a scramble
  to get out of the middle and pick a home.
- **Bases are claimable districts.** There are 39 named blocks ("Dominion Bank", "Military
  Garrison", "Main Library" and so on). `-claim` takes the block you stand in, together with the
  pre-placed allied units and structures there. Districts differ in size (about 70–620 cells),
  entrances, starting garrison and terrain such as lakes. **Choosing a base is the first
  strategic decision.**
- Buildings can go on any walkable tile, roads included. You fortify a block by **walling its
  street entrances**.
- **Enemies roam.** Each wave attack-moves toward a random non-hostile unit on the map. That
  spreads pressure across everyone's bases, and it's also why units got stuck.
- Quest NPC zones (Brewery, Pirates, Garrison and others) trigger the "protect X for N minutes"
  side events.
- **The plots are fixed**: hand-placed, with set sizes, entrances and garrisons. From
  `map/plots.md`:
  - **39 plots.**
  - **Buildable area:** 51–457 cells, median 90. Most are small; a few big ones (Storage Room,
    Summer Cottage Garden, Courtyard, Main Library) are the prizes.
  - **Entrances:** most plots (30) have **1 entrance**, 7 have 2 and 2 have 3. Entrances are
    usually **2–4 cells wide**; a few are wide, open edges (Fort Harbor 15, Bear Cave 9,
    Woodlands 9.5).
  - **Walking distance to the nearest spawn:** 15–85 cells, median about 40. Nearest spawns are
    spread out: centre 10 plots, N 9, S 7, W 7, E 6.
  - **Garrisons:** 26 plots come with a pre-placed garrison (defenders, a Command Center,
    vendors, repair mechanics). Bigger and richer plots tend to have more entrances, more
    water, or sit closer to a spawn.
  - So the typical plot is "small room, one door". The real trade-offs are which door (how wide,
    how close to a spawn) and whether to take a big plot with more openings.

### Economy
- **Lumber is the main currency** and comes almost entirely from **Lumber Mills**:

| Building | Lumber per second |
|---|---|
| Lumber Mill Lvl 1 | 0.025 |
| Lumber Mill Lvl 2 | 0.05 |
| Lumber Mill Lvl 3 | 0.1 |
| Lumber Mill Lvl 4 | 0.25 |

- A mill can then become a **Gold Mine** (0.033 → 0.066 gold/s, max 1 per player). Gold is a
  scarce premium currency for top-tier upgrades.
- Low levels are **free or nearly free** (a Barricade costs 0). Costs rise steeply at the top: a
  Devil's Barricade or Nature's Spirit costs 2000 lumber.
- A refund rate of 100% (construction and upgrade) means rebuilding and repositioning carry no
  penalty.
- **Bookshelves** (max 8) slowly produce "books". Trading 200 / 400 / 800 books unlocks techtree
  manuals (Defensive/Offensive Holy Blessing, Mechanical Robotics, God's Knowledge). This is a
  second, slow progression track.

### Building roster: a few roots, very deep upgrade chains
Everything starts from **one cheap root building** and grows by upgrading in place:

| Root | Branches × levels | Role |
|---|---|---|
| Barricade | 1 × 20 | Pure HP wall, 75 HP → 200k HP. Gets thorns ("Spiked") and electric defense late. |
| Energy Wall | 1 × 13 | Regenerating wall, 450 HP / 40 regen → 80k HP / 3000 regen |
| Basic Tower | **10 × 6** | Arrow (multishot), Rock Impaler (bash/crit), Tesla Coil (shock), Slow Freezer (frost slow), Flamer (high damage), Peasant Launcher (huge splash, 50% vs bosses), Gravity (long-range homing), Assassin (crit, +130% vs bosses), Burner (mana burn), Minigun (anti-air) |
| Aura Statue | 3 × 4 | Damage aura (+20% → +50% tower damage), armor aura (+3 → +18 building armor), Sentry (detection) |
| Lumber Mill | 1 × 6 | Income; the last 2 levels turn it into a Gold Mine |
| Repair Mechanic | 1 × 8 | Stationary auto-repair, 33% → 110% efficiency |
| Repair Factory | 1 + advanced | Trains repair bots, 5 tiers |
| Mercenary HQ | 4 tabs | Marines (rank-up promotions Private → Staff Sergeant), Melee, Range (Sniper, Abrams Tank), Support (Medic, Scout, Mine Layer, Alchemist) |
| Command Center | 5 tabs | Research (tower / wall / unit / team upgrades) and **pick 1 of ~135 heroes** |
| Item Vendor, Bookshelf | – | Items, book economy |

- Towers all share one footprint and one root, so a **build decision is cheap and the
  specialization decision is deferred**. You place a Basic Tower and decide what it becomes later.
- **Bosses vs mobs.** Several towers are explicitly tuned against one target type, e.g. the
  splash tower does 50% to bosses and the crit tower does 60% to mobs but 130% to bosses (Hero
  armor). Hero armor on bosses forces a mixed defense.
- **Statues are force multipliers.** Aura range is 750 (about 6 cells), so how you cluster towers
  around statues matters.
- Every structure has a "Stats Checker" ability and self-regen (Solar Batteries / 1Regen,
  researchable).

### Combat model (WC3 constants in this map)
- Damage types against armor types matter: pierce, siege, chaos, magic and hero attack types.
  Bosses carry hero armor; buildings carry fortified or large armor.
- Heroes get **+18 HP per STR**. Max hero level is 99. XP is global.

## Learnings for our game

What to **keep in spirit**:
1. **Shallow roots, deep trees.** A few cheap root buildings with many in-place upgrades and
   branching specializations. This gives variety without a huge build menu, and fits our
   "building variety is key" pillar. *For us: fewer levels (3–5) but more meaningful branches,
   each with a visual change.*
2. **Walls as a progression track.** HP walls vs regenerating walls is a simple and strong
   choice. Add a reason to mix them (e.g. regen walls are weak to burst, HP walls to attrition).
3. **Repair is a core mechanic**: static repair buildings, mobile repair bots and the builder's
   own repair. Combined with free rebuilding, defense is about *sustaining* the walls, not only
   killing.
4. **Aura statues** create spatial puzzles in base layout. Keep them.
5. **Mobs vs bosses counterplay**: towers that are good against swarms but bad against bosses,
   and the reverse.
6. **Run modifiers**: difficulty, boss multiplier, endless mode, plus side events mid-game.
   These are cheap replayability.
7. **Named enemy families with tiers** (base → alpha → greater) and scheduled bosses with
   personality.
8. **Pick-your-base maps.** A handcrafted map of distinct, **fixed** plots (size, entrances,
   terrain, starting garrison) makes base choice a real decision. **We replicate this plot
   design** (see `map/plots.md`).
   Fortifying chokepoints, like the original's street entrances, is the core spatial skill.
9. **Spawns from several directions, including the middle**, so no base is fully safe.

What to **change or avoid**:
1. **Numbers inflation** (75 HP → 200k HP walls, 155k HP boss). It's hard to read and balance.
   Use smaller numbers and multipliers.
2. **Too many levels of the same thing** (20 barricade levels). Merge them into fewer,
   distinct steps.
3. **135 heroes and 280 builder skins** is content bloat from community history. Start with a
   handful.
4. **Trigger-driven hidden mechanics** (scripted auras, homing, special damage) were opaque to
   players. Our data must state every effect explicitly, and the tests must check it.
5. **Pathing and performance problems** in the original: monsters stuck at spawns, lag late in
   the match. These are core quality requirements for us (see AGENTS.md).
6. **Sci-fi vs medieval.** The original mixes sci-fi (marines, tesla, minigun, Abrams) with
   fantasy. Our setting is a fantasy medieval castle, so roles translate rather than names. For
   example:
   - Minigun becomes a ballista battery (anti-air).
   - Tesla Coil becomes an arcane lightning spire.
   - Gravity becomes a homing arcane orb.
   - Peasant Launcher becomes a trebuchet.

## Provenance
- Source map: `Fortress Survival Alpha 6.76P.w3x`, a protected map. Its file index is encrypted
  and the checksums are deliberately broken, so the tools here work around that.
- Defaults: WC3 TFT custom-game SLKs and profile files from
  [WarRaft/War3.mpq](https://github.com/WarRaft/War3.mpq) (`extract/Custom_V1`, `extract/Units`).
- To regenerate: see `tools/`.
  - `mpqread.py` unpacks the map.
  - `w3u.py` parses the object files.
  - `script_abils.py` finds auras and abilities that triggers add.
  - `export.py` writes `data/`.
  - `gen.py` writes the overview tables.
  - The scripts expect the extracted files and the SLKs in a working directory; paths are
    relative to the script's parent folder.
