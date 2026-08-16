"""The ripe cloud-cream plant, modelled in Blender.

    blender --background --python models/plant-wolkenroom.py

Reference: `references/garden/plant-wolkenroom.png`. Writes
`app/NinaBakeryPOC/Resources/Models/plant-wolkenroom.usdz`.

**A cloud resting where the flower would be**, which is the plate's whole joke
and the reason this plant needs no head of its own: the cluster *is* the flower.

Six overlapping faceted balls, not one. `models/README.md` records the rule from
the garden tree — a single sphere on a stick is a lollipop — and the cloud is
the same construction one size down. What the model buys over
`KitchenProps.buildCloudCream`'s four balls is the **contact shading between
them**: where two lobes push into each other there is a crease the facets cannot
answer, because both surfaces face outwards and come back the same tone. Four
separate `ModelEntity` spheres cannot be measured against each other at all;
here they are one mesh with a bake over it.

The lobes are fixed rather than random, which is the same call
`GardenProps.tree` makes: a cloud that rebuilds differently every time the
flat-shading toggle flips is a cloud that moved while she was looking.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import garden

NAME = "PlantWolkenroom"

#: `(radius, centre)` in the head's own frame, Blender axes. Wide and low, the
#: way the plate draws it: a cloud that is as tall as it is wide is a cauliflower.
LOBES = [(0.0068, (-0.0082, -0.0012, 0.0074)),
         (0.0070, (0.0080, 0.0022, 0.0078)),
         (0.0060, (0.0006, -0.0072, 0.0068)),
         (0.0058, (-0.0028, 0.0068, 0.0082)),
         (0.0055, (0.0042, -0.0038, 0.0122))]
#: The one that carries the top of the silhouette, a shade lighter — the same
#: split `KitchenProps.buildCloudCream` makes, and the only thing standing
#: between this and one flat white blob.
CROWN = (0.0072, (0.0000, 0.0010, 0.0128))


def build():
    garden.fresh("Plant", "Room", "Wolk")

    leaf_green = garden.material("WolkLeaf", garden.SAGE)
    stem_green = garden.material("WolkStem", garden.SAGE_DEEP)
    earth = garden.material("WolkEarth", garden.WOOD_BROWN)
    cloud = garden.material("WolkCloud", garden.CREAM)
    cloud_top = garden.material("WolkCloudTop", garden.CREAM_LIGHT)

    parts = garden.plant_base(leaf_green, stem_green, earth)
    head = (0.0, 0.0, garden.HEAD_Z)

    parts.append(garden.balls("RoomBol", cloud, LOBES, at=head))
    parts.append(garden.balls("RoomBolTop", cloud_top, [CROWN], at=head))

    # 2.2 mm across a 27 mm cloud: enough to find the seams where two lobes push
    # into each other and the ring where the stem enters underneath, and far too
    # short to reach across a lobe's own face. A cloud shaded all over is fog.
    return garden.finish(NAME, parts, distance=0.0022)


if __name__ == "__main__":
    garden.write(build(), "plant-wolkenroom")
