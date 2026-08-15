#!/usr/bin/env python3
"""Swap the mint backdrop of the icon for deep sage, leaving the cake alone.

Background is the only mint in the picture: green above both red and blue. Cake,
plate and star are all red-dominant, so a hue test separates them cleanly, and a
soft edge on that test keeps the antialiased rim from leaving a mint halo. The
contact shadow is darkened backdrop, so scaling the target by each pixel's own
luminance carries the shadow across intact.

Run it from this folder: `python3 recolour-dark.py`. No dependencies — png_tools
reads and writes 8-bit RGB PNGs directly. It rewrites H-cake-final-dark.png plus
the 320 px and 60 px previews; copy the full-size result over
app/NinaBakeryPOC/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024-dark.png.
"""
import png_tools as sheet

SRC = 'H-cake-final.png'
DST = 'H-cake-final-dark.png'
TARGET = (70, 88, 76)      # deep sage, one step below palette Sage deep #7E9A88
BG = (175, 195, 172)       # the light backdrop, sampled

def lum(r, g, b):
    return 0.2126 * r + 0.7152 * g + 0.0722 * b

def main():
    w, h, px = sheet.read_png(SRC)
    out = bytearray(px)
    bg_l = lum(*BG)
    for i in range(0, len(px), 3):
        r, g, b = px[i], px[i+1], px[i+2]
        # how much this pixel reads as mint backdrop, 0..1 with a soft edge
        f = (g - max(r, b) - 2) / 8.0
        f = 0.0 if f < 0 else (1.0 if f > 1 else f)
        if f == 0.0:
            continue
        k = lum(r, g, b) / bg_l
        for c in range(3):
            t = TARGET[c] * k
            t = 0 if t < 0 else (255 if t > 255 else t)
            out[i+c] = int(round(px[i+c] * (1 - f) + t * f))
    sheet.write_png(DST, w, h, out)
    sheet.write_png('candidates/H-cake-final-dark-320.png', 320, 320, sheet.resize(w, h, out, 320, 320))
    sheet.write_png('candidates/H-cake-final-dark-60.png', 60, 60, sheet.resize(w, h, out, 60, 60))
    print('wrote', DST)

main()
