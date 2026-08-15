#!/usr/bin/env python3
"""Render what `UI/FacetButton.swift` draws, without a Swift toolchain.

Not a mock-up: every number here is read straight out of `FacetPlate` — the
same chamfer ratio, the same ring scales, the same light vector, the same
shade spread, the same press inversion. When one of those changes in Swift,
change it here and re-run, and the sheet stays the record of what the button
looks like on a machine that cannot build the app.

    python3 render-facetbutton.py

Writes `swiftui-preview.png` beside this file. Anti-aliasing is 4× supersample,
which the real thing gets from the GPU.
"""

import math
from PIL import Image, ImageDraw

# --- The locked palette, references/REFERENCES.md §4 -----------------------

CREAM_LIGHT = (0xF2, 0xE6, 0xDC)
MINT        = (0xC2, 0xDE, 0xCF)
SAGE        = (0xA7, 0xC0, 0xAC)
SAGE_DEEP   = (0x7E, 0x9A, 0x88)
BLUSH       = (0xFB, 0xD0, 0xCA)
ROSE        = (0xEA, 0xB5, 0xAA)
BUTTER      = (0xDC, 0xC9, 0x94)
SANDY       = (0xC7, 0x9C, 0x86)

BERRY_DEEP  = (0x9B, 0xB2, 0xD2)

EDGE = 0.80                    # FacetTone.edge = shade(face, 0.80)

FACES = {                      # FacetTone — the face picks the rest
    "sage":  SAGE,
    "rose":  ROSE,
    "sandy": SANDY,
    "berry": BERRY_DEEP,
}

# --- FacetPlate's constants ------------------------------------------------

CHAMFER = (2 - math.sqrt(2)) / 2   # Octagon.chamfer
RIM_SCALE = 0.945                  # outer edge ends here
FACE_SCALE = 0.805                 # flat face starts here
LIGHT = (-0.7071, -0.7071)         # FacetPlate.light, y down
SPREAD = 0.13                      # FacetPlate.spread
PRESS_RIM_DIM = 0.94               # (2 - lit) * this
PRESS_FACE_DIM = 0.90

SS = 4                             # supersample


def shade(colour, factor):
    return tuple(min(255, int(round(c * factor))) for c in colour)


def vertices(x, y, size):
    c = size * CHAMFER
    return [
        (x + c, y), (x + size - c, y),
        (x + size, y + c), (x + size, y + size - c),
        (x + size - c, y + size), (x + c, y + size),
        (x, y + size - c), (x, y + c),
    ]


def scaled(points, k, centre):
    cx, cy = centre
    return [(cx + (px - cx) * k, cy + (py - cy) * k) for px, py in points]


def facet_shade(a, b, centre, pressed):
    mx, my = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
    nx, ny = mx - centre[0], my - centre[1]
    length = max(1e-4, math.hypot(nx, ny))
    facing = (nx / length) * LIGHT[0] + (ny / length) * LIGHT[1]
    lit = 1 + SPREAD * facing
    return (2 - lit) * PRESS_RIM_DIM if pressed else lit


def plate(draw, x, y, size, tone, pressed=False):
    face_c = FACES[tone]
    rim_c, edge_c = CREAM_LIGHT, shade(face_c, EDGE)
    centre = (x + size / 2, y + size / 2)
    outer = vertices(x, y, size)
    rim = scaled(outer, RIM_SCALE, centre)
    face = scaled(outer, FACE_SCALE, centre)

    draw.polygon(outer, fill=edge_c)
    for i in range(8):
        j = (i + 1) % 8
        draw.polygon([rim[i], rim[j], face[j], face[i]],
                     fill=shade(rim_c, facet_shade(rim[i], rim[j], centre, pressed)))
    draw.polygon(face, fill=shade(face_c, PRESS_FACE_DIM) if pressed else face_c)
    return centre


def glyph(draw, kind, centre, size):
    """Rough stand-ins for the SF Symbols, at FacetGlyph's 0.42 proportion."""
    cx, cy = centre
    s = size * 0.42
    w = (255, 255, 255)
    if kind == "skip":
        draw.polygon([(cx - s * 0.55, cy - s * 0.5), (cx - s * 0.55, cy + s * 0.5),
                      (cx + s * 0.1, cy)], fill=w)
        draw.rectangle([cx + s * 0.22, cy - s * 0.5, cx + s * 0.45, cy + s * 0.5], fill=w)
    elif kind == "back":
        draw.polygon([(cx - s * 0.5, cy), (cx + s * 0.05, cy - s * 0.5),
                      (cx + s * 0.05, cy + s * 0.5)], fill=w)
        draw.rectangle([cx, cy - s * 0.16, cx + s * 0.5, cy + s * 0.16], fill=w)
    elif kind == "house":
        draw.polygon([(cx, cy - s * 0.55), (cx + s * 0.6, cy), (cx - s * 0.6, cy)], fill=w)
        draw.rectangle([cx - s * 0.42, cy, cx + s * 0.42, cy + s * 0.5], fill=w)
    elif kind == "note":
        draw.rectangle([cx + s * 0.1, cy - s * 0.55, cx + s * 0.25, cy + s * 0.35], fill=w)
        draw.ellipse([cx - s * 0.35, cy + s * 0.1, cx + s * 0.28, cy + s * 0.6], fill=w)


def main():
    W, H = 1160, 620
    img = Image.new("RGB", (W * SS, H * SS), (0xCF, 0xCE, 0xCF))
    draw = ImageDraw.Draw(img)

    # Bottom half on a cream ground: the wall the film ends on, and the worst
    # case for a cream rim.
    draw.rectangle([0, 330 * SS, W * SS, H * SS], fill=CREAM_LIGHT)

    game, chrome = 120, 72

    # Row 1 — the family at game size, resting.
    for i, (tone, kind) in enumerate([("sage", "skip"), ("rose", "back"),
                                      ("sandy", "house"), ("berry", "note")]):
        x, y = (60 + i * 170) * SS, 60 * SS
        c = plate(draw, x, y, game * SS, tone)
        glyph(draw, kind, c, game * SS)

    # Row 1, right — the same buttons pressed.
    for i, (tone, kind) in enumerate([("sage", "skip"), ("rose", "back")]):
        x, y = (760 + i * 170) * SS, 60 * SS
        c = plate(draw, x, y, game * SS, tone, pressed=True)
        glyph(draw, kind, c, game * SS)

    # Row 2 — skip at its real 72 pt, resting and pressed, on cream.
    for i, pressed in enumerate([False, True]):
        x, y = (60 + i * 120) * SS, 400 * SS
        c = plate(draw, x, y, chrome * SS, "sage", pressed=pressed)
        glyph(draw, "skip", c, chrome * SS)

    # Row 2, right — every tone at 72 pt on cream, the legibility check.
    for i, tone in enumerate(FACES):
        x, y = (400 + i * 110) * SS, 400 * SS
        c = plate(draw, x, y, chrome * SS, tone)
        glyph(draw, "skip", c, chrome * SS)

    img.resize((W, H), Image.LANCZOS).save("swiftui-preview.png")
    print("wrote swiftui-preview.png")


if __name__ == "__main__":
    main()
