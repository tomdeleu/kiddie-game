"""Het hek — the picket fence that De Tuin has instead of walls.

    blender --background --python models/garden-fence.py

References: `references/garden/garden-fence.png` for the pickets and rails,
`references/garden/fence-gate.png` for the capped posts, and
`references/garden/roombox-v2.png` for where the whole thing stands. Writes
`app/NinaBakeryPOC/Resources/Models/garden-fence.usdz`.

**The whole L, in one file.** Every other prop here is one object placed by the
room; this is the room's own boundary, so the model is built in world
coordinates and dropped at the origin. It is the same two runs
`GardenRoomBuilder.addRun` lays out — the same posts, the same 19 mm picket
spacing, the same gap for the gate — computed here rather than in Swift, and the
reason to move it is that it stops being forty-odd separate entities: three
meshes carry the lot.

**It is not a room box, and that is an owner's call**
(`GardenLayout.fenceLineX`): a garden with plaster round it is a garden indoors.
The rule's purpose survives exactly — the fence stands on the two far edges,
where the walls stood, so the two near sides are open and nothing has entered a
sightline.

Two things from the plate, and one deliberately left out:

  * **Chamfered pickets.** `GardenRoomBuilder` cuts a flat board, which gives a
    picket two faces and both of them flat. The plate draws turned timber with
    the corners taken off, so a picket shows four tones instead of two — which
    is most of what makes a row of forty read as forty rather than as a fringe.
    The footprint is unchanged: 8 mm along the run, so the **11 mm gap between
    pickets stays**, and that gap is what makes this a fence and not a low wall.
  * **A faceted point on every picket**, and a flat pyramid cap on every post.
  * **The grey bolt heads are not modelled.** Two per picket, each under a
    screen pixel at this scale. `references/REFERENCES.md` §1 is explicit that
    fine detail fights the style, and this is the same call the door's four
    panels made when they became two.

**And the rails stay behind the pickets**, where the code put them, against a
plate that clearly nails them to the front. The plate is a studio shot on a grey
backdrop with nothing standing next to it; in the room, the inside face of the
left run is 4 mm from the back of the potting bench, and a 10 mm rail on that
side goes through it. It is `references/garden/README.md`'s own rule pointing
the other way for once: *a plate cannot answer a question about the room it is
not standing in*, and this time the room-box plate does not answer it either.
"""

import os
import sys

import bmesh

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import garden
import lowpoly

NAME = "Fence"

# ------------------------------------------------------- `GardenLayout` says
HALF = 0.46 / 2
LINE_X = -0.212
LINE_Z = -0.212
FLOOR_Y = 0.004
HEIGHT = 0.070
POST_HEIGHT = 0.086
POST_SIZE = 0.016
#: (along the run, across it).
PICKET = (0.008, 0.013)
PICKET_SPACING = 0.019
POST_SPACING = 0.114
RAILS = [0.30, 0.72]
#: The rails sit **flush against the back of the pickets**, not overlapping
#: them. `GardenRoomBuilder` centres them 8 mm out from the run's line, which
#: buries 3.5 mm of rail inside every picket it passes — invisible while both
#: were separate entities, and two problems once they are one mesh: coplanar
#: faces inside solid geometry, and an occlusion bake that measures the join
#: from *inside* it and comes back with the rail uniformly dark and the pickets
#: untouched. Butted, the bake finds what is actually there: the strip of rail
#: in each 11 mm gap that a picket edge shades.
RAIL_ACROSS = -(PICKET[1] / 2 + 0.010 / 2)
RAIL_DEPTH = 0.010
RAIL_HEIGHT = 0.007
GATE_Z = 0.160
GATE_OPENING = 0.080
#: Each run ends past the slab's edge, so the L closes at the far corner and
#: simply runs out of frame at the other — which is what a garden fence does.
END = HALF + 0.004

# ------------------------------------------------------------ what the plate
CHAMFER = 0.0022
POINT_RISE = 0.0072
CAP_HALF = 0.0094
CAP_RISE = 0.0092


def to_blender(x, y, z):
    """Game (x, y, z) → Blender. The exporter maps it back on the way out."""
    return (x, -z, y)


def game_box(x, y, z):
    """A `(min, max)` box in game axes, as `lowpoly.add_box` wants it."""
    return ((x[0], x[1]), (-z[1], -z[0]), (y[0], y[1]))


def run(along_z, line, start, end, gap_centre):
    """One straight run: its posts, its pickets and its rail spans.

    A transcription of `GardenRoomBuilder.addRun`, deliberately — the fence has
    to stand exactly where the room has always drawn it, and the one thing that
    must not happen is a model and a layout file disagreeing by a picket.
    """
    def place(across, y, along):
        return (line + across, y, along) if along_z else (along, y, line + across)

    gap = None
    if gap_centre is not None:
        half_gap = GATE_OPENING / 2 + POST_SIZE
        gap = (gap_centre - half_gap, gap_centre + half_gap)

    posts = [start]
    at = start + POST_SPACING
    while at < end:
        posts.append(at)
        at += POST_SPACING
    posts.append(end)
    if gap_centre is not None:
        offset = GATE_OPENING / 2 + POST_SIZE / 2
        posts += [gap_centre - offset, gap_centre + offset]
        posts = [p for p in posts if abs(p - gap_centre) >= offset - 0.001]

    pickets = []
    along = start + PICKET_SPACING
    while along < end:
        if not (gap and gap[0] <= along <= gap[1]) and \
                not any(abs(p - along) < POST_SIZE for p in posts):
            pickets.append(along)
        along += PICKET_SPACING

    spans = [(start, gap[0]), (gap[1], end)] if gap else [(start, end)]
    return place, posts, pickets, [s for s in spans if s[1] - s[0] > 0.004]


def build():
    garden.fresh("Fence")

    picket_cream = garden.material("FencePicket", garden.CREAM)
    frame_cream = garden.material("FenceFrame", garden.CREAM_LIGHT)

    runs = [run(True, LINE_X, LINE_Z, END, GATE_Z),
            run(False, LINE_Z, LINE_X, END, None)]

    pickets = bmesh.new()
    posts = bmesh.new()
    rails = []

    for along_z, (place, post_at, picket_at, spans) in zip((True, False), runs):
        # The picket's 8 mm face looks along the run and its 13 mm one across
        # it, whichever way the run travels.
        half_along, half_across = PICKET[0] / 2, PICKET[1] / 2
        section = garden.octagon(half_across, half_along, CHAMFER) if along_z \
            else garden.octagon(half_along, half_across, CHAMFER)
        for along in picket_at:
            garden.add_column(
                pickets, section,
                [(1.0, 0.0), (1.0, HEIGHT), (0.55, HEIGHT + 0.0026),
                 (0.0, HEIGHT + POINT_RISE)],
                at=to_blender(*place(0.0, FLOOR_Y, along)))

        square = [(-POST_SIZE / 2, -POST_SIZE / 2), (POST_SIZE / 2, -POST_SIZE / 2),
                  (POST_SIZE / 2, POST_SIZE / 2), (-POST_SIZE / 2, POST_SIZE / 2)]
        cap = [(-CAP_HALF, -CAP_HALF), (CAP_HALF, -CAP_HALF),
               (CAP_HALF, CAP_HALF), (-CAP_HALF, CAP_HALF)]
        for along in post_at:
            foot = to_blender(*place(0.0, FLOOR_Y, along))
            garden.add_column(posts, square, [(1.0, 0.0), (1.0, POST_HEIGHT)],
                              at=foot)
            garden.add_column(posts, cap,
                              [(1.0, POST_HEIGHT), (0.86, POST_HEIGHT + 0.0032),
                               (0.0, POST_HEIGHT + CAP_RISE)], at=foot)

        for rail in RAILS:
            y = FLOOR_Y + HEIGHT * rail
            for low, high in spans:
                a = place(RAIL_ACROSS, y, low)
                b = place(RAIL_ACROSS, y, high)
                across = (RAIL_DEPTH / 2 if along_z else 0.0,
                          0.0 if along_z else RAIL_DEPTH / 2)
                rails.append(game_box(
                    (min(a[0], b[0]) - across[0], max(a[0], b[0]) + across[0]),
                    (y - RAIL_HEIGHT / 2, y + RAIL_HEIGHT / 2),
                    (min(a[2], b[2]) - across[1], max(a[2], b[2]) + across[1])))

    parts = [garden.placed("FencePickets", picket_cream, pickets),
             garden.placed("FencePosts", frame_cream, posts),
             garden.boxes("FenceRails", frame_cream, rails)]

    # **3 mm, and it finds nothing — which is the honest answer for this prop
    # and worth recording rather than tuning away.**
    #
    # The bake quantises occlusion onto whole facets, and a fence is butted
    # boxes with very large ones: a rail's front face is a single 400 mm
    # polygon, so the strip of it that each picket edge would shade is averaged
    # across the entire run and comes back as nothing. Raising the distance does
    # not fix that, it just tips the whole face over the threshold and darkens
    # 400 mm of rail.
    #
    # The spoon reached the same place from the other direction
    # (`models/README.md`): a shape with barely a crevice in it measures as
    # having barely a crevice in it. Everything the fence needed from shading it
    # already gets from its facets — the chamfers give a picket four tones, and
    # the 11 mm gaps give the row its rhythm.
    return garden.finish(NAME, parts, distance=0.0030)


if __name__ == "__main__":
    garden.write(build(), "garden-fence")
