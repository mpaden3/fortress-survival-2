import struct, sys, json, re
def parse_obj(path, has_levels=False):
    d = open(path,'rb').read(); p = 0
    def i32():
        nonlocal p; v = struct.unpack_from('<i', d, p)[0]; p += 4; return v
    def f32():
        nonlocal p; v = struct.unpack_from('<f', d, p)[0]; p += 4; return v
    def id4():
        nonlocal p; v = d[p:p+4].decode('latin1'); p += 4; return v
    def cstr():
        nonlocal p; e = d.index(b'\0', p); v = d[p:e].decode('utf-8','replace'); p = e+1; return v
    ver = i32(); objs = []
    for table in ('orig','custom'):
        n = i32()
        for _ in range(n):
            oid = id4(); nid = id4(); mods = {}
            for _ in range(i32()):
                fid = id4(); typ = i32()
                lvl = None
                if has_levels: lvl = i32(); i32()
                v = i32() if typ == 0 else f32() if typ in (1,2) else cstr()
                id4()
                key = fid if not lvl else f"{fid}{lvl}"
                mods[key] = v
            objs.append({'table': table, 'base': oid, 'id': nid if nid != '\0\0\0\0' else oid, 'mods': mods})
    return ver, objs
if __name__ == '__main__':
    ver, objs = parse_obj(sys.argv[1], len(sys.argv) > 3)
    print("version", ver, "objects", len(objs), file=sys.stderr)
    json.dump(objs, open(sys.argv[2],'w'), indent=1)
