"""The DJ's headphones — one Blender accessory for whichever friend has the decks.

The DJ is one of the eleven friends, not a twelfth character. `FeestRoom` deals
one friend who is not on the floor and gives that same model this accessory.
Keeping the headphones separate therefore avoids eleven almost-identical DJ
files while still making every visible part of the character Blender geometry.

The shape comes from `references/feest/dj.png`: a broad arch clearing both ears,
two deep faceted cups, a dark cushion against the head, and a small pale outer
panel. It is authored around the guest head's local origin; `GuestCharacter`
parents the loaded wrapper directly to its animated head pivot.
"""

import math
import os
import sys

import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import feest
import garden


def g(x, y, z):
    """The game's local (x, y, z) in Blender's axes."""
    return (x, -z, y)


def build():
    mint = feest.material("DJMint", feest.MINT_LIGHT)
    dark = feest.material("DJDark", feest.WOOD_BROWN)
    cream = feest.material("DJCream", feest.CREAM_LIGHT)
    rose = feest.material("DJRose", feest.ROSE)

    parts = []

    # A real bent band rather than the former straight Swift box over the
    # forehead. Seven stations leave six broad, readable facets across the arch.
    points = []
    for i in range(7):
        angle = math.radians(25 + i * (130 / 6))
        points.append(g(math.cos(angle) * 0.030,
                        0.002 + math.sin(angle) * 0.030,
                        -0.004))
    band = garden.sweep("DJMintKopBand", mint, points, 0.0028, sides=6,
                        up=(0.0, 1.0, 0.0))
    parts.append(band)

    cups = []
    cushions = []
    for i, side in enumerate([-1, 1]):
        # The outer cup is tall and flattened only across the head. Its depth is
        # kept so the fixed isometric camera sees a cabinet, not a mint disc.
        cup = feest.blob(
            "DJMintKopCup%d" % i, mint, 0.0090, subdivisions=2,
            scale=(0.48, 0.92, 1.08), at=g(side * 0.0290, 0.002, -0.001))
        parts.append(cup)
        cups.append(cup)

        cushion = feest.blob(
            "DJDarkKopKussen%d" % i, dark, 0.0078, subdivisions=1,
            scale=(0.30, 0.82, 0.98), at=g(side * 0.0254, 0.002, 0.000))
        parts.append(cushion)
        cushions.append(cushion)

        panel = feest.blob(
            "DJCreamKopPaneel%d" % i, cream, 0.0052, subdivisions=1,
            scale=(0.18, 0.78, 0.92), at=g(side * 0.0331, 0.002, -0.001))
        parts.append(panel)

        # A blocky hinge is what joins the arch to each cup in the reference.
        hinge = feest.boxes(
            "DJRoseKopScharnier%d" % i, rose,
            [((-0.0025, 0.0025), (-0.0022, 0.0022), (-0.0030, 0.0030))],
            at=g(side * 0.0280, 0.0140, -0.003))
        parts.append(hinge)

    return parts, [band] + cups + cushions


def main():
    feest.fresh("DJHeadphones", "DJ")
    parts, shade = build()

    bpy.context.view_layer.update()
    corners = [ob.matrix_world @ v.co for ob in parts for v in ob.data.vertices]
    feest.check(max(abs(v.x) for v in corners) < 0.037,
                "headphones exceed the guest's 74 mm head envelope")
    feest.check(max(v.z for v in corners) < 0.036,
                "headphones rise more than 36 mm above the head pivot")

    objects = feest.finish("DJHeadphones", parts, shade=shade)
    feest.write(objects, "dj-headphones", save=True)


if __name__ == "__main__":
    main()
