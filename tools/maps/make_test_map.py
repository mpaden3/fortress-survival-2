"""Builds data/maps/test_map.json: a small 64x64 development map with contrasting plots.

Layout (like the original at small scale): a + of avenues meeting at a centre plaza (start +
centre spawn), edge spawns at the avenue ends, and walled plots in the four quadrants.

Run: python3 tools/maps/make_test_map.py   (from the project root)
"""
import os
import sys
sys.path.insert(0, os.path.dirname(__file__))
import maplib

N = 64
grid = [['.'] * N for _ in range(N)]


def fill(x, z, w, h, c):
    for zz in range(z, z + h):
        for xx in range(x, x + w):
            grid[zz][xx] = c


def room(interior, doors):
    """Walls a 1-cell ring around `interior` (x, z, w, h); `doors` are (x, z, w, h) gaps in the ring."""
    x, z, w, h = interior
    fill(x - 1, z - 1, w + 2, 1, '#')
    fill(x - 1, z + h, w + 2, 1, '#')
    fill(x - 1, z, 1, h, '#')
    fill(x + w, z, 1, h, '#')
    for d in doors:
        fill(*d, '.')


# map border
fill(0, 0, N, 1, '#'); fill(0, N - 1, N, 1, '#'); fill(0, 0, 1, N, '#'); fill(N - 1, 0, 1, N, '#')

plots = []


def plot(pid, name, interior, doors, notes):
    room(interior, doors)
    plots.append({'id': pid, 'name': name, 'rects': [list(interior)], 'notes': notes})


# NW quadrant
plot('cell', 'Cell', (20, 20, 6, 6), [(26, 22, 1, 2)],
     'Small, 1 narrow door, right next to the centre spawn.')
plot('long_hall', 'Long Hall', (4, 4, 14, 8), [(6, 12, 3, 1), (13, 12, 3, 1)],
     'Medium, 2 doors on the same side, far corner.')
fill(8, 20, 3, 3, '#')  # rubble
# NE quadrant
plot('keep', 'Keep', (38, 4, 16, 14), [(37, 9, 1, 4)],
     'Large, 1 wide door, trees inside.')
fill(45, 10, 2, 2, 'T')
plot('watchpost', 'Watchpost', (44, 22, 6, 5), [(46, 27, 2, 1)],
     'Small, 1 narrow door facing the east avenue.')
# SW quadrant
plot('courtyard', 'Courtyard', (6, 38, 16, 16), [(10, 37, 3, 1), (22, 44, 1, 4), (15, 54, 2, 1)],
     'Large, 3 doors, pond inside.')
fill(8, 48, 3, 4, '~')
# SE quadrant
plot('open_field', 'Open Field', (40, 40, 14, 12), [(54, 40, 1, 12)],
     'Large, whole east side open, scattered trees.')
for x, z in ((44, 44), (48, 47), (50, 42)):
    grid[z][x] = 'T'
fill(57, 36, 2, 9, 'T')  # tree line outside the field

spawns = [
    {'id': 'centre', 'rect': [30, 30, 4, 4]},
    {'id': 'north', 'rect': [30, 1, 4, 3]},
    {'id': 'east', 'rect': [60, 30, 3, 4]},
    {'id': 'south', 'rect': [30, 60, 4, 3]},
    {'id': 'west', 'rect': [1, 30, 3, 4]},
]

m = {
    'format': 1,
    'id': 'test_map',
    'name': 'Test Map',
    'size': [N, N],
    'legend': {'.': 'ground', '#': 'blocked', '~': 'water', 'T': 'tree'},
    'start': [32, 35],
    'spawns': spawns,
    'plots': plots,
    'rows': [''.join(r) for r in grid],
}
maplib.annotate(m)
root = os.path.join(os.path.dirname(__file__), '..', '..')
maplib.save(m, os.path.join(root, 'data/maps/test_map.json'))
maplib.write_png(m, os.path.join(root, 'docs/maps/test_map.png'), scale=8)
open(os.path.join(root, 'docs/maps/test_map.md'), 'w').write(maplib.summary_md(m))
print(maplib.summary_md(m))
