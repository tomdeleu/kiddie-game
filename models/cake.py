"""The cake, modelled in Blender.

    blender --background --python models/cake.py

Reference: `references/props/cake.png`. Writes
`app/NinaBakeryPOC/Resources/Models/cake.usdz`. Shared rules and export
settings are in `lowpoly.py`; `models/README.md` has the why.

**This is the payoff object.** It is what the round is for, it is what goes up
on the plank, and it is what ends up in a frame on the wall. The code version
is three plain prisms and a ball: a stack of coloured discs, correct and
completely unceremonious.

The plate names the three things that turn a stack into a cake, and none of
them is a profile a lathe can spin:

  * **Icing that drips over the edge.** A scalloped skirt hanging off each
    tier's top, dipping between the corners. It is the single most cake-like
    thing in the picture.
  * **A ring of pearls** round each tier, sitting where the tier above meets
    the one below.
  * **A cherry with a stem**, which the code version has as a bare ball.

**Everything the round varies still varies**, which is the constraint this
model is built to:

  * The three tiers keep their own names, so `CakeSpec.tierColours` still
    paints them one, two or three colours through `ModelLibrary`'s tint map.
  * The icing, the pearls and the cherry are separate meshes, so they stay
    cream and rose whatever the tiers do.
  * `isTall` is a Y-scale on the upright wrapper — the same 1.5 the code
    version applies to each tier's height.
  * `glows` swaps the material function, not the mesh.

Radii and heights are the code version's, unchanged: the plank, the frame and
the carry animation are all built against that envelope.
"""

import math
import os
import sys

import bmesh
import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lowpoly

BLEND = os.path.join(lowpoly.REPO, "models", "cake.blend")
USDZ = lowpoly.bundle_path("cake")

SIDES = 10                                   # as the code version, and the plate
RADII = [0.0260, 0.0210, 0.0150]
HEIGHTS = [0.0130, 0.0110, 0.0090]

DRIP_DROP = 0.0056      # how far the belly of a drip hangs down
DRIP_SHORT = 0.0026     # and how thick the icing band is between drips
DRIP_OUT = 0.0012       # how far the icing stands proud of the tier's side
DRIP_STEPS = 4          # segments per scallop. Three still reads as a sawtooth:
                        # the arc needs a short, a middle, a long and a middle.
PEARL = 0.0021          # radius of one pearl on the ring


def _drip(radius, top):
    """A scalloped skirt round a tier: an icing collar whose lower edge dips
    between the corners. The dip is the whole trick — a straight-edged band is
    a stripe of paint, and a band that dips is icing that ran."""
    bm = bmesh.new()
    outer = radius + DRIP_OUT
    n = SIDES * DRIP_STEPS
    top_ring, hem, inner = [], [], []
    for i in range(n):
        a = 2 * math.pi * i / n
        # One scallop per side of the tier, each a cosine arc rather than a
        # single alternating vertex: alternating gives a sawtooth, and icing
        # does not run in zigzags. Three segments is enough to curve.
        phase = (i % DRIP_STEPS) / DRIP_STEPS
        # `sin ** 0.6`, not a cosine ramp. A cosine puts the lowest point on a
        # single vertex, which is a V — icing hangs in tongues: a **round belly
        # and a narrow neck**. The fractional power fattens the bottom of the
        # arc and pinches the top.
        drop = DRIP_SHORT + (DRIP_DROP - DRIP_SHORT) * math.sin(math.pi * phase) ** 0.6
        top_ring.append(bm.verts.new((math.cos(a) * outer, math.sin(a) * outer, top)))
        hem.append(bm.verts.new((math.cos(a) * outer, math.sin(a) * outer, top - drop)))
        inner.append(bm.verts.new((math.cos(a) * radius, math.sin(a) * radius, top)))

    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((top_ring[i], top_ring[j], hem[j], hem[i]))   # the face of it
        bm.faces.new((inner[i], inner[j], top_ring[j], top_ring[i]))  # the flat top
        bm.faces.new((hem[i], hem[j], inner[j], inner[i]))         # and the underside
    bm.normal_update()
    return bm


def _pearls(bm, radius, z):
    """A ring of little faceted beads, tucked against the foot of the tier above.

    **Squashed, and six round rather than four.** A tall bead on a four-vertex
    equator is a pyramid, and a row of pyramids reads as spikes on a cake — the
    plate has soft blobs. Wider than it is tall, with six sides, it reads as a
    pearl at the 4 mm it is drawn at.
    """
    for i in range(SIDES):
        a = 2 * math.pi * (i + 0.5) / SIDES
        cx, cy = math.cos(a) * radius, math.sin(a) * radius
        top = bm.verts.new((cx, cy, z + PEARL * 0.62))
        bot = bm.verts.new((cx, cy, z - PEARL * 0.62))
        ring = [bm.verts.new((cx + math.cos(t) * PEARL, cy + math.sin(t) * PEARL, z))
                for t in (math.pi * k / 3 for k in range(6))]
        for k in range(6):
            m = (k + 1) % 6
            bm.faces.new((top, ring[k], ring[m]))
            bm.faces.new((bot, ring[m], ring[k]))
    return bm


def build():
    lowpoly.clear("Cake")

    icing = lowpoly.material("CakeIcing", 0xF2E6DC)    # Palette.creamLight
    sponge = lowpoly.material("CakeSponge", 0xFBD0CA)  # a stand-in: the round paints it
    fruit = lowpoly.material("CakeFruit", 0xEAB5AA)    # Palette.rose
    stalk_green = lowpoly.material("CakeStalk", 0x7E9A88)  # Palette.sageDeep

    parts = []
    z = 0.0
    drips = bmesh.new()
    pearls = bmesh.new()
    for tier in range(3):
        height = HEIGHTS[tier]
        top = z + height
        parts.append(lowpoly.flat_obj(
            "CakeTier%d" % tier,
            lowpoly.tube([(RADII[tier], z), (RADII[tier], top)], SIDES),
            sponge))

        # Icing on every tier, and pearls on the two that have a tier landing
        # on them — which is where the plate puts them.
        _merge(drips, _drip(RADII[tier], top))
        if tier < 2:
            # Against the foot of the tier above, which is where a piped ring of
            # pearls actually goes — out in the middle of the ledge they read as
            # scattered sweets.
            _pearls(pearls, RADII[tier + 1] + PEARL * 0.95, top + PEARL * 0.55)
        z = top

    drips.normal_update()
    parts.append(lowpoly.flat_obj("CakeIcing", drips, icing))
    pearls.normal_update()
    parts.append(lowpoly.flat_obj("CakePearls", pearls, icing))

    # The cherry, and the stem the code version never had. It is what makes the
    # cake read as a cake at thumbnail size, which is the size it spends most of
    # its life at: on the plank, and in a frame on the wall.
    cherry = lowpoly.tube([(0.0018, z + 0.0006), (0.0042, z + 0.0022),
                           (0.0050, z + 0.0042), (0.0040, z + 0.0062),
                           (0.0018, z + 0.0074)], 8)
    parts.append(lowpoly.flat_obj("CakeCherry", cherry, fruit))
    stalk = bmesh.new()
    lowpoly.add_box(stalk, (-0.0005, 0.0005), (-0.0005, 0.0005),
                    (z + 0.0070, z + 0.0110))
    stalk.normal_update()
    parts.append(lowpoly.flat_obj("CakeStalk", stalk, stalk_green))

    root = bpy.data.objects.new("Cake", None)
    root.empty_display_size = 0.02
    bpy.context.collection.objects.link(root)
    for ob in parts:
        ob.parent = root

    # Contact shading under each icing skirt and between the pearls.
    #
    # **The tiers occlude but are never shaded.** They are repainted every round
    # from `CakeSpec.tierColours` — one, two or three colours, which is how
    # "rainbow" is visible at all — and a tier that came back a step darker
    # would read as a fourth colour nobody chose. The first bake did exactly
    # that: the top tier sits inside its own icing skirt, so 11 of its 12 faces
    # measured as occluded and the whole tier went dark.
    trimmings = [ob for ob in parts if not ob.name.startswith("CakeTier")]
    shades = lowpoly.bake_ao_facets(trimmings, distance=0.0022, occluders=parts)

    return [root] + parts + shades


def _merge(target, source):
    """Append one bmesh into another. `bmesh` has no join, and building the
    three skirts into one mesh keeps the cake at seven objects rather than ten.

    Keyed on the vertex itself rather than on `v.index`: a freshly built bmesh
    has not had its indices assigned, so every vertex would answer -1.
    """
    remap = {}
    for face in source.faces:
        verts = []
        for v in face.verts:
            if v not in remap:
                remap[v] = target.verts.new(v.co)
            verts.append(remap[v])
        target.faces.new(verts)
    source.free()
    return target


if __name__ == "__main__":
    objects = build()
    lowpoly.export_usdz(objects, USDZ)
    if "--no-save" not in sys.argv:
        bpy.ops.wm.save_as_mainfile(filepath=BLEND)
