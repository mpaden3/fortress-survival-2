import struct
def doo(path):
    d=open(path,'rb').read()
    ver,sub,n=struct.unpack_from('<iii',d,4); p=16; out=[]
    for _ in range(n):
        tid=d[p:p+4].decode('latin1'); p+=4
        var,x,y,z,ang,sx,sy,sz=struct.unpack_from('<iffffff f'.replace(' ',''),d,p); p+=32
        flags,life=d[p],d[p+1]; p+=2
        if ver>=8:
            itp,nsets=struct.unpack_from('<ii',d,p); p+=8
            for _ in range(nsets):
                ni,=struct.unpack_from('<i',d,p); p+=4+ni*8
        eid,=struct.unpack_from('<i',d,p); p+=4
        out.append((tid,x,y,flags))
    return ver,sub,out
