"""The ripe moon-dust plant, modelled in Blender.

    blender --background --python models/plant-maanstof.py

Reference: `references/garden/plant-maanstof.png`. Writes
`app/NinaBakeryPOC/Resources/Models/plant-maanstof.usdz`.

**The pouch, as a seed pod.** The kitchen's token is cloth — a bag gathered at
the neck, because dust has no shape and is read through its container. A bag
does not grow on a stem, and the plate does the obvious right thing with that:
the same round belly and the same narrow neck, but the neck has **split open**
into a crown of pointed teeth with the dark inside showing between them.

`garden.wedge_ring` is what the split needs and it is the one shape in the
garden nothing else wanted. Each tooth is a four-sided pyramid rather than a
board — a tooth with a flat top is a battlement, and this has to read as
something that burst rather than as something that was built.

The dark opening is `Palette.lilacDeep` and not a hole. A hole in a closed mesh
is a face wound inwards, which RealityKit culls: it would not be dark, it would
be a window through the prop (`models/README.md`, "Outward winding").
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import garden

NAME = "PlantMaanstof"

#: The pod. Round-bellied and narrow-necked, which is the silhouette the token's
#: pouch was given so that it could never be mistaken for a small flour sack —
#: and the same reason holds here, because this bed also grows a strawberry.
POD = [(0.0000, 0.0000),
       (0.0060, 0.0024),
       (0.0095, 0.0072),
       (0.0102, 0.0124),
       (0.0088, 0.0166),
       (0.0064, 0.0190)]
MOUTH = 0.0190
MOUTH_RADIUS = 0.0064


def build():
    garden.fresh("Plant", "Maanstof")

    leaf_green = garden.material("MaanstofLeaf", garden.SAGE)
    stem_green = garden.material("MaanstofStem", garden.SAGE_DEEP)
    earth = garden.material("MaanstofEarth", garden.WOOD_BROWN)
    pod_lilac = garden.material("MaanstofPod", garden.LILAC)
    crown_pale = garden.material("MaanstofCrown", garden.CREAM_LIGHT)
    inside = garden.material("MaanstofInside", garden.LILAC_DEEP)

    parts = garden.plant_base(leaf_green, stem_green, earth)
    head = garden.HEAD_Z

    parts.append(garden.lathe("MaanstofPeul", pod_lilac, POD, 9,
                              at=(0.0, 0.0, head)))

    # The inside, a hair above the pod's own cap so it is the surface you see
    # down the neck rather than z-fighting with it.
    parts.append(garden.prism("MaanstofOpening", inside,
                              MOUTH_RADIUS - 0.0008, 0.0008, 9,
                              at=(0.0, 0.0, head + MOUTH - 0.0004)))

    # Six teeth, splaying up and out. Six rather than the plate's five: an even
    # count puts a tooth on each side of the silhouette from any angle, and at
    # 20 mm the silhouette is the whole of what says *split open*.
    parts.append(garden.wedge_ring(
        "MaanstofKroon", crown_pale, 6,
        base_radius=MOUTH_RADIUS - 0.0004, base_width=0.0052,
        tip_radius=0.0090, height=0.0088, thickness=0.0024,
        at=(0.0, 0.0, head + MOUTH - 0.0016)))

    # 2.2 mm. It has to find the ring where the teeth stand out of the neck and
    # the step down to the dark inside, and nothing else — the pod's belly is
    # convex everywhere and has nothing to say.
    return garden.finish(NAME, parts, distance=0.0022)


if __name__ == "__main__":
    garden.write(build(), "plant-maanstof")
