"""The flour sack, modelled in Blender.

    blender --background --python models/flour-sack.py

Reference: `references/ingredients/flour-sack.png`. Writes
`app/NinaBakeryPOC/Resources/Models/flour-sack.usdz`. Shared rules and export
settings are in `lowpoly.py`; `models/README.md` has the why.

What the plate has and the code version could not reach: **vertical gather
folds** pinching into the tie, and a **pleated crown** of cloth fanning open
above it. The procedural sack in `KitchenProps.proceduralFlourSack` is four
stacked lathes and two wedges, and a lathe cannot make either — it can spin a
profile, but not make alternating verts ride high and wide with the ones
between tucked low, which is what a pleat is.
"""

import math
import os
import sys

import bmesh
import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lowpoly

BLEND = os.path.join(lowpoly.REPO, "models", "flour-sack.blend")
USDZ = lowpoly.bundle_path("flour-sack")

N = 10  # sides around. The plate reads as about this many vertical facets.

# The body: (radius, height, jitter) in metres.
#
# Flat-sided and settled rather than round — a sack of flour is heavy and sits
# down into itself, widest a third of the way up, and an onion bulge above that
# reads as a vase. `jitter` alternates the radius vertex by vertex and grows
# towards the neck, which is where the cloth is actually pinched: the gather.
BODY = [(0.0176, 0.0000, 0.00),
        (0.0221, 0.0032, 0.02),
        (0.0241, 0.0092, 0.03),
        (0.0239, 0.0162, 0.03),
        (0.0221, 0.0232, 0.04),
        (0.0181, 0.0302, 0.05),
        (0.0124, 0.0364, 0.07),
        (0.0092, 0.0402, 0.08)]

# The tie: a band with a groove down its middle, as the plate has it.
TIE = [(0.0096, 0.0386), (0.0110, 0.0398), (0.0104, 0.0414),
       (0.0110, 0.0430), (0.0096, 0.0442)]

# The four corners of cloth where a full sack meets the floor. They are most of
# what stops the body reading as a vase, and they are tucked under the bulge —
# splayed out flat they read as four separate wedges lying on the ground.
CORNER_ANGLES = (0.55, 2.45, 3.95, 5.55)
CORNER_ORBIT = 0.0162


def build():
    lowpoly.clear("FlourSack")

    cloth = lowpoly.material("FlourSackCloth", 0xF2E6DC)      # Palette.creamLight
    corner_cloth = lowpoly.material("FlourSackCorner", 0xE4DACA)  # Palette.cream
    pink = lowpoly.material("FlourSackTieBand", 0xE3B1AE)     # Palette.blushPinkDeep

    body = lowpoly.flat_obj("FlourSackBody", lowpoly.tube(BODY, N), cloth)
    tie = lowpoly.flat_obj("FlourSackTie", lowpoly.tube(TIE, N), pink)

    corners = []
    for i, a in enumerate(CORNER_ANGLES):
        bm = bmesh.new()
        tip = bm.verts.new((0.0088, 0.0, 0.0006))
        left = bm.verts.new((-0.0010, 0.0052, 0.0))
        right = bm.verts.new((-0.0010, -0.0052, 0.0))
        top = bm.verts.new((-0.0036, 0.0, 0.0052))
        bm.faces.new((tip, left, top))
        bm.faces.new((tip, top, right))
        bm.faces.new((tip, right, left))
        bm.normal_update()
        ob = lowpoly.flat_obj("FlourSackCorner%d" % i, bm, corner_cloth)
        ob.rotation_euler = (0, 0, a)
        ob.location = (math.cos(a) * CORNER_ORBIT, math.sin(a) * CORNER_ORBIT, 0.0)
        corners.append(ob)

    # The collar: cloth fanning open above the tie, as a crown of pleats.
    # Alternate verts ride high and wide, the ones between sit low and tucked
    # in. A single flare with no alternation is a funnel, not cloth.
    bm = bmesh.new()
    base = lowpoly.ring(bm, 0.0092, 0.0440, N)
    mid, top = [], []
    for i in range(N):
        a = 2 * math.pi * i / N
        high = (i % 2 == 0)
        rm, zm = (0.0148, 0.0496) if high else (0.0112, 0.0474)
        rt, zt = (0.0205, 0.0556) if high else (0.0130, 0.0494)
        mid.append(bm.verts.new((math.cos(a) * rm, math.sin(a) * rm, zm)))
        top.append(bm.verts.new((math.cos(a) * rt, math.sin(a) * rt, zt)))
    lowpoly.bridge(bm, base, mid, N)
    lowpoly.bridge(bm, mid, top, N)
    bm.faces.new(list(reversed(top)))  # closes the mouth: she never sees inside
    bm.normal_update()
    collar = lowpoly.flat_obj("FlourSackCollar", bm, cloth)
    solid = collar.modifiers.new("Thickness", 'SOLIDIFY')
    solid.thickness = 0.0011  # a real edge on the fan, not a paper-thin sheet
    solid.offset = 0.0

    root = bpy.data.objects.new("FlourSack", None)
    root.empty_display_size = 0.02
    bpy.context.collection.objects.link(root)
    parts = [body, tie, collar] + corners
    for ob in parts:
        ob.parent = root

    # The solidify has to be real geometry before the bake: the split-off shade
    # pieces are new objects with no modifiers, so an unapplied solidify would
    # leave the collar's shaded faces paper-thin inside a thick fan.
    lowpoly.apply_modifiers(collar)

    # Contact shading where the sack folds into itself — under the fanned
    # collar, into the groove of the tie, along the gather where the cloth is
    # pinched, and where the corners tuck under the bulge. Same bake as the
    # berry (`models/README.md`), scaled to a prop five times the size: 6 mm of
    # reach on a 48 mm sack is the same *proportion* of contact shading, not a
    # step towards lighting the whole thing.
    shades = lowpoly.bake_ao_facets(parts, distance=0.006, thresholds=(0.14, 0.34))

    return [root] + parts + shades


if __name__ == "__main__":
    objects = build()
    lowpoly.export_usdz(objects, USDZ)
    if "--no-save" not in sys.argv:
        bpy.ops.wm.save_as_mainfile(filepath=BLEND)
