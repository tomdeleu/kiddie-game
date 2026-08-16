"""The ripe clover plant, modelled in Blender.

    blender --background --python models/plant-klaver.py

Reference: `references/garden/plant-klaver.png`. Writes
`app/NinaBakeryPOC/Resources/Models/plant-klaver.usdz`.

**Two heads on two curved stems**, which is what the plate is actually about and
what `GardenProps` cannot say at all. A clover does not grow one flower on a
mast: it throws up several stems from one crown and each carries its own head,
and the plate draws exactly that — a taller stem leaning one way, a shorter one
leaning the other, both bending as they go.

`garden.sweep` is what makes it possible. `FacetedMesh` has no bend, so the code
version stands one straight prism up the middle and hangs the kitchen's token on
it, and the reason nobody noticed is that a single stem is the one arrangement a
straight prism can be right about.

The heads are `models/klaver.py`'s petal, unchanged — the fold, four hearts, one
colour. **Four petals, not the plate's three**: that decision is already
recorded on `KitchenProps.buildClover`, and a four-leaf clover is the lucky one,
which is the right note for the ingredient with *tover* in its name.

Both stems lean along the game's **X−Z diagonal**, which is the one direction in
this room that is exactly screen-horizontal (`GardenLayout.flowerSpot` proves it
for the flower row). Leaning them apart along +X would put one head in front of
the other from the fixed camera, and two heads that overlap are one head.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import garden

NAME = "PlantKlaver"

#: The tall stem and the short one, each as a path from the crown to its head.
#: In Blender the game's X−Z diagonal is +X+Y, so one leans to +X+Y and the
#: other to −X−Y.
STEMS = [[(0.0000, 0.0000, 0.0040),
          (-0.0016, -0.0016, 0.0130),
          (-0.0048, -0.0048, 0.0240),
          (-0.0074, -0.0074, 0.0330)],
         [(0.0000, 0.0000, 0.0040),
          (0.0022, 0.0022, 0.0110),
          (0.0060, 0.0060, 0.0195),
          (0.0082, 0.0082, 0.0262)]]
STEM_RADII = [0.0018, 0.0016, 0.0014, 0.0013]

#: How far each head tips forward out of upright. A clover head held dead
#: vertical is a sign; tipped, it is a leaf you are looking down onto — and this
#: camera looks down about 34°.
HEAD_TILT = -0.42


def build():
    garden.fresh("Plant", "Klaver")

    leaf_green = garden.material("KlaverLeaf", garden.SAGE)
    stem_green = garden.material("KlaverStem", garden.SAGE_DEEP)
    earth = garden.material("KlaverEarth", garden.WOOD_BROWN)

    # **No straight stem.** The two swept ones are the stems, and a vertical
    # prism between them would be a third plant nobody asked for.
    parts = garden.plant_base(leaf_green, stem_green, earth, with_stem=False)

    for i, path in enumerate(STEMS):
        parts.append(garden.sweep("PlantStalk%d" % i, stem_green, path,
                                  STEM_RADII, sides=5))
        parts += garden.clover_head("KlaverBlad", leaf_green, first=i * 4,
                                    at=path[-1],
                                    rot=(HEAD_TILT, 0.0, garden.FACING_CAMERA))

    # 2.5 mm — `models/klaver.py`'s own number, and for its own reason: the
    # petals are 10 mm long, so this stays at the hub where four of them crowd
    # together and never darkens a petal's open face.
    return garden.finish(NAME, parts, distance=0.0025)


if __name__ == "__main__":
    garden.write(build(), "plant-klaver")
