"""The maanstof pouch, modelled in Blender.

    blender --background --python models/maanstof.py

Reference: `references/ingredients/maanstof.png`. Writes
`app/NinaBakeryPOC/Resources/Models/maanstof.usdz`.

Moon dust is read through its pouch — a substance with no shape of its own is
read through its container, which is the lesson the honey pot taught. So the
prop is the bag, and the bag is cloth, which is where `FacetedMesh` stops: the
same two things the flour sack needed are needed here at a quarter of the size.
**Gather folds** pinching into the cord, and **cloth standing open above it**.

**It must not read as a small flour sack**, and the plate is where that is won:

  * The sack is squat, settled and wide, with corners splayed on the floor. The
    pouch is **round-bellied and narrow-necked** — a bag of marbles rather than
    a bag of flour, gathered high instead of low.
  * The cloth above the cord stands in a few **irregular** points rather than an
    even pleated crown.
  * Lilac against the sack's cream, with a `lilacDeep` cord.

That is the rule the whole ingredient set follows: at thumbnail size two props
of the same family have to differ in silhouette, or they are one prop in two
colours.
"""

import math
import os
import sys

import bmesh
import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lowpoly

BLEND = os.path.join(lowpoly.REPO, "models", "maanstof.blend")
USDZ = lowpoly.bundle_path("maanstof")

N = 10

# (radius, height, jitter). Round and full low down, pinched hard into the neck
# — the jitter grows the same way the sack's does, because that is what a
# gather is, but the profile above the belly falls away much faster.
BODY = [(0.0026, 0.0000, 0.00),
        (0.0070, 0.0016, 0.02),
        (0.0092, 0.0046, 0.03),
        (0.0096, 0.0080, 0.03),
        (0.0082, 0.0112, 0.05),
        (0.0058, 0.0136, 0.07),
        (0.0042, 0.0152, 0.09)]

CORD = [(0.0044, 0.0148), (0.0054, 0.0158), (0.0048, 0.0166),
        (0.0054, 0.0174), (0.0044, 0.0182)]

MOUTH_Z = 0.0180


def build():
    lowpoly.clear("Maanstof")

    cloth = lowpoly.material("MaanstofCloth", 0xD3C6E4)  # Palette.lilac
    cord = lowpoly.material("MaanstofCord", 0xAE9CC9)    # Palette.lilacDeep

    bag = lowpoly.flat_obj("MaanstofZak", lowpoly.tube(BODY, N), cloth)
    tie = lowpoly.flat_obj("MaanstofKoord", lowpoly.tube(CORD, N), cord)

    # The cloth above the cord. Three lengths rather than two, cycling, so the
    # points come out uneven — an even alternation reads as a pleated collar,
    # which is the flour sack's, and this must not be that.
    bm = bmesh.new()
    base = lowpoly.ring(bm, 0.0042, MOUTH_Z, N)
    mid, tip = [], []
    for i in range(N):
        a = 2 * math.pi * i / N
        rm, zm, rt, zt = [(0.0076, 0.0206, 0.0108, 0.0248),
                          (0.0062, 0.0196, 0.0074, 0.0212),
                          (0.0070, 0.0202, 0.0094, 0.0232)][i % 3]
        mid.append(bm.verts.new((math.cos(a) * rm, math.sin(a) * rm, zm)))
        tip.append(bm.verts.new((math.cos(a) * rt, math.sin(a) * rt, zt)))
    lowpoly.bridge(bm, base, mid, N)
    lowpoly.bridge(bm, mid, tip, N)
    bm.faces.new(list(reversed(tip)))   # closed: she sees it from every side
    bm.normal_update()
    mouth = lowpoly.flat_obj("MaanstofOpening", bm, cloth)

    root = bpy.data.objects.new("Maanstof", None)
    root.empty_display_size = 0.01
    bpy.context.collection.objects.link(root)
    parts = [bag, tie, mouth]
    for ob in parts:
        ob.parent = root

    # Contact shading under the cord and where the open cloth folds into it.
    # 2 mm on a 25 mm prop, which keeps it at the neck.
    shades = lowpoly.bake_ao_facets(parts, distance=0.0020)

    return [root] + parts + shades


if __name__ == "__main__":
    objects = build()
    lowpoly.export_usdz(objects, USDZ)
    if "--no-save" not in sys.argv:
        bpy.ops.wm.save_as_mainfile(filepath=BLEND)
