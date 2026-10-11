import re, json, sys, collections
J = open(sys.argv[1], encoding='latin1').read()
funcs = {m.group(1): m.group(2) for m in re.finditer(r'^function (\w+) takes [^\n]*\n(.*?)^endfunction', J, re.S | re.M)}
cond_units = {}
for f, body in funcs.items():
    m = re.fullmatch(r"\s*return\((.*)\)\s*", body, re.S)
    if m and 'GetUnitTypeId' in body and '=' in body:
        ids = re.findall(r"=='([A-Za-z0-9]{4})'", body)
        if ids: cond_units[f] = ids
out = collections.defaultdict(lambda: {'added': set(), 'removed': set(), 'events': set()})
for f, body in funcs.items():
    for cm in re.finditer(r'TriggerAddCondition\((\w+),Condition\(function (\w+)\)\)', body):
        trig, cf = cm.groups()
        if cf not in cond_units: continue
        events = set(re.findall(r'TriggerRegister\w+\(' + trig + r',(EVENT_\w+)', body))
        for am in re.finditer(r'TriggerAddAction\(' + trig + r',function (\w+)\)', body):
            ab = funcs.get(am.group(1), '')
            add = re.findall(r"UnitAddAbility(?:BJ)?\([^,]*?,?'([A-Za-z0-9]{4})'", ab)
            add += re.findall(r"UnitAddAbility\(\w+\(\),'([A-Za-z0-9]{4})'\)", ab)
            rem = re.findall(r"UnitRemoveAbility\(\w+\(\),'([A-Za-z0-9]{4})'\)", ab)
            if not add and not rem: continue
            for u in cond_units[cf]:
                out[u]['added'].update(add); out[u]['removed'].update(rem); out[u]['events'].update(events)
res = {u: {k: sorted(v) for k, v in d.items()} for u, d in out.items()}
json.dump(res, open(sys.argv[2], 'w'), indent=1)
print(len(res), 'unit types get abilities from script')
