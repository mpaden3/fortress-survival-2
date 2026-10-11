"""Shared helpers for map tools: analysis (mirrors src/sim/map/map_analysis.gd), JSON writer, PNG preview.

Map format: see data/maps/README.md. Cells are (x, z); row 0 is north.
"""
import json
import struct
import zlib
from collections import deque

WALKABLE = '.'
NEIGHBOURS_4 = ((1, 0), (-1, 0), (0, 1), (0, -1))


def area_cells(rects):
    cells = set()
    for x, z, w, h in rects:
        for zz in range(z, z + h):
            for xx in range(x, x + w):
                cells.add((xx, zz))
    return cells


def walkable(rows, x, z):
    return 0 <= z < len(rows) and 0 <= x < len(rows[0]) and rows[z][x] == WALKABLE


def buildable_cells(rows, rects):
    return sum(1 for x, z in area_cells(rects) if walkable(rows, x, z))


def entrances(rows, rects):
    """Walkable cells inside the area touching walkable ground outside it, grouped 8-connected."""
    area = area_cells(rects)
    edge = set()
    for x, z in area:
        if not walkable(rows, x, z):
            continue
        for dx, dz in NEIGHBOURS_4:
            n = (x + dx, z + dz)
            if n not in area and walkable(rows, *n):
                edge.add((x, z))
                break
    groups, seen = [], set()
    for start in sorted(edge):
        if start in seen:
            continue
        group, queue = [], [start]
        seen.add(start)
        while queue:
            x, z = queue.pop()
            group.append((x, z))
            for dz in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    n = (x + dx, z + dz)
                    if n in edge and n not in seen:
                        seen.add(n)
                        queue.append(n)
        xs = [c[0] for c in group]
        zs = [c[1] for c in group]
        width = max(max(xs) - min(xs), max(zs) - min(zs)) + 1
        centre = (round(sum(xs) / len(xs), 1), round(sum(zs) / len(zs), 1))
        groups.append({'width': width, 'centre': centre})
    groups.sort(key=lambda g: -g['width'])
    return groups


def walk_distances(rows, origins):
    dist = {}
    q = deque()
    for o in origins:
        if walkable(rows, *o):
            dist[o] = 0
            q.append(o)
    while q:
        x, z = q.popleft()
        for dx, dz in NEIGHBOURS_4:
            n = (x + dx, z + dz)
            if n not in dist and walkable(rows, *n):
                dist[n] = dist[(x, z)] + 1
                q.append(n)
    return dist


def rect_walkable_cells(rows, rect):
    return [c for c in area_cells([rect]) if walkable(rows, *c)]


def annotate(m):
    """Fill each plot's `expected` and `info` from the terrain. Returns the map dict."""
    rows = m['rows']
    spawn_dist = {s['id']: walk_distances(rows, rect_walkable_cells(rows, s['rect'])) for s in m['spawns']}
    start_dist = walk_distances(rows, [tuple(m['start'])])
    for p in m['plots']:
        ents = entrances(rows, p['rects'])
        p['expected'] = {
            'buildable_cells': buildable_cells(rows, p['rects']),
            'entrance_widths': [e['width'] for e in ents],
        }
        inside = [c for c in area_cells(p['rects']) if walkable(rows, *c)]
        d = {}
        for sid, dist in spawn_dist.items():
            vals = [dist[c] for c in inside if c in dist]
            d[sid] = min(vals) if vals else None
        sv = [start_dist[c] for c in inside if c in start_dist]
        p['info'] = {
            'entrance_centres': [list(e['centre']) for e in ents],
            'walk_distance_to_spawns': d,
            'walk_distance_to_start': min(sv) if sv else None,
            'water_cells': sum(1 for x, z in area_cells(p['rects']) if rows[z][x] == '~'),
            'tree_cells': sum(1 for x, z in area_cells(p['rects']) if rows[z][x] == 'T'),
        }
    return m


def save(m, path):
    """JSON with one row per line, so terrain diffs stay readable."""
    head = {k: v for k, v in m.items() if k not in ('rows', 'plots', 'spawns')}
    lines = ['{']
    for k, v in head.items():
        lines.append(f'  {json.dumps(k)}: {json.dumps(v)},')
    lines.append('  "spawns": [')
    lines.append(',\n'.join(f'    {json.dumps(s)}' for s in m['spawns']))
    lines.append('  ],')
    lines.append('  "plots": [')
    lines.append(',\n'.join(f'    {json.dumps(p)}' for p in m['plots']))
    lines.append('  ],')
    lines.append('  "rows": [')
    lines.append(',\n'.join(f'    {json.dumps(r)}' for r in m['rows']))
    lines.append('  ]')
    lines.append('}')
    open(path, 'w').write('\n'.join(lines) + '\n')


COLOURS = {'.': (196, 180, 140), '#': (52, 52, 58), '~': (60, 110, 190), 'T': (30, 100, 40)}


def write_png(m, path, scale=6):
    """Preview: terrain, plot outlines (pink), spawns (red), start (white)."""
    rows = m['rows']
    W, H = len(rows[0]) * scale, len(rows) * scale
    img = [[COLOURS[rows[z // scale][x // scale]] for x in range(W)] for z in range(H)]

    def outline(rect, colour, thick=1):
        x, z, w, h = rect
        x0, z0, x1, z1 = x * scale, z * scale, (x + w) * scale - 1, (z + h) * scale - 1
        for t in range(thick):
            for xx in range(x0, x1 + 1):
                for zz in (z0 + t, z1 - t):
                    if 0 <= zz < H and 0 <= xx < W: img[zz][xx] = colour
            for zz in range(z0, z1 + 1):
                for xx in (x0 + t, x1 - t):
                    if 0 <= zz < H and 0 <= xx < W: img[zz][xx] = colour

    for p in m['plots']:
        for r in p['rects']:
            outline(r, (240, 80, 180), 1)
    for s in m['spawns']:
        outline(s['rect'], (230, 30, 30), 2)
    sx, sz = m['start']
    outline([sx, sz, 1, 1], (255, 255, 255), 2)
    raw = b''.join(b'\x00' + bytes(c for px in row for c in px) for row in img)
    def chunk(tag, data):
        return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', zlib.crc32(tag + data) & 0xffffffff)
    png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', W, H, 8, 2, 0, 0, 0)) \
        + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b'')
    open(path, 'wb').write(png)


def summary_md(m):
    sp = [s['id'] for s in m['spawns']]
    out = [f"# {m['name']} (`{m['id']}`)\n",
           f"{len(m['rows'][0])}×{len(m['rows'])} cells. Start at {m['start']}. Spawns: {', '.join(sp)}.\n",
           '| Plot | Buildable cells | Entrances (widths) | Walk to start | ' + ' | '.join(f'Walk to {s}' for s in sp) + ' | Water | Trees |',
           '|---|---|---|---|' + '---|' * len(sp) + '---|---|']
    for p in m['plots']:
        e, i = p['expected'], p['info']
        widths = ', '.join(map(str, e['entrance_widths'])) or '–'
        out.append(f"| {p['name']} (`{p['id']}`) | {e['buildable_cells']} | {len(e['entrance_widths'])} ({widths}) | "
                   f"{i['walk_distance_to_start']} | " + ' | '.join(str(i['walk_distance_to_spawns'][s]) for s in sp)
                   + f" | {i['water_cells']} | {i['tree_cells']} |")
    return '\n'.join(out) + '\n'
