# Fortress Survival 6.76 — map layout (reference)

Extracted from `Fortress Survival Alpha 6.76P.w3x` (Maddawg101 & Nevo). **Inspiration only, not a
blueprint.** Coordinates are in WC3 world units: 1 build cell = 128 units, 1 pathing pixel = 32.

## Files
| File | What |
|---|---|
| `layout.png` | Top-down render with pathing, trees/doodads, districts, spawns, script regions and pre-placed allies (legend included) |
| `layout.json` | Map bounds, start location, 19 spawn locations with unit types, 39 claimable districts with their garrisons, all 151 script regions with role guesses, all pre-placed units |
| `minimap.png` | The map's own minimap (`war3mapMap.blp`), upscaled to 512 px |
| `preview.png` | The map's loading-screen preview (`war3mapPreview.tga`) |

## The layout
- **Size:** 160×160 cells (20,480 units per side). The playable camera area is about 142×144
  cells, from (−9088, −9728) to (9088, 8832).
- **City grid:** The tileset is Dalaran Ruins/cityscape. Wide avenues form a **plus (+)** that
  meets at a plaza in the map centre. A grid of smaller streets divides the rest into roughly
  40 city blocks, separated by impassable walls and cliffs (dark on the render). The edges are
  rougher: grass and woods, water in the south-east and south-west, and lakes inside a few
  blocks.
- **Start:** all 12 player slots start at the **centre** (0, −384).
  - Slots 0–9 are probably the humans (a guess).
  - Slot 10 is an allied computer that owns the garrisons.
  - Slot 11 is the enemy.
- **Bases = claimable districts:** 39 named blocks, such as "The Courtyard", "Dominion Bank",
  "Military Garrison" and "Main Library".
  - The `-claim` chat command claims the block your builder stands in. You then take
    ownership of the pre-placed allied units and structures inside: marines, snipers, medics,
    weak barricades, repair mechanics, turrets, item vendors and so on.
  - `-unclaim` releases a block, and `-claimcount` shows your claim limit.
  - Districts range from about 70 to 620 cells. Their contents are in `layout.json →
    districts`.
- **Building rule:** every player building's only placement restriction is "unwalkable".
  Roads and the WC3-"unbuildable" city tiles are therefore buildable too. Players wall off
  street entrances to close a block.
- **Enemy spawns:** 5 main points, all on the + avenues.
  - `TW`: the **centre plaza** (also the start location!). It has the most varied spawns:
    107 types appear in the script.
  - `XY` north, `EY` east, `OY` south, `RY` west: the ends of the avenues at the map edge,
    each with about 27 types.
  - Event/boss spawns use small rects in and around the centre (`DZ`, `WW`, `VY`, `UW`,
    `WY`), plus locations computed from other units' positions.
- **Enemy movement:** each spawned group gets an attack-move order to the position of a
  **random non-hostile unit anywhere on the map**. The order is re-issued when they re-enter
  spawn or route rects. So enemies roam the avenues and hit whichever base they reach, which
  fits the forum report that the "Trojan gets stuck in the middle".
- **NPC/quest zones** (purple): Brewery (`JW`), "Offer" (`P2`), pirates (`TZ`), "I need your
  help" (`R2`), "Protect this Garrison" (`U1`). Entering one opens a dialog.
- **Allied/guard zones** (cyan/yellow): rects that trigger allied paratroopers or aggro
  orders. These roles are guesses.

## Caveats
- `spawns[].by_type` counts **unit-creation calls in the script**, not real totals per game.
  Timers and loops repeat them, and difficulty scales them.
- The script is obfuscated, so region variable names are meaningless. Roles come from how
  each rect is used. Anything marked "guess" is unverified.
- Pre-placed units come from the script, because the map's `war3mapUnits.doo` was stripped
  by its protection.

## How the files were made
1. A custom MPQ reader opened the protected archive. Its files are encrypted and their
   checksums were deliberately broken.
2. Parsed files:
   - `war3map.w3e`: the terrain heightmap and cliff layers
   - `war3map.wpm`: pathing flags
   - `war3map.doo`: 9,551 doodads
   - `war3map.j`: the script — 151 `Rect(...)` regions, district registration
     (`R6X/R7X`), `CreateNUnitsAtLoc(..., Player(11), ...)` spawns, enter-rect triggers and
     `CreateUnit(p, ...)` pre-placement
3. Rendered with Pillow. Scripts: `../tools/map/` (terrain, doodads, regions, render, layoutjson).
