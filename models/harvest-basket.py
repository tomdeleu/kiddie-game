"""Het oogstmandje, modelled in Blender.

    blender --background --python models/harvest-basket.py

Reference: `references/garden/harvest-basket.png`. Writes
`app/NinaBakeryPOC/Resources/Models/harvest-basket.usdz`.

**Square, on the plate's say-so**, and `GardenProps.basket` already argues why
it earns that: the kitchen has a round basket on the table, and two baskets in
one game had better not be the same object in two colours.

What the plate asks for that the code cannot say, all four of them about the
same thing — a basket is a container, and a container has an inside:

  * **A lining in a different colour.** `FacetedMesh.bowl` is the vocabulary's
    one double-walled primitive and it is **one mesh with one tone**, so the
    code's basket is sandy inside and out. The plate lines it in rose, and that
    lining is most of what you see: the camera looks down into the tub.
  * **A rim with a thickness.** The code lays a flat `annulus` across the top at
    `basketRimY` — a plate resting on a tub. The plate draws a mint **band**
    that stands 5 mm tall, stands 2.1 mm proud of the body, and therefore has
    an underside. That underside is a real overhang, and the bake finds it.
  * **A tapered tub with a foot.** Straight from a narrow base to a wide mouth
    with a small chamfer where it sits down, rather than one cone.
  * **One handle.** The code arcs seven boxes over the rim; they overlap at
    their corners and each is cut square, so the arch is seven objects reading
    as seven objects. `garden.sweep` carries one section round the arc and
    mitres every joint.

**The handle spans the diagonal the camera actually looks across.** The code
stands it along the world X, which the fixed camera on the +X+Z diagonal sees
end-on and foreshortened. The plate draws it corner to corner, square to the
eye, and that is the (+X, −Z) diagonal — `HANDLE_ACROSS` below.

**It is built axis-aligned and the Swift side drops its 45° turn**, which is
`models/crate.py`'s rule for the same reason: the camera looks down the +X+Z
diagonal, so a box whose faces are square to the world already shows two sides
and the corner between them — the plate's own view.

Every dimension the room was laid out against is kept: the rim is at
`GardenLayout.basketRimY` (26 mm), the tub is 45 mm across its flats against a
38 mm touch sphere and a 30 mm contact shadow, and the inside at the height
`GardenRoom.refreshBasketContents` stacks tokens is the width it was.
"""

import math
import os
import sys

import bmesh

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import garden
import lowpoly

NAME = "HarvestBasket"

#: Vertices per side of the square. Two rather than one, and the extra one is
#: for the bake rather than for the shape: a wall that is one 45 mm quad has
#: nothing to quantise, which is `models/README.md`'s fence lesson, and the
#: shadow under the rim would be averaged away across the whole side.
PER_SIDE = 2

#: The outer body, `(half-width, z)`. The bottom two stations are the plate's
#: little chamfered foot; the top one is `GardenProps.basket`'s own 29 mm corner
#: radius, which is 20.5 mm across the flat.
#:
#: **The body has to come up nearly to the rim's own width**, which cost one
#: render. At 19.2 the band overhung it by 3.4 mm, and from a camera looking
#: down at 31° a 3.4 mm brim hides the tub: the render came back as a green tray
#: with a sliver of basket under it. The plate stands its band on a body that
#: reaches almost to the same width, so the tub is what you see and the band is
#: a band.
OUTER = [(0.0118, 0.0000),
         (0.0136, 0.0026),
         (0.0205, 0.0210)]

#: The rim band: it steps out to 22.6 mm — the code's 32 mm corner radius — and
#: stands to `GardenLayout.basketRimY`.
RIM_HALF = 0.0226
RIM_BASE = 0.0210
RIM_TOP = 0.0260

#: The lining, top first, `(half-width, z)`. Its mouth is the code's inner
#: radius and its floor is 3 mm up, so what the tub holds is what it held.
INNER = [(0.0184, 0.0260),
         (0.0150, 0.0140),
         (0.0106, 0.0030)]

#: The handle. `ACROSS` is the game's (+X, −Z) in Blender axes — the horizontal
#: that the fixed camera looks square at — and `NORMAL` is the plane it arches
#: in. Radius 29 mm puts both feet on the flat of the rim band, 2 mm buried in
#: it so no cut end is ever in the air.
HANDLE_ACROSS = (math.sqrt(0.5), math.sqrt(0.5), 0.0)
HANDLE_NORMAL = (math.sqrt(0.5), -math.sqrt(0.5), 0.0)
HANDLE_RADIUS = 0.0290
HANDLE_RISE = 0.0235
HANDLE_FOOT = RIM_TOP - 0.0020
HANDLE_THICKNESS = 0.0028
HANDLE_STATIONS = 9


def square_ring(bm, half, z):
    """One square ring, wound anticlockwise, **corners on the diagonals**.

    `lowpoly.ring` with four sides puts its vertices on the axes, which turns
    the faces 45° and stands a flat side square to the camera. A basket wants
    the opposite: corner to the eye, two sides visible, which is what the plate
    draws and what `models/crate.py` records as the reason a box needs no turn.
    """
    corners = [(half, -half), (half, half), (-half, half), (-half, -half)]
    verts = []
    for index, (x0, y0) in enumerate(corners):
        x1, y1 = corners[(index + 1) % 4]
        for step in range(PER_SIDE):
            t = step / float(PER_SIDE)
            verts.append(bm.verts.new((x0 + (x1 - x0) * t,
                                       y0 + (y1 - y0) * t, z)))
    return verts


def band(bm, lower, upper):
    """Bridge two rings. Lower→upper faces outward; reverse it to face inward.

    The whole tub is that one sentence: up the outside, out under the rim's
    overhang, up the band, across the top, and back **down the inside** with the
    arguments swapped. Winding is the normal (`models/README.md`), and each of
    the three shells here is open, so `lowpoly.flat_obj` leaves it exactly as
    wound rather than recalculating it.
    """
    lowpoly.bridge(bm, lower, upper, 4 * PER_SIDE)


def build_tub(material):
    """The outside and the bottom, sandy. Open where the rim takes over."""
    bm = bmesh.new()
    rings = [square_ring(bm, half, z) for half, z in OUTER]
    for lower, upper in zip(rings, rings[1:]):
        band(bm, lower, upper)
    bm.faces.new(list(reversed(rings[0])))
    return garden.placed("BasketTub", material, bm)


def build_rim(material):
    """The mint band: its underside, its outer face and its top.

    Three bands rather than a ring laid on top, and the first of them is the
    one the plate is really asking for — a 2.1 mm **overhang**, facing down,
    which is the only shadow on this prop that reads from across the room.
    """
    bm = bmesh.new()
    under = square_ring(bm, OUTER[-1][0], RIM_BASE)
    out_low = square_ring(bm, RIM_HALF, RIM_BASE)
    out_high = square_ring(bm, RIM_HALF, RIM_TOP)
    mouth = square_ring(bm, INNER[0][0], RIM_TOP)
    band(bm, under, out_low)      # the overhang, facing down
    band(bm, out_low, out_high)   # the band itself
    band(bm, out_high, mouth)     # the top, facing up
    return garden.placed("BasketRim", material, bm)


def build_lining(material):
    """The rose inside, wound the other way, and its floor."""
    bm = bmesh.new()
    rings = [square_ring(bm, half, z) for half, z in INNER]
    for upper, lower in zip(rings, rings[1:]):
        band(bm, upper, lower)
    bm.faces.new(rings[-1])
    return garden.placed("BasketLining", material, bm)


def build_handle(material):
    """One swept arc from rim to rim, over the diagonal the camera looks along."""
    points = []
    for index in range(HANDLE_STATIONS):
        angle = math.pi * index / (HANDLE_STATIONS - 1)
        reach = math.cos(angle) * HANDLE_RADIUS
        points.append((HANDLE_ACROSS[0] * reach,
                       HANDLE_ACROSS[1] * reach,
                       HANDLE_FOOT + math.sin(angle) * HANDLE_RISE))
    # `up` is the plane's own normal, which is what keeps the section from
    # tumbling at the two ends: the fallback in `garden.sweep` triggers when the
    # tangent is parallel to `up`, and the tangent at a foot is straight up.
    return garden.sweep("BasketHandle", material, points, HANDLE_THICKNESS,
                        sides=6, up=HANDLE_NORMAL)


def build():
    garden.fresh("Basket", "Harvest")

    body = garden.material("BasketWood", garden.SANDY_WOOD)
    band_green = garden.material("BasketBand", garden.MINT)
    lining = garden.material("BasketLining", garden.ROSE)
    cane = garden.material("BasketCane", garden.CREAM_LIGHT)

    parts = [build_tub(body), build_rim(band_green),
             build_lining(lining), build_handle(cane)]

    # 3 mm across a 45 mm basket, set against a 2.6 mm wall and a 4.2 mm rim
    # band so it never reaches out onto the flat of either. What it has to find
    # is the underside of the rim's overhang, the corners where the lining folds
    # into its own floor, and the two places the handle stands on the band.
    return garden.finish(NAME, parts, distance=0.0030)


if __name__ == "__main__":
    garden.write(build(), "harvest-basket")
