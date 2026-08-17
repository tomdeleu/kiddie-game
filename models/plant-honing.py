"""The ripe honey plant, modelled in Blender.

    blender --background --python models/plant-honing.py

Reference: `references/garden/plant-honing.png`. Writes
`app/NinaBakeryPOC/Resources/Models/plant-honing.usdz`.

**The pot is the flower head.** Honey has no shape of its own — the lesson the
kitchen's token already learned, where the readable object became the jar it is
in — and a pot does not grow, so the plate asks the same question one level up
and answers it the same way: the pot *is* the flower, ringed by a collar of flat
petals, on a straight stem.

The collar is the whole of what makes a jar on a stem read as a thing that grew
there, and the plate makes its petals **chips rather than points**, which is the
same call `flower-row.png` made for the chiming flowers. A ring of points is a
star; a ring of chips is a sunflower.

**Two things in the plate are deliberately not here**, and both were argued
before this model existed. The glossy icing dripping over the pot's lip is a
smooth curved surface, which `references/REFERENCES.md` §1 rules out — the same
call the fence's bolt heads got. And the honey **dipper** lying across the rim
*is* here even though the plate has no dipper: it is on the kitchen's token, and
`references/garden/README.md` is explicit that what she picks off a plant and
what she drops in the bowl are the same object. A pot that grows a dipper when
it is picked is two pots.
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import garden

NAME = "PlantHoning"

#: The bowl. Narrower at the foot than the kitchen's token, because this one
#: stands on a stem rather than on a table and the plate tapers it in to meet
#: it. A third bigger than the other seven heads, which is the token's own
#: exception (owner, 2026-08-16) and holds for the same reason: it is the only
#: head whose subject is a container, and a container has to read as having an
#: inside.
#:
#: **Nearly as tall as it is wide**, which took a second pass. At 28 mm across
#: and 19 mm high the first one read as a pie: this camera looks down 34°, so a
#: wide shallow pot shows the viewer its lid and hides its body, and the body is
#: the half that says *pot*.
POT = [(0.0062, 0.0000),
       (0.0098, 0.0060),
       (0.0126, 0.0140),
       (0.0134, 0.0206)]
RIM_RADIUS = 0.0142
RIM_TOP = 0.0236

#: The petal collar, tucked **under the rim** — which is where the plate puts it
#: and, it turns out, the only place it can go. A collar round the pot's middle
#: is a collar this camera looks straight down onto: at 34° it covers the bowl
#: below it and the head comes back as a pie on a stick. Up at the lip the chips
#: stand out against the backdrop and the whole bowl stays visible under them.
PETALS = 8
PETAL_RING = 0.0150
PETAL_Z = 0.0196


def build():
    garden.fresh("Plant", "Honing")

    leaf_green = garden.material("HoningLeaf", garden.SAGE)
    stem_green = garden.material("HoningStem", garden.SAGE_DEEP)
    earth = garden.material("HoningEarth", garden.WOOD_BROWN)
    pot_cream = garden.material("HoningPotCream", garden.CREAM)
    rim_cream = garden.material("HoningRimCream", garden.CREAM_LIGHT)
    amber = garden.material("HoningAmber", garden.HONEY_AMBER)
    petal_yellow = garden.material("HoningPetal", garden.BUTTER_YELLOW)
    wood = garden.material("HoningWood", garden.SANDY_WOOD)

    parts = garden.plant_base(leaf_green, stem_green, earth)
    head = garden.HEAD_Z

    parts.append(garden.lathe("HoningPot", pot_cream, POT, 8,
                              at=(0.0, 0.0, head)))
    rim = garden.lathe("HoningRand", rim_cream,
                       [(RIM_RADIUS, 0.0204), (RIM_RADIUS, RIM_TOP)], 8,
                       at=(0.0, 0.0, head))
    fill = garden.prism("HoningVulling", amber, 0.0112, 0.0016, 8,
                        at=(0.0, 0.0, head + 0.0230))
    parts += [rim, fill]

    for i in range(PETALS):
        around = 2 * math.pi * i / PETALS
        parts.append(garden.chip(
            "HoningBlad%d" % i, petal_yellow, 0.0052, 0.0024, sides=6,
            at=(math.cos(around) * PETAL_RING, math.sin(around) * PETAL_RING,
                head + PETAL_Z)))

    # The dipper, **standing in the pot and leaning out of it**, along the
    # room's screen-horizontal diagonal so it is seen along its length rather
    # than end-on. Lying flat across the rim it is a plank seen from above,
    # which is what the first pass rendered; leaning, it is a dipper. Two parts,
    # not the plate's five rings — at this size the rings would be half a
    # millimetre.
    lip = head + RIM_TOP
    parts.append(garden.sweep(
        "HoningStok", wood,
        [(-0.0044, -0.0044, lip - 0.0044), (0.0128, 0.0128, lip + 0.0104)],
        0.0016, sides=5))
    parts.append(garden.lathe(
        "HoningKop", wood,
        [(0.0018, 0.0000), (0.0040, 0.0028), (0.0018, 0.0056)], 6,
        at=(0.0150, 0.0150, lip + 0.0126),
        rot=(0.0, 2.30, math.pi / 4)))

    # 2.4 mm. It has to reach under a 5.2 mm petal chip and into the step
    # between the bowl and its rim, and stop well short of the 27 mm bowl's own
    # face — the bowl is the one part here big enough to be darkened all over.
    #
    # **The rim and the honey are cast from and never shaded.** They are a 3 mm
    # band and a 1.6 mm disc sitting inside a ring of petals, so nine of every
    # ten of their faces measure as occluded and the bake's own floor-shifting
    # rule hands back a pot of dark honey. It is the cake's tiers again
    # (`models/README.md`): a part that is small, enclosed and the one bright
    # note of the prop has to cast without receiving.
    return garden.finish(NAME, parts, distance=0.0024,
                         shade=[p for p in parts if p not in (rim, fill)])


if __name__ == "__main__":
    garden.write(build(), "plant-honing")
