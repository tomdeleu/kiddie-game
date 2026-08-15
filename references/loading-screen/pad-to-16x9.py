#!/usr/bin/env python3
"""Pad the 4:3 title plate out to 16:9 for the app, by mirroring its edge strip.

`flux_2` renders 4:3 (1.333); iPads run from 1.333 (12.9", 9.7") to 1.523
(mini). Aspect-filling a 4:3 plate on a mini would crop 6.2% off each side of
the *height* — straight through the title, whose top margin is only 3.5%.

Padding to 16:9 (1.778) inverts that: every iPad is narrower than the asset, so
the fill crops the **sides** and never the top or bottom. The 320 px added on
each side is pure background, and the widest iPad only eats 45 px of the plate
proper — well clear of the title's 20% side margins.

The padding is **synthesised, not copied**, in two parts:

- a *ramp*, the row's own background colour, averaged across the edge columns
  and smoothed down the frame. The backdrop is not flat — it lifts from
  (207,222,200) at the top to (213,238,215) at the bottom — so a single fill
  colour would band against the plate.
- *grain*, lifted from the plate's true background strip with its row mean
  subtracted, then ping-pong tiled. The paper grain measures 2.35 levels sd,
  which is subtle, but a perfectly smooth band beside a grainy one is the kind
  of seam you cannot unsee once you have seen it.

Copying pixels outright was tried twice and both ways show: repeating the edge
*column* stretches the grain into horizontal streaks across the whole pad, and
mirroring a wide strip drags content into the background — the left strip is
only 147 px of clean backdrop and the right one 36 px, both measured, because
the base slab's shadow reaches nearly to the right edge. Grain is taken from
the left strip for both sides; noise has no handedness.

    python3 pad-to-16x9.py J-icing-final.png ../../app/.../loading-screen.png
"""
import os
import struct
import sys
import zlib

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                '..', 'app-icon'))
import png_tools as P  # noqa: E402


def pingpong(k, span):
    """0,1,..,span-1,span-2,..,0,1,.. — a mirror that repeats without a seam."""
    period = 2 * span - 2
    i = k % period
    return i if i < span else period - i


def edge_ramp(w, h, px, x0, x1, smooth=8):
    """The backdrop colour per row, averaged over columns [x0, x1) and then
    box-smoothed down the frame. Averaging kills the grain; smoothing kills
    what the averaging missed."""
    span = x1 - x0
    rows = []
    for y in range(h):
        base = y * w * 3
        rows.append(tuple(sum(px[base + x * 3 + c] for x in range(x0, x1)) / span
                          for c in range(3)))
    out = []
    for y in range(h):
        lo, hi = max(0, y - smooth), min(h, y + smooth + 1)
        n = hi - lo
        out.append(tuple(sum(rows[yy][c] for yy in range(lo, hi)) / n
                         for c in range(3)))
    return out


def pad_to(w, h, px, nw, grain_strip=147):
    """Centre the image on a wider canvas over synthesised background."""
    assert nw >= w and (nw - w) % 2 == 0
    pad = (nw - w) // 2
    out = bytearray(nw * h * 3)

    left = edge_ramp(w, h, px, 0, 40)
    right = edge_ramp(w, h, px, w - 30, w)
    # Destination pad column -> source column in the clean left strip. The two
    # sides start at opposite phases so the same grain does not read as a pair.
    grain_x = [pingpong(k, grain_strip) for k in range(pad)]
    grain_x_r = [pingpong(k + grain_strip // 2, grain_strip) for k in range(pad)]

    for y in range(h):
        row = px[y * w * 3:(y + 1) * w * 3]
        o = y * nw * 3
        # This row's grain: the strip with its own mean taken out.
        mean = [sum(row[x * 3 + c] for x in range(grain_strip)) / grain_strip
                for c in range(3)]
        grain = [[row[x * 3 + c] - mean[c] for c in range(3)]
                 for x in range(grain_strip)]

        def put(dest_x, ramp, gx):
            d = o + dest_x * 3
            g = grain[gx]
            for c in range(3):
                v = int(round(ramp[c] + g[c]))
                out[d + c] = 0 if v < 0 else (255 if v > 255 else v)

        for k in range(pad):
            put(pad - 1 - k, left[y], grain_x[k])       # walking out to the left
            put(pad + w + k, right[y], grain_x_r[k])    # and out to the right
        out[o + pad * 3:o + (pad + w) * 3] = row
    return out


def write_png(path, w, h, px):
    """8-bit RGB, one filter chosen per row.

    `png_tools.write_png` stores every row unfiltered, which costs ~25% on a
    2560x1440 plate. Same pixels out, and `png_tools.read_png` reads it back.
    """
    stride = w * 3
    raw = bytearray()
    prev = bytearray(stride)
    for y in range(h):
        line = px[y * stride:(y + 1) * stride]
        sub = bytearray(stride)
        up = bytearray(stride)
        paeth = bytearray(stride)
        for i in range(stride):
            a = line[i - 3] if i >= 3 else 0
            b = prev[i]
            c = prev[i - 3] if i >= 3 else 0
            sub[i] = (line[i] - a) & 255
            up[i] = (line[i] - b) & 255
            pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
            pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
            paeth[i] = (line[i] - pr) & 255
        # Lowest sum of signed magnitudes wins — the standard heuristic.
        ft, data = min([(0, bytes(line)), (1, bytes(sub)),
                        (2, bytes(up)), (4, bytes(paeth))],
                       key=lambda c: sum(v if v < 128 else 256 - v for v in c[1]))
        raw.append(ft)
        raw += data
        prev = line

    def chunk(tag, data):
        body = tag + data
        return (struct.pack('>I', len(data)) + body +
                struct.pack('>I', zlib.crc32(body) & 0xffffffff))

    hdr = struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0)
    with open(path, 'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', hdr) +
                chunk(b'IDAT', zlib.compress(bytes(raw), 9)) + chunk(b'IEND', b''))


if __name__ == '__main__':
    src, dst = sys.argv[1], sys.argv[2]
    w, h, px = P.read_png(src)
    nw = h * 16 // 9
    out = pad_to(w, h, px, nw)
    write_png(dst, nw, h, out)
    corners = [(0, 0), (nw - 1, 0), (0, h - 1), (nw - 1, h - 1)]
    mean = [sum(out[(y * nw + x) * 3 + c] for x, y in corners) // 4
            for c in range(3)]
    print('%s  %dx%d -> %dx%d' % (dst, w, h, nw, h))
    print('corner mean #%02X%02X%02X — the LaunchBackground colour' % tuple(mean))
