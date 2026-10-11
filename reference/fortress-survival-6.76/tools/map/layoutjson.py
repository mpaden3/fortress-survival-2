import json, re, collections, sys, os
S = os.path.join(os.path.dirname(__file__), '..'); OUT = sys.argv[1]
sys.path.insert(0, os.path.dirname(__file__))
from PIL import Image
Image.open(f'{S}/ex676/war3mapPreview.tga').convert('RGB').save(f'{OUT}/preview.png')
Image.open(f'{S}/ex676/war3mapMap.blp').convert('RGB').resize((512, 512), Image.NEAREST).save(f'{OUT}/minimap.png')
U = {x['id']: x for x in json.load(open(f'{S}/units.json'))}
def nm(i):
    x = U.get(i); return re.sub(r'\|c\w{8}|\|r', '', str(x['mods'].get('unam', i))) if x else i
reg = json.load(open(f'{S}/regions.json')); R = reg['rects']
dist = json.load(open(f'{S}/districts.json'))
pre = json.load(open(f'{S}/preplaced.json'))
def inside(x, y, r): return r[0] <= x <= r[2] and r[1] <= y <= r[3]
roles = {
 'TW': ('enemy_spawn_main', 'Map centre (also the start location). GetRandomLocInRect(TW) + CreateNUnitsAtLoc(..,Player(11),..); units then attack-move to a random non-hostile unit.'),
 'XY': ('enemy_spawn_main', 'North edge spawn'), 'EY': ('enemy_spawn_main', 'East edge spawn'),
 'OY': ('enemy_spawn_main', 'South edge spawn'), 'RY': ('enemy_spawn_main', 'West edge spawn'),
 'DZ': ('enemy_spawn_event', 'Small rect just south of centre; event/boss spawns'),
 'WW': ('enemy_spawn_event', 'Centre; event spawns'), 'VY': ('enemy_spawn_event', 'Centre; event spawns'),
 'UW': ('enemy_spawn_event', 'Centre; event spawns'), 'WY': ('enemy_spawn_event', 'Just north of centre; single spawn'),
 'JW': ('npc_dialog', 'Enter-rect trigger opens dialog "Welcome to my Brewery!"'),
 'P2': ('npc_dialog', 'Dialog "I have an Offer for you. Interested?"'),
 'TZ': ('npc_dialog', 'Dialog "Hellooo there MATEY" (pirates)'),
 'R2': ('npc_dialog', 'Dialog "I Need Your Help!"'),
 'U1': ('npc_dialog', 'Dialog "You will Protect this Garrison!"'),
 'Q1': ('allied_zone', 'Enter-rect: allied computer (Player 10) paratroopers sent at enemies (guess: allied reinforcement path)'),
 'S1': ('allied_zone', 'Same trigger as Q1'), 'P1': ('allied_zone', 'Enter-rect re-issues attack-move to entering units (guess: keeps enemies moving out of E spawn)'),
 'U0': ('allied_zone', 'Same as P1 for W spawn (guess)'),
 'JZ': ('guard_zone', 'Enter-rect: entering unit ordered to attack a unit near KZ (guess: guard/aggro trigger)'),
 'KZ': ('guard_zone', 'Target area for JZ trigger'),
 'HZ': ('guard_zone', 'Enter-rect: entering unit ordered to attack a unit in P0 (guess: guard/aggro trigger)'),
 'P0': ('guard_zone', 'Target area for HZ trigger'),
}
regions = []
for k, v in R.items():
    role, ev = roles.get(k, ('other', ''))
    for di in dist:
        if k in di['rects']: role, ev = 'base_district', f'Claimable base "{di["name"]}" (R6X/R7X at line {di["line"]})'
    sp = reg['spawns'].get(k)
    regions.append(dict(var=k, rect=v['rect'], defined_line=v['line'], role=role, evidence=ev,
        uses=len(reg['uses'].get(k, [])), enter_events=[e[1] for e in reg['events'].get(k, [])],
        spawns_total=sum(sp.values()) if sp else 0))
spawn_summary = {}
for k, c in reg['spawns'].items():
    spawn_summary[k] = dict(rect=R.get(k, {}).get('rect'), total_units=sum(c.values()),
        script_lines=reg['spawn_lines'][k][:20],
        by_type=sorted(({'id': i, 'name': nm(i), 'count': n} for i, n in c.items()), key=lambda x: -x['count']))
districts = []
for di in dist:
    rs = [R[r]['rect'] for r in di['rects']]
    units = collections.Counter(nm(p['id']) for p in pre if p['player'] == '$A' and any(inside(p['x'], p['y'], r) for r in rs))
    districts.append(dict(name=di['name'], rects=[dict(var=r, rect=R[r]['rect']) for r in di['rects']],
        cells=sum(int((r[2] - r[0]) / 128) * int((r[3] - r[1]) / 128) for r in rs),
        preplaced_allied=dict(units.most_common()), script_line=di['line']))
data = dict(
    source='Fortress Survival Alpha 6.76P.w3x (Maddawg101 & Nevo)',
    note='Reference for inspiration only. Coordinates in WC3 world units; 1 build cell = 128 units; pathing pixel = 32 units.',
    map=dict(tileset='J (Dalaran Ruins/cityscape textures)', tiles=[160, 160], build_cells=[160, 160],
             world_min=[-10240, -10240], world_max=[10240, 10240],
             playable_camera_bounds=dict(min=[-9088, -9728], max=[9088, 8832]),
             pathing_grid=[640, 640]),
    players=dict(count=12, humans='0-9 (guess: up to 10 players)', allied_computer=10, hostile=11,
                 start_location=[0, -384], start_note='All 12 start locations are identical, at the map centre.'),
    building_rule='All player buildings use placement restriction "unwalkable" only, so they can be placed on any walkable tile (roads included).',
    base_claim='Chat command "-claim" claims the district your builder is in: ownership of pre-placed allied (Player 10) units/structures inside transfers to you. "-unclaim" releases; "-claimcount" shows limit.',
    enemy_ai='Spawned enemies (Player 11) get attack-move orders to the position of a random non-hostile unit anywhere on the map; re-issued when they enter spawn/route rects.',
    spawns=spawn_summary, districts=districts, regions=regions,
    preplaced=[dict(owner={'$A': 'allied_computer(10)', '$B': 'hostile(11)'}.get(p['player'], 'neutral/other'), id=p['id'], name=nm(p['id']), x=p['x'], y=p['y']) for p in pre],
)
json.dump(data, open(f'{OUT}/layout.json', 'w'), indent=1)
print('regions', len(regions), 'districts', len(districts), 'spawns', len(spawn_summary))
for k in ['TW', 'XY']: print(k, spawn_summary[k]['total_units'], [(x['name'], x['count']) for x in spawn_summary[k]['by_type'][:8]])
for di in districts[:5]: print(di['name'], di['cells'], di['preplaced_allied'])
