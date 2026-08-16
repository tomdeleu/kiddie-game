"""De zaaibak — the raised planter, modelled in Blender.

    blender --background --python models/garden-bed.py

Reference: `references/garden/garden-bed.png`. Writes
`app/NinaBakeryPOC/Resources/Models/garden-bed.usdz`.

**It is the room's required action**, so it is the one prop in De Tuin that has
to read instantly from across the floor: five drags to plant, three sweeps to
water, five taps to pick, all of it on this. Everything here comes off the
plate.

Three things the code version does not have:

  * **Two board bands, not one.** `GardenRoomBuilder.buildBed` runs a single
    40 mm slab from the ground to the rim; the plate draws two planks with a
    groove between them, which is the difference between a bed built out of
    boards and a bed cast out of one piece. It is the crate's argument
    (`models/README.md`) at a larger size: a crate is joinery.
  * **Posts standing proud of the boards.** The code makes them flush, so the
    corner post is a corner rather than a post. The plate insets the boards
    2 mm and lets the four posts stand out past them, and that is the whole of
    what makes it read as a frame with sides fixed to it.
  * **Holes with a wall.** The code sinks a flat annulus 1.2 mm above the soil.
    The plate's holes are rings you can see *into* — a wall standing proud of
    the soil with a recess inside it — and that matters beyond looks: the halo
    can only ever be on one hole, so the other four have to be legible on their
    own facets (`GardenRoomBuilder.buildBed` already argues this and then
    builds a flat ring).

    **The recess comes from dropping the soil, not from cutting it.** A hole
    through a slab is a boolean, and a boolean on a flat-shaded low-poly mesh
    hands back a fan of triangles where there was one facet. So the soil sits
    3 mm lower than `GardenLayout.bedSoilY` and each ring stands 2.2 mm above
    it: what she looks down into is a 5 mm well with a lit rim and a floor, made
    of nothing but two convex solids that happen to overlap. The plant still
    grows at `bedSoilY`, which puts its mound's foot inside the ring — earth in
    a hole, which is what a sown hole should look like.

**Every dimension is `GardenLayout`'s.** The bed is where the game says it is,
the five holes are `plotSpot` to the millimetre, and the rim is what a carried
seed rides over (`GardenLayout.surfaces`). A model that disagreed with that
table by a millimetre would be the exact bug the table exists to prevent.
"""

import os
import sys

import bmesh

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import garden
import lowpoly

NAME = "SeedBed"

# ------------------------------------------------------- `GardenLayout` says
SIZE_X = 0.250
SIZE_Z = 0.080
FLOOR_Y = 0.004
RIM_Y = 0.050
SOIL_Y = 0.040
RIM_WIDTH = 0.012
POST = 0.016
PLOTS = 5
PLOT_RADIUS = 0.015

# ------------------------------------------------------------ what the plate
#: How far the boards sit inside the posts' faces. Small, and it is the
#: difference between four corners and four posts.
INSET = 0.002
#: The two board bands and the groove between them.
BOARD_GAP = 0.004
BOARD_THICKNESS = 0.006
RAIL_HEIGHT = 0.008
#: How far the soil sits below `GardenLayout.bedSoilY`. It is what makes the
#: rings wells rather than washers — see the module docstring.
SOIL_DROP = 0.003
#: The hole's ring: how far its wall stands above `bedSoilY`, how far it is
#: buried below, and how thick it is.
HOLE_PROUD = 0.0022
HOLE_BURIED = 0.0060
HOLE_WALL = 0.0035


def plot_x(index):
    """`GardenLayout.plotSpot`, relative to the bed's own centre."""
    usable = SIZE_X - 2 * RIM_WIDTH - POST
    spacing = usable / PLOTS
    return -usable / 2 + spacing / 2 + spacing * index


def build():
    garden.fresh("Bed", "SeedBed")

    board_pink = garden.material("BedBoard", garden.BLUSH_PINK_DEEP)
    frame_rose = garden.material("BedFrame", garden.ROSE)
    soil_brown = garden.material("BedSoil", garden.WOOD_BROWN)
    hole_edge = garden.material("BedHoleEdge", garden.HOLE_EDGE)

    half_x = SIZE_X / 2
    half_z = SIZE_Z / 2
    board_face_z = half_z - INSET
    board_face_x = half_x - INSET

    # **The two bands.** Between the floor and the underside of the rim there is
    # 38 mm; two planks and a 4 mm groove is 17 mm each.
    span = (RIM_Y - RAIL_HEIGHT) - FLOOR_Y
    plank = (span - BOARD_GAP) / 2
    bands = [(FLOOR_Y, FLOOR_Y + plank),
             (FLOOR_Y + plank + BOARD_GAP, FLOOR_Y + span)]

    def inwards(face, side):
        """A board's span, from its outward face inwards by its thickness."""
        return (face - BOARD_THICKNESS, face) if side > 0 else \
               (face, face + BOARD_THICKNESS)

    boards = []
    for low, high in bands:
        for side in (-1, 1):
            boards.append(((-half_x + POST / 2, half_x - POST / 2),
                           inwards(side * board_face_z, side),
                           (low, high)))
            boards.append((inwards(side * board_face_x, side),
                           (-half_z + POST / 2, half_z - POST / 2),
                           (low, high)))
    parts = [garden.boxes("BedBoards", board_pink, boards)]

    # The rim, four rails laid flat on top, and the four posts standing through
    # them and 6 mm above.
    frame = []
    for side in (-1, 1):
        frame.append(((-half_x, half_x),
                      (side * (half_z - RIM_WIDTH / 2) - RIM_WIDTH / 2,
                       side * (half_z - RIM_WIDTH / 2) + RIM_WIDTH / 2),
                      (RIM_Y - RAIL_HEIGHT, RIM_Y)))
        frame.append(((side * (half_x - RIM_WIDTH / 2) - RIM_WIDTH / 2,
                       side * (half_x - RIM_WIDTH / 2) + RIM_WIDTH / 2),
                      (-half_z + RIM_WIDTH, half_z - RIM_WIDTH),
                      (RIM_Y - RAIL_HEIGHT, RIM_Y)))
    for sx in (-1, 1):
        for sz in (-1, 1):
            frame.append(((sx * (half_x - POST / 2) - POST / 2,
                           sx * (half_x - POST / 2) + POST / 2),
                          (sz * (half_z - POST / 2) - POST / 2,
                           sz * (half_z - POST / 2) + POST / 2),
                          (FLOOR_Y, RIM_Y + 0.006)))
    parts.append(garden.boxes("BedFrame", frame_rose, frame))

    parts.append(garden.boxes("BedSoil", soil_brown,
                              [((-half_x + RIM_WIDTH, half_x - RIM_WIDTH),
                                (-half_z + RIM_WIDTH, half_z - RIM_WIDTH),
                                (SOIL_Y - 0.012, SOIL_Y - SOIL_DROP))]))

    # **The five holes.** A ring wall standing proud of the soil and buried into
    # it — nine sides, so no two facets of a hole are parallel and the ring
    # catches the key light on one side whichever way it is turned.
    #
    # Four bands bridged in a loop rather than two discs capping a tube: an
    # annulus closed with a disc at each end is a solid with its own inside
    # doubled back through it, which the winding pass cannot recalculate and the
    # occlusion bake reads as a face buried in geometry.
    bm = bmesh.new()
    top = SOIL_Y + HOLE_PROUD
    bottom = SOIL_Y - HOLE_BURIED
    for index in range(PLOTS):
        x = plot_x(index)
        bands = [lowpoly.ring(bm, PLOT_RADIUS, bottom, 9),
                 lowpoly.ring(bm, PLOT_RADIUS, top, 9),
                 lowpoly.ring(bm, PLOT_RADIUS - HOLE_WALL, top, 9),
                 lowpoly.ring(bm, PLOT_RADIUS - HOLE_WALL, bottom, 9)]
        for band in bands:
            for vert in band:
                vert.co.x += x
        for lower, upper in zip(bands, bands[1:] + bands[:1]):
            lowpoly.bridge(bm, lower, upper, 9)
    parts.append(garden.placed("BedHoles", hole_edge, bm))

    # 4 mm, the crate's number and for the crate's reason: it is set against a
    # 6 mm board so it never reaches out onto the flat of one, and it is what
    # finds the groove between the two bands, the butt joints at every post, and
    # the step from the rim down to the soil.
    return garden.finish(NAME, parts, distance=0.0040)


if __name__ == "__main__":
    garden.write(build(), "garden-bed")
