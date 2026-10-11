import struct
def w3e(path):
    d=open(path,'rb').read(); p=4
    ver,=struct.unpack_from('<i',d,p); p+=4
    tileset=chr(d[p]); p+=1
    custom,=struct.unpack_from('<i',d,p); p+=4
    n,=struct.unpack_from('<i',d,p); p+=4
    gt=[d[p+i*4:p+i*4+4].decode() for i in range(n)]; p+=4*n
    n,=struct.unpack_from('<i',d,p); p+=4
    ct=[d[p+i*4:p+i*4+4].decode() for i in range(n)]; p+=4*n
    W,H=struct.unpack_from('<ii',d,p); p+=8
    ox,oy=struct.unpack_from('<ff',d,p); p+=8
    pts=[]
    for i in range(W*H):
        h,wf,b1,b2,b3=struct.unpack_from('<hhBBB',d,p); p+=7
        water=wf&0x3FFF; flags=b1>>4
        pts.append(dict(h=h,water=water,flags=flags,tex=b1&0xF,layer=b3&0xF))
    return dict(ver=ver,tileset=tileset,ground=gt,cliff=ct,W=W,H=H,ox=ox,oy=oy,pts=pts)
def wpm(path):
    d=open(path,'rb').read()
    ver,W,H=struct.unpack_from('<iii',d,4)
    return W,H,d[16:16+W*H]
