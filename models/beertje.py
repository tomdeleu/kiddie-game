"""De beertjes — the friends dancing at Het Feest, one file per species.

    blender --background --python models/beertje.py            # all eleven
    blender --background --python models/beertje.py -- beer    # just one

References: `references/feest/beertje-solo.png` for the construction,
`references/feest/beertjes.png` for how the species differ. Writes
`app/NinaBakeryPOC/Resources/Models/beertje-<soort>.usdz`, eleven of them —
`GAMEPLAY.md` §4's whole cast, because the room deals six guests and a DJ out of
eleven friends and a friend with no head is not an option.

## What the rebuild takes from the plate

The first modelled pass preserved the procedural guest too literally. In the
room it still read as a generic barrel with a cluster of face parts: 46 mm head
against a 56 mm body, a cream panel wrapping almost the whole visible torso,
radial peg feet, and the same round skull under every species.

`beertjes.png` is the source of truth now, while the animation pivots and 62 mm
room footprint stay fixed. The head is 52 mm and nearly the body's width; the
belly is a bounded oval on the furry animals only; feet project forward; paws
have inset pads; the frog is wide and low; the bird is an upright egg with a
broad two-part bill; and the cat and dog carry the markings the lineup actually
uses to identify them.

Modelling also buys **the joins**, and there are four of them on every friend:

  * **The belly is a patch, not a ball.** `GuestCharacter` sticks a squashed
    icosphere onto the front of the barrel; on the plate the pale front is a
    panel that *belongs to* the body, and what says so is the shading where it
    meets the coat. Two surfaces both facing outwards come back the same tone —
    the clover's lesson, and here it is on the largest surface of the character.
  * **The head sits into the shoulders with no neck**, which is most of what
    makes these cute and is also a join no facet can shade: the underside of a
    26 mm head and the top of a barrel face the same way.
  * **The muzzle and the ears stand off the skull.** This is the blueberry's
    crown exactly (`models/README.md`): standing a shape up costs you the join,
    and only a measurement gets it back.
  * **The paw meets the arm**, and the arms are the parts held in the air.

All four are `bake_ao_facets` cases and none of them is reachable from Swift.

## The rig is unchanged, and the naming is what keeps it that way

`CONCEPT.md` §9.7 and `GuestCharacter`: one solid body, two legs pivoting at the
hip, arms welded on at a fixed pose, squash-and-stretch on the root. **Hands in
the air is a pose, not an animation** — so the arms are modelled pointing
straight up from the shoulder and the room turns them to whatever
`DanceStyle.raise` asks for, exactly as before.

Three groups of parts therefore have to be movable, and they carry their
placement as an **object transform** rather than baked into their vertices —
`feest.animated` has the argument, and `models/scale.py` is the precedent:

  * everything named `…Kop…` is the head, which nods and turns;
  * `…Arm0…` / `…Arm1…` are the arms, posed once at build time;
  * `…Been0…` / `…Been1…` are the legs, which swing from the hip.

**A name's first word is its colour.** `Coat…`, `Accent…`, `Cream…`, `Dark…`,
`Gold…` and `Rose…` are the six tints, so `ModelLibrary.load` paints eleven
different friends without species-specific Swift geometry. `Friend.colour` and
`Friend.accent` stay the only place each friend's coat colours are written down;
gold and rose are the bird's shared beak, crest and lower bill.

## Eleven files rather than one with eleven heads

A friend is one body with a swapped head — that is what `gasten.png` settled and
it is why eleven friends cost one builder. It would be tempting to ship one body
file and eleven head files. **The bake is what makes that wrong**: the head's
best shading is where it sinks into the shoulders, and a head measured on its own
has no shoulders to sink into. Each species is assembled whole, measured whole,
and written out whole.
"""

import math
import os
import bpy
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import feest

# ---------------------------------------------------------------- proportions
#
# **Measured off `references/feest/beertje-solo.png`, not transcribed from
# `GuestCharacter`** — and that is a deliberate break from the rest of this
# folder, where a model's job is to reproduce the code prop exactly.
#
# The first version did transcribe it, and the result was a blob: a head and a
# body of the same width, concentric, fused into one lump with ears on it. The
# numbers are why. In the plate the head is a **separate ball sitting on the
# shoulders** — it overlaps the body by about 3% of its own diameter — and the
# bear is roughly twice as tall as it is wide. The shipped rig puts the head's
# *centre* at the torso's top, so half the head is inside the body, and makes the
# character only 87 mm tall against 62 mm wide.
#
# Measured off the plate, as fractions of the whole standing height:
#
#     head diameter   40%     (which is `references/feest/README.md`'s
#                              "two fifths", and it is right)
#     body height     53%
#     legs            10%
#     body width      52%     — so the head is about three quarters of the
#                              body's width, not equal to it
#
# **The width is unchanged at 62 mm** and that is load-bearing rather than
# incidental: `FeestLayout.guestRadius` is 32 mm, `assertSpacing` is measured
# against it, and `FeestLayout.boothCentre` records that the booth was pulled
# 30 mm forward precisely because "a `beertjes.png` body is 62 mm wide". Only the
# vertical budget moves, and it moves towards the 102 mm `GuestCharacter`'s own
# comment always claimed the guests were.
LEG_HEIGHT = 0.014
BODY_BASE = 0.012
BODY_HEIGHT = 0.046
BODY_WIDEST = 0.028
#: Head centre, in body space. Chosen so the head's underside sits ~4 mm into the
#: torso's top: enough to read as "no neck", far too little to fuse.
HEAD_Y = 0.064
# The lineup plate makes the head almost as wide as the 56 mm body. 23 mm left
# a conspicuous waist at the neck and made the face a cluster of tiny parts;
# 26 mm restores the teddy-bear silhouette without changing the footprint.
HEAD_RADIUS = 0.026
SHOULDER_Y = 0.038      # in body space, just under the head
ARM_LENGTH = 0.024

#: The head radius every number in `face` was tuned against. `build` scales the
#: finished face by `HEAD_RADIUS / this`, so the two can move independently.
FACE_REFERENCE_RADIUS = 0.026

#: Blender is Z-up and the exporter maps (x, y, z) → (x, z, −y), so the game's
#: (x, y, z) is Blender's (x, −z, y). Every number above is written in the
#: game's frame, and this is the one place it is converted.
def g(x, y, z):
    return (x, -z, y)


SOORTEN = ["beer", "muis", "kat", "hond", "kikker", "vogel", "schaap", "mol",
           "egel", "vlinder", "slak"]


def build(soort):
    coat = feest.material("GastCoat", feest.SANDY_WOOD)
    accent = feest.material("GastAccent", feest.BLUSH_PINK_DEEP)
    cream = feest.material("GastCream", feest.CREAM_LIGHT)
    dark = feest.material("GastDark", feest.WOOD_BROWN)
    gold = feest.material("GastGold", feest.BUTTER_YELLOW)
    rose = feest.material("GastRose", feest.ROSE)

    parts = []
    w = BODY_WIDEST

    # ------------------------------------------------------------------ body
    # Widest about a third of the way up and pulled in at the shoulders, which
    # is the profile on the plate. Ten sides keeps the facets big.
    #
    # **Built in root space — the origin is on the floor, under the character.**
    #
    # It was body space (the body pivot, `BODY_BASE` up) on the first pass, which
    # is the frame the head and arms are *placed* in but not the frame the room
    # works in: `GuestCharacter` hangs the legs off the **root** and the body off
    # a pivot above it, so a model in body space puts the feet 12 mm in the air.
    # Everything here is therefore floor-relative, and the Swift side re-parents
    # each group onto the pivot that drives it.
    # **The shoulders are deliberately narrower than the head.** In the plate
    # the head's circle cuts across the body's outline and leaves a notch on each
    # side; that notch is the entire reason a head reads as a head rather than as
    # the top of a lump, and it only exists if the two silhouettes differ.
    # Fourteen sides and seven stations, up from ten and six. Measured off the
    # plate the body is widest at about 60% of its own height and pulls in
    # towards both ends — a pear, not a drum — and at ten sides the barrel's
    # facets are wide enough that the silhouette reads as a polygon.
    torso = [
        (w * 0.52, 0.0), (w * 0.80, 0.007), (w * 0.95, 0.015),
        (w * 1.00, 0.024), (w * 0.96, 0.032), (w * 0.83, 0.040),
        (w * 0.55, BODY_HEIGHT),
    ]
    parts.append(feest.lathe("CoatRomp", coat, torso, 16,
                             at=(0.0, 0.0, BODY_BASE)))

    # **The pale belly, and it is not decoration.** The three furry animals on
    # `beertjes.png` wear one; the frog and bird do not. The former panel wrapped
    # 136° around the torso and ran from its foot to its neck, so from the game
    # camera it replaced the body instead of sitting on it. This one is an oval:
    # 42° either side at its widest, closed above the hips and below the chin.
    #
    # Pressed into the barrel so only its front stands out — the seam that leaves
    # is what the bake measures.
    # **A panel cut from the body's own surface**, over the front 150° and the
    # middle of the torso's height. `feest.patch` has the argument for why a
    # squashed ball cannot do this job at any setting.
    #
    # The front of the character is the game's +Z, which is Blender −Y — so the
    # sector is centred on −90°, not on 0.
    front = -math.pi / 2
    if soort not in ("kikker", "vogel"):
        widest = math.radians(42)
        belly = [
            (w * 0.74, BODY_BASE + 0.006, widest * 0.16),
            (w * 0.86, BODY_BASE + 0.010, widest * 0.48),
            (w * 0.97, BODY_BASE + 0.017, widest * 0.82),
            (w * 1.00, BODY_BASE + 0.024, widest),
            (w * 0.95, BODY_BASE + 0.032, widest * 0.78),
            (w * 0.82, BODY_BASE + 0.039, widest * 0.42),
            (w * 0.70, BODY_BASE + 0.042, widest * 0.14),
        ]
        parts.append(feest.patch("CreamBuik", cream, belly, front))

    # ------------------------------------------------------------------ head
    # Big, round, and sitting straight on the shoulders. It carries the whole
    # face with it, which is why every part of it has `Kop` in its name.
    # The five heads are not five spheres. The common furry head is a slightly
    # squashed ball; the frog is broad and low, and the bird is the one upright
    # egg in the lineup. The old shared 0.94 vertical scale erased those reads.
    skull_scale = {
        "kikker": (1.10, 0.94, 0.76),
        "vogel": (0.96, 0.93, 1.00),
    }.get(soort, (1.0, 0.95, 0.88))
    skull = feest.blob("CoatKop", coat, HEAD_RADIUS, subdivisions=2,
                       scale=skull_scale)
    feest.animated(skull, g(0, BODY_BASE + HEAD_Y, 0))
    parts.append(skull)

    head = []                       # built at the head's own origin, at the
                                    # reference radius; scaled with the face below
    if soort != "kikker":
        # The frog's eyes stand on top of its head instead, which is the whole
        # of what makes a frog a frog at this size.
        for i, dx in enumerate([-0.0098, 0.0098]):
            head.append(feest.blob(
                "DarkKopOog%d" % i, dark, 0.0027, subdivisions=2,
                at=g(dx, 0.0045, HEAD_RADIUS * skull_scale[1] + 0.0012)))
            # (reference-sized, like everything `face` builds)
    head += face(soort, coat, accent, cream, dark, gold, rose)

    # **Every number in `face` is tuned at a 26 mm head**, which is the radius
    # the first pass used. Rather than convert forty literals by hand — and get
    # one of them wrong — the whole face is built at that reference size and
    # scaled to the head actually being used. One factor, applied once, and the
    # ears, muzzle and eyes keep their proportions to the skull exactly.
    k = HEAD_RADIUS / FACE_REFERENCE_RADIUS
    if abs(k - 1.0) > 1e-9:
        for ob in head:
            for v in ob.data.vertices:
                v.co = (v.co.x * k, v.co.y * k, v.co.z * k)

    for ob in head:
        feest.animated(ob, g(0, BODY_BASE + HEAD_Y, 0))
    parts += head

    # ------------------------------------------------------------------ arms
    # **Modelled straight up from the shoulder**, which is `DanceStyle.raise`'s
    # own frame: 0 is hands in the air, π/2 is straight out, π is hanging down.
    # The room poses them once at build time and never touches them again.
    for i, dx in enumerate([-(BODY_WIDEST * 0.86), BODY_WIDEST * 0.86]):
        # **No rotation at all.** A lathe already stands on Blender +Z, and
        # Blender +Z *is* the game's +Y — so an arm built along the profile axis
        # is already pointing straight up out of the shoulder. The first version
        # turned it −90° about X "to make it point up", which sends it to
        # Blender +Y, i.e. the game's −Z: both arms lay backwards into the
        # character's own back, which is what the first render showed.
        arm = feest.lathe("CoatArm%d" % i, coat, [
            (0.0060, 0.0), (0.0070, ARM_LENGTH * 0.22),
            (0.0067, ARM_LENGTH * 0.62), (0.0072, ARM_LENGTH * 0.88),
            (0.0058, ARM_LENGTH),
        ], 10)
        feest.animated(arm, g(dx, BODY_BASE + SHOULDER_Y, 0))
        parts.append(arm)

        # A coat-coloured paw with a small accent pad, as on the solo bear. The
        # old whole-accent ball looked like a pom-pom and lost the hand/arm join.
        paw = feest.blob(
            "CoatArm%dHand" % i, coat, 0.0078, subdivisions=1,
            scale=(1.06, 0.92, 0.86), at=g(0, ARM_LENGTH - 0.0018, 0))
        feest.animated(paw, g(dx, BODY_BASE + SHOULDER_Y, 0))
        parts.append(paw)
        palm = feest.blob(
            "AccentArm%dPalm" % i, accent, 0.0046, subdivisions=1,
            scale=(1.0, 0.20, 0.82),
            at=g(0, ARM_LENGTH - 0.0010, 0.0065))
        feest.animated(palm, g(dx, BODY_BASE + SHOULDER_Y, 0))
        parts.append(palm)

    # ------------------------------------------------------------------ legs
    # Stubs, and the only parts that move independently. **The origin is the
    # hip, not the foot**: `ModelLibrary.pivot` puts a holder at the part's own
    # position, and a leg whose origin is on the floor swings about its toes.
    for i, dx in enumerate([-0.0140, 0.0140]):
        leg = feest.lathe("CoatBeen%d" % i, coat, [
            (0.0072, -LEG_HEIGHT), (0.0080, -LEG_HEIGHT + 0.004),
            (0.0078, -0.002), (0.0068, 0.0),
        ], 10)
        # Pushed 3 mm forward of the body's axis. Directly under the barrel the
        # feet sit inside the belly's own bulge and are invisible from a camera
        # looking down at 31°, which is every camera this game has.
        feest.animated(leg, g(dx, LEG_HEIGHT, 0.008))
        parts.append(leg)

        # A real foot in front of the leg. In the plate the legs are short
        # columns ending in broad horizontal feet; the former radial lathe ended
        # in another column and made every friend stand on two pegs.
        foot_material = gold if soort == "vogel" else coat
        foot_prefix = "Gold" if soort == "vogel" else "Coat"
        foot = feest.blob(
            "%sBeen%dVoet" % (foot_prefix, i), foot_material, 0.0100,
            subdivisions=1, scale=(1.10, 1.18, 0.50),
            at=g(0, -LEG_HEIGHT + 0.0050, 0.006))
        feest.animated(foot, g(dx, LEG_HEIGHT, 0.008))
        parts.append(foot)

    return parts


def face(soort, coat, accent, cream, dark, gold, rose):
    """**Ears and a muzzle, and nothing else.**

    Two to five primitives each, all hung on the same round head at the same
    place, which is what makes eleven friends one builder — and what
    `references/feest/beertjes.png` shows five animals doing. Everything here is
    built at the head's own origin; the caller places the lot.
    """
    r = FACE_REFERENCE_RADIUS
    out = []

    def mark(name, material, width, height, at, angle=0.0):
        """One thin solid mark laid over the face.

        Eyes can be little balls; brows, whiskers and mouths are lines in the
        plate. Giving those lines 0.8 mm of thickness keeps them real geometry
        without turning them into black rods at room scale.
        """
        out.append(feest.boxes(
            name, material,
            [((-width / 2, width / 2), (-0.00045, 0.00045),
              (-height / 2, height / 2))],
            at=g(*at), rot=(0, angle, 0)))

    def brows():
        for i, dx in enumerate([-0.010, 0.010]):
            mark("DarkKopWenkbrauw%d" % i, dark, 0.0070, 0.0010,
                 (dx, 0.0125, r * 0.945), -0.15 if dx < 0 else 0.15)

    def muzzle(width, nose=True, mouth=True):
        # `width` is measured off `beertje-solo.png`, where the snout is about a
        # third of the head's width and sits low on the face. At the first
        # setting it was 23% and read as a chip of white rather than a snout.
        """The pale rounded snout every animal on the plate has, plus its dark
        nose. It does as much work as the ears: it breaks the head's silhouette
        and it is where the face *is*."""
        # Place the muzzle *on* the skull rather than mostly inside it. The first
        # rebuilt render left only three cream tips showing because 68% of the
        # radius plus the muzzle depth did not clear the head's 95% front.
        centre_z = r * 0.96
        out.append(feest.blob("CreamKopSnuit", cream, width, subdivisions=2,
                              scale=(1.20, 0.55, 0.86),
                              at=g(0, -0.0085, centre_z)))
        if nose:
            # A third of the snout's width, sat high on it — in the plate the
            # nose is a small dark cap near the top of the muzzle, not a ball
            # filling it.
            out.append(feest.blob("DarkKopNeus", dark, width * 0.26,
                                  subdivisions=2, scale=(1.15, 0.85, 0.9),
                                  at=g(0, 0.0005, centre_z + width * 0.66)))
        if mouth:
            front_z = centre_z + width * 0.76
            # A short stem and two smile strokes. Three boxes are cheaper and
            # more legible here than a curve with a sub-millimetre bevel.
            mark("DarkKopMondSteel", dark, 0.0010, 0.0040,
                 (0, -0.0105, front_z))
            mark("DarkKopMond0", dark, 0.0055, 0.0009,
                 (-0.0023, -0.0132, front_z), -0.28)
            mark("DarkKopMond1", dark, 0.0055, 0.0009,
                 (0.0023, -0.0132, front_z), 0.28)

    def round_ear(dx, i, radius, y, flatten=1.0):
        """A round ear with a paler inner disc — the bear, the cat and the mouse
        all have one on the plate, and the inner disc is what stops an ear being
        a lump."""
        out.append(feest.blob("CoatKopOor%d" % i, coat, radius, subdivisions=1,
                              scale=(1.0, flatten, 1.0), at=g(dx, y, 0)))
        out.append(feest.blob("AccentKopOor%d" % i, accent, radius * 0.58,
                              subdivisions=1, scale=(1.0, flatten * 0.6, 1.0),
                              at=g(dx, y, radius * 0.40 * flatten)))

    def pair(dx, build_one):
        for i, side in enumerate([-dx, dx]):
            build_one(side, i)

    if soort == "beer":
        pair(0.017, lambda dx, i: round_ear(dx, i, 0.0088, 0.020))
        brows()
        muzzle(0.0090)

    elif soort == "muis":
        # Big flat round ears, which is the whole mouse.
        pair(0.021, lambda dx, i: round_ear(dx, i, 0.0125, 0.014, flatten=0.30))
        brows()
        muzzle(0.0076)

    elif soort == "kat":
        # Pointed ears: a four-sided cone is a triangle from every angle this
        # camera has.
        pair(0.014, lambda dx, i: out.append(feest.lathe(
            "CoatKopOor%d" % i, coat, [(0.0078, 0.0), (0.0, 0.013)], 4,
            at=g(dx, 0.018, 0), rot=(0, 0, math.pi / 4))))
        brows()
        muzzle(0.0080)
        # Three forehead stripes and six whiskers are the entire cat read in the
        # supplied lineup. Ears and a muzzle alone left a pink bear with points.
        for i, dx in enumerate([-0.006, 0.0, 0.006]):
            mark("DarkKopStreep%d" % i, dark, 0.0020, 0.0070,
                 (dx, 0.0155 - abs(dx) * 0.25, r * 0.935),
                 -dx * 18.0)
        for side in (-1, 1):
            for row in range(3):
                mark("DarkKopSnor%d%d" % (side, row), dark, 0.0110, 0.00075,
                     (side * 0.0160, -0.0055 - row * 0.0030, r * 0.955),
                     side * (row - 1) * 0.11)

    elif soort == "hond":
        # Floppy ears down the sides — the only pair that hangs rather than
        # stands, and the reason a dog is not a bear.
        for i, dx in enumerate([-0.026, 0.026]):
            ear = feest.blob(
                "CoatKopOor%d" % i, coat, 0.0110, subdivisions=2,
                scale=(0.70, 0.35, 1.30), at=g(dx, 0.003, 0.004))
            ear.rotation_euler[1] = -0.16 if dx > 0 else 0.16
            out.append(ear)
        # The white blaze is the dog plate's strongest mark. A thin flattened
        # ellipsoid sits on the skull and disappears cleanly under the muzzle.
        out.append(feest.blob(
            "CreamKopBles", cream, 0.0100, subdivisions=2,
            scale=(0.62, 0.18, 1.35), at=g(0, 0.008, r * 0.93)))
        brows()
        muzzle(0.0097)

    elif soort == "kikker":
        # Eyes on bulges on top, which is the one animal whose eyes are not in
        # the skull — and why `build` skips the dot eyes for it.
        pair(0.013, lambda dx, i: out.append(feest.blob(
            "CoatKopOog%d" % i, coat, 0.0092, subdivisions=1,
            at=g(dx, 0.019, 0.004))))
        pair(0.013, lambda dx, i: out.append(feest.blob(
            "DarkKopPupil%d" % i, dark, 0.0032, subdivisions=1,
            at=g(dx, 0.022, 0.011))))
        # Nostrils and a wide, thin mouth — dark marks rather than a pale bar.
        for i, dx in enumerate([-0.004, 0.004]):
            out.append(feest.blob("DarkKopNeus%d" % i, dark, 0.0013,
                                  subdivisions=1, at=g(dx, -0.001, r * 0.955)))
        mark("DarkKopMond", dark, 0.0180, 0.0010,
             (0, -0.0100, r * 0.955))

    elif soort == "vogel":
        # A broad two-part beak, not the old front-on cone that read as a tiny
        # yellow diamond. The upper bill is a low faceted ellipsoid and the rose
        # lower bill peeks out beneath it, exactly as in `beertjes.png`.
        out.append(feest.blob(
            "GoldKopSnavel", gold, 0.0092, subdivisions=1,
            scale=(1.45, 0.82, 0.62), at=g(0, -0.005, r * 0.82)))
        out.append(feest.blob(
            "RoseKopOndSnavel", rose, 0.0055, subdivisions=1,
            scale=(1.15, 0.72, 0.48), at=g(0, -0.013, r * 0.86)))
        # One simple crest: the plate has one gold tuft, not three blue aerials.
        out.append(feest.lathe(
            "GoldKopKuif", gold, [(0.0040, 0.0), (0.0030, 0.012),
                                  (0.0, 0.015)], 5,
            at=g(0, r * 0.92, -0.002)))

    elif soort == "schaap":
        # A fleece: five small spheres crowding the crown. The one head that is
        # a cluster rather than a pair.
        for i, (ox, oy, oz) in enumerate([(-0.011, 0.019, 0.003),
                                          (0.011, 0.019, 0.003),
                                          (0.0, 0.024, -0.006),
                                          (0.0, 0.021, 0.012),
                                          (0.0, 0.026, 0.002)]):
            out.append(feest.blob("AccentKopWol%d" % i, accent, 0.0072,
                                  subdivisions=1, at=g(ox, oy, oz)))
        pair(0.024, lambda dx, i: out.append(feest.blob(
            "CoatKopOor%d" % i, coat, 0.0062, subdivisions=1,
            scale=(1.5, 0.7, 0.6), at=g(dx, 0.004, 0))))
        brows()
        muzzle(0.0088)

    elif soort == "mol":
        # A long snout and almost no ears, which is a mole seen from a metre
        # away. The pink nose on the end is the readable part.
        out.append(feest.lathe("CreamKopSnuit", cream, [
            (0.0090, 0.0), (0.0072, 0.006), (0.0050, 0.013)], 6,
            at=g(0, -0.004, r * 0.72), rot=(math.pi / 2, 0, 0)))   # out of the face
        out.append(feest.blob("AccentKopNeus", accent, 0.0038, subdivisions=1,
                              at=g(0, -0.004, r * 0.72 + 0.013)))

    elif soort == "egel":
        # Spines: five cones fanning back off the crown.
        for i in range(5):
            t = i / 4 - 0.5
            # `GuestCharacter` fans these back with −0.55 + t·0.4 about the
            # game's X and t·0.8 about the game's **Z**. A turn about the game's
            # X is the same turn about Blender's X, but the game's Z is
            # Blender's −Y — so the second one becomes a turn about Blender's Y
            # with the sign flipped. Written as a Blender Z turn it fans them
            # sideways round the crown instead of outwards.
            out.append(feest.lathe("DarkKopStekel%d" % i, dark, [
                (0.0042, 0.0), (0.0, 0.014)], 4,
                at=g(t * 0.020, 0.020, -0.006),
                rot=(-0.55 + t * 0.4, -t * 0.8, 0)))
        brows()
        muzzle(0.0078)

    elif soort == "vlinder":
        # Two flat petal wings behind the head, and antennae with knobs. They
        # sit on the *head* rather than the shoulders so they read at this size.
        pair(0.022, lambda dx, i: out.append(feest.blob(
            "AccentKopVleugel%d" % i, accent, 0.014, subdivisions=1,
            scale=(1.0, 0.16, 1.15), at=g(dx, 0.004, -0.016))))
        pair(0.006, lambda dx, i: (
            out.append(feest.boxes("DarkKopSpriet%d" % i, dark, [
                ((-0.0009, 0.0009), (-0.0009, 0.0009), (0.0, 0.012))],
                at=g(dx, 0.019, 0), rot=(0, 0.25 if dx > 0 else -0.25, 0))),
            out.append(feest.blob("AccentKopSprietKnop%d" % i, accent, 0.0026,
                                  subdivisions=1, at=g(dx, 0.031, 0)))))
        muzzle(0.0072, nose=False)

    elif soort == "slak":
        # A shell on the back, and two eye-stalks. The shell is a lathe with a
        # stepped profile, which is the cheapest thing that reads as a spiral
        # without being one.
        # The shell faces **backwards**, so this is the beak's turn reversed:
        # −π/2 about X sends +Z to Blender +Y, which is the game's −Z.
        out.append(feest.lathe("AccentKopHuis", accent, [
            (0.005, 0.0), (0.015, 0.005), (0.014, 0.012),
            (0.008, 0.017), (0.0, 0.019)], 8,
            at=g(0, 0.002, -0.018), rot=(-math.pi / 2, 0, 0)))
        pair(0.007, lambda dx, i: (
            out.append(feest.boxes("CoatKopSteel%d" % i, coat, [
                ((-0.0009, 0.0009), (-0.0009, 0.0009), (0.0, 0.013))],
                at=g(dx, 0.018, 0.005), rot=(0, 0.22 if dx > 0 else -0.22, 0))),
            out.append(feest.blob("DarkKopStok%d" % i, dark, 0.0028,
                                  subdivisions=1, at=g(dx, 0.032, 0.005)))))
        muzzle(0.0070, nose=False)

    else:
        feest.check(False, "no face for %r" % soort)

    return out


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    wanted = [a for a in args if a in SOORTEN] or SOORTEN

    for soort in wanted:
        feest.fresh("Beertje", "Coat", "Accent", "Cream", "Dark", "Gold",
                    "Rose", "Gast")
        parts = build(soort)

        # **The room envelope, asserted rather than described.** The plate now
        # wins inside it — 52 mm head, broader feet and species-specific skulls —
        # while the 62 mm footprint and ~102 mm standing height stay fixed. A
        # friend growing outside that box would break `FeestLayout`'s screen
        # spacing and put the DJ into the plaster.
        #
        # `matrix_world` is cached, and the head, the arms and the legs were
        # placed with `feest.animated` — setting `.location` does not refresh it.
        # Measured without this the whole character is 48 mm tall, which is the
        # torso on its own.
        bpy.context.view_layer.update()
        corners = [ob.matrix_world @ v.co for ob in parts
                   for v in ob.data.vertices]
        # Everything here is built in **body space**, whose origin is the body
        # pivot `BODY_BASE` off the floor, so the standing height is that plus
        # what the parts reach. The range rather than a single number is the
        # ears: a mouse's clear the crown by 9 mm where a mole's are not there
        # at all, and the check exists to catch a limb in the wrong frame, not
        # to police a species.
        top = max(p.z for p in corners)
        wide = max(abs(p.x) for p in corners)
        # ~102 mm, which is what `GuestCharacter`'s own comment always claimed
        # the guests were and what the plate's proportions produce. The range is
        # the ears: a mouse's clear the crown by 9 mm where a mole's are not
        # there at all. It exists to catch a limb built in the wrong frame, not
        # to police a species.
        feest.check(0.095 < top < 0.118,
                    "%s stands %.4f m tall, not the ~102 mm the plate gives"
                    % (soort, top))
        feest.check(wide < 0.040,
                    "%s is %.4f m wide — the DJ has 24 mm behind his booth"
                    % (soort, wide))

        # **30 mm, the long-reach character bake from
        # `app/AMBIENT-OCCLUSION.md`.** The 2 mm contact bake found the joins;
        # the room study showed that the missing readable term is larger: under
        # the chin, between each arm and the side, between the legs, and the
        # belly over the feet. Ten ShadeN rungs preserve those broad
        # transitions and restore contrast under RealityKit without turning
        # isolated facets into dark blemishes.
        # **Only the big forms may be darkened; the small features cast but are
        # never shaded**, which is `garden.finish`'s `shade` argument doing the
        # honey pot's job (`models/README.md`).
        #
        # The reason is specific to characters and worth writing down. The bake
        # samples a **fixed Fibonacci set of ray directions**, which is
        # deterministic — the point of it — but is *not* mirror-symmetric. On a
        # 7.8 mm ear that is enough to push the left one to `Shade2` and the
        # right one to `Shade1`: measured on this bear, and on a face two
        # different tones on two identical ears reads as damage rather than as
        # shading. The big surfaces are broad enough that the same asymmetry is
        # invisible on them.
        shade = [ob for ob in parts if ob.name in
                 ("CoatRomp", "CreamBuik", "CoatKop", "CreamKopSnuit")
                 or ob.name.startswith(("CoatArm", "CoatBeen", "GoldBeen"))]
        objects = feest.finish("Beertje", parts, shade=shade)
        for ob in objects:
            if ob.type != 'MESH':
                continue
            for poly in ob.data.polygons:
                poly.use_smooth = True
        shaded = sum(1 for ob in objects
                     if ob.type == 'MESH' and "Shade" in ob.name)
        print("%-9s %3d parts, %2d shaded" %
              (soort, sum(1 for o in objects if o.type == 'MESH'), shaded))
        feest.write(objects, "beertje-%s" % soort, save=True)


if __name__ == "__main__":
    main()
