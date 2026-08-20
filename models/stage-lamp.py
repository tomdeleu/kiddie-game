"""De lamp — one fitting off Het Feest's lichtrek.

    blender --background --python models/stage-lamp.py

Reference: `references/feest/lichtrek.png`. Writes
`app/NinaBakeryPOC/Resources/Models/stage-lamp.usdz`.

The code version is a tapered prism with a disc on the end. The plate draws a
**stage lantern**: a clamp gripping the bar with a little flag on top, a yoke
dropping either side to a hexagonal pivot bolt, a barrel that widens towards the
front, a rim standing proud of it, and a bright lens sunk behind the rim. Five
things, and the code has one of them.

## Which way it points, and why nothing here is turned twice

`FeestProps.lamp` aims a fitting by rotating its root so that **local −Y** runs
down the line to whatever it is lit at, and then turns the housing a further π
about X because the code lathe stands on +Y. A model does not need that second
turn: it is built pointing the right way in the first place.

Blender +Z is the game's +Y, so the lamp is modelled looking **down −Z** — clamp
at the top, lens at the bottom — and the wrapper's −Y is then exactly the barrel's
axis. The room's existing aim rotation does the rest, unchanged.

## The whole fitting turns together, clamp included — and that was tried the
## other way first

The three back lamps aim from (x, 0.190, −0.206) at the middle of the floor,
which is **44° off vertical**, so what happens to the clamp is a real question
rather than a detail.

The obvious answer is the ironmongery: a clamp that stays square on the bar, and
a barrel that pivots inside its yoke. It was built that way and it does not
survive contact with how the room aims a lamp. A real lantern's body turns about
**the bolt axis** — one horizontal line through the two pivots — and
`FeestProps.lamp` turns a fitting with `simd_quatf(from: [0, -1, 0], to: down)`,
which is a general rotation about whatever axis gets −Y onto the aim line. Under a
general rotation every point of the yoke that is not on the rotation centre
moves, so a fixed clamp and a turning yoke come apart: at 44° the arms swing about
10 mm out from under a clamp 21 mm wide, and the gap is bigger than the clamp.

So the fitting is one rigid part and it hangs at whatever angle it is aimed. That
is not a compromise so much as the other true thing about stage lighting: a
lantern on a hook clamp really does hang tilted, and five of them angled at the
floor is what a lighting bar looks like. The rejected version cost one render and
is recorded here so it is not attempted a third time.

## Everything hangs below the bar line

Local z = 0 is **the bar**, because `FeestProps.lamp` puts the fitting's origin at
exactly the bar's own position. The first build ignored that and centred the
barrel on the origin, which put the clamp 9 mm above a bar it was supposed to be
gripping and left the jaw closed round nothing. The clamp now straddles z = 0 and
the barrel hangs 27 mm under it, which is the plate's proportion.

## The lens carries its position on the object

`FeestRoom` squashes it on every beat (`ticker.squash(lamp.lens, …)`), which
scales the entity about its own origin. `feest.animated` has the argument for why
that has to be an object transform rather than baked geometry.
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import feest

NAME = "Lamp"

#: `FeestProps.lamp`'s housing, transcribed: 21 mm across the front, 13.6 at the
#: back, 14 long. The lens is 18.4 mm across.
FRONT_RADIUS = 0.0105
BACK_RADIUS = 0.0068
BARREL = 0.014
LENS_RADIUS = 0.0092

#: The bar's own radius, so the clamp's jaw actually fits round it.
BAR_RADIUS = 0.0030


#: Where the barrel's back ring sits, below the bar. Everything else follows.
#:
#: **Every joint below interpenetrates by `BITE`, and none of them merely
#: touches.** That is the rule this prop paid three renders to establish, and it
#: is the opposite of what the first two attempts assumed.
#:
#: A face parity test over the assembled lantern found twelve faces at exactly
#: the joints — the crossbar's end caps, the arms' top faces, the clamp's
#: underside, both bolt base discs — and every one of them was **coincident with
#: a face of the part it butts against**: same plane, same place, opposite
#: normals. Two coincident faces are a depth tie the renderer has to break
#: arbitrarily, and Cycles broke it as the black blotches the render kept coming
#: back with.
#:
#: It was diagnosed twice as a winding problem and it never was one. Overlap the
#: parts by a fraction of a millimetre and the tie cannot arise: the buried face
#: is then unambiguously inside a solid, which is a question depth testing can
#: answer.
#:
#: The same fault, in the same room: the booth's front panel sitting flush in the
#: cabinet face, and the booth's rail sharing its underside with its end blocks,
#: and the speaker's driver disc lying in the plane of the baffle. All three were
#: fixed by separating them, which is this rule arrived at one prop at a time.
HANG = 0.0052

#: How far one part is pushed into the next. Small enough to be invisible on a
#: 21 mm lantern, large enough to be far outside floating-point noise.
BITE = 0.0004
#: The front of the rim, and therefore the lens.
NOSE = HANG + BARREL + 0.0034
#: How far out the yoke's arms stand. Wide enough to clear the barrel's widest
#: point at the height the bolts sit, checked in `main`.
ARM_X = 0.0118
BOLT_Z = -0.0128
#: Where the yoke's crossbar meets the clamp above it and the arms below it.
YOKE_TOP = -0.0006
YOKE_BOTTOM = -0.0034


def build():
    shell = feest.material("LampShell", feest.BLUSH_PINK)
    lens_material = feest.material("LampLensGlas", feest.BUTTER_YELLOW)
    parts = []

    # ------------------------------------------------------------- the barrel
    # One lathe, front to back: the rim's front face, the rim, the barrel
    # widening from back to front, and a faceted point closing the back. Read the
    # z values as "distance below the bar", since the lamp looks down −Z.
    barrel = feest.lathe("LampVat", shell, [
        (LENS_RADIUS, -NOSE),                       # behind the lens, sealing it
        (FRONT_RADIUS + 0.0018, -NOSE),             # rim, front face
        (FRONT_RADIUS + 0.0018, -NOSE + 0.0018),    # rim, outer
        (FRONT_RADIUS, -NOSE + 0.0034),             # barrel, front
        (BACK_RADIUS, -HANG - 0.0018),              # barrel, back
        (BACK_RADIUS, -HANG),
        (0.0, -HANG + 0.0022),                      # a faceted point on the back
    ], 10)

    # ---------------------------------------------------------------- the yoke
    # A crossbar under the clamp and two arms down the sides to a hexagonal bolt
    # each, which is the join the plate makes most of. The arms stop where the
    # bolt is, so the bolt reads as a hinge rather than as a stud on the barrel.
    # Crossbar and arms meet edge to edge at `YOKE_BOTTOM`; neither reaches the
    # barrel.
    #
    # **Each piece is its own `boxes` call.** They interpenetrate, and
    # `garden.boxes` recalculates the winding of everything it is handed in one
    # go — which is a question with no answer once two of its boxes share a
    # volume. Built separately each call sees only disjoint boxes, and
    # `feest.join` then merges them without recalculating.
    # **Its ends stop short of the arms' outer faces**, which is `BITE` applied
    # across X as well as up Z. Run out to the same ±(ARM_X + 1.6 mm) as the arms
    # and the crossbar's end cap is exactly coplanar and coincident with the
    # arm's outer face — a depth tie with no answer, which Cycles resolved as two
    # black hexagons and which the Workbench render hid behind its depth bias.
    # That is why this was diagnosed three times as a winding problem: the
    # rasteriser said the model was fine and it was, and the tie is still a fault.
    crossbar = feest.boxes("LampJukBalk", shell, [
        ((-ARM_X - 0.0016 + BITE, ARM_X + 0.0016 - BITE), (-0.0016, 0.0016),
         (YOKE_BOTTOM, YOKE_TOP))])
    arms = feest.boxes("LampJukArm", shell, [
        # Stopping **inside** the crossbar rather than level with its top, and
        # standing 0.3 mm proud of it front and back. Both are the same
        # coincident-face tie, on the two axes the first fix did not cover: an
        # arm run to `YOKE_TOP` shares the crossbar's top plane, and an arm the
        # crossbar's own 3.2 mm thickness shares both of its side planes.
        #
        # **The lesson is that the tie has to be broken on every axis the two
        # parts share, not just the obvious one.** It took three rebuilds here,
        # each one shrinking the black patch rather than removing it, which is
        # exactly what a partly-fixed coincidence looks like.
        ((sx * ARM_X - 0.0016, sx * ARM_X + 0.0016), (-0.0019, 0.0019),
         (BOLT_Z, YOKE_TOP - BITE))
        for sx in (-1, 1)])
    # **Each bolt bites into its own arm and points outwards.** Written with one
    # rotation for both, the left-hand bolt extends along +X — which is straight
    # into its own arm and out the far side of the lamp.
    bolts = [feest.lathe("LampBout%d" % i, shell,
                         [(0.0026, 0.0), (0.0026, 0.0026)], 6,
                         at=(sx * (ARM_X + 0.0016 - BITE), 0.0, BOLT_Z),
                         rot=(0.0, sx * math.pi / 2, 0.0))
             for i, sx in enumerate((-1, 1))]

    # --------------------------------------------------------------- the clamp
    # A jaw straddling the bar — local z = 0 **is** the bar — biting down over
    # the crossbar, and the little flag the plate puts on top of every one of the
    # three.
    jaw = feest.boxes("LampKaakBlok", shell, [
        ((-0.0054, 0.0054), (-0.0054, 0.0054), (YOKE_TOP - BITE, 0.0044))])
    flag = feest.boxes("LampKaakVlag", shell, [
        ((-0.0024, 0.0024), (-0.0034, 0.0034), (0.0044 - BITE, 0.0082))])

    parts.append(feest.join("LampHuis", shell,
                            [barrel, crossbar, arms, jaw, flag] + bolts))

    # --------------------------------------------------------------- the lens
    # Sunk 1.6 mm behind the rim's front face, which is what makes it a lens in a
    # lantern rather than a coloured disc stuck on the end. It never sits flush:
    # the booth's panel, the booth's rail and the speaker's baffle between them
    # cost three renders learning that two faces in one plane are not a join.
    lens = feest.lathe("LampLens", lens_material,
                       [(LENS_RADIUS, 0.0), (LENS_RADIUS, 0.0018)], 10)
    feest.animated(lens, (0.0, 0.0, -NOSE + 0.0016))
    parts.append(lens)

    return parts


def main():
    feest.fresh(NAME, "Lamp")
    parts = build()

    corners = [ob.matrix_world @ v.co for ob in parts for v in ob.data.vertices]
    reach = max(abs(p.x) for p in corners)
    feest.check(reach <= 0.016,
                "the lamp is %.4f m across — five of them are 110 mm apart" % reach)
    feest.check(abs(min(p.z for p in corners) + NOSE) < 1e-6,
                "the barrel's nose is not where the lens was put")
    feest.check(max(p.z for p in corners) > 0,
                "nothing reaches above the bar — the clamp is not gripping it")

    # **The arms have to clear the barrel at the height the bolts sit**, which is
    # the one number here that a nudge to the taper could quietly break — and the
    # failure is an arm buried in the barrel, i.e. the intersecting shells that
    # blacked this prop out once already.
    t = (abs(BOLT_Z) - HANG) / BARREL
    at_bolt = BACK_RADIUS + t * (FRONT_RADIUS - BACK_RADIUS)
    feest.check(ARM_X - 0.0016 > at_bolt,
                "the yoke arms are inside the barrel: %.4f against %.4f"
                % (ARM_X - 0.0016, at_bolt))

    # The 30 mm room-study reach now shades the yoke against the barrel and the
    # clamp against the bar as broad forms. Ten rungs replace the old two hard
    # thresholds, so the 14 mm barrel band does not simply flip one tone.
    #
    # **The lens casts but is never shaded.** It is the thing the prop is *for*,
    # it sits down a well with a rim all round it, and it measures as almost
    # fully occluded — correct as physics and wrong as a lamp. `shade` is
    # `garden.finish`'s way of saying so, and the honey pool is the case that
    # wanted it first.
    shade = [ob for ob in parts if ob.name != "LampLens"]
    objects = feest.finish(NAME, parts, shade=shade)
    for ob in objects:
        if ob.type == 'MESH':
            print("  %-22s %3d faces" % (ob.name, len(ob.data.polygons)))
    feest.write(objects, "stage-lamp")


if __name__ == "__main__":
    main()
