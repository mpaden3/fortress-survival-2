import json, re, sys, os
sys.path.insert(0, os.path.dirname(__file__))
import slk

os.chdir(os.path.join(os.path.dirname(__file__), '..'))
units = {x['id']: x for x in json.load(open('units.json'))}
abils = {x['id']: x for x in json.load(open('abil.json'))}
bal = slk.load('slk/UnitBalance.slk')
wep = slk.load('slk/UnitWeapons.slk')
uab = slk.load('slk/UnitAbilities.slk')
adata = slk.load('slk/AbilityData.slk')

wts = {}
t = open('ex676/war3map.wts', encoding='utf-8-sig', errors='replace').read()
for m in re.finditer(r'STRING (\d+)\s*(?://[^\n]*\n)?\s*\{\r?\n(.*?)\r?\n\}', t, re.S):
    wts[int(m.group(1))] = m.group(2)

def trig(v):
    if isinstance(v, str):
        m = re.fullmatch(r'TRIGSTR_0*(\d+)', v)
        if m: return wts.get(int(m.group(1)), v)
    return v

def clean(v):
    v = str(trig(v) or '')
    v = re.sub(r'\|c[0-9a-fA-F]{8}|\|r', '', v)
    v = v.replace('|n', ' / ').replace('\r', '').replace('\n', ' / ')
    v = re.sub(r'(\s*/\s*)+', ' / ', v).strip(' /')
    return v.replace('|', '\\|')

def num(v):
    if isinstance(v, (int, float)): return v
    try: return float(v)
    except (TypeError, ValueError): return None

def fmt(v):
    if v is None: return '–'
    if isinstance(v, float):
        return str(int(v)) if v == int(v) else f'{v:.2f}'.rstrip('0').rstrip('.')
    return str(v)

FIELDS = {  # map field -> (slk table, column)
    'uhpm': (bal, 'HP'), 'udef': (bal, 'def'), 'udty': (bal, 'defType'),
    'umvs': (bal, 'spd'), 'ugol': (bal, 'goldcost'), 'ulum': (bal, 'lumbercost'),
    'ubld': (bal, 'bldtm'), 'ufoo': (bal, 'fused'), 'uhpr': (bal, 'regenHP'),
    'umpm': (bal, 'manaN'),
    'ustr': (bal, 'STR'), 'uagi': (bal, 'AGI'), 'uint': (bal, 'INT'),
    'ustp': (bal, 'STRplus'), 'uagp': (bal, 'AGIplus'), 'uinp': (bal, 'INTplus'),
    'upra': (bal, 'Primary'),
    'uaen': (wep, 'weapsOn'), 'ua1b': (wep, 'dmgplus1'), 'ua1d': (wep, 'dice1'),
    'ua1s': (wep, 'sides1'), 'ua1c': (wep, 'cool1'), 'ua1r': (wep, 'rangeN1'),
    'ua1t': (wep, 'atkType1'), 'ua1w': (wep, 'weapTp1'), 'ua1f': (wep, 'Farea1'),
    'uabi': (uab, 'abilList'),
}

def get(uid, f):
    x = units.get(uid)
    if x and f in x['mods']: return x['mods'][f]
    base = x['base'] if x else uid
    tab, col = FIELDS[f]
    v = tab.get(base, {}).get(col)
    if isinstance(v, str) and v.strip() in ('-', '_', ''): return None
    return v

def name(uid):
    x = units.get(uid)
    n = clean(x['mods'].get('unam')) if x else ''
    return n or f'({uid})'

def abil_name(aid):
    a = abils.get(aid)
    if a:
        n = clean(a['mods'].get('anam', ''))
        if n: return n
        aid = a['base']
    d = adata.get(aid)
    return clean(d.get('comments', aid)) if d else aid

def abil_list(uid):
    v = get(uid, 'uabi') or ''
    names = [abil_name(a) for a in str(v).split(',') if a]
    skip = {'6 Slot Inventory', 'Inventory', 'Invulnerable', 'Building', 'Locust'}
    return ', '.join(n for n in names if n and n not in skip)

def damage(uid):
    en = num(get(uid, 'uaen'))
    if not en: return None
    b, d, s = num(get(uid, 'ua1b')) or 0, num(get(uid, 'ua1d')) or 0, num(get(uid, 'ua1s')) or 0
    return f'{fmt(b + d)}–{fmt(b + d * s)}'

def attack_cols(uid):
    dmg = damage(uid)
    if not dmg: return ['–'] * 4
    wt = get(uid, 'ua1w')
    area = num(get(uid, 'ua1f'))
    atype = fmt(get(uid, 'ua1t'))
    if wt in ('msplash', 'artillery', 'aline', 'mbounce', 'mline'):
        atype += f' / {wt}' + (f' {fmt(area)}' if area else '')
    return [dmg, fmt(num(get(uid, 'ua1c'))), fmt(num(get(uid, 'ua1r'))), atype]

def armor(uid):
    return f"{fmt(num(get(uid, 'udef')))} {fmt(get(uid, 'udty'))}"

def cost(uid):
    return f"{fmt(num(get(uid, 'ugol')) or 0)} / {fmt(num(get(uid, 'ulum')) or 0)}"

def tip(uid, n=220):
    x = units.get(uid)
    t = clean(x['mods'].get('utub', '')) if x else ''
    return t if len(t) <= n else t[:n].rsplit(' ', 1)[0] + '…'

BUILD_HDR = '| Name | ID | HP | Armor | Damage | Cooldown | Range | Attack type | Cost (g/l) | Build time | Abilities | Tooltip |\n|---|---|---|---|---|---|---|---|---|---|---|---|'
def build_row(uid, depth=0):
    pre = '↳ ' * depth if depth else ''
    return '| ' + ' | '.join([pre + name(uid), f'`{uid}`', fmt(num(get(uid, 'uhpm'))), armor(uid),
        *attack_cols(uid), cost(uid), fmt(num(get(uid, 'ubld'))), abil_list(uid), tip(uid)]) + ' |'

UNIT_HDR = '| Name | ID | HP | Armor | Damage | Cooldown | Range | Attack type | Speed | Cost (g/l) | Food | Abilities | Tooltip |\n|---|---|---|---|---|---|---|---|---|---|---|---|---|'
def unit_row(uid, prefix=''):
    return '| ' + ' | '.join([prefix + name(uid), f'`{uid}`', fmt(num(get(uid, 'uhpm'))), armor(uid),
        *attack_cols(uid), fmt(num(get(uid, 'umvs'))), cost(uid), fmt(num(get(uid, 'ufoo'))),
        abil_list(uid), tip(uid)]) + ' |'

def ids(v): return [x for x in str(v or '').split(',') if x]

def chain_rows(root, depth=0, out=None, seen=None):
    out = [] if out is None else out
    seen = set() if seen is None else seen
    if root in seen: return out
    seen.add(root); out.append(build_row(root, depth))
    kids = ids(units.get(root, {}).get('mods', {}).get('uupt'))
    for k in kids:
        chain_rows(k, depth + 1 if len(kids) > 1 or depth == 0 else depth, out, seen)
    return out

def linear_chain(root):
    out, seen, cur = [], set(), root
    while cur and cur not in seen:
        seen.add(cur); out.append(build_row(cur, 0 if cur == root else 1))
        k = ids(units.get(cur, {}).get('mods', {}).get('uupt'))
        cur = k[0] if k else None
    return out

L = []
w = L.append
w('# Fortress Survival Alpha 6.76 — units & buildings\n')
w('Extracted from `Fortress Survival Alpha 6.76P.w3x` (by Maddawg101 & Nevo, WC3 1.27a). '
  'Values = map overrides merged with WC3 TFT custom-game defaults. Reference only — do not copy content.\n')
w('**Reading the tables**')
w('- Costs are gold / lumber. For upgrades (↳) the listed cost is what the upgrade step costs (WC3 charges the target\'s cost).')
w('- Damage = min–max per hit. Cooldown in seconds. Range / speed in WC3 units (1 build cell = 128, a footman is ~270 speed).')
w('- Armor = value + armor type. Attack types: normal/pierce/siege/magic/chaos/spells/hero.')
w('- HP/damage of enemies is the **base**; difficulty scales it (mainly HP) at runtime via triggers.\n')

w('## Builder\n')
w(UNIT_HDR); w(unit_row('h001'))
w('\nThe ~280 other builder variants are identical cosmetic skins (named after community members/VIPs).\n')

w('## Walls\n')
for root, title in (('h003', 'Barricade line (cheap HP walls)'), ('h01Y', 'Energy Wall line ("life walls")')):
    w(f'### {title}\n'); w(BUILD_HDR); L.extend(linear_chain(root)); w('')

w('## Towers\n')
w('Everything starts as **Basic Tower** and branches into 10 lines of 6 levels.\n')
w(BUILD_HDR); w(build_row('h0ES'))
for br in ids(units['h0ES']['mods'].get('uupt')):
    L.extend(linear_chain(br))
w('')

w('## Aura statues\n')
w(BUILD_HDR); w(build_row('h023'))
for br in ids(units['h023']['mods'].get('uupt')):
    L.extend(linear_chain(br))
w('')

w('## Economy\n'); w(BUILD_HDR); L.extend(linear_chain('h00Q')); w('')

w('## Repair\n'); w(BUILD_HDR); L.extend(linear_chain('h00I'))
w(build_row('h00L')); w(build_row('h03Y')); w('')
w('### Repair bots\n'); w(UNIT_HDR)
for b in ('n008', 'n01V', 'n01W', 'n00V', 'n02A', 'n02N'):
    if b in units: w(unit_row(b))
w('')

w('## Utility buildings\n'); w(BUILD_HDR)
for b in ('h00T', 'h01L', 'h05R', 'h07B'): w(build_row(b))
w('')

w('## Mercenaries (Mercenary HQ tabs)\n')
for tab, ttl in (('h0KE', 'Marines (rank promotions ↳)'), ('h022', 'Melee'), ('h0F6', 'Range'), ('h00U', 'Support')):
    trains = ids(units[tab]['mods'].get('utra'))
    w(f'### {ttl}\n'); w(UNIT_HDR)
    seen = set()
    for t_ in trains:
        cur, pre = t_, ''
        while cur and cur not in seen and cur in units:
            seen.add(cur); w(unit_row(cur, pre))
            nxt = units[cur]['mods'].get('useu')
            cur, pre = (nxt if nxt and nxt in units else None), '↳ '
    w('')

w('## Heroes (Command Center → Hero Management, pick 1)\n')
w('Map constants: **+18 HP per STR**, +0.03 armor per AGI (base −5), +3 mana per INT, +1 damage per primary stat. Lvl 1 HP = base HP + 18 × STR.\n')
w('| Name | ID | Lvl 1 HP | Armor | Damage | Cooldown | Range | Attack type | Speed | STR / AGI / INT (+per lvl) | Primary | Abilities |\n|---|---|---|---|---|---|---|---|---|---|---|---|')
hero_seen = set()
for h in ids(units['h06I']['mods'].get('utra')):
    if h in hero_seen or h not in units: continue
    hero_seen.add(h)
    attrs = '{} / {} / {} (+{} / +{} / +{})'.format(*[fmt(num(get(h, f))) for f in ('ustr', 'uagi', 'uint', 'ustp', 'uagp', 'uinp')])
    w('| ' + ' | '.join([name(h), f'`{h}`', fmt((num(get(h, 'uhpm')) or 0) + 18 * (num(get(h, 'ustr')) or 0)), armor(h), *attack_cols(h),
        fmt(num(get(h, 'umvs'))), attrs, fmt(get(h, 'upra')), abil_list(h)]) + ' |')
w('')

w('## Enemies (spawned for the hostile player)\n')
w('Sorted by base HP. Includes wave units, mini-bosses and bosses (e.g. The Trojan).\n')
w(UNIT_HDR)
en = [e for e in json.load(open('enemy_ids.json')) if e in units and e[0] in 'nzu'
      and 'Dummy' not in name(e) and num(get(e, 'uhpm'))]
for e in sorted(en, key=lambda e: num(get(e, 'uhpm')) or 0):
    w(unit_row(e))
w('')

open(sys.argv[1], 'w').write('\n'.join(L))
print('rows', len(L), 'enemies', len(en), 'heroes', len(hero_seen))
