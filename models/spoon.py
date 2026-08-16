"""The wooden spoon, modelled in Blender.

    blender --background --python models/spoon.py

Reference: `references/props/spoon.png`, generated from the owner's photograph
of three turned wooden scoops. Writes
`app/NinaBakeryPOC/Resources/Models/spoon.usdz`.

A **scoop**, not a table spoon: a deep round bowl with a thin rim, and one
straight handle leaving the rim horizontally, widening a little to a flat cut
end. Nothing tapers into anything — there is no waist, no neck, no butt cap.
That is the whole shape, and three things in the code version fight it:

  * `FacetedMesh.bowl` is the vocabulary's only double-walled primitive and its
    walls are **straight**, so the bowl can only be a tapered cup. This one is
    a round hollow, which is a two-walled lathe.
  * The handle was a tapered prism with a separate butt piece seamed onto its
    end, where the reference is one piece.
  * **The handle rose out of the middle of the bowl.** Neck at y = 0.003 and
    handle at 0.009, in a cavity whose floor is 0.003 and whose rim is 0.012 —
    so it came up through the hollow and the prop read as a goblet.

## Why the root is rotated

The spoon has two poses in the room, and `KitchenRoom.refreshLayout` swaps
between them: **lying** on the table (tipped 81.8° about the game's X) and
**standing** in the bowl while she stirs (identity). So the pose that gets the
identity transform is the upright one, which is why the code version is built
standing and why this cannot simply be modelled lying down.

It is modelled lying anyway — exactly as the reference draws it, which is the
only way to get the shape right by eye — and the root then carries **minus** the
room's tip. The room's rotation cancels it, so the resting pose is the modelled
one and the stirring pose is that same spoon stood on its handle. Authoring
matches the picture; the game keeps both poses.

A turn of θ about the game's X is a turn of +θ about Blender's X, so the root
takes −81.8° about Blender X.
"""

import math
import os
import sys

import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lowpoly

BLEND = os.path.join(lowpoly.REPO, "models", "spoon.blend")
USDZ = lowpoly.bundle_path("spoon")

SIDES = 12          # the reference counts about this many round the rim
ROOM_TIP = math.pi / 2.2    # what KitchenRoom applies; the root carries its inverse

# The bowl, as one closed surface of revolution: a small flat where it rests,
# a round outer wall up to a **thin** rim, and back down the inside to a
# rounded floor. The rim is 1.5 mm — a real edge, not the fat band a tapered
# `bowl` primitive leaves.
BOWL = [(0.0034, 0.0000),
        (0.0098, 0.0022),
        (0.0140, 0.0058),
        (0.0160, 0.0098),
        (0.0165, 0.0130),   # rim, outer top
        (0.0150, 0.0130),   # rim, inner top
        (0.0144, 0.0098),
        (0.0122, 0.0058),
        (0.0074, 0.0026),
        (0.0030, 0.0016)]   # the floor of the hollow

# The handle: one bar off the rim, six-sided, widening steadily to a flat cut
# end. Built vertically and laid down, because `tube` stacks its rings up Z.
HANDLE = [(0.0032, 0.0000),
          (0.0034, 0.0060),
          (0.0040, 0.0280),
          (0.0046, 0.0480),
          (0.0044, 0.0520)]

HANDLE_Z = 0.0100   # its axis, just under the rim, so its top edge is level
HANDLE_Y = -0.0140  # where it leaves the bowl, on the near side

# `KitchenRoom` parks the spoon at `spoonHome + 6 mm` of clearance, which the
# code version needs: built standing and then tipped, its bowl swings below its
# own origin. This one is modelled lying, so its underside is already on zero
# and that clearance would leave it hovering. The parts are dropped by the same
# 6 mm to cancel it.
#
# Dropped **inside** the root, so it stays vertical in the resting pose: the
# root carries the inverse tip, so a translation on the children lands in the
# resting frame. In the stirring pose it becomes 6 mm along the spoon's own
# axis, which nothing can see.
TABLE_LIFT = 0.0060


def build():
    lowpoly.clear("Spoon")

    # Cream rather than the reference's beech, and the handle keeps the wood:
    # the table is `sandyWood`, and a wooden spoon lying on a wooden table is a
    # spoon nobody can see. That split is the code version's, and it was right.
    cream = lowpoly.material("SpoonScoop", 0xE4DACA)   # Palette.cream
    wood = lowpoly.material("SpoonWood", 0xC79C86)     # Palette.sandyWood

    bowl = lowpoly.flat_obj("SpoonScoop", lowpoly.tube(BOWL, SIDES), cream)
    bowl.location = (0, 0, -TABLE_LIFT)

    # Laid along −Y, which is the game's +Z: the handle comes towards the
    # camera, so it is the part of the prop nearest her finger.
    handle = lowpoly.flat_obj("SpoonHandle", lowpoly.tube(HANDLE, 6), wood)
    handle.rotation_euler = (math.pi / 2, 0, 0)
    handle.location = (0, HANDLE_Y, HANDLE_Z - TABLE_LIFT)

    root = bpy.data.objects.new("Spoon", None)
    root.empty_display_size = 0.02
    bpy.context.collection.objects.link(root)
    # Minus the room's tip — see the note at the top of this file.
    root.rotation_euler = (-ROOM_TIP, 0, 0)
    parts = [bowl, handle]
    for ob in parts:
        ob.parent = root

    # Contact shading where the handle meets the bowl's outer wall — the only
    # crevice this prop has, and a shallow one: the handle leaves the rim along
    # a tangent rather than burying itself in the bowl.
    #
    # **5.5 mm, where every other prop wants less.** At 2.5 and at 4 the bake
    # found nothing at all, which is the honest answer for a shape this open;
    # the join only reads once the rays can reach across it. Three faces on each
    # side is the whole result, and that is the join.
    shades = lowpoly.bake_ao_facets(parts, distance=0.0055)

    return [root] + parts + shades


if __name__ == "__main__":
    objects = build()
    lowpoly.export_usdz(objects, USDZ)
    if "--no-save" not in sys.argv:
        bpy.ops.wm.save_as_mainfile(filepath=BLEND)
