"""The ripe strawberry plant, modelled in Blender.

    blender --background --python models/plant-aardbei.py

Reference: `references/garden/plant-aardbei.png`. Writes
`app/NinaBakeryPOC/Resources/Models/plant-aardbei.usdz`. Shared rules are in
`lowpoly.py`, the garden's own vocabulary in `garden.py`, and `models/README.md`
has the why.

**It is the only plate in the room that hangs its fruit**, and that is the whole
reason this one is worth modelling first. The berry swings out of a low rosette
on a stalk that rises, arches over and comes back down — one continuous bend.
`GardenProps.plant` fakes it with three rotated boxes, which is honest at 10 mm
and is visibly three boxes at any size above it; `garden.sweep` carries a
pentagon along the curve instead, so the arch is an arch.

**No straight stem.** Every other plant here has one and this one must not: in
the plate the arched stalk *is* the stem, and a vertical stalk standing beside
it would put a second line through the silhouette exactly where the berry
hangs.

The berry itself is `KitchenProps.buildStrawberry`'s profile, station for
station. What she picks off this plant and what she drops in the kitchen's bowl
are meant to be the same object, and a strawberry that changes shape when it is
picked is two strawberries.
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import garden

NAME = "PlantAardbei"

#: The berry, from `KitchenProps.buildStrawberry`. Pointed at the bottom, widest
#: above the middle, flat enough on top to stand a crown on.
#:
#: **Drawn out 18% taller than the token's**, and only that. The calyx covers
#: the berry's top third, and at the token's proportions what is left below it
#: is as wide as it is tall — a plum. The plate's berry is plainly taller than
#: it is wide; the extra height is all under the crown, where it shows.
BERRY = [(0.0000, 0.0000),
         (0.0055, 0.0041),
         (0.0090, 0.0092),
         (0.0100, 0.0139),
         (0.0082, 0.0179),
         (0.0042, 0.0196)]
BERRY_TOP = 0.0196

#: Where the stalk lets go of the berry, and therefore where the berry's own
#: top ends up. `GardenProps` leans the fruit to +X and slightly towards the
#: camera; in Blender that is +X and −Y.
#:
#: **It has to clear the rosette**, which is the one measurement in this file
#: that a first pass got wrong: at the 10.5 mm `GardenProps` leans by, the berry
#: comes down inside a 27 mm rosette and the arch disappears behind it. The
#: plate hangs it in clear air outside the leaves, and 14 mm is what that takes.
#:
#: **And 17 mm was too far**, which only showed with the bed assembled: the five
#: holes are 42 mm apart, and a berry hung 17 mm out with a 10 mm radius of its
#: own arrives on top of whatever is growing next door. At 14 mm it clears its
#: own rosette and still leaves 10 mm of air to the neighbour's mound.
#:
#: **And it leans along the game's X−Z diagonal, not along +X.** That is the one
#: direction in this room that is exactly screen-horizontal
#: (`GardenLayout.flowerSpot` proves it for the flower row), so the arch is seen
#: broadside. `GardenProps` leans towards +X+Z, which is the direction the
#: camera is looking down: the second render came back with the whole arch
#: foreshortened into the berry, so there was a bend and no way to see it.
#: In Blender the game's X−Z diagonal is +X+Y.
HANG = (0.0100, 0.0100, 0.0402)

#: The arch, base to tip. It leaves the mound upright, so the plant still reads
#: as growing out of the earth, and only commits to the lean above the rosette —
#: then goes **over the top** rather than out at an angle, which is what makes
#: the berry hang rather than lean.
STALK = [(0.0000, 0.0000, 0.0040),
         (0.0003, 0.0003, 0.0170),
         (0.0013, 0.0013, 0.0310),
         (0.0034, 0.0034, 0.0405),
         (0.0069, 0.0069, 0.0445),
         (HANG[0], HANG[1], HANG[2] + 0.0012)]
STALK_RADIUS = [0.0017, 0.0016, 0.0015, 0.0014, 0.0013, 0.0013]


def build():
    garden.fresh("Plant", "Berry")

    leaf_green = garden.material("AardbeiLeaf", garden.SAGE)
    stem_green = garden.material("AardbeiStem", garden.SAGE_DEEP)
    earth = garden.material("AardbeiEarth", garden.WOOD_BROWN)
    berry_rose = garden.material("AardbeiBerry", garden.ROSE)

    # **The plate's rosette is the room's rosette**, splayed low with nothing
    # standing up out of it — which is exactly the shape `sprout-half.png`
    # leaves behind, so the last sweep of the can grows a head rather than
    # rebuilding a plant.
    parts = [garden.mound(earth)]
    parts += garden.rosette(leaf_green)

    parts.append(garden.sweep("PlantStalk", stem_green, STALK, STALK_RADIUS,
                              sides=5))

    parts.append(garden.lathe("BerryBody", berry_rose, BERRY, 8,
                              at=(HANG[0], HANG[1], HANG[2] - BERRY_TOP)))

    # The calyx: six little leaves lying almost flat over the berry's shoulders.
    # 1.45 rad rather than the rosette's 1.15, because a crown that stands up is
    # a blueberry's (`models/README.md`) and a strawberry's lies down.
    for i in range(6):
        parts.append(garden.leaf(
            "BerryLeaf%d" % i, leaf_green, 0.0118, width=0.26,
            at=(HANG[0], HANG[1], HANG[2] - 0.0008),
            rot=(1.45, 0.0, math.pi / 6 + 2 * math.pi * i / 6)))

    # 2.2 mm. The berry is 17 mm and the calyx leaves are 10 mm, so this stays
    # in the joint between them and under the arch's own curl, and never reaches
    # out onto the open face of a leaf.
    return garden.finish(NAME, parts, distance=0.0022)


if __name__ == "__main__":
    garden.write(build(), "plant-aardbei")
