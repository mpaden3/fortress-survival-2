import struct
def _table():
    t=[0]*0x500; seed=0x00100001
    for i in range(0x100):
        idx=i
        for j in range(5):
            seed=(seed*125+3)%0x2AAAAB; a=(seed&0xFFFF)<<16
            seed=(seed*125+3)%0x2AAAAB; b=seed&0xFFFF
            t[idx]=a|b; idx+=0x100
    return t
T=_table()
def hs(s,ht):
    s1=0x7FED7FED; s2=0xEEEEEEEE
    for c in s.upper().encode():
        v=T[(ht<<8)+c]; s1=(v^(s1+s2))&0xFFFFFFFF; s2=(c+s1+s2+(s2<<5)+3)&0xFFFFFFFF
    return s1
def decrypt(data,key):
    s2=0xEEEEEEEE; out=[]
    n=len(data)//4
    for v in struct.unpack('<%dI'%n,data[:n*4]):
        s2=(s2+T[0x400+(key&0xFF)])&0xFFFFFFFF
        r=v^((key+s2)&0xFFFFFFFF); out.append(r)
        key=((((~key)<<0x15)+0x11111111)|(key>>0x0B))&0xFFFFFFFF
        s2=(r+s2+(s2<<5)+3)&0xFFFFFFFF
    return out
