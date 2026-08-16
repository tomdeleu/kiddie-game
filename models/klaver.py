"""The toverklaver, modelled in Blender.

    blender --background --python models/klaver.py

Reference: `references/ingredients/klaver.png`. Writes
`app/NinaBakeryPOC/Resources/Models/klaver.usdz`. Shared rules and export
settings are in `lowpoly.py`; `models/README.md` has the why.

**What the code version cannot do is the fold.** `FacetedMesh.extrude` makes a
flat slab: one front face, one tone, however many sides the outline has. Every
petal in the plate is creased along its midline — a ridge running from the
centre out to the notch, with the two halves of the petal catching the light at
different angles. That crease is the whole reason the plate reads as leaves and
the slab reads as four stickers on a stick. The code version compensates by
painting alternate petals `sage` and `sageDeep`, which is a tint standing in for
a shape.

With a real fold the facets do that job, so this is **one colour** for all four
petals, which is what the plate actually shows.

**Four petals, not the plate's five.** That is a decision already made and
recorded on `KitchenProps.buildClover`: a four-leaf clover is the lucky one,
which is the right note for the one ingredient with *tover* in its name. The
plate is the brief for the shape, not for the count.

Built in the XZ plane with its thickness along Y, so the finished prop faces
game +Z and the 45° turn `KitchenProps` already applies still points it at the
fixed camera.
"""

import math
import os
import sys

import bmesh
import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lowpoly

BLEND = os.path.join(lowpoly.REPO, "models", "klaver.blend")
USDZ = lowpoly.bundle_path("klaver")

HUB = 0.0128        # where the four tips meet, and the top of the stem
RIDGE = 0.0022      # how far the crease stands proud of the petal's edges
THICKNESS = 0.0009  # the petal is a leaf, not a sheet of paper

# Half of a heart, tip at the origin, growing along +Z, mirrored across X.
# The last point is the inner side of the lobe, which the notch closes back to.
HALF_OUTLINE = [(-0.0024, 0.0022),
                (-0.0045, 0.0050),
                (-0.0050, 0.0078),
                (-0.0038, 0.0098),
                (-0.0016, 0.0092)]

NOTCH = 0.0076      # the dip between the two lobes, on the crease
SPINE_MID = 0.0050  # where the crease is at its highest


def _petal(material, index):
    """One folded heart. Two fans, one per half, meeting on the crease."""
    bm = bmesh.new()
    tip = bm.verts.new((0, 0, 0))
    mid = bm.verts.new((0, -RIDGE, SPINE_MID))
    notch = bm.verts.new((0, -RIDGE * 0.45, NOTCH))

    for side in (-1, 1):
        edge = [bm.verts.new((side * x, 0, z)) for (x, z) in HALF_OUTLINE]
        chain = [tip] + edge + [notch]
        # A fan around the crease's midpoint: each triangle takes its own angle
        # off the fold, which is where the shading comes from.
        for a, b in zip(chain, chain[1:]):
            if side < 0:
                bm.faces.new((mid, a, b))
            else:
                bm.faces.new((mid, b, a))

    bm.normal_update()
    ob = lowpoly.flat_obj("KlaverBlad%d" % index, bm, material)

    solid = ob.modifiers.new("Thickness", 'SOLIDIFY')
    solid.thickness = THICKNESS
    solid.offset = 0.0
    return ob


def build():
    lowpoly.clear("Klaver")

    leaf_green = lowpoly.material("KlaverLeaf", 0xA7C0AC)   # Palette.sage
    stem_green = lowpoly.material("KlaverStem", 0x7E9A88)   # Palette.sageDeep

    petals = []
    for i in range(4):
        ob = _petal(leaf_green, i)
        # Same four directions as the code version: up-left, up-right and the
        # two below. The tip is at the petal's own origin, so placing every
        # petal at the hub lands all four tips on it — no compensation needed.
        ob.rotation_euler = (0, math.pi / 4 + i * math.pi / 2, 0)
        ob.location = (0, 0, HUB)
        lowpoly.apply_modifiers(ob)
        petals.append(ob)

    # **Behind the petals, not through them.** The petals' crease stands proud
    # towards the viewer and their edges sit on y = 0, so a stem centred on the
    # axis draws a stripe straight down the front of the two lower leaves. Set
    # back, it is hidden by them and shows only where it should: below.
    bm = bmesh.new()
    lowpoly.add_box(bm, (-0.0013, 0.0013), (0.0006, 0.0032), (0.0, HUB))
    bm.normal_update()
    stem = lowpoly.flat_obj("KlaverSteel", bm, stem_green)

    root = bpy.data.objects.new("Klaver", None)
    root.empty_display_size = 0.01
    bpy.context.collection.objects.link(root)
    parts = petals + [stem]
    for ob in parts:
        ob.parent = root

    # Contact shading where the four petals crowd into the hub and where they
    # meet the stem. 2.5 mm — the petals are 10 mm long, so this stays at the
    # centre and never darkens a petal's open face.
    shades = lowpoly.bake_ao_facets(parts, distance=0.0025)

    return [root] + parts + shades


if __name__ == "__main__":
    objects = build()
    lowpoly.export_usdz(objects, USDZ)
    if "--no-save" not in sys.argv:
        bpy.ops.wm.save_as_mainfile(filepath=BLEND)
