import re
def load(path):
    rows = {}; cols = {}; cur = {}; y = None; x = None
    for line in open(path, encoding='latin1'):
        if not line.startswith('C;'): continue
        parts = line.rstrip('\r\n').split(';')
        val = None
        for p in parts[1:]:
            if p[0] == 'X': x = int(p[1:])
            elif p[0] == 'Y': y = int(p[1:])
            elif p[0] == 'K':
                v = p[1:]
                val = v[1:-1] if v.startswith('"') else (float(v) if re.fullmatch(r'-?[\d.]+(E-?\d+)?', v) else v)
        if val is None: continue
        if y == 1: cols[x] = val
        else: rows.setdefault(y, {})[x] = val
    out = {}
    for y, r in rows.items():
        d = {cols.get(x, x): v for x, v in r.items()}
        k = r.get(1)
        if k: out[k] = d
    return out
