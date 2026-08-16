"""The toverbosbes, modelled in Blender.

    blender --background --python models/bosbes.py

Reference: `references/ingredients/bosbes.png`. Writes
`app/NinaBakeryPOC/Resources/Models/bosbes.usdz`. Shared rules and export
settings are in `lowpoly.py`; `models/README.md` has the why.

What the plate has and the code version could not reach:

  * **A faceted globe.** The procedural berry is a six-point lathe profile,
    which gives it broad vertical panels and a pole at each end. The plate is a
    grid — fourteen columns by eight bands — so the facets are small quads all
    over, and there is no pole for them to converge on.
  * **A calyx.** The plate sinks a shallow crater into the top and stands the
    crown in it. That is what stops a blue ball reading as a marble, and a
    lathe cannot make a dish and a dome from one profile.
  * **A crown of five sharp spikes**, standing up off the rim. The code version
    is a flat extruded star lying on top, which reads as printed on the berry.

It also carries **the only ambient occlusion in the game**, baked onto the
facets rather than into a texture. `bake_ao_facets` and `models/README.md` have
the argument; the short version is that a standing crown and the globe under it
are two shapes that touch, and nothing else in the renderer says so.
"""

import math
import os
import sys

import bmesh
import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lowpoly

BLEND = os.path.join(lowpoly.REPO, "models", "bosbes.blend")
USDZ = lowpoly.bundle_path("bosbes")

N = 14  # columns around. The plate counts about this many.

# (radius, height) in metres. A squashed globe: a touch wider than it is tall,
# widest just below the middle, with a small flat where it rests. The last two
# rings are the crater — over the rim at 18.6 mm and back down into the dish.
BODY = [(0.0030, 0.0000), (0.0062, 0.0018), (0.0084, 0.0048), (0.0097, 0.0086),
        (0.0098, 0.0124), (0.0086, 0.0154), (0.0068, 0.0175),
        (0.0046, 0.0186),
        (0.0028, 0.0180)]

# The crown **stands up, and it is pointy** — five sharp spikes rising off the
# rim, not a hat.
#
# It took two wrong versions to read the plate properly, and the mistake worth
# recording is that **the centre is the low point, not the high one**. A star
# with a peak in the middle is a cone with notches cut in it: the spikes get
# absorbed into one silhouette and the thing reads as a little hat. In the
# plate the middle dips, and each spike runs from that dip up and outward to a
# tip at the rim — which is what puts a hard ridge down every spike and a deep
# V between each pair. That is where "pointy" comes from.
#
# Under the star is a folded hull, narrowing to a small pentagon in the crater,
# which is what stands the whole thing up off the berry.
#
# Measured off `references/ingredients/bosbes.png`: about a third of the
# berry's width across, rising about 4 mm clear of its top.
DISH = 0.0178        # the pentagon the hull stands on, down in the crater
HUB_Z = 0.0192       # the low centre of the star
TIP_R, TIP_Z = 0.0042, 0.0224      # the five spikes: out, and well up
NOTCH_R, NOTCH_Z = 0.0026, 0.0196  # the V between each pair
HULL_R = 0.0024                    # the folded skirt's footprint


def build():
    lowpoly.clear("Bosbes")

    skin = lowpoly.material("BosbesSkin", 0x9BB2D2)   # Palette.berryBlueDeep
    pale = lowpoly.material("BosbesCalyx", 0xC2D2E8)  # Palette.berryBlue

    body = lowpoly.flat_obj("BosbesBody", lowpoly.tube(BODY, N), skin)

    bm = bmesh.new()
    hub = bm.verts.new((0, 0, HUB_Z))
    tips, notches, hull = [], [], []
    for i in range(5):
        a = 2 * math.pi * i / 5 + math.pi / 2
        b = a + math.pi / 5
        tips.append(bm.verts.new((math.cos(a) * TIP_R, math.sin(a) * TIP_R, TIP_Z)))
        notches.append(bm.verts.new((math.cos(b) * NOTCH_R, math.sin(b) * NOTCH_R, NOTCH_Z)))
        hull.append(bm.verts.new((math.cos(b) * HULL_R, math.sin(b) * HULL_R, DISH)))

    for i in range(5):
        # The star itself: two faces per spike, meeting on the ridge that runs
        # from the hub out to the tip.
        bm.faces.new((hub, notches[i], tips[i]))
        bm.faces.new((hub, tips[i], notches[(i - 1) % 5]))
        # The hull under it, folding in to the pentagon it stands on.
        bm.faces.new((notches[(i - 1) % 5], tips[i], hull[(i - 1) % 5]))
        bm.faces.new((tips[i], notches[i], hull[i]))
        bm.faces.new((tips[i], hull[i], hull[(i - 1) % 5]))
    bm.faces.new(hull)   # closed underneath: she sees it from every side
    bm.normal_update()
    crown = lowpoly.flat_obj("BosbesCrown", bm, pale)

    root = bpy.data.objects.new("Bosbes", None)
    root.empty_display_size = 0.01
    bpy.context.collection.objects.link(root)
    body.parent = root
    crown.parent = root

    # **The one piece of ambient occlusion in the game**, and the reason it is
    # here: once the crown stands up rather than lying folded on the berry, the
    # two shapes stop being one silhouette, and nothing tells you they touch.
    # The facets cannot do this job — the crater floor and the crown's underside
    # face the same way as everything around them, so they come back the same
    # tone. `bake_ao_facets` measures the occlusion and splits the faces that
    # are actually in the crevice into `BosbesBodyShade1` / `BosbesCrownShade1`,
    # which `ModelLibrary` paints a step darker.
    #
    # 5 mm of reach: this is contact shading where two parts meet, not the
    # all-over darkening `references/REFERENCES.md` rejected.
    shades = lowpoly.bake_ao_facets([body, crown], distance=0.0022,
                                    thresholds=(0.18, 0.40))

    return [root, body, crown] + shades


if __name__ == "__main__":
    objects = build()
    lowpoly.export_usdz(objects, USDZ)
    if "--no-save" not in sys.argv:
        bpy.ops.wm.save_as_mainfile(filepath=BLEND)
