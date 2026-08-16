"""De molshoop en Mo, modelled in Blender.

    blender --background --python models/molehill.py

Reference: `references/garden/molehill.png`. Writes
`app/NinaBakeryPOC/Resources/Models/molehill.usdz`.

**The nose is the whole character.** `references/garden/README.md` said so when
the plate was generated and the plate proves it: a round head, two dots, and one
big pink nose that carries every bit of the expression. Everything here is in
service of that nose being visible.

Three things the code version cannot do, and one it got wrong:

  * **The hill is a dome, not a cone.** `GardenProps.molehill` builds a
    ten-sided tapered prism — a truncated cone, straight from base to flat top.
    The plate's hill has a **convex** profile: it flares out at the foot, rises
    steeply and rolls over at the crown, which is what loose earth pushed up
    from below does. A straight taper is a lampshade.
  * **Paws.** The plate rests two little paws on the earth either side of the
    head, and they are what turn a ball with a nose into an animal leaning out
    of a hole.
  * **He was buried.** This is the one the model had to fix and it is a real
    bug rather than a matter of taste. `GardenRoom.tapMolehill` lifts Mo to
    y = +0.0135; his head sits at the pivot's own origin with a radius of
    9.2 mm, and the hill's flat top is at 19.5 mm — so at full pop the head
    cleared the earth by **3.2 mm** and the nose, which hangs 1.6 mm below the
    head's centre, never came up at all. The whole toy was a grey sliver.
    **Fixed here rather than in Swift**, by building the mole 11.2 mm up its own
    pivot: the room's two tween positions are gameplay numbers that have been
    played against, and the fix belongs to the thing that was modelled wrong.
    At −14 mm he is still completely inside the hill, which is the other half of
    what those two numbers have to be true about.
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import garden

NAME = "Molehill"

#: The hill. `GardenProps` starts at 27 mm and ends at 9.2 mm over 19.5 mm of
#: rise, and those three numbers stay — `GardenLayout.molehillSpot` and the
#: 38 mm touch sphere registered against it were sized on them. What changes is
#: everything in between: a convex profile instead of a straight one.
HILL = [(0.0270, 0.0000),
        (0.0242, 0.0050),
        (0.0192, 0.0108),
        (0.0140, 0.0158),
        (0.0092, 0.0195)]
HILL_TOP = 0.0195

#: **Where Mo sits on his own pivot.** See the module docstring: this is the
#: 11.2 mm that gets his nose above the earth at the room's +13.5 mm pop.
MOLE_Z = 0.0112
HEAD_RADIUS = 0.0092


def build():
    garden.fresh("Mole", "Hill")

    earth = garden.material("HillEarth", garden.WOOD_BROWN)
    fur = garden.material("MoleFur", garden.MOLE_GREY)
    pink = garden.material("MoleNose", garden.BLUSH_PINK)
    dark = garden.material("MoleEye", garden.OVEN_INSIDE)

    parts = [garden.lathe("HillEarth", earth, HILL, 10)]

    parts.append(garden.balls("MoleHead", fur,
                              [(HEAD_RADIUS, (0.0, 0.0, MOLE_Z))]))

    # He looks out along the game's +X+Z diagonal, straight at the camera. In
    # Blender that is +X−Y, and everything on his face is placed on it.
    face = (math.sqrt(0.5), -math.sqrt(0.5))

    parts.append(garden.balls(
        "MoleNose", pink,
        [(0.0042, (face[0] * 0.0084, face[1] * 0.0084, MOLE_Z - 0.0018))],
        subdivisions=0))

    # Two dots, standing off the head rather than sunk into it: a hexagon lying
    # on a sphere at this size is three pixels, and the one thing it must not do
    # is disappear into the facet under it.
    for side in (-1, 1):
        across = (-face[1] * side, face[0] * side)
        parts.append(garden.lathe(
            "MoleEye%d" % (side > 0), dark,
            [(0.0015, 0.0000), (0.0015, 0.0016)], 6,
            at=(face[0] * 0.0072 + across[0] * 0.0034,
                face[1] * 0.0072 + across[1] * 0.0034,
                MOLE_Z + 0.0030),
            rot=(math.pi / 2, 0.0, -garden.FACING_CAMERA)))

    # The paws, resting on the earth either side of him.
    #
    # **They have to be outside the hill, not merely below the head**, which
    # cost one render: the hill is 19 mm across at the height they sit at, and a
    # paw tucked in at 10 mm from the axis is inside solid earth. 14 mm out and
    # 4.5 mm up its pivot puts them on the slope just under the crown, which is
    # where the plate rests them.
    for side in (-1, 1):
        across = (-face[1] * side, face[0] * side)
        out = (face[0] * 0.0060 + across[0] * 0.0126,
               face[1] * 0.0060 + across[1] * 0.0126)
        parts.append(garden.lathe(
            "MolePaw%d" % (side > 0), fur,
            [(0.0000, 0.0000), (0.0030, 0.0014), (0.0034, 0.0038),
             (0.0026, 0.0056), (0.0000, 0.0064)], 6,
            at=(out[0], out[1], 0.0045),
            rot=(1.05, 0.0, math.atan2(out[1], out[0]) - math.pi / 2)))

    # 4 mm across a 54 mm hill. It has to find the ring where the head comes out
    # of the earth and the joins under the nose and the paws, and stop well
    # short of the hill's own slope — a molehill shaded down its sides is a
    # rock. `occluders` is not needed: nothing here is repainted per round.
    return garden.finish(NAME, parts, distance=0.0040)


if __name__ == "__main__":
    garden.write(build(), "molehill")
