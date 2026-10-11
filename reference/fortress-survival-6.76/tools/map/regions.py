import re, json, collections, sys
J = open(sys.argv[1], encoding='latin1').read().splitlines()
rects = {}
for i, l in enumerate(J, 1):
    m = re.match(r'set (\w+)=Rect\((-?[\d.]+),(-?[\d.]+),(-?[\d.]+),(-?[\d.]+)\)$', l)
    if m and i > 39000:
        rects[m.group(1)] = dict(var=m.group(1), rect=[float(m.group(k)) for k in range(2, 6)], line=i)
# function boundaries
func_of = {}; cur = None
for i, l in enumerate(J, 1):
    if l.startswith('function '): cur = (l.split()[1], i)
    func_of[i] = cur
rx = '|'.join(map(re.escape, rects))
use = collections.defaultdict(list)
for i, l in enumerate(J, 1):
    if i in [r['line'] for r in rects.values()]: continue
    for m in re.finditer(r'\b(' + rx + r')\b', l):
        use[m.group(1)].append(i)
# resolve spawn locs
spawns = collections.defaultdict(collections.Counter)
spawn_lines = collections.defaultdict(list)
def resolve(loc, i):
    m = re.fullmatch(r'(?:GetRectCenter|GetRandomLocInRect)\((\w+)\)', loc)
    if m: return m.group(1)
    if loc in rects: return loc
    f = func_of[i]
    for j in range(i - 1, f[1] - 1 if f else 0, -1):
        m = re.match(r'set ' + re.escape(loc) + r'=(?:GetRectCenter|GetRandomLocInRect)\((\w+)\)', J[j - 1])
        if m: return m.group(1)
    for j, l in enumerate(J, 1):
        m = re.match(r'set ' + re.escape(loc) + r'=(?:GetRectCenter|GetRandomLocInRect)\((\w+)\)', l)
        if m: return m.group(1)
    return None
for i, l in enumerate(J, 1):
    m = re.search(r"CreateNUnitsAtLoc\((\w+),'(\w{4})',Player\(\$B\),(.+?),bj_UNIT_FACING", l)
    if m:
        r = resolve(m.group(3).strip(), i) or ('?' + m.group(3))
        n = int(m.group(1), 16) if m.group(1).startswith('$') else (int(m.group(1)) if m.group(1).isdigit() else 1)
        spawns[r][m.group(2)] += n; spawn_lines[r].append(i)
events = collections.defaultdict(list)
for i, l in enumerate(J, 1):
    m = re.search(r'TriggerRegister(EnterRectSimple|LeaveRectSimple)\(\w+,(\w+)\)', l)
    if m: events[m.group(2)].append((m.group(1), i))
out = dict(rects=rects, uses={k: v for k, v in use.items()}, spawns={k: dict(v) for k, v in spawns.items()},
           spawn_lines={k: v for k, v in spawn_lines.items()}, events={k: v for k, v in events.items()})
json.dump(out, open(sys.argv[2], 'w'), indent=1)
print(len(rects), 'rects;', len(spawns), 'spawn regions')
for r, c in sorted(spawns.items(), key=lambda x: -sum(x[1].values())):
    print(r, rects.get(r, {}).get('rect'), sum(c.values()), 'units', len(c), 'types', 'lines', spawn_lines[r][:3])
print('events', {k: v[:2] for k, v in events.items()})
