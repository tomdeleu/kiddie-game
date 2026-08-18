"""De boxen — one complete two-cabinet speaker stack for Het Feest.

    blender --background --python models/speaker.py

Reference: `references/feest/boxen.png`. Writes
`app/NinaBakeryPOC/Resources/Models/speaker.usdz`.

**Both cabinets are in one asset.** The first model contained one cabinet and
`FeestProps` stacked two copies at runtime. That made the geometry look right but
made its AO blind to the strongest contact in `boxen.png`: the dark seam where
the lilac upper cabinet stands over the peach lower one. One full-stack USDZ lets
the same bake see cabinet-to-cabinet and driver-to-baffle contact. There are two
identical stacks in the room, one in each back corner.

Two things the plate has that the code version could not say, and they are the
only two:

  * **Every edge is chamfered.** Not just the four vertical ones — the top and
    bottom rims are cut as well, and on a pastel box under even lighting that
    cut is the entire difference between a loudspeaker and a cardboard carton.
    A box has two visible faces from this camera and both are flat; a chamfered
    box has five, and the narrow ones catch a tone of their own. It is the
    fence's chamfered picket argument (`models/README.md`) on a much bigger
    facet.
  * **A driver is a hole, not a disc.** `FeestProps.speakers` builds a tapered
    prism lying on the baffle with a ball stuck to it, which reads as a knob on
    a plate. In the plate the cone is **recessed**: a rim standing proud, a wall
    falling away behind it, and a dust cap rising back out of the middle. The
    wall is the one genuine crevice in this whole room, and it is what the bake
    is for — in the plate the far side of each cone is a full tone down on a
    cabinet that is otherwise one colour.

## The whole cabinet is one colour, and that is the plate

Both speakers in `boxen.png` are monochrome: the cone, the surround and the dust
cap are all the cabinet's own tone, and every bit of shape on them is read from
form and contact shading alone. The code version paints the cone `creamLight` and
the cap `woodBrown` against a `sandyWood` box — three colours doing the job that
one colour plus a real recess does better, and it is the clover's lesson exactly
(`models/README.md`): *a tint standing in for a shape.*

## The drivers carry their position on the object

`FeestRoom` pushes them out on the beat with `cone.scale = [1, 1, push]`, so each
one goes on `ModelLibrary.pivot` — and a part whose placement is baked into its
vertices reports a position of zero, which would put the holder on the cabinet's
foot and stretch the cone away from *that* instead of out of its own baffle.
`feest.animated` has the argument and `models/scale.py` is the precedent.
"""

import math
import os
import sys

import bpy
import bmesh
import mathutils

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import feest
import garden
import lowpoly

NAME = "Box"

# **Measured off `boxen.png`, not transcribed from `FeestProps.speakers`.**
#
# The code cabinet is 44 wide × 38 tall, i.e. wider than it is tall (1.16). Every
# cabinet in the plate is the other way round — 230 px across a 355 px front face,
# a ratio of **0.65** — and a squat box with a small driver on it is most of why
# the built speaker "looks very flat" and unlike the plate.
#
# Taken literally the plate gives a 68 mm-tall cabinet. 56 mm keeps the plate's
# tall silhouette while putting the 114 mm stack only just above a 102 mm guest.
#
# `FeestProps.speakers` follows these when the Swift side is wired up.
HALF_X = 0.042 / 2
HALF_Y = 0.030 / 2
HEIGHT = 0.056
STACK_GAP = 0.002
CHAMFER = 0.0042

#: Blender +Y is the game's −Z, so the baffle — the face the drivers are in —
#: looks out at −Y, towards the camera.
BAFFLE = -HALF_Y

#: **How far a driver's foot is sunk into the cabinet.**
#:
#: 0.4 mm, and it is now only enough to break the coplanar tie described below —
#: **not** enough to bury the driver. The first four builds sank it 1.2 mm and
#: hid the boss the plate is built around; see `driver`.
#:
#: A driver's profile starts with a disc across its own full radius, which seals
#: it shut at the back. Mounted flush, that disc is exactly coplanar with the
#: baffle — and a coplanar pair renders as **black**, which is what the first
#: render came back with: two holes straight through into the sealed cabinet.
#:
#: It is the third time this bug has been built in this room, after the booth's
#: front panel and the rail's end blocks, so it is worth stating as a rule rather
#: than as a note: **two faces in the same plane are never a join.** Sinking the
#: driver 1.2 mm puts its back disc inside the cabinet where nothing can see it
#: and still leaves the surround standing 1 mm proud of the baffle.
SINK = 0.0004

#: `(outer radius, height up the cabinet)`.
#:
#: **The woofer is 76% of the baffle's width**, measured off the plate, where the
#: code version made it 55%. That single number is most of the difference between
#: a loudspeaker and a box with a button on it: in `boxen.png` the driver nearly
#: fills the front, leaving only a narrow margin either side, and the tweeter
#: sits in the gap above it almost touching.
DRIVERS = [(0.0158, 0.0210), (0.0058, 0.0460)]


def driver(name, material, radius):
    """One loudspeaker driver: **a boss with a cone, and a dome capping it.**

    Returns **two objects**, and that split is what finally made the cap read.

    Built as one continuous lathe — cone and dome in a single profile — the dome
    is geometrically present and visually absent, because the occlusion bake
    cannot tell the two apart. A cone is concave, so the bake darkens it; the
    dome sits inside that same mesh and gets darkened with it, and a dome the
    same tone as the funnel it stands in has nothing to be seen against. In the
    game the woofer came back as a raised ring with a flat middle (owner,
    2026-08-18: *"you're missing the center cone of the woofer"*).

    Splitting the dome into `…Dop` lets `main` hand the cone to the bake and keep
    the dome out of it, so the cone falls two steps darker and the dome stays at
    the coat's own colour. That is exactly the honey pool's rule
    (`models/README.md`): **the bright note of a prop casts but is never
    shaded** — and it is what `boxen.png` shows, where the dome is the lightest
    thing on the cabinet.

    The dome's base is deliberately **wider than the throat it stands on**, so it
    overhangs. That overhang is a real crease for the bake to find and it is what
    draws the dark ring round the cap in the plate.

    Numbers, in units of the outer radius, measured off a 3× crop of the plate:

        cone mouth   0.86      the rim's inner edge
        cap radius   0.32      a small faceted sphere
        cap centre  -0.10      inside the funnel; front reaches +0.22
    """
    r = radius
    cone = feest.lathe(name, material, [
        (r * 0.97, 0.0),          # the boss's foot, on the baffle
        (r * 1.00, r * 0.07),     # its outer wall, flaring a little
        (r * 0.95, r * 0.13),     # the rim's outer edge
        (r * 0.86, r * 0.13),     # the flat rim band — a narrow lip, not a collar
        (r * 0.62, r * 0.02),     # the cone, beginning its long fall
        (r * 0.30, -r * 0.52),    # a genuinely deep narrow throat
        (r * 0.29, -r * 0.54),    # and a floor, so it is not a hole
    ], 14)
    # The dust cap is a **small faceted sphere**, not another lathe. The long
    # egg profiles repeatedly collapsed into a broad pale disc at the game
    # camera — exactly the failure visible in the owner's simulator crop. A
    # 0.32 r icosphere centred 0.10 r behind the baffle leaves most of the 0.54 r
    # funnel visible, while its front reaches +0.22 r. Subdivision 2 gives eighty
    # broad triangular facets: round enough to read at room scale, still visibly
    # low-poly in a close-up.
    dome = feest.balls(
        name + "Dop", material,
        [(r * 0.32, (0.0, 0.0, -r * 0.10))],
        subdivisions=2)
    return [cone, dome]


def _cut_driver_holes(cabinet, z0):
    """Cut real circular openings through the cabinet's front baffle.

    The first five speaker passes put recessed cone geometry *behind a complete
    cabinet face*. That face won the depth test and covered the funnel, so every
    screenshot still showed a flat disc however deep the cone profile became.
    These two short 14-sided cylinders remove only the front 13 mm of the box:
    enough to expose each cone, while leaving the rear cabinet wall intact.
    """
    cutters = bmesh.new()
    for radius, z in DRIVERS:
        transform = (
            mathutils.Matrix.Translation((0.0, -0.0090, z0 + z))
            @ mathutils.Matrix.Rotation(math.pi / 2, 4, "X")
        )
        bmesh.ops.create_cone(
            cutters, cap_ends=True, cap_tris=False, segments=14,
            radius1=radius * 0.82, radius2=radius * 0.82,
            depth=0.0130, matrix=transform)
    cutters.normal_update()
    cutter = lowpoly.flat_obj("BoxBaffleCutters", cutters, cabinet.data.materials[0])

    boolean = cabinet.modifiers.new("DriverHoles", "BOOLEAN")
    boolean.operation = "DIFFERENCE"
    boolean.solver = "EXACT"
    boolean.object = cutter
    lowpoly.apply_modifiers(cabinet)
    bpy.data.objects.remove(cutter, do_unlink=True)
    return cabinet


def _cabinet(prefix, coat, z0):
    """One plate cabinet, positioned inside the full-stack asset."""
    parts = []

    # The cabinet: chamfered on the verticals by the section, and on the top and
    # bottom rims by pulling the section in at the first and last station.
    pull = 0.0026
    cabinet = feest.octa_column(prefix + "Kast", coat, [
        (HALF_X - pull, HALF_Y - pull, CHAMFER, z0),
        (HALF_X, HALF_Y, CHAMFER, z0 + pull),
        (HALF_X, HALF_Y, CHAMFER, z0 + HEIGHT - pull),
        (HALF_X - pull, HALF_Y - pull, CHAMFER, z0 + HEIGHT),
    ])
    parts.append(_cut_driver_holes(cabinet, z0))

    # The drivers. Built on the axis and then turned to look out of the baffle:
    # a +90° turn about X sends the lathe's +Z to −Y, which is out towards the
    # camera. The negative turn points them into the cabinet, where they are
    # invisible rather than obviously wrong — the beak's mistake in
    # `GuestCharacter`, and the harder one to spot.
    for i, (radius, z) in enumerate(DRIVERS):
        # Turned to look out of the baffle: a +90° turn about X sends +Z to −Y,
        # which is out towards the camera. The negative turn points them into the
        # cabinet, where they are invisible rather than obviously wrong.
        for ob in driver("%sConus%d" % (prefix, i), coat, radius):
            ob.rotation_euler = (math.pi / 2, 0.0, 0.0)
            feest.animated(ob, (0.0, BAFFLE + SINK, z0 + z))
            parts.append(ob)

    return parts


def build():
    lower = feest.material("BoxOnderCoat", feest.ROSE)
    upper = feest.material("BoxBovenCoat", feest.LILAC)
    return (_cabinet("BoxOnder", lower, 0.0)
            + _cabinet("BoxBoven", upper, HEIGHT + STACK_GAP))


def main():
    feest.fresh("Boxen", "Box")
    parts = build()

    corners = [ob.matrix_world @ v.co for ob in parts for v in ob.data.vertices]
    stack_height = HEIGHT * 2 + STACK_GAP
    feest.check(max(p.z for p in corners) <= stack_height + 1e-6,
                "the stack is taller than %.1f mm" % (stack_height * 1000))
    feest.check(max(abs(p.x) for p in corners) <= HALF_X + 1e-6,
                "the cabinet is wider than the 42 mm the room stacks")

    # **30 mm, 0.35 strength and four rungs.** The room-wide ten-rung ramp was
    # needed before the baffle had holes; after the boolean cut it turned the
    # exposed cone nearly black. Real depth now does most of the work and this
    # gentler ramp carries the cabinet hue through the recess like the plate.
    #
    # Only the cone walls receive the ramp. The boolean-cut baffle is one large
    # n-gon whose centre lies over a dark opening; face-centre AO therefore
    # classified the *entire cabinet front* as Shade10 and turned it black in the
    # simulator. Cabinets and domes still cast into the cones, but remain at
    # their palette colours.
    shade = [ob for ob in parts
             if "Conus" in ob.name and not ob.name.endswith("Dop")]
    # The actual holes now provide the depth cue; Het Feest's full 0.80/ten-step
    # ramp turned the exposed cone walls almost black. The plate keeps their
    # cabinet hue, so speakers use the measured gentler end of the study range.
    objects = garden.finish(
        "Boxen", parts, distance=feest.AO_REACH, shade=shade,
        ramp_strength=0.35, ramp_levels=4)
    for ob in objects:
        if ob.type == 'MESH':
            print("  %-22s %3d faces" % (ob.name, len(ob.data.polygons)))
    feest.write(objects, "speaker")


if __name__ == "__main__":
    main()
