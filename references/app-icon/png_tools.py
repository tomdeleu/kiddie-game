#!/usr/bin/env python3
"""Minimal PNG read/box-resize/write, no deps. Handles 8-bit RGB non-interlaced."""
import zlib, struct, sys

def read_png(path):
    d = open(path, 'rb').read()
    assert d[:8] == b'\x89PNG\r\n\x1a\n'
    pos, idat, w = 8, b'', None
    while pos < len(d):
        ln = struct.unpack('>I', d[pos:pos+4])[0]
        typ = d[pos+4:pos+8]
        data = d[pos+8:pos+8+ln]
        if typ == b'IHDR':
            w, h, bd, ct, _, _, il = struct.unpack('>IIBBBBB', data)
            assert bd == 8 and ct == 2 and il == 0, (bd, ct, il)
        elif typ == b'IDAT':
            idat += data
        pos += ln + 12
    raw = zlib.decompress(idat)
    stride = w * 3
    out = bytearray(h * stride)
    prev = bytearray(stride)
    p = 0
    for y in range(h):
        f = raw[p]; p += 1
        line = bytearray(raw[p:p+stride]); p += stride
        if f == 1:
            for i in range(3, stride): line[i] = (line[i] + line[i-3]) & 255
        elif f == 2:
            for i in range(stride): line[i] = (line[i] + prev[i]) & 255
        elif f == 3:
            for i in range(stride):
                a = line[i-3] if i >= 3 else 0
                line[i] = (line[i] + ((a + prev[i]) >> 1)) & 255
        elif f == 4:
            for i in range(stride):
                a = line[i-3] if i >= 3 else 0
                b = prev[i]
                c = prev[i-3] if i >= 3 else 0
                pa, pb, pc = abs(b-c), abs(a-c), abs(a+b-2*c)
                pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                line[i] = (line[i] + pr) & 255
        out[y*stride:(y+1)*stride] = line
        prev = line
    return w, h, out

def resize(w, h, px, nw, nh):
    out = bytearray(nw * nh * 3)
    for y in range(nh):
        y0, y1 = y*h//nh, max(y*h//nh + 1, (y+1)*h//nh)
        for x in range(nw):
            x0, x1 = x*w//nw, max(x*w//nw + 1, (x+1)*w//nw)
            r = g = b = n = 0
            for yy in range(y0, y1):
                base = yy*w*3
                for xx in range(x0, x1):
                    i = base + xx*3
                    r += px[i]; g += px[i+1]; b += px[i+2]; n += 1
            i = (y*nw + x)*3
            out[i], out[i+1], out[i+2] = r//n, g//n, b//n
    return out

def write_png(path, w, h, px):
    raw = bytearray()
    for y in range(h):
        raw.append(0)
        raw += px[y*w*3:(y+1)*w*3]
    def chunk(t, d):
        c = t + d
        return struct.pack('>I', len(d)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)
    hdr = struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0)
    open(path, 'wb').write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', hdr) +
                           chunk(b'IDAT', zlib.compress(bytes(raw), 9)) + chunk(b'IEND', b''))

def blit(dst, dw, sx, sy, src, sw, sh):
    for y in range(sh):
        di = ((sy+y)*dw + sx)*3
        dst[di:di+sw*3] = src[y*sw*3:(y+1)*sw*3]

if __name__ == '__main__':
    names = sys.argv[1:]
    imgs = {}
    for n in names:
        w, h, px = read_png(n + '.png')
        imgs[n] = (w, h, px)
        write_png(n + '-320.png', 320, 320, resize(w, h, px, 320, 320))
        write_png(n + '-60.png', 60, 60, resize(w, h, px, 60, 60))
        print('done', n)
