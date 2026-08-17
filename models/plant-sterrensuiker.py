"""The ripe sugar-star plant, modelled in Blender.

    blender --background --python models/plant-sterrensuiker.py

Reference: `references/garden/plant-sterrensuiker.png`. Writes
`app/NinaBakeryPOC/Resources/Models/plant-sterrensuiker.usdz`.

**The ridge is the whole model.** `FacetedMesh.star` extrudes a flat outline, so
the star's entire front is one tone and the five arms are told apart only by
where they stop. The plate does something else: the centre stands proud and a
hard crease runs from it out to every tip, with a valley between each pair — so
each arm is two facets at different angles and the star has a *surface* rather
than an outline.

It is `models/README.md`'s blueberry-crown lesson upside down. There the centre
had to be the **low** point, because a raised middle turned five spikes into one
hat. Here the plate wants that hat, and it is right to: a sugar star is a solid
object, not a crown standing in a calyx.

Turned to face the camera, like the clover and the feather. The flat props in
this game are cheap and read instantly at thumbnail size, and nothing ever moves
the camera, so facing it is a constant rather than a billboard.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import garden

NAME = "PlantSterrensuiker"

OUTER = 0.0115
INNER = 0.0048
#: How far the centre stands proud towards the viewer, and how far behind. Not
#: symmetrical: the plate's star is a low pyramid on the front and nearly flat
#: behind, which is what keeps the crease reading as a crease rather than as the
#: edge of a diamond.
DEPTH = 0.0034
BACK_DEPTH = 0.0018

#: The lowest points of a five-point star standing on two arms are at
#: sin(234°) = −0.809 of the outer radius, so this is what lifts it to sit on
#: the stem rather than sink into it.
LIFT = OUTER * 0.809


def build():
    garden.fresh("Plant", "Ster")

    leaf_green = garden.material("SterLeaf", garden.SAGE)
    stem_green = garden.material("SterStem", garden.SAGE_DEEP)
    earth = garden.material("SterEarth", garden.WOOD_BROWN)
    sugar = garden.material("SterSugar", garden.MINT_LIGHT)

    parts = garden.plant_base(leaf_green, stem_green, earth)

    parts.append(garden.ridged_star(
        "SterBody", sugar, 5, OUTER, INNER, DEPTH, back_depth=BACK_DEPTH,
        at=(0.0, 0.0, garden.HEAD_Z + LIFT),
        rot=(0.0, 0.0, garden.FACING_CAMERA)))

    # 2.0 mm, and the star will barely use it — it is convex from the front and
    # every crease on it is a ridge rather than a groove. What this finds is the
    # valley between two arms and the joint where the stem enters, which is
    # exactly the honest amount for a shape this open. The spoon taught the same
    # thing (`models/README.md`).
    return garden.finish(NAME, parts, distance=0.0020)


if __name__ == "__main__":
    garden.write(build(), "plant-sterrensuiker")
