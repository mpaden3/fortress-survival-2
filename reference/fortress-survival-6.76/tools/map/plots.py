"""Analyse the original map's base plots (districts): size, buildable area, entrances, spawn distance, terrain.

Usage: python -I plots.py <work_dir> <out_dir>
work_dir must contain ex676/ (extracted map files), slk/DestructableData.slk, and
<out_dir>/layout.json (from layoutjson.py).
"""
import json, os, re, sys, struct
from collections import deque
sys.path.insert(0, os.path.dirname(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
import terrain, doo, slk
from w3u import parse_obj

WORK, OUT = sys.argv[1], sys.argv[2]
layout = json.load(open(f'{OUT}/layout.json'))
MINX, MINY = layout['map']['world_min']
PX = 32  # pathing pixel size in world units
CELL = 128

W, H, flags = terrain.wpm(f'{WORK}/ex676/war3map.wpm')
walk = bytearray(W * H)
water = bytearray(W * H)
for i, f in enumerate(flags):
    walk[i] = 0 if f & 0x02 else 1
    water[i] = 0 if f & 0x40 else 1

# destructibles are not baked into the wpm: rasterize the ones that block pathing
ddata = slk.load(f'{WORK}/slk/DestructableData.slk')
_, bobjs = parse_obj(f'{WORK}/ex676/war3map.w3b')
custom = {x['id']: x for x in bobjs}
def path_tex(tid):
    x = custom.get(tid)
    if x and 'bptx' in x['mods']: return x['mods']['bptx']
    base = x['base'] if x else tid
    return ddata.get(base, {}).get('pathTex') if base in ddata else None
def is_tree(tid):
    x = custom.get(tid); base = x['base'] if x else tid
    return ddata.get(base, {}).get('category') == 'D'
_, _, items = doo.doo(f'{WORK}/ex676/war3map.doo')
tree_px = bytearray(W * H)
blocked_by_destructible = 0
for tid, x, y, _f in items:
    tex = path_tex(tid)
    if not tex or not isinstance(tex, str): continue
    m = re.search(r'(\d+)x(\d+)(\w+)\.tga', tex)
    if not m or 'Unbuildable' in m.group(3): continue
    n = int(m.group(1))
    cx, cy = int((x - MINX) // PX), int((y - MINY) // PX)
    for dy in range(-n // 2, n - n // 2):
        for dx in range(-n // 2, n - n // 2):
            px, py = cx + dx, cy + dy
            if 0 <= px < W and 0 <= py < H:
                walk[py * W + px] = 0
                if is_tree(tid): tree_px[py * W + px] = 1
    blocked_by_destructible += 1

def to_px(wx, wy): return int((wx - MINX) // PX), int((wy - MINY) // PX)

# BFS path distance (in pixels, 4-neighbour) from every main spawn
MAIN_SPAWNS = {'TW': 'centre', 'XY': 'north', 'EY': 'east', 'OY': 'south', 'RY': 'west'}
def bfs(seeds):
    dist = [-1] * (W * H); q = deque()
    for s in seeds:
        if walk[s]: dist[s] = 0; q.append(s)
    while q:
        i = q.popleft(); x, y = i % W, i // W
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < W and 0 <= ny < H:
                j = ny * W + nx
                if walk[j] and dist[j] < 0: dist[j] = dist[i] + 1; q.append(j)
    return dist
spawn_dist = {}
for var, label in MAIN_SPAWNS.items():
    r = layout['spawns'][var]['rect']
    x0, y0 = to_px(r[0], r[1]); x1, y1 = to_px(r[2], r[3])
    seeds = [y * W + x for y in range(y0, y1) for x in range(x0, x1)]
    spawn_dist[label] = bfs(seeds)

plots = []
for d in layout['districts']:
    inside = set()
    for rr in d['rects']:
        x0, y0 = to_px(rr['rect'][0], rr['rect'][1]); x1, y1 = to_px(rr['rect'][2], rr['rect'][3])
        for y in range(max(y0, 0), min(y1, H)):
            for x in range(max(x0, 0), min(x1, W)):
                inside.add(y * W + x)
    walk_in = [i for i in inside if walk[i]]
    # buildable 128-unit cells: all 4x4 pixels walkable and inside
    cells = {}
    for i in inside:
        cells.setdefault(((i % W) // 4, (i // W) // 4), []).append(i)
    buildable = sum(1 for c, px in cells.items() if len(px) == 16 and all(walk[p] for p in px))
    # entrances: walkable inside pixels touching walkable outside pixels, grouped by connectivity
    edge = set()
    for i in walk_in:
        x, y = i % W, i // W
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            j = ny * W + nx
            if 0 <= nx < W and 0 <= ny < H and walk[j] and j not in inside:
                edge.add(i); break
    entrances, seen = [], set()
    for e in edge:
        if e in seen: continue
        comp, q = [], deque([e]); seen.add(e)
        while q:
            i = q.popleft(); comp.append(i); x, y = i % W, i // W
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    j = (y + dy) * W + (x + dx)
                    if j in edge and j not in seen: seen.add(j); q.append(j)
        xs = [i % W for i in comp]; ys = [i // W for i in comp]
        width_px = max(max(xs) - min(xs), max(ys) - min(ys)) + 1
        cx = MINX + (sum(xs) / len(xs) + .5) * PX; cy = MINY + (sum(ys) / len(ys) + .5) * PX
        entrances.append({'width_cells': round(width_px * PX / CELL, 2), 'centre': [round(cx), round(cy)]})
    # ignore 1-pixel slivers (rect edge noise)
    entrances = sorted([e for e in entrances if e['width_cells'] >= 0.5], key=lambda e: -e['width_cells'])
    sd = {}
    for label, dist in spawn_dist.items():
        vals = [dist[i] for i in walk_in if dist[i] >= 0]
        sd[label] = round(min(vals) * PX / CELL, 1) if vals else None
    reach = {k: v for k, v in sd.items() if v is not None}
    nearest = min(reach, key=reach.get) if reach else None
    garrison = d.get('preplaced_allied', {})
    plots.append({
        'name': d['name'],
        'rect_cells': d['cells'],
        'buildable_cells': buildable,
        'blocked_fraction': round(1 - len(walk_in) / max(len(inside), 1), 2),
        'water_cells': round(sum(1 for i in inside if water[i]) / 16, 1),
        'tree_cells': round(sum(1 for i in inside if tree_px[i]) / 16, 1),
        'entrances': len(entrances),
        'entrance_widths_cells': [e['width_cells'] for e in entrances],
        'total_entrance_width_cells': round(sum(e['width_cells'] for e in entrances), 2),
        'entrance_details': entrances,
        'path_distance_to_spawns_cells': sd,
        'nearest_spawn': nearest,
        'reachable': bool(reach),
        'garrison': garrison,
    })

plots.sort(key=lambda p: p['name'])
json.dump({'note': 'Approximate. Entrances = openings where walkable ground crosses the district boundary; '
                   'distances = walking route in 128-unit cells from the edge of each main spawn rect. '
                   'Destructible pathing (blockers, trees) rasterized from war3map.doo; script-removed blockers '
                   '(e.g. "Chamber" doors) counted as closed.',
           'destructible_blockers_rasterized': blocked_by_destructible,
           'plots': plots}, open(f'{OUT}/plots.json', 'w'), indent=1)

def g(gar):
    if not gar: return '–'
    if isinstance(gar, dict): return ', '.join(f'{v}× {k}' for k, v in list(gar.items())[:6])
    return str(gar)[:80]
L = ['# Original plots (districts) — analysis\n',
     'Approximate, computed from the pathing grid + rasterized destructible blockers. Cells are 128×128 world units. '
     'Distance = walking route in cells to the nearest edge of each main spawn (centre/N/E/S/W). '
     'See `plots.json` for entrance coordinates.\n',
     '| Plot | Rect cells | Buildable | Entrances | Widths (cells) | Nearest spawn (cells) | Centre | N | E | S | W | Water | Trees | Garrison |',
     '|---|---|---|---|---|---|---|---|---|---|---|---|---|---|']
for p in sorted(plots, key=lambda p: -p['buildable_cells']):
    sd = p['path_distance_to_spawns_cells']
    near = f"{p['nearest_spawn']} ({sd[p['nearest_spawn']]})" if p['nearest_spawn'] else 'unreachable'
    L.append('| ' + ' | '.join(map(str, [p['name'], p['rect_cells'], p['buildable_cells'], p['entrances'],
        ', '.join(map(str, p['entrance_widths_cells'])) or '–', near,
        *[sd[k] if sd[k] is not None else '–' for k in ('centre', 'north', 'east', 'south', 'west')],
        p['water_cells'], p['tree_cells'], g(p['garrison'])])) + ' |')
open(f'{OUT}/plots.md', 'w').write('\n'.join(L) + '\n')
print(len(plots), 'plots;', blocked_by_destructible, 'destructible blockers')
