"""The kitchen scale, modelled in Blender.

    blender --background --python models/scale.py

Reference: `references/props/scale-a.png`. Writes
`app/NinaBakeryPOC/Resources/Models/scale.usdz`. Shared rules and export
settings are in `lowpoly.py`; `models/README.md` has the why.

**The code version is a box, a disc and a tilted prism**, and it reads as three
parts sitting near each other rather than as one object. The plate makes the
case for what a scale actually needs:

  * **A dial that is a fat coin standing on a neck**, not a disc lying against
    the base at an angle. It is nearly as wide as the pan, and it is the whole
    silhouette — the thing that says *scale* from across the room.
  * **A pan with a rim**, a shallow dish you could put flour in, rather than a
    flat plate.
  * **A plinth under the base**, which is what stops a box reading as a box.

It faces the room (game +Z) with no turn applied, the way the code version
does: the camera looks down the +X+Z diagonal, so a prop facing +Z is already
being seen three-quarter — the plate's own angle.

**The pan is the part the game animates** (`KitchenRoom.tapScale` bounces it),
so it is its own mesh and `KitchenProps.scale` puts it on an upright pivot
through `ModelLibrary.pivot`.
"""

import math
import os
import sys

import bmesh
import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lowpoly

BLEND = os.path.join(lowpoly.REPO, "models", "scale.blend")
USDZ = lowpoly.bundle_path("scale")

SIDES = 12

PLINTH = (0.0180, 0.0160, 0.0000, 0.0035)   # half-x, half-y, z0, z1
BODY = (0.0160, 0.0140, 0.0035, 0.0125)
BASE_TOP = 0.0125

# **Blender +Y is the game's −Z**, so the dial goes at positive Y to stand at
# the back, and it faces −Y to look out into the room. Same rule the tap
# established; the scale is the second prop with a front and a back.
DIAL_Y = 0.0110
DIAL_Z = 0.0280
DIAL_R = 0.0105
DIAL_THICK = 0.0050
DIAL_TILT = 0.16        # leans back a little, as the plate has it

# **Forward, and smaller than the base.** The first pass put a 34 mm pan on
# the middle of the base, and it swallowed the bottom half of the dial: the
# plate stands the dial clear behind a pan that sits towards the front.
PAN_Y = -0.0055
PAN = [(0.0112, 0.0000),
       (0.0154, 0.0018),
       (0.0160, 0.0044),   # rim, outer top
       (0.0140, 0.0044),   # rim, inner top
       (0.0130, 0.0026),
       (0.0102, 0.0016)]   # the dish she could put flour in


def build():
    lowpoly.clear("Scale")

    mint = lowpoly.material("ScaleBody", 0xC2DECF)      # Palette.mint
    rim = lowpoly.material("ScaleDialRim", 0xF2E6DC)    # Palette.creamLight
    face = lowpoly.material("ScaleDialFace", 0xE4DACA)  # Palette.cream
    needle = lowpoly.material("ScaleNeedle", 0x7E9A88)  # Palette.sageDeep
    brass = lowpoly.material("ScalePanBrass", 0xDCC994)  # Palette.butterYellow

    # Base: a plinth, a body, and the neck the dial stands on. One mesh — they
    # are all the same colour and none of them moves.
    bm = bmesh.new()
    for hx, hy, z0, z1 in (PLINTH, BODY):
        lowpoly.add_box(bm, (-hx, hx), (-hy, hy), (z0, z1))
    lowpoly.add_box(bm, (-0.0042, 0.0042), (DIAL_Y - 0.0032, DIAL_Y + 0.0032),
                    (BASE_TOP - 0.0010, DIAL_Z - 0.0040))
    bm.normal_update()
    base = lowpoly.flat_obj("ScaleBase", bm, mint)

    # The dial: a coin built lying down and stood up on its edge. Rotating +90°
    # about X maps its axis (+Z) to −Y, which is the game's +Z — facing the
    # room. Rotating −90° would face it at the wall.
    dial = lowpoly.flat_obj("ScaleDial",
                            lowpoly.tube([(DIAL_R, 0.0), (DIAL_R, DIAL_THICK)], SIDES),
                            rim)
    dial_face = lowpoly.flat_obj(
        "ScaleDialFace",
        lowpoly.tube([(DIAL_R * 0.82, DIAL_THICK), (DIAL_R * 0.82, DIAL_THICK + 0.0008)],
                     SIDES),
        face)

    # The needle, and the hub it turns on. Built in the dial's own space: local
    # +Y becomes world up once the coin is stood on its edge.
    bm = bmesh.new()
    lowpoly.add_box(bm, (-0.0006, 0.0006), (-0.0008, 0.0090),
                    (DIAL_THICK + 0.0008, DIAL_THICK + 0.0016))
    lowpoly.add_box(bm, (-0.0016, 0.0016), (-0.0016, 0.0016),
                    (DIAL_THICK + 0.0008, DIAL_THICK + 0.0020))
    bm.normal_update()
    pointer = lowpoly.flat_obj("ScaleNeedle", bm, needle)

    for ob in (dial, dial_face, pointer):
        ob.rotation_euler = (math.pi / 2 - DIAL_TILT, 0, 0)
        ob.location = (0, DIAL_Y, DIAL_Z)

    pan = lowpoly.flat_obj("ScalePan", lowpoly.tube(PAN, SIDES), brass)
    pan.location = (0, PAN_Y, BASE_TOP)

    root = bpy.data.objects.new("Scale", None)
    root.empty_display_size = 0.02
    bpy.context.collection.objects.link(root)
    parts = [base, dial, dial_face, pointer, pan]
    for ob in parts:
        ob.parent = root

    # Contact shading where the dial meets its neck, under the pan's rim, and
    # along the plinth's step. 2.5 mm, against a prop 36 mm wide.
    shades = lowpoly.bake_ao_facets(parts, distance=0.0025)

    return [root] + parts + shades


if __name__ == "__main__":
    objects = build()
    lowpoly.export_usdz(objects, USDZ)
    if "--no-save" not in sys.argv:
        bpy.ops.wm.save_as_mainfile(filepath=BLEND)
