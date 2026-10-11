import sys, json, os
sys.path.insert(0, os.path.dirname(__file__))
import terrain, doo
from PIL import Image, ImageDraw, ImageFont
S = os.path.join(os.path.dirname(__file__), '..'); OUT = sys.argv[1]
t = terrain.w3e(f'{S}/ex676/war3map.w3e')
W, H, f = terrain.wpm(f'{S}/ex676/war3map.wpm')
MIN = t['ox']; PX = 32; SC = 2; M = 60; LEG = 300
img = Image.new('RGB', (W * SC + 2 * M + LEG, H * SC + 2 * M), (250, 250, 247))
pix = Image.new('RGB', (W, H))
P = pix.load()
TW_ = t['W']
for yy in range(H):
    for xx in range(W):
        v = f[yy * W + xx]
        tx, ty = min(xx // 4, TW_ - 1), min(yy // 4, t['H'] - 1)
        layer = t['pts'][ty * TW_ + tx]['layer']
        if not v & 0x40:
            c = (40, 80, 160) if v & 0x02 else (110, 160, 215)
        elif v & 0x02:
            c = (55, 55, 60)
        elif v & 0x08:
            c = (196, 180, 140)
        else:
            c = (130, 172, 100)
        k = max(0.6, min(1.3, 1 + 0.08 * (layer - 2)))
        if v & 0x40 and not v & 0x02: c = tuple(min(255, int(ch * k)) for ch in c)
        P[xx, H - 1 - yy] = c
img.paste(pix.resize((W * SC, H * SC), Image.NEAREST), (M, M))
d = ImageDraw.Draw(img)
try:
    font = ImageFont.truetype('/usr/share/fonts/TTF/DejaVuSans.ttf', 13); fb = ImageFont.truetype('/usr/share/fonts/TTF/DejaVuSans-Bold.ttf', 14)
except OSError:
    font = fb = ImageFont.load_default()
def w2i(x, y): return (M + (x - MIN) / PX * SC, M + (H - (y - MIN) / PX) * SC)
_, _, dd = doo.doo(f'{S}/ex676/war3map.doo')
for tid, x, y, fl in dd:
    X, Y = w2i(x, y)
    if tid[1] == 'T': d.point((X, Y), fill=(20, 90, 30)); d.point((X + 1, Y), fill=(20, 90, 30))
    else: d.point((X, Y), fill=(90, 90, 90))
# grid every 16 build cells (2048 units)
for c in range(0, 161, 16):
    X, _ = w2i(MIN + c * 128, 0); _, Y = w2i(0, MIN + c * 128)
    d.line([(X, M), (X, M + H * SC)], fill=(0, 0, 0), width=1)
    d.line([(M, Y), (M + W * SC, Y)], fill=(0, 0, 0), width=1)
    d.text((X - 8, M + H * SC + 6), str(c), fill='black', font=font)
    d.text((M - 30, Y - 7), str(c), fill='black', font=font)
d.text((M + W * SC // 2 - 120, M + H * SC + 26), 'build cells (128 units) from map min corner', fill='black', font=font)
# playable bounds
x0, y0 = w2i(-9088, 8832); x1, y1 = w2i(9088, -9728)
d.rectangle([x0, y0, x1, y1], outline=(255, 255, 255), width=2)
reg = json.load(open(f'{S}/regions.json'))
R = reg['rects']
for k, v in R.items():
    a, b, c_, e = v['rect']; X0, Y0 = w2i(a, e); X1, Y1 = w2i(c_, b)
    d.rectangle([X0, Y0, X1, Y1], outline=(150, 150, 150))
groups = [
    ((220, 20, 20), 'Enemy spawn (main)', ['TW', 'XY', 'EY', 'OY', 'RY']),
    ((255, 140, 0), 'Enemy spawn (event/boss)', ['DZ', 'WW', 'VY', 'UW', 'WY']),
    ((150, 40, 200), 'NPC quest / dialog zone', ['JW', 'P2', 'TZ', 'R2', 'U1']),
    ((0, 170, 190), 'Allied (computer) zone', ['Q1', 'S1', 'P1', 'U0']),
    ((230, 200, 0), 'Guard / aggro zone', ['JZ', 'HZ', 'KZ', 'P0']),
]
# districts (claimable bases)
dist = json.load(open(f'{S}/districts.json'))
small = ImageFont.truetype('/usr/share/fonts/TTF/DejaVuSans-Bold.ttf', 11) if font is not fb else font
for di in dist:
    for k in di['rects']:
        a, b, c_, e = R[k]['rect']; X0, Y0 = w2i(a, e); X1, Y1 = w2i(c_, b)
        d.rectangle([X0, Y0, X1, Y1], outline=(255, 60, 160), width=2)
    a, b, c_, e = R[di['rects'][0]]['rect']; X0, Y0 = w2i(a, e)
    d.text((X0 + 3, Y0 + 2), di['name'], fill=(120, 0, 70), font=small, stroke_width=2, stroke_fill='white')
U = {x['id']: x for x in json.load(open(f'{S}/units.json'))}
for pp in json.load(open(f'{S}/preplaced.json')):
    if pp['player'] != '$A': continue
    X, Y = w2i(pp['x'], pp['y'])
    base = U.get(pp['id'], {}).get('base', '')
    if base in ('hgtw', 'hhou', 'hbla', 'h0EL'):
        d.rectangle([X - 3, Y - 3, X + 3, Y + 3], fill=(0, 200, 220), outline='black')
    else:
        d.ellipse([X - 2, Y - 2, X + 2, Y + 2], fill=(0, 120, 255))
for col, lab, ks in groups:
    for k in ks:
        a, b, c_, e = R[k]['rect']; X0, Y0 = w2i(a, e); X1, Y1 = w2i(c_, b)
        d.rectangle([X0 - 2, Y0 - 2, X1 + 2, Y1 + 2], outline=col, width=3)
        d.text((X1 + 4, Y0 - 2), k, fill=col, font=fb, stroke_width=2, stroke_fill='white')
sx, sy = w2i(0, -384)
d.regular_polygon((sx, sy, 9), 5, fill=(255, 255, 255), outline=(0, 0, 0))
# legend
lx = M * 2 + W * SC; ly = M
d.text((lx, ly), 'Fortress Survival 6.76 — layout', fill='black', font=fb); ly += 28
items = [((130, 172, 100), 'Buildable ground'), ((196, 180, 140), 'Walkable, WC3-unbuildable*'), ((55, 55, 60), 'Unwalkable (cliff/blocker)'),
         ((110, 160, 215), 'Shallow water'), ((40, 80, 160), 'Deep water'), ((20, 90, 30), 'Tree (dot)'), ((90, 90, 90), 'Other doodad (dot)')]
for c, lab in items:
    d.rectangle([lx, ly, lx + 16, ly + 14], fill=c, outline='black'); d.text((lx + 24, ly), lab, fill='black', font=font); ly += 22
ly += 8
for col, lab, _ in groups:
    d.rectangle([lx, ly, lx + 16, ly + 14], outline=col, width=3); d.text((lx + 24, ly), lab, fill='black', font=font); ly += 22
d.rectangle([lx, ly, lx + 16, ly + 14], outline=(255, 60, 160), width=2); d.text((lx + 24, ly), 'Claimable base district (-claim)', fill='black', font=font); ly += 22
d.rectangle([lx + 5, ly + 4, lx + 11, ly + 10], fill=(0, 200, 220), outline='black'); d.text((lx + 24, ly), 'Pre-placed allied structure', fill='black', font=font); ly += 22
d.ellipse([lx + 6, ly + 5, lx + 10, ly + 9], fill=(0, 120, 255)); d.text((lx + 24, ly), 'Pre-placed allied unit', fill='black', font=font); ly += 22
d.rectangle([lx, ly, lx + 16, ly + 14], outline=(150, 150, 150)); d.text((lx + 24, ly), 'Other script region', fill='black', font=font); ly += 22
d.rectangle([lx, ly, lx + 16, ly + 14], outline='white', width=2, fill=(200, 200, 200)); d.text((lx + 24, ly), 'Playable (camera) bounds', fill='black', font=font); ly += 22
d.regular_polygon((lx + 8, ly + 7, 8), 5, fill='white', outline='black'); d.text((lx + 24, ly), 'Start location (all players)', fill='black', font=font); ly += 30
d.text((lx, ly), 'Grid lines every 16 cells', fill='black', font=font); ly += 18
d.text((lx, ly), '(2048 units). Map 160x160 cells.', fill='black', font=font); ly += 26
for line in ['* FS buildings only check', '"unwalkable", so they can be', 'placed on any walkable tile.']:
    d.text((lx, ly), line, fill='black', font=font); ly += 18
img.save(OUT)
print(img.size)
