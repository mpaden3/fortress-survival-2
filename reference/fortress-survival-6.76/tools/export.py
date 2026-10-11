"""Export full object data (units/buildings, abilities, buffs, upgrades) merged with WC3 defaults."""
import json, re, sys, os, csv, glob
sys.path.insert(0, os.path.dirname(__file__))
import slk
from w3u import parse_obj

S = os.path.join(os.path.dirname(__file__), '..')
OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)

def L(n): return slk.load(f'{S}/slk/{n}.slk')

# ---------- strings ----------
wts = {}
t = open(f'{S}/ex676/war3map.wts', encoding='utf-8-sig', errors='replace').read()
for m in re.finditer(r'STRING (\d+)\s*(?://[^\n]*\n)?\s*\{\r?\n(.*?)\r?\n\}', t, re.S):
    wts[int(m.group(1))] = m.group(2)

west = {}
for line in open(f'{S}/slk/WorldEditStrings.txt', encoding='utf-8', errors='replace'):
    if '=' in line and line.startswith('WESTRING'):
        k, v = line.rstrip('\r\n').split('=', 1); west[k] = v.strip('"')

def clean(v):
    if isinstance(v, str):
        m = re.fullmatch(r'TRIGSTR_0*(\d+)', v.strip())
        if m: v = wts.get(int(m.group(1)), v)
        v = re.sub(r'\|c[0-9a-fA-F]{8}|\|r', '', v).replace('|n', '\n').replace('\r', '')
        return v.strip()
    if isinstance(v, float):
        v = round(v, 4)
        if v == int(v): return int(v)
    return v

def isnull(v): return v is None or (isinstance(v, str) and v.strip() in ('', '-', '_', ' - '))

# profile txt files: [id] key=value
prof = {}
for f in glob.glob(f'{S}/slk/prof/*.txt'):
    cur = None
    for line in open(f, encoding='utf-8', errors='replace'):
        line = line.rstrip('\r\n')
        if line.startswith('['): cur = prof.setdefault(line.strip('[]'), {}); continue
        if cur is not None and '=' in line and not line.startswith('//'):
            k, v = line.split('=', 1); cur.setdefault(k, v)

def prof_get(oid, field, level=None):
    v = prof.get(oid, {}).get(field)
    if v is None: return None
    if level is None: return v.strip('"')
    parts = re.findall(r'"[^"]*"|[^,]+', v)
    if not parts: return None
    p = parts[min(level - 1, len(parts) - 1)]
    return p.strip('"')

def dname(meta, fid):
    n = west.get(meta[fid].get('displayName', ''), meta[fid].get('field', fid))
    return re.sub(r'&', '', n)

def write_csv(path, rows, cols=None):
    if cols is None:
        cols = []
        for r in rows:
            for k in r:
                if k not in cols: cols.append(k)
    with open(path, 'w', newline='', encoding='utf-8') as fh:
        w = csv.DictWriter(fh, fieldnames=cols, extrasaction='ignore')
        w.writeheader()
        for r in rows:
            w.writerow({k: (json.dumps(v) if isinstance(v, (list, dict)) else v) for k, v in r.items()})

# ---------- units & buildings ----------
umeta = L('UnitMetaData')
utabs = {n: L(n) for n in ('UnitBalance', 'UnitWeapons', 'UnitData', 'UnitAbilities')}
_, uobjs = parse_obj(f'{S}/ex676/war3map.w3u')
units = {x['id']: x for x in uobjs}
enemy_ids = set(json.load(open(f'{S}/enemy_ids.json')))
script_abils = json.load(open(f'{S}/script_abils.json'))

def uval(x, fid):
    m = umeta[fid]
    if fid in x['mods']: return x['mods'][fid]
    s = m['slk']
    if s in utabs: v = utabs[s].get(x['base'], {}).get(m['field'])
    elif s == 'Profile': v = prof_get(x['base'], m['field'])
    else: return None
    return None if isnull(v) else v

def ids(v): return [i for i in str(v or '').split(',') if i]

merc_ids, trained_ids = set(), set()
for x in uobjs:
    tr = ids(x['mods'].get('utra'))
    nm = clean(x['mods'].get('unam', '')) or ''
    (merc_ids if ('Mercenary' in nm) else trained_ids).update(tr)

def category(x, rec):
    i = x['id']
    if 'Dummy' in str(rec.get('Name', '')) or x['base'] in ('uaco', 'uabo') and not rec.get('Hit Points Maximum (Base)'): return 'dummy'
    if rec.get('_builds'): return 'builder'
    if i[0].isupper(): return 'hero'
    if i in enemy_ids: return 'enemy'
    if rec.get('_is_building'): return 'building'
    if i in merc_ids: return 'mercenary'
    if i in trained_ids: return 'trainable_unit'
    return 'other'

unit_rows = []
for x in uobjs:
    is_bldg = x['mods'].get('ubdg', utabs['UnitBalance'].get(x['base'], {}).get('isbldg'))
    is_bldg = bool(is_bldg) and not isnull(is_bldg)
    is_hero = x['id'][0].isupper()
    rec = {'id': x['id'], 'base_id': x['base'], 'modified_original': x['table'] == 'orig'}
    for fid, m in sorted(umeta.items(), key=lambda kv: kv[1].get('sort', '')):
        if m['slk'] == 'ItemData': continue
        use = (is_hero and m.get('useHero')) or (is_bldg and m.get('useBuilding')) or (not is_hero and not is_bldg and m.get('useUnit'))
        if not use and fid not in x['mods']: continue
        v = uval(x, fid)
        if v is None: continue
        key = dname(umeta, fid)
        if key in rec: key = f'{key} [{fid}]'
        rec[key] = clean(v)
    rec['_builds'] = ids(x['mods'].get('ubui'))
    rec['_is_building'] = is_bldg
    unit_rows.append(rec)

aobjs_v, aobjs = parse_obj(f'{S}/ex676/war3map.w3a', True)
abils = {x['id']: x for x in aobjs}
adata = L('AbilityData')
def abil_name(a):
    x = abils.get(a)
    if x and 'anam' in x['mods']: return clean(x['mods']['anam'])
    base = x['base'] if x else a
    return clean(prof_get(base, 'Name') or adata.get(base, {}).get('comments') or a)

for r, x in zip(unit_rows, uobjs):
    r['category'] = category(x, r)
    abl = ids(uval(x, 'uabi'))
    r['ability_ids'] = abl
    r['ability_names'] = [abil_name(a) for a in abl]
    sa = script_abils.get(x['id'], {})
    r['script_added_ability_ids'] = sa.get('added', [])
    r['script_added_ability_names'] = [abil_name(a) for a in sa.get('added', [])]
    r['script_removed_ability_ids'] = sa.get('removed', [])
    del r['_builds'], r['_is_building']

# ---------- abilities ----------
ameta = L('AbilityMetaData')
def acode(base): return adata.get(base, {}).get('code', base)

abil_out, abil_long = [], []
for x in aobjs:
    base = x['base']; code = acode(base); mods = x['mods']
    levels = int(mods.get('alev', adata.get(base, {}).get('levels') or 1) or 1)
    rec = {'id': x['id'], 'base_id': base, 'code': code, 'name': abil_name(x['id']), 'levels': levels,
           'hero_ability': clean(mods.get('aher', adata.get(base, {}).get('hero'))),
           'item_ability': clean(mods.get('aite', adata.get(base, {}).get('item'))),
           'fields': {}, 'per_level': [{} for _ in range(levels)]}
    for fid, m in ameta.items():
        spec = m.get('useSpecific')
        if not isnull(spec) and code not in str(spec).split(',') and base not in str(spec).split(','): continue
        if not isnull(m.get('notSpecific')) and (code in str(m['notSpecific']).split(',')): continue
        name = dname(ameta, fid)
        rep = m.get('repeat') or 0
        if not rep:
            if fid in ('alev', 'aher', 'aite', 'anam'): continue
            v = mods.get(fid)
            if v is None:
                v = prof_get(base, m['field']) if m['slk'] == 'Profile' else adata.get(base, {}).get(m['field'])
            if not isnull(v): rec['fields'][name] = clean(v)
            continue
        letter = 'ABCDEFGHI'[int(m['data']) - 1] if m.get('data') else ''
        for lv in range(1, levels + 1):
            v = mods.get(f'{fid}{lv}')
            if v is None:
                if m['slk'] == 'Profile': v = prof_get(base, m['field'], lv)
                else: v = adata.get(base, {}).get(f"{m['field']}{letter}{min(lv, 4)}")
            if isnull(v): continue
            rec['per_level'][lv - 1][name] = clean(v)
    abil_out.append(rec)
    for k, v in rec['fields'].items():
        abil_long.append({'ability_id': x['id'], 'ability_name': rec['name'], 'code': code, 'level': '', 'field': k, 'value': v})
    for lv, d in enumerate(rec['per_level'], 1):
        for k, v in d.items():
            abil_long.append({'ability_id': x['id'], 'ability_name': rec['name'], 'code': code, 'level': lv, 'field': k, 'value': v})

# ---------- buffs / effects ----------
bmeta = L('AbilityBuffMetaData'); bdata = L('AbilityBuffData')
_, bobjs = parse_obj(f'{S}/ex676/war3map.w3h')
buff_rows = []
for x in bobjs:
    rec = {'id': x['id'], 'base_id': x['base']}
    for fid, m in bmeta.items():
        v = x['mods'].get(fid)
        if v is None:
            v = prof_get(x['base'], m['field']) if m['slk'] == 'Profile' else bdata.get(x['base'], {}).get(m['field'])
        if not isnull(v): rec[dname(bmeta, fid)] = clean(v)
    buff_rows.append(rec)

# ---------- upgrades / research ----------
gmeta = L('UpgradeMetaData'); gdata = L('UpgradeData')
_, gobjs = parse_obj(f'{S}/ex676/war3map.w3q', True)
upg_out, upg_long = [], []
for x in gobjs:
    base = x['base']; mods = x['mods']
    levels = int(mods.get('glvl', gdata.get(base, {}).get('maxlevel') or 1) or 1)
    rec = {'id': x['id'], 'base_id': base, 'levels': levels, 'fields': {}}
    for fid, m in gmeta.items():
        name = dname(gmeta, fid)
        if m.get('repeat'):
            vals = []
            for lv in range(1, levels + 1):
                v = mods.get(f'{fid}{lv}')
                if v is None and m['slk'] == 'Profile': v = prof_get(base, m['field'], lv)
                vals.append(clean(v) if not isnull(v) else None)
            if any(v is not None for v in vals): rec['fields'][name] = vals
        else:
            v = mods.get(fid)
            if v is None:
                v = prof_get(base, m['field']) if m['slk'] == 'Profile' else gdata.get(base, {}).get(m['field'])
            if not isnull(v): rec['fields'][name] = clean(v)
    upg_out.append(rec)
    for k, v in rec['fields'].items():
        upg_long.append({'upgrade_id': x['id'], 'name': (rec['fields'].get('Name') or [''])[0] if isinstance(rec['fields'].get('Name'), list) else rec['fields'].get('Name'), 'field': k, 'value': v})

# ---------- auras on buildings/units ----------
AURA_CODES = {'AOae', 'AHad', 'AOac', 'AHab', 'AUau', 'AEah', 'AEar', 'AUav', 'Aakb', 'AIav', 'AIae', 'AIad', 'AIar', 'AIba', 'AIcd', 'AIda', 'AIrm', 'AIlf', 'ACav', 'ACac', 'ACae', 'ACba', 'ACat', 'ACah', 'ACua', 'SCae', 'AIau', 'AIas', 'AIat', 'Arel', 'ACnr', 'Aoar', 'ACbb', 'ACdv'}
by_id = {a['id']: a for a in abil_out}
aura_rows = []
for r in unit_rows:
    for aid in r['ability_ids'] + r['script_added_ability_ids']:
        a = by_id.get(aid)
        code = a['code'] if a else acode(aid)
        name = a['name'] if a else abil_name(aid)
        if code in AURA_CODES or 'aura' in str(name).lower():
            lv1 = a['per_level'][0] if a else {}
            aura_rows.append({'unit_id': r['id'], 'unit_name': r.get('Name'), 'category': r['category'],
                              'ability_id': aid, 'ability_name': name, 'source': 'script' if aid in r['script_added_ability_ids'] else 'object_data', 'aura_code': code,
                              'level_1': lv1, 'tooltip': (lv1.get('Tooltip - Normal - Extended') or lv1.get('Tooltip - Learn - Extended') or '')})

# ---------- write ----------
def dump(name, obj): json.dump(obj, open(f'{OUT}/{name}.json', 'w', encoding='utf-8'), indent=1, ensure_ascii=False)
dump('units_buildings', unit_rows); write_csv(f'{OUT}/units_buildings.csv', unit_rows)
dump('abilities', abil_out); write_csv(f'{OUT}/abilities_long.csv', abil_long)
flat = []
for a in abil_out:
    for lv, d in enumerate(a['per_level'], 1):
        flat.append({'id': a['id'], 'name': a['name'], 'code': a['code'], 'level': lv, **a['fields'], **d})
write_csv(f'{OUT}/abilities.csv', flat)
dump('buffs_effects', buff_rows); write_csv(f'{OUT}/buffs_effects.csv', buff_rows)
dump('upgrades_research', upg_out); write_csv(f'{OUT}/upgrades_research_long.csv', upg_long)
dump('auras', aura_rows); write_csv(f'{OUT}/auras.csv', aura_rows)
import collections
print('units', len(unit_rows), collections.Counter(r['category'] for r in unit_rows))
print('abilities', len(abil_out), 'ability rows', len(abil_long), 'buffs', len(buff_rows), 'upgrades', len(upg_out), 'auras', len(aura_rows))
