# Map data

Handcrafted maps live here, one JSON file per map, loaded by `MapLayout` (`src/sim/map/map_layout.gd`).

| File | What |
|---|---|
| `test_map.json` | Small 64×64 development map: + avenues, centre plaza (start + centre spawn), 4 edge spawns, 6 contrasting plots. Built by `tools/maps/make_test_map.py`. |
| `mvp_map.json` | Full-size 142×145 map: the original Fortress Survival 6.76 layout (39 fixed plots, 5 spawns). Built by `tools/maps/convert_original.py`. |

Previews and per-plot tables: `docs/maps/<id>.png` and `docs/maps/<id>.md`.

## Format (version 1)

```json
{
  "format": 1,
  "id": "test_map",
  "name": "Test Map",
  "size": [64, 64],
  "legend": {".": "ground", "#": "blocked", "~": "water", "T": "tree"},
  "start": [32, 35],
  "spawns": [{"id": "centre", "rect": [30, 30, 4, 4]}],
  "plots": [{"id": "keep", "name": "Keep", "rects": [[38, 4, 16, 14]],
             "expected": {"buildable_cells": 220, "entrance_widths": [4]},
             "info": {"...": "derived stats, informational only"}, "notes": "..."}],
  "rows": ["################", "#..............#"]
}
```

- **Cells** are build-grid cells (`SimConstants.CELL_SIZE` world units each). A cell is `(x, z)`:
  x grows east, z grows south, and `rows[0]` is the north edge.
- **Terrain:**
  - `.` ground: walkable and buildable
  - `#` blocked
  - `~` water: blocks movement and building
  - `T` trees: block movement and building (they may become destructible later)
- **Rects** are `[x, z, width, height]` in cells. A plot is a union of one or more rects.
- **`expected`** on each plot holds the measured buildable cells and entrance widths. The tools
  write it, and `tests/unit/test_map_layout.gd` checks it against `MapAnalysis`. If you change
  terrain, regenerate the map so the expectations update, then review the diff.
- **Entrance** = a group of walkable cells inside the plot that touch walkable ground outside it
  (8-connected). Width = the longest side of the group, in cells.

## Regenerating

```sh
python3 tools/maps/make_test_map.py
python3 tools/maps/convert_original.py <work_dir>   # needs the extracted original map, see the script
```
