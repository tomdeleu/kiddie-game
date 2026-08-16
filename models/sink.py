"""The sink and its tap, modelled in Blender.

    blender --background --python models/sink.py

Reference: `references/props/sink-tap.png`. Writes
`app/NinaBakeryPOC/Resources/Models/sink.usdz`. Shared rules and export
settings are in `lowpoly.py`; `models/README.md` has the why.

**The tap is the worst prop in the room and the plate says why.** The code
version is a 5-sided prism standing up and a second 5-sided prism rotated 90°
for a spout — two sticks meeting at a right angle, with nothing on top. The
plate has a square post, a spout that leaves it and turns down over the basin
at a hard mitred angle, and a chunky faceted handle: the three things that make
a shape read as *a tap* rather than as plumbing.

**The water is not in here, and that is deliberate.** `KitchenProps.sink` keeps
building the stream and the pool in code, for three reasons that all point the
same way:

  * They are **animated by scaling one axis** — the stream grows down its own Y
    to open, the pool rises up its own Y as it fills. An imported prop hangs
    under the exporter's Z-up-to-Y-up rotation, so a child's local Y is not the
    world's, and driving those two from a model would mean an axis-swap hidden
    inside an animation. `ModelLibrary` deliberately hands back an upright
    wrapper to keep that trap out of the codebase; putting the water in would
    walk straight back into it.
  * They are the **one transparent surface in the game** (`Palette.waterMaterial`),
    and the palette is re-applied on load as opaque matte.
  * A stream's look is its material and its motion. There is no facet the lathe
    cannot already make here — which is the test a prop has to pass to be in
    this folder at all.

So the plate's water informs `KitchenProps.sink`'s numbers, and the geometry
that ships from here is the basin and the tap.
"""

import os
import sys

import bmesh
import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lowpoly

BLEND = os.path.join(lowpoly.REPO, "models", "sink.blend")
USDZ = lowpoly.bundle_path("sink")

SIDES = 12   # the plate's basin counts about this many round the rim

# The basin, as one closed surface of revolution: up the outside, out across
# the rim, back down the inside, and the floor closes it. (radius, height).
#
# The rim is the part the plate insists on — a flat band with real width, not
# an edge. It is what stops a bowl reading as a bucket, and it is where the
# light catches.
BASIN = [(0.0130, 0.0000),
         (0.0200, 0.0060),
         (0.0215, 0.0115),
         (0.0215, 0.0130),   # rim, outer top
         (0.0180, 0.0130),   # rim, inner top
         (0.0165, 0.0075),
         (0.0130, 0.0045)]   # the floor she fills

POST_X = 0.0042              # the post is square in section, as the plate has it
POST_TOP = 0.0400

# **Blender +Y is the game's −Z.** The exporter's Z-up-to-Y-up rotation maps
# (x, y, z) to (x, z, −y), so a tap placed at negative Y in Blender comes out
# standing in *front* of its basin, between the sink and the camera. It did,
# and this is the sign that fixes it. Everything symmetric got away with not
# knowing; the tap is the first modelled prop with a front and a back.
POST_Y = 0.0270              # behind the basin, and clear of its rim: at 0.0200
                             # the post stood inside the 0.0215 rim and grew
                             # through the far wall

SPOUT_Z0, SPOUT_Z1 = 0.0340, 0.0400   # the arm reaching out over the basin
NOZZLE_Z0 = 0.0325                    # and the short turn down at its end
NOZZLE_Y = 0.0020                     # where the water leaves, over the basin


def build():
    lowpoly.clear("Sink")
    lowpoly.clear("Tap")

    porcelain = lowpoly.material("SinkPorcelain", 0xD6F0DE)  # Palette.mintLight
    brass = lowpoly.material("TapBody", 0xA7C0AC)            # Palette.sage
    knob = lowpoly.material("TapKnob", 0xC2DECF)             # Palette.mint

    basin = lowpoly.flat_obj("SinkBasin", lowpoly.tube(BASIN, SIDES), porcelain)

    # The tap: post, arm, and the turn down. Three boxes, mitred by overlap —
    # at 4 mm square against this camera a real mitre is invisible and a hard
    # corner is the style anyway.
    bm = bmesh.new()
    lowpoly.add_box(bm, (-POST_X / 2, POST_X / 2),
                    (POST_Y - POST_X / 2, POST_Y + POST_X / 2),
                    (0.0, POST_TOP))
    lowpoly.add_box(bm, (-0.0032, 0.0032),
                    (NOZZLE_Y - 0.0016, POST_Y),
                    (SPOUT_Z0, SPOUT_Z1))
    lowpoly.add_box(bm, (-0.0028, 0.0028),
                    (NOZZLE_Y - 0.0016, NOZZLE_Y + 0.0016),
                    (NOZZLE_Z0, SPOUT_Z0))
    bm.normal_update()
    tap = lowpoly.flat_obj("TapBody", bm, brass)

    # The handle. An eight-sided cap on a short neck — the one round thing on
    # the prop, and the part that says a tap can be turned.
    stalk = lowpoly.flat_obj(
        "TapHandleNeck",
        lowpoly.tube([(0.0022, POST_TOP), (0.0022, POST_TOP + 0.0030)], 8),
        brass)
    handle = lowpoly.flat_obj(
        "TapHandleCap",
        lowpoly.tube([(0.0058, POST_TOP + 0.0030), (0.0062, POST_TOP + 0.0044),
                      (0.0050, POST_TOP + 0.0058)], 8),
        knob)
    for ob in (stalk, handle):
        ob.location = (0, POST_Y, 0)

    root = bpy.data.objects.new("Sink", None)
    root.empty_display_size = 0.02
    bpy.context.collection.objects.link(root)
    parts = [basin, tap, handle, stalk]
    for ob in parts:
        ob.parent = root

    # Contact shading inside the basin where the wall meets the floor, under
    # the rim, and where the spout leaves the post. 3 mm: the basin is 43 mm
    # across, so this stays in the corner and off the open porcelain.
    shades = lowpoly.bake_ao_facets(parts, distance=0.003)

    return [root] + parts + shades


if __name__ == "__main__":
    objects = build()
    lowpoly.export_usdz(objects, USDZ)
    if "--no-save" not in sys.argv:
        bpy.ops.wm.save_as_mainfile(filepath=BLEND)
