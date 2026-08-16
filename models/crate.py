"""The crate, modelled in Blender.

    blender --background --python models/crate.py

Reference: `references/props/crate-a.png`. Writes
`app/NinaBakeryPOC/Resources/Models/crate.usdz`. Shared rules and export
settings are in `lowpoly.py`; `models/README.md` has the why.

**This one is not a shape the vocabulary was missing — it is a shape nobody
built.** The code crate is a four-sided `bowl` with a lathe ring on top: a
tapered tub with a rim, which reads as a plastic bucket, and no amount of
tuning three numbers turns a solid tub into something made of boards. A crate
is *joinery* — four corner posts with boards spanning between them and gaps you
can see through — and that is a dozen boxes, not a profile.

The plate names its own parts, which is what a good reference plate does:
corner posts standing proud of the boards, three bands around the sides, a gap
between each, and an inner floor. Two colours, sandy wood for the posts and the
bottom band, cream for the boards.

Sizes hold the prop where the room already expects it: the token that waits in
the crate is placed at `crateSpot + 17 mm` by `RoomBuilder.Layout`, and the
footprint stays inside the 26 mm contact-shadow radius `KitchenRoom` attaches.
"""

import os
import sys

import bmesh
import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lowpoly

BLEND = os.path.join(lowpoly.REPO, "models", "crate.blend")
USDZ = lowpoly.bundle_path("crate")

# Metres. Square in plan, built **axis-aligned** — faces normal to X and Z.
#
# That is deliberate and it is why the Swift side drops its 45° turn for this
# model. The old crate is a 4-sided prism, whose vertices sit on the axes and
# whose faces therefore run diagonally, so it had to be spun 45° to put a flat
# face square to the room. A box needs no such correction: the fixed camera
# looks down the +X+Z diagonal, so an axis-aligned crate already shows it two
# sides and the corner post between them, which is the plate's own view.
HALF = 0.0230        # outer half-width: 46 mm across, as the old one was
POST = 0.0058        # corner posts, square in section
POST_TOP = 0.0290    # they stand proud of the top rail, as the plate has them
BOARD = 0.0038       # board thickness
PROUD = 0.0008       # how far the posts sit outside the boards

# The three bands, bottom to top, as (z0, z1). The gaps between them are the
# whole point — a crate you cannot see through is a box.
BOTTOM = (0.0030, 0.0092)
MIDDLE = (0.0120, 0.0182)
TOP = (0.0210, 0.0272)

FLOOR = (0.0092, 0.0122)   # the inner floor, sitting on the bottom band


def _band(bm, z0, z1):
    """Four boards round the square, butted against the posts rather than
    crossing them: in the plate the posts are the thing in front."""
    outer = HALF - PROUD
    inner = outer - BOARD
    run = HALF - POST          # the boards stop where the posts start
    for sign in (1, -1):
        # Boards on the two X faces...
        lowpoly.add_box(bm, (sign * inner, sign * outer), (-run, run), (z0, z1))
        # ...and on the two Z faces.
        lowpoly.add_box(bm, (-run, run), (sign * inner, sign * outer), (z0, z1))
    return bm


def build():
    lowpoly.clear("Crate")

    board_wood = lowpoly.material("CrateBoard", 0xE4DACA)  # Palette.cream
    post_wood = lowpoly.material("CratePost", 0xC79C86)    # Palette.sandyWood

    # The boards: two bands and the floor she drops the ingredient onto.
    bm = bmesh.new()
    _band(bm, *MIDDLE)
    _band(bm, *TOP)
    run = HALF - POST
    lowpoly.add_box(bm, (-run, run), (-run, run), FLOOR)
    bm.normal_update()
    boards = lowpoly.flat_obj("CrateBoards", bm, board_wood)

    # The frame: four corner posts and the bottom band, in the darker wood. The
    # bottom band is here rather than with the boards because the plate paints
    # it with the posts, and because it reads as the thing the crate stands on.
    bm = bmesh.new()
    for sx in (1, -1):
        for sy in (1, -1):
            lowpoly.add_box(bm,
                            (sx * HALF, sx * (HALF - POST)),
                            (sy * HALF, sy * (HALF - POST)),
                            (0.0, POST_TOP))
    _band(bm, *BOTTOM)
    bm.normal_update()
    posts = lowpoly.flat_obj("CratePosts", bm, post_wood)

    root = bpy.data.objects.new("Crate", None)
    root.empty_display_size = 0.02
    bpy.context.collection.objects.link(root)
    parts = [boards, posts]
    for ob in parts:
        ob.parent = root

    # Contact shading in the joinery: where each board butts into a post, into
    # the inside corners, and under the top rail. 4 mm of reach — the boards
    # are 6 mm deep, so this stays inside the joints and never reaches out onto
    # the flat of a board. See `models/README.md`.
    shades = lowpoly.bake_ao_facets(parts, distance=0.004)

    return [root] + parts + shades


if __name__ == "__main__":
    objects = build()
    lowpoly.export_usdz(objects, USDZ)
    if "--no-save" not in sys.argv:
        bpy.ops.wm.save_as_mainfile(filepath=BLEND)
