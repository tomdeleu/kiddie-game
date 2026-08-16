"""The toverveertje, modelled in Blender.

    blender --background --python models/veertje.py

Reference: `references/ingredients/veertje.png`. Writes
`app/NinaBakeryPOC/Resources/Models/veertje.usdz`.

**Same gap as the clover, for the same reason: the fold.**
`FacetedMesh.extrude` gives a flat slab — one front face, one tone — and a
feather's vane rises from its shaft on both sides. That crease down the middle
is what makes a blade read as a feather rather than as a leaf cut from card,
and it is the one thing the plate has that the code version cannot borrow.

**Two decisions come from the code, not from the plate:**

  * **No barbs.** The plate came back with notches cut into the vane; at 20 mm
    those are sub-millimetre teeth, the same argument that gave the honey
    dipper two parts instead of five rings.
  * **Asymmetry.** The plate's blade is near enough symmetrical; a real
    feather's vane is fuller on one side of the shaft than the other, and the
    code version already says so. It is the one detail a leaf shape cannot
    borrow, so it stays — the narrow side is 70% of the wide one.

Built in the XZ plane with its thickness along Y, like the clover, so the prop
faces game +Z and the 45° turn `KitchenProps` applies points it at the camera.
"""

import os
import sys

import bmesh
import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lowpoly

BLEND = os.path.join(lowpoly.REPO, "models", "veertje.blend")
USDZ = lowpoly.bundle_path("veertje")

RIDGE = 0.0020      # how far the shaft line stands proud of the vane's edges
THICKNESS = 0.0008
NARROW = 0.58       # the thin side of the vane, as a fraction of the full one

# (height, half-width) up the vane, tip last.
# The vane sits in the **upper two thirds**, on a bare quill — which is as much
# of what says "feather" as the fold is. Widest a third of the way up it, then a
# long taper to the tip. Two earlier attempts made it a full-length blade and
# both read as a leaf on a stick.
VANE = [(0.0100, 0.0000),
        (0.0130, 0.0048),
        (0.0165, 0.0062),
        (0.0205, 0.0056),
        (0.0245, 0.0036),
        (0.0280, 0.0000)]

QUILL_TOP = 0.0300
QUILL_SWELL = 0.0090   # where the bare shaft is thickest, below the vane
QUILL_R = 0.0011


def build():
    lowpoly.clear("Veertje")

    vane_cream = lowpoly.material("VeertjeVane", 0xF2E6DC)   # Palette.creamLight
    quill_cream = lowpoly.material("VeertjeQuill", 0xE4DACA)  # Palette.cream

    bm = bmesh.new()
    spine = [bm.verts.new((0, -RIDGE * (1.0 if 0 < i < len(VANE) - 1 else 0.35), z))
             for i, (z, _) in enumerate(VANE)]
    for side, scale in ((-1, 1.0), (1, NARROW)):
        edge = [bm.verts.new((side * w * scale, 0, z)) for (z, w) in VANE]
        for i in range(len(VANE) - 1):
            # Skip the degenerate triangles at the two ends, where the vane's
            # width is zero and the edge vertex sits on the spine.
            if VANE[i][1] == 0:
                bm.faces.new((spine[i], edge[i + 1], spine[i + 1])[::side])
            elif VANE[i + 1][1] == 0:
                bm.faces.new((spine[i], edge[i], spine[i + 1])[::side])
            else:
                bm.faces.new((spine[i], edge[i], edge[i + 1], spine[i + 1])[::side])
    bm.normal_update()
    vane = lowpoly.flat_obj("VeertjeBlad", bm, vane_cream)
    solid = vane.modifiers.new("Thickness", 'SOLIDIFY')
    solid.thickness = THICKNESS
    solid.offset = 0.0
    lowpoly.apply_modifiers(vane)

    # The shaft, showing above the tip and below the vane, and standing proud of
    # the fold on the front. One quill the vane is threaded onto, not two.
    quill = lowpoly.flat_obj(
        "VeertjeSchacht",
        lowpoly.tube([(QUILL_R * 0.8, 0.0), (QUILL_R * 1.3, QUILL_SWELL),
                      (QUILL_R * 0.7, QUILL_TOP)], 4),
        quill_cream)
    # **In front of the crease, not behind it.** At −RIDGE × 0.55 the shaft sat
    # inside the fold and was invisible from the front, which left the prop
    # reading as a leaf. It has to be the ridge you see.
    quill.location = (0, -RIDGE - 0.0007, 0)

    root = bpy.data.objects.new("Veertje", None)
    root.empty_display_size = 0.01
    bpy.context.collection.objects.link(root)
    parts = [vane, quill]
    for ob in parts:
        ob.parent = root

    # Contact shading in the crease, where the vane meets the shaft. 2 mm on a
    # 27 mm prop: it stays on the fold and off the open vane.
    shades = lowpoly.bake_ao_facets(parts, distance=0.0020)

    return [root] + parts + shades


if __name__ == "__main__":
    objects = build()
    lowpoly.export_usdz(objects, USDZ)
    if "--no-save" not in sys.argv:
        bpy.ops.wm.save_as_mainfile(filepath=BLEND)
