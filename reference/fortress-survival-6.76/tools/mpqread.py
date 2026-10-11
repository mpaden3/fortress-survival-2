import sys, struct, zlib, bz2, os
sys.path.insert(0, os.path.dirname(__file__))
from mpqcrypt import hs, decrypt
try:
    import pwexplode
except ImportError:
    pwexplode = None

class MPQ:
    def __init__(self, path, base=512):
        self.d = open(path,'rb').read(); self.base = base
        h = struct.unpack('<4sIIHHIIII', self.d[base:base+32])
        self.sector = 512 << h[4]
        ho, bo, hn, bn = h[5], h[6], h[7], h[8]
        raw = self.d[base+ho: base+ho+hn*16]
        ht = decrypt(raw, hs("(hash table)",3))
        self.hash = [ht[i*4:i*4+4] for i in range(hn)]
        raw = self.d[base+bo: base+bo+bn*16]
        bt = decrypt(raw, hs("(block table)",3))
        self.block = [bt[i*4:i*4+4] for i in range(len(bt)//4)]
    def find(self, name):
        n = len(self.hash); i = hs(name,0) % n; a=hs(name,1); b=hs(name,2)
        for _ in range(n):
            n1,n2,lp,bi = self.hash[i]
            if bi == 0xFFFFFFFF: return None
            if n1==a and n2==b and bi < len(self.block): return bi
            i = (i+1) % n
        return None
    def decomp(self, data, usize):
        if len(data) >= usize: return data
        m = data[0]; data = data[1:]
        if m & 0x08:
            return pwexplode.explode(data)
        if m & 0x10: data = bz2.decompress(data)
        elif m & 0x02: data = zlib.decompressobj(-15).decompress(data[2:])
        else: raise ValueError("unsupported compression %x" % m)
        return data
    def read(self, name):
        bi = self.find(name)
        if bi is None: return None
        off, csize, fsize, flags = self.block[bi]
        if not flags & 0x80000000: return None
        start = self.base + off
        key = None
        if flags & 0x10000:
            key = hs(name.replace('/','\\').split('\\')[-1], 3)
            if flags & 0x20000: key = ((key + off) ^ fsize) & 0xFFFFFFFF
        def dec(b, k):
            pad = (-len(b)) % 4
            w = decrypt(b + b'\0'*pad, k)
            return struct.pack('<%dI'%len(w), *w)[:len(b)]
        if flags & 0x01000000:
            data = self.d[start:start+csize]
            if key is not None: data = dec(data, key)
            if flags & 0x200: return self.decomp(data, fsize)
            if flags & 0x100: return pwexplode.explode(data)
            return data
        ns = (fsize + self.sector - 1) // self.sector
        if not (flags & 0x300):
            data = self.d[start:start+fsize]
            if key is not None:
                out=b''
                for i in range(ns):
                    out += dec(data[i*self.sector:(i+1)*self.sector], (key+i)&0xFFFFFFFF)
                data = out
            return data
        tab = self.d[start:start+(ns+1)*4]
        if key is not None: tab = dec(tab, (key-1)&0xFFFFFFFF)
        offs = struct.unpack('<%dI'%(ns+1), tab)
        out = b''
        for i in range(ns):
            chunk = self.d[start+offs[i]:start+offs[i+1]]
            if key is not None: chunk = dec(chunk, (key+i)&0xFFFFFFFF)
            us = min(self.sector, fsize - i*self.sector)
            if flags & 0x200: out += self.decomp(chunk, us)
            else: out += pwexplode.explode(chunk) if len(chunk)<us else chunk
        return out

if __name__ == '__main__':
    m = MPQ(sys.argv[1]); out = sys.argv[2]
    print("sector", m.sector, "hash", len(m.hash), "blocks", len(m.block))
    names = ["(listfile)","war3map.w3u","war3map.w3a","war3map.w3q","war3map.w3t","war3map.w3h","war3map.wts","war3map.j","scripts\\war3map.j","Scripts\\war3map.j","war3map.w3i","war3map.w3b","war3map.w3d","war3mapMisc.txt","war3map.imp","war3mapUnits.doo"]
    for n in names:
        try: d = m.read(n)
        except Exception as e: print(n, "ERR", repr(e)[:150]); continue
        if d is None: print(n, "missing"); continue
        open(os.path.join(out, n.replace("\\","_")),'wb').write(d); print(n, len(d))
