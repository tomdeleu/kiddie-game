"""The ripe feather plant, modelled in Blender.

    blender --background --python models/plant-veertje.py

Reference: `references/garden/plant-veertje.png`. Writes
`app/NinaBakeryPOC/Resources/Models/plant-veertje.usdz`.

**The clover's gap, for the clover's reason: the fold.** A vane rises from its
shaft on both sides, and `FacetedMesh.extrude` makes a flat slab with one front
face and one tone. That crease is the difference between a feather and a leaf
cut from card — which is exactly what the code version reads as when it is
standing on a stem in a flower bed surrounded by actual leaves.

The vane is `models/veertje.py`'s, station for station, and it keeps that
model's two decisions that came from the code rather than from a plate:

  * **No barbs.** This plate has them too — fine notches down the vane's
    edge — and at this size they are sub-millimetre teeth.
  * **Asymmetry.** A real feather's vane is fuller on one side of the shaft than
    the other, and neither plate draws it. It is the one detail a leaf shape
    cannot borrow, so it is the one worth keeping.
"""

import os
import sys

import bmesh
import mathutils

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import garden

NAME = "PlantVeertje"

RIDGE = 0.0022
THICKNESS = 0.0010
NARROW = 0.62

#: `(height, half-width)` up the vane, tip last — `models/veertje.py`'s own
#: table. The vane sits in the **upper two thirds** on a bare quill, which is as
#: much of what says *feather* as the fold is: two earlier attempts on the
#: kitchen's token made it a full-length blade and both read as a leaf on a
#: stick.
#:
#: **Broader than the token's, and starting lower.** The token is a 20 mm thing
#: held in a hand; this one is a plant standing in a bed between a cloud and a
#: star, and at the token's proportions — a 10 mm vane on a 30 mm quill — the
#: first render came back as a pale stick with a smudge near the top. The plate
#: draws a full feather, so the widths are the token's × 1.25 and the bare quill
#: below the vane is 6 mm rather than 10.
#:
#: **× 1.75 was too far**, which is worth recording because it is not obvious
#: from a number: at that width the vane is 21 mm across a 22 mm rise, and a
#: feather as wide as it is tall renders as a pale disc. The proportion the
#: plate draws is a shade under two to one, and it is the proportion rather than
#: the barbs that carries the word *feather*.
VANE = [(0.0050, 0.0000),
        (0.0110, 0.0052),
        (0.0170, 0.0076),
        (0.0225, 0.0072),
        (0.0280, 0.0048),
        (0.0330, 0.0000)]

QUILL_TOP = 0.0350
QUILL_SWELL = 0.0060
QUILL_R = 0.0011


def build():
    garden.fresh("Plant", "Veertje")

    leaf_green = garden.material("VeertjeLeaf", garden.SAGE)
    stem_green = garden.material("VeertjeStem", garden.SAGE_DEEP)
    earth = garden.material("VeertjeEarth", garden.WOOD_BROWN)
    vane_cream = garden.material("VeertjeVane", garden.CREAM_LIGHT)
    quill_cream = garden.material("VeertjeQuill", garden.CREAM)

    parts = garden.plant_base(leaf_green, stem_green, earth)
    head = garden.HEAD_Z
    turn = (0.0, 0.0, garden.FACING_CAMERA)

    bm = bmesh.new()
    spine = [bm.verts.new((0.0, -RIDGE * (1.0 if 0 < i < len(VANE) - 1 else 0.35), z))
             for i, (z, _) in enumerate(VANE)]
    for side, scale in ((-1, 1.0), (1, NARROW)):
        edge = [bm.verts.new((side * w * scale, 0.0, z)) for z, w in VANE]
        for i in range(len(VANE) - 1):
            # Skip the degenerate triangles at the two ends, where the vane's
            # width is zero and the edge vertex sits on the spine.
            if VANE[i][1] == 0:
                face = (spine[i], edge[i + 1], spine[i + 1])
            elif VANE[i + 1][1] == 0:
                face = (spine[i], edge[i], spine[i + 1])
            else:
                face = (spine[i], edge[i], edge[i + 1], spine[i + 1])
            bm.faces.new(face[::side])
    parts.append(garden.solidify(
        garden.placed("VeertjeBlad", vane_cream, bm,
                      at=(0.0, 0.0, head), rot=turn),
        THICKNESS))

    # **In front of the crease, not behind it.** At −RIDGE × 0.55 the shaft sat
    # inside the fold and was invisible from the front, which left the kitchen's
    # first feather reading as a leaf. It has to be the ridge you see.
    #
    # The offset has to be turned with the vane. `garden.matrix` translates
    # *after* it rotates, so a raw −Y here would push the shaft towards the
    # camera while the crease it belongs in had already swung 45° away — the
    # exact class of mistake the "everything at identity" rule exists to make
    # visible rather than to prevent.
    stand_off = mathutils.Vector((0.0, -RIDGE - 0.0007, 0.0))
    stand_off.rotate(mathutils.Euler(turn, 'XYZ'))
    parts.append(garden.lathe(
        "VeertjeSchacht", quill_cream,
        [(QUILL_R * 0.8, 0.0), (QUILL_R * 1.3, QUILL_SWELL),
         (QUILL_R * 0.7, QUILL_TOP)], 4,
        at=(stand_off.x, stand_off.y, head), rot=turn))

    # 2.0 mm, `models/veertje.py`'s number: on a 30 mm feather it stays in the
    # crease where the vane meets the shaft and off the open vane.
    return garden.finish(NAME, parts, distance=0.0020)


if __name__ == "__main__":
    garden.write(build(), "plant-veertje")
