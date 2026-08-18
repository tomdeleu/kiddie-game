"""De box — one cabinet of Het Feest's speaker stacks.

    blender --background --python models/speaker.py

Reference: `references/feest/boxen.png`. Writes
`app/NinaBakeryPOC/Resources/Models/speaker.usdz`.

**One cabinet, and the room stacks two of it** — which is what the plate draws
and what `FeestProps.speakers` already builds. There are two stacks in the room,
one in each back corner (owner, 2026-08-17), so this file is loaded four times.

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

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import feest

NAME = "Box"

# **Measured off `boxen.png`, not transcribed from `FeestProps.speakers`.**
#
# The code cabinet is 44 wide × 38 tall, i.e. wider than it is tall (1.16). Every
# cabinet in the plate is the other way round — 230 px across a 355 px front face,
# a ratio of **0.65** — and a squat box with a small driver on it is most of why
# the built speaker "looks very flat" and unlike the plate.
#
# Taken literally the plate gives a 68 mm-tall cabinet, and two of those stacked
# would stand 136 mm against a 102 mm guest, which is a tower rather than a
# speaker in a corner. 48 mm is the compromise: a ratio of 0.87, much nearer the
# plate than 1.16, and a stack that comes to about a guest's height.
#
# `FeestProps.speakers` follows these when the Swift side is wired up.
HALF_X = 0.042 / 2
HALF_Y = 0.030 / 2
HEIGHT = 0.048
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
DRIVERS = [(0.0158, 0.0180), (0.0058, 0.0396)]


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
        cap base     0.36      overhanging a 0.26 throat
        cap apex     +0.08     proud of the baffle, just under the rim
    """
    r = radius
    cone = feest.lathe(name, material, [
        (r * 0.97, 0.0),          # the boss's foot, on the baffle
        (r * 1.00, r * 0.07),     # its outer wall, flaring a little
        (r * 0.95, r * 0.13),     # the rim's outer edge
        (r * 0.86, r * 0.13),     # the flat rim band — a narrow lip, not a collar
        (r * 0.62, r * 0.02),     # the cone, falling back
        (r * 0.30, -r * 0.20),    # a narrow throat, so the cap overhangs it
        (r * 0.29, -r * 0.22),    # and a floor, so it is not a hole
    ], 14)
    # The dome, standing on the throat and reaching back out past the baffle.
    # Its apex stops short of the rim so the rim's inner edge still crosses in
    # front of it, which is how the plate reads and is what keeps the cone deep.
    # **An egg nested in the cone, reaching almost to the rim.**
    #
    # Three shapes have been tried here and only the third is the plate. A tall
    # narrow spire is invisible — the cone is wider than it everywhere but the
    # throat, so only its tip shows. A flat hemisphere sunk on the throat is the
    # bump this had until now, which reads as a dimple rather than a cap. What
    # `boxen.png` draws, measured on the crop, is:
    #
    #     cap width    0.36 r    = 42% of the cone's mouth
    #     cap height   0.46 r    taller than half its width — an egg, not a dish
    #     apex         +0.08 r   proud of the baffle, just shy of the rim
    #
    # And its base is **wider than the throat it stands on**, so it overhangs.
    # That overhang is the hard dark ring the plate draws all round the cap, and
    # it is real geometry rather than a painted line: the bake finds it because
    # the cone's floor is genuinely tucked under the egg.
    #
    # **The cone is shallow on purpose, and that is the last thing this prop
    # taught.** Built 0.35 r deep, the cap measured the right size and still
    # rendered at a third of it — because a deep funnel *hides the bottom of
    # whatever is in it*. The room's camera is 42° off the baffle normal, so the
    # near wall covers 0.9 × its own depth of the floor, and at 0.35 r that ate
    # the widest part of the egg and left only its narrow tip showing. At 0.22 r
    # the whole cap clears the near wall. The plate's funnel is shallow for the
    # same reason; what makes it *look* deep is the 42° view and the shading.
    dome = feest.lathe(name + "Dop", material, [
        (r * 0.36, -r * 0.22),
        (r * 0.355, -r * 0.15),
        (r * 0.33, -r * 0.07),
        (r * 0.27, 0.0),
        (r * 0.18, r * 0.06),
        (0.0, r * 0.10),
    ], 14)
    return [cone, dome]


def build():
    coat = feest.material("BoxCoat", feest.SANDY_WOOD)
    parts = []

    # The cabinet: chamfered on the verticals by the section, and on the top and
    # bottom rims by pulling the section in at the first and last station.
    pull = 0.0026
    parts.append(feest.octa_column("BoxKast", coat, [
        (HALF_X - pull, HALF_Y - pull, CHAMFER, 0.0),
        (HALF_X, HALF_Y, CHAMFER, pull),
        (HALF_X, HALF_Y, CHAMFER, HEIGHT - pull),
        (HALF_X - pull, HALF_Y - pull, CHAMFER, HEIGHT),
    ]))

    # The drivers. Built on the axis and then turned to look out of the baffle:
    # a +90° turn about X sends the lathe's +Z to −Y, which is out towards the
    # camera. The negative turn points them into the cabinet, where they are
    # invisible rather than obviously wrong — the beak's mistake in
    # `GuestCharacter`, and the harder one to spot.
    for i, (radius, z) in enumerate(DRIVERS):
        # Turned to look out of the baffle: a +90° turn about X sends +Z to −Y,
        # which is out towards the camera. The negative turn points them into the
        # cabinet, where they are invisible rather than obviously wrong.
        for ob in driver("BoxConus%d" % i, coat, radius):
            ob.rotation_euler = (math.pi / 2, 0.0, 0.0)
            feest.animated(ob, (0.0, BAFFLE + SINK, z))
            parts.append(ob)

    return parts


def main():
    feest.fresh(NAME, "Box")
    parts = build()

    corners = [ob.matrix_world @ v.co for ob in parts for v in ob.data.vertices]
    feest.check(max(p.z for p in corners) <= HEIGHT + 1e-6,
                "the cabinet is taller than the 38 mm the room stacks")
    feest.check(max(abs(p.x) for p in corners) <= HALF_X + 1e-6,
                "the cabinet is wider than the 44 mm the room stacks")

    # **2.5 mm, against a cone 7 mm deep and a chamfer 4 mm across.** The rule is
    # the tree's (`models/README.md`): the distance is chosen against the facet
    # the shading has to sit inside, not against the prop. Reach further and the
    # chamfer strips — which are 4 mm of a 44 mm box — tip over the threshold
    # whole, and a cabinet with every edge darkened is a cabinet painted brown.
    # **The cabinet is shaded; the drivers cast but are never darkened.**
    #
    # Baked at 2.5 mm the woofer came back with 33 of its 40 faces on `Shade2`
    # and the tweeter with 61 of 73 — a cone is concave, so nearly every face on
    # it is within 2.5 mm of another face on it, and the honest measurement is
    # "all of it". That is `models/README.md`'s rule pointing straight at this
    # prop: *a part shaded uniformly is not shaded at all.* What it produced was
    # a driver painted a darker brown, with the dust cap — the brightest thing on
    # the cabinet in the plate — dark along with everything else.
    #
    # So the drivers get the honey pool's treatment (`garden.finish`'s `shade`):
    # they cast into the bake, and the chamfered cabinet receives it. The cone's
    # depth is then read from its facet normals, which is what the whole style is
    # for, and the dome stays the bright note it is in `boxen.png`.
    # **3 mm, chosen by trying three.** The bake is what supplies the cone's
    # tonal separation, because the room's own lighting cannot: the speakers
    # stand in the back corners with their baffles towards the camera and
    # `LightingSettings` puts the key at azimuth 135° — *behind* them — so their
    # fronts only ever see fill and the ambient dome.
    #
    #     1.5 mm   85 / 12 / 44   the cone barely separates from the rim
    #     3.0 mm   42 / 30 / 69   a real three-step gradient down the funnel
    #     4.5 mm   42 /  0 / 99   level 1 empties: the whole cone goes one tone,
    #                             which is the honey pot's failure again
    #
    # 3 mm keeps unshaded faces on the rim and the dome's front while the wall
    # falls away in two steps, which is what `boxen.png` shows.
    # **The domes cast but are never darkened.** They are the bright note of the
    # prop and the reason the driver reads at all; shaded along with the cone
    # they vanish into it, which is what the split in `driver` exists to prevent.
    shade = [ob for ob in parts if not ob.name.endswith("Dop")]
    objects = feest.finish(NAME, parts, distance=0.0030, shade=shade)
    for ob in objects:
        if ob.type == 'MESH':
            print("  %-22s %3d faces" % (ob.name, len(ob.data.polygons)))
    feest.write(objects, "speaker")


if __name__ == "__main__":
    main()
