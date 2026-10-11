"""Builds data/maps/mvp_map.json from the original Fortress Survival 6.76 map (fixed plot layout).

The original's 32-unit pathing grid (plus rasterized destructible blockers) is downsampled to our
128-unit build cells over the playable area. Districts become plots, the 5 main spawns become ours.

Run: python3 tools/maps/convert_original.py <work_dir>
  work_dir: holds ex676/ (extracted map files) and slk/DestructableData.slk, as produced by the
  extraction in reference/fortress-survival-6.76/tools.
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..', '..')
REF = os.path.join(ROOT, 'reference', 'fortress-survival-6.76')
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(REF, 'tools'))
sys.path.insert(0, os.path.join(REF, 'tools', 'map'))
import maplib
import terrain
import doo
import slk
from w3u import parse_obj

WORK = sys.argv[1]
layout = json.load(open(os.path.join(REF, 'map', 'layout.json')))
MINX, MINY = layout['map']['world_min']
PX, CELL = 32, 128
# playable (camera) bounds in cells
pb = layout['map']['playable_camera_bounds']
CX0, CX1 = (pb['min'][0] - MINX) // CELL, (pb['max'][0] - MINX) // CELL
CY0, CY1 = (pb['min'][1] - MINY) // CELL, (pb['max'][1] - MINY) // CELL
WIDTH, HEIGHT = CX1 - CX0, CY1 - CY0

W, H, flags = terrain.wpm(os.path.join(WORK, 'ex676', 'war3map.wpm'))
walk = [0 if f & 0x02 else 1 for f in flags]
deep = [1 if (f & 0x02) and not (f & 0x40) else 0 for f in flags]
tree = [0] * (W * H)

# destructibles (pathing blockers, tree walls) are not baked into the wpm
ddata = slk.load(os.path.join(WORK, 'slk', 'DestructableData.slk'))
_, bobjs = parse_obj(os.path.join(WORK, 'ex676', 'war3map.w3b'))
custom = {x['id']: x for x in bobjs}
for tid, x, y, _f in doo.doo(os.path.join(WORK, 'ex676', 'war3map.doo'))[2]:
    c = custom.get(tid)
    base = c['base'] if c else tid
    tex = c['mods']['bptx'] if c and 'bptx' in c['mods'] else ddata.get(base, {}).get('pathTex')
    if not isinstance(tex, str):
        continue
    m = re.search(r'(\d+)x(\d+)(\w+)\.tga', tex)
    if not m or 'Unbuildable' in m.group(3):
        continue
    n = int(m.group(1))
    is_tree = ddata.get(base, {}).get('category') == 'D'
    cx, cy = int((x - MINX) // PX), int((y - MINY) // PX)
    for dy in range(-n // 2, n - n // 2):
        for dx in range(-n // 2, n - n // 2):
            px, py = cx + dx, cy + dy
            if 0 <= px < W and 0 <= py < H:
                walk[py * W + px] = 0
                if is_tree:
                    tree[py * W + px] = 1


def cell_symbol(cx, cy):
    pix = [(cy * 4 + j) * W + cx * 4 + i for j in range(4) for i in range(4)]
    if sum(walk[p] for p in pix) >= 8:
        return '.'
    if sum(deep[p] for p in pix) >= 8:
        return '~'
    if sum(tree[p] for p in pix) >= 4:
        return 'T'
    return '#'


rows = []
for r in range(HEIGHT):  # row 0 = north
    cy = CY1 - 1 - r
    rows.append(''.join(cell_symbol(cx, cy) for cx in range(CX0, CX1)))


def to_rect(world):
    x0, y0, x1, y1 = world
    cx0 = round((x0 - MINX) / CELL) - CX0
    cx1 = round((x1 - MINX) / CELL) - CX0
    r0 = CY1 - round((y1 - MINY) / CELL)
    r1 = CY1 - round((y0 - MINY) / CELL)
    cx0, cx1 = max(cx0, 0), min(cx1, WIDTH)
    r0, r1 = max(r0, 0), min(r1, HEIGHT)
    return [cx0, r0, cx1 - cx0, r1 - r0]


def to_cell(wx, wy):
    return [int((wx - MINX) // CELL) - CX0, CY1 - 1 - int((wy - MINY) // CELL)]


def slug(name):
    return re.sub(r'[^a-z0-9]+', '_', name.lower()).strip('_')


spawns = [{'id': label, 'rect': to_rect(layout['spawns'][var]['rect'])}
          for var, label in (('TW', 'centre'), ('XY', 'north'), ('EY', 'east'), ('OY', 'south'), ('RY', 'west'))]
plots = []
for d in sorted(layout['districts'], key=lambda d: d['name']):
    plots.append({'id': slug(d['name']), 'name': d['name'], 'rects': [to_rect(r['rect']) for r in d['rects']],
                  'notes': 'Original district; name is a placeholder until our lore exists.'})

m = {
    'format': 1,
    'id': 'mvp_map',
    'name': 'MVP Map (original layout)',
    'size': [WIDTH, HEIGHT],
    'legend': {'.': 'ground', '#': 'blocked', '~': 'water', 'T': 'tree'},
    'source': 'Fortress Survival Alpha 6.76P playable area, 1 cell = 128 WC3 units',
    'start': to_cell(*layout['players']['start_location']),
    'spawns': spawns,
    'plots': plots,
    'rows': rows,
}
maplib.annotate(m)
maplib.save(m, os.path.join(ROOT, 'data', 'maps', 'mvp_map.json'))
maplib.write_png(m, os.path.join(ROOT, 'docs', 'maps', 'mvp_map.png'), scale=5)
open(os.path.join(ROOT, 'docs', 'maps', 'mvp_map.md'), 'w').write(maplib.summary_md(m))
print(maplib.summary_md(m))
