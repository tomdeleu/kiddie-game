"""De boom achter het hek, modelled in Blender.

    blender --background --python models/garden-tree.py

Reference: `references/garden/garden-tree.png`. Writes
`app/NinaBakeryPOC/Resources/Models/garden-tree.usdz`.

**A cluster, not a ball.** The plate is emphatic and `GardenProps.tree` already
agrees with it — a single sphere on a stick is a lollipop. What the model buys
is the thing eight separate `ModelEntity` spheres cannot have:

  * **The seams.** Where two lobes push into each other there is a crease no
    facet can answer: both surfaces face outwards and come back the same tone.
    The code compensates by painting alternate lobes `sage` and `mint`, which is
    a tint standing in for a shape — and at 139 mm across it reads as a bag of
    two-coloured balls rather than as foliage. One mesh can be measured against
    itself, so the crease is shaded and **the whole canopy is one colour**,
    which is what the plate draws. It is `plant-wolkenroom.py`'s argument at
    four times the size.
  * **The plate's dozen.** The code stops at eight because eight lobes is eight
    entities and eight draw calls. In one mesh the count is free, and the count
    is what turns a heap of balls into a crown: fourteen here, on a low ring, a
    middle ring and a crown, exactly the packing the plate draws.
  * **A trunk with bands in it.** One 128 mm prism is six faces 128 mm tall, and
    `models/README.md`'s fence lesson is that a facet that big has nothing to
    quantise — the contact shading where the canopy sits down over the trunk has
    nowhere to land. Four stations instead of two, and the top band takes it.

**Every number of the envelope is kept, to the millimetre.** The tree was sized
twice by the owner on 2026-08-17 (it read as a bush, then it was still too
short) and `GardenLayout.treeSpot` records what the result has to stay true
about: it stands **225 mm** on a **128 mm trunk**, its canopy hangs from
**105 mm** — clear of the 86 mm fence posts and the bench's 90 mm backboard —
and it is **139 mm across**, which is the overhang past the room box's back edge
that is the point of where it stands. `build()` asserts all three rather than
trusting the table below, because a lobe nudged out by two millimetres is a
canopy through a fence post and nothing in Blender would say so.
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import garden

NAME = "GardenTree"

#: The envelope the room was laid out against. See the module docstring — these
#: are `GardenLayout.treeSpot`'s numbers and the model is checked against them.
TOTAL_HEIGHT = 0.2245
CANOPY_FLOOR = 0.1050
CANOPY_RADIUS = 0.0697

#: The trunk, `(radius, height)` up its own axis. The two ends are
#: `GardenProps.tree`'s 17.1 mm and 12.2 mm over 128 mm; the two stations
#: between them sit on that same straight line and exist for the bake.
TRUNK = [(0.0171, 0.0000),
         (0.0160, 0.0300),
         (0.0142, 0.0750),
         (0.0122, 0.1280)]

#: The canopy, `(radius, (x, y, z))` in **game** axes — the frame every number
#: in `GardenProps` and `GardenLayout` is written in. `build()` converts.
#:
#: Fixed rather than random, which is the call the code version already makes: a
#: tree that rebuilds differently every time the flat-shading toggle flips is a
#: tree that moved while she was looking.
LOBES = [
    # The core, carrying the middle of the silhouette.
    (0.0470, (0.0000, 0.1620, 0.0000)),
    # The low ring — the widest of them, and what the canopy hangs from.
    (0.0330, (0.0360, 0.1400, 0.0000)),
    (0.0335, (0.0108, 0.1435, 0.0333)),
    (0.0341, (-0.0287, 0.1400, 0.0209)),
    (0.0318, (-0.0287, 0.1455, -0.0209)),
    (0.0340, (0.0108, 0.1420, -0.0333)),
    # The middle ring, turned 36° off the low one so no two lobes stack.
    (0.0320, (0.0243, 0.1760, 0.0176)),
    (0.0310, (-0.0096, 0.1735, 0.0295)),
    (0.0300, (-0.0320, 0.1780, 0.0000)),
    (0.0300, (-0.0094, 0.1745, -0.0290)),
    (0.0305, (0.0243, 0.1755, -0.0176)),
    # The crown.
    (0.0275, (0.0075, 0.1965, 0.0060)),
    (0.0250, (-0.0140, 0.1900, -0.0090)),
    (0.0245, (0.0130, 0.1880, 0.0120)),
]


def to_blender(point):
    """Game (x, y, z) → Blender (x, −z, y). `garden.py`'s header has the map."""
    return (point[0], -point[2], point[1])


def check_envelope():
    """**The three numbers the room is laid out against.**

    A canopy is fourteen loose numbers and the eye cannot add them up; the room
    can — `GardenLayout.treeSpot` clears the fence posts, the bench's backboard
    and the base slab's back edge by margins that were measured once, against
    this envelope. So it is asserted here rather than described.
    """
    top = max(y + r for r, (_, y, _) in LOBES)
    floor = min(y - r for r, (_, y, _) in LOBES)
    wide = max(math.hypot(x, z) + r for r, (x, _, z) in LOBES)
    print("canopy: top %.4f floor %.4f radius %.4f (%d lobes)"
          % (top, floor, wide, len(LOBES)))
    assert top <= TOTAL_HEIGHT + 1e-6, "the tree grew past its frame: %.4f" % top
    assert floor >= CANOPY_FLOOR - 1e-6, "the canopy dropped onto the fence: %.4f" % floor
    assert wide <= CANOPY_RADIUS + 1e-6, "the canopy reached past the slab: %.4f" % wide


def build():
    garden.fresh("Garden", "Tree")
    check_envelope()

    bark = garden.material("TreeBark", garden.CREAM)
    leaves = garden.material("TreeLeaves", garden.MINT)

    parts = [garden.lathe("TreeTrunk", bark, TRUNK, 6)]
    # **`subdivisions` does not mean the same thing on the two sides**, and
    # copying the number across cost one render. Blender's
    # `create_icosphere(subdivisions=1)` is the bare 20-face icosahedron;
    # `FacetedMesh.icosphere(subdivisions: 1)` has already subdivided once, at
    # 80. At 1 the canopy came back as fourteen spiky lumps — a visible
    # regression against the tree already in the game, which is what the render
    # caught. 2 is the code's own lobe, and its 11 mm facet is also what the
    # bake distance below is set against.
    parts.append(garden.balls("TreeCanopy", leaves,
                              [(r, to_blender(c)) for r, c in LOBES],
                              subdivisions=2))

    # 5 mm across a 139 mm canopy — the wolkenroom's 2.2 mm scaled by the
    # *facet* rather than by the prop, which is the number that matters: these
    # lobes are 30–47 mm across but their facets are 11 mm, near enough the
    # cloud's own. What it has to find is the same thing — the crease where two
    # lobes push into each other, and the ring where the trunk goes up into the
    # underside. 9 mm was tried first and looks identical from outside: every
    # extra face it shaded was one already buried inside a neighbouring lobe.
    # A canopy shaded all over is a hedge at dusk.
    return garden.finish(NAME, parts, distance=0.0050)


if __name__ == "__main__":
    garden.write(build(), "garden-tree")
