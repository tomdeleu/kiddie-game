"""De discobal — the mirror ball Het Feest hangs over its dance floor.

    blender --background --python models/discobal.py

Reference: `references/feest/discobal.png`. Writes
`app/NinaBakeryPOC/Resources/Models/discobal.usdz`.

**This prop has already been got wrong once, and the reason is worth keeping.**
It was first built as one icosphere in a single glowing cream — a *faceted
sphere* — and the owner's verdict on seeing it was blunt (2026-08-17: *"that
mirror ball looks like shit."*). The plate is not showing facets, it is showing
**tiles**: a twelve-by-seven grid of small quads, each its own pale tone, with a
seam between them. `references/feest/README.md` draws the general lesson —
*count the things* — and the room was rebuilt as the mosaic.

So what is left for a model to add, given the mosaic already exists in code? One
thing, and it is the thing the whole occlusion story started over: **the seam is
a groove, not a line.** `FeestProps.ballTile` builds each tile as a flat quad
with a gap around it, and a gap between two surfaces that both face outwards
comes back the same tone on both sides — nothing says the tiles are separate
objects. Here every tile is a **truncated pyramid lying on the sphere**, so
between two neighbours there are two real walls angled into a V, and the bake
finds them. That is the berry's crown exactly (`models/README.md`): standing a
shape up costs you the join, and only a measurement gets it back.

## Seven meshes, not eighty-four

Every tile in a row is the same patch turned about the ball's axis, so the row is
modelled once and `FeestProps` clones it twelve times — which is what the code
version already does and is the reason a 60 mm prop is not 84 unbatchable
meshes.

**The bake still sees all eighty-four.** `lowpoly.bake_ao_facets` separates what
*casts* from what *receives*, so the whole ball is assembled, the twelve
representatives are measured against it, and the seventy-seven extras are deleted
before the export. Measuring one tile alone would find nothing at all: a tile has
no crevice, a tile *next to another tile* does.

## What the split buys the room, for free

A tile is six faces: the top, the four walls of the groove, and a base buried in
the core. The bake puts the top in level 0 and the walls a step or two down — so
`Spiegeltje<row>` comes out of the loader holding **just the face that catches
the light**, and its `…Shade1` sibling holds the seam. `FeestRoom` lights a
rotating handful of tiles on the beat by swapping one material, and it now lights
the tile face without ever brightening the groove, which is what a mirror ball
does. That fell out of the geometry rather than being arranged.
"""

import math
import os
import sys

import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import feest
import lowpoly

NAME = "Discobal"

# `FeestLayout.ballRadius` — 60 mm across, which the room box plate argued up
# from 44. Transcribed, and `check` fails the build if it drifts.
RADIUS = 0.030
#: **Fourteen by eight, up from twelve by seven.** The silhouette of a tiled ball
#: is set by its column count — twelve columns is a 30° facet, and against the
#: plate the outline read as visibly polygonal where the plate's is nearly round.
#: Fourteen brings it to 25.7°. The extra row keeps the tiles from going wide and
#: squat. It costs one more shared mesh; the tile *entities* are clones of a row,
#: which is the trick `FeestProps` already plays.
ROWS = 8
COLUMNS = 14

#: How deep a tile stands off the core. It is the depth of the groove between two
#: neighbours, so it is the one number the bake actually measures.
#:
#: **1 mm, down from 2.2, and the first render is why.** 2.2 mm is 7% of a 30 mm
#: radius: the tiles stood off the core like plates bolted onto a grenade, the
#: silhouette went lumpy, and the grooves read as gaps with the core showing at
#: the bottom of them. The plate butts its tiles nearly flush and shows a
#: *crease*, not a channel. This is the plate's crease.
DEPTH = 0.0008
#: How much of each tile's angular span is given up to the groove, per edge.
INSET = 0.040

#: The pale spread the plate came back with. Twelve tones rather than one,
#: because a mirror ball whose tiles are all the same colour is a ball. Every one
#: is already in the game.
#: **The pale end of the palette only.** The first build used all twelve tones
#: including `rose`, `sage`, `sandyWood` and `blushPinkDeep`, and beside the
#: plate it read as a beach ball: in `discobal.png` the darkest tile is barely a
#: tone off the lightest, and the whole prop sits inside a narrow pale band.
#: What makes it a mirror ball is *many nearly-identical* tones, not many
#: different colours — the variation has to be small enough that the eye reads a
#: surface catching light rather than a pattern.
TONES = [feest.CREAM_LIGHT, feest.CREAM, feest.BLUSH_PINK, feest.MINT_LIGHT,
         feest.MINT, feest.LILAC, feest.BERRY_BLUE, feest.BUTTER_YELLOW]


def tone(row, column):
    """Deterministic, and deliberately not random.

    `FeestProps.ballTone`'s rule, transcribed: the multipliers are coprime with
    the row and column counts so the pattern does not fall into stripes or
    diagonals, and a ball that redealt itself on every rebuild is a ball nobody
    can review a diff of.
    """
    return TONES[(row * 5 + column * 7 + (row * column) % 11) % len(TONES)]


def build():
    parts = []

    # **A core, so a groove never shows daylight.** The tiles stand off the
    # surface with gaps between them; without something solid behind, the ball is
    # a colander seen against a grey backdrop.
    core = feest.lathe("DiscobalKern", feest.material("BalKern", feest.CREAM),
                       _sphere_profile(RADIUS - DEPTH * 1.15, 9), 12)
    parts.append(core)

    # The eyelet it hangs from, which the plate draws as a proper ring rather
    # than the flat washer the code version used.
    ring = feest.torus("DiscobalRing",
                       feest.material("BalRing", feest.CREAM_LIGHT),
                       ring_radius=0.0042, tube_radius=0.0013,
                       ring_sides=10, tube_sides=6,
                       at=(0, 0, RADIUS + 0.0034),
                       rot=(math.pi / 2, 0, 0))
    parts.append(ring)

    # Every tile, so the bake has neighbours to measure against. Column 0 of each
    # row is the one that survives to the export.
    keep, scratch = [], []
    span = 2 * math.pi / COLUMNS
    for row in range(ROWS):
        theta0 = row / ROWS * math.pi
        theta1 = (row + 1) / ROWS * math.pi
        for column in range(COLUMNS):
            name = ("Spiegeltje%d" % row) if column == 0 \
                else "BalSchraap-%d-%d" % (row, column)
            tile = feest.sphere_tile(
                name, feest.material("BalTegel-%d-%d" % (row, column),
                                     tone(row, column)),
                RADIUS, theta0, theta1,
                column * span, (column + 1) * span,
                depth=DEPTH, inset=INSET)
            (keep if column == 0 else scratch).append(tile)

    return parts, keep, scratch


def _sphere_profile(radius, stations):
    """A lathe profile that is half a circle, pole to pole.

    `garden.lathe` collapses a zero-radius station to a single apex vertex, so
    the core has a real point at each pole rather than twelve coincident
    vertices — which is the degenerate-triangle trap `garden.py` opens with, and
    the bake reads such a fan as facing every direction at once.
    """
    return [(radius * math.sin(i / stations * math.pi),
             radius * math.cos(i / stations * math.pi))
            for i in range(stations + 1)]


def main():
    feest.fresh(NAME, "Discobal", "Spiegeltje", "BalSchraap")
    parts, keep, scratch = build()

    reach = max(math.sqrt(v.co.x ** 2 + v.co.y ** 2 + v.co.z ** 2)
                for ob in keep for v in ob.data.vertices)
    feest.check(abs(reach - RADIUS) < 1e-6,
                "a tile reaches %.5f m, not the ball's %.5f" % (reach, RADIUS))

    # **Measured against the whole ball, exported as one row.** `occluders` is
    # what makes that possible, and without it every tile measures zero: a patch
    # on its own has no neighbour to be in a groove with.
    #
    # The room study extends the reach from the 0.8 mm groove depth to 30 mm.
    # Its ten-rung ramp keeps the groove and lets neighbouring rows shade one
    # another without turning the whole 60 mm ball one dark material.
    shades = lowpoly.bake_ao_facets(
        keep, distance=feest.AO_REACH, occluders=parts + keep + scratch,
        ramp_strength=feest.AO_STRENGTH, ramp_levels=feest.AO_LEVELS)
    for ob in scratch:
        bpy.data.objects.remove(ob, do_unlink=True)

    everything = parts + keep + shades
    root = feest.root_for(NAME, everything)
    for ob in everything:
        print("  %-22s %3d faces" % (ob.name, len(ob.data.polygons)))
    feest.write([root] + everything, "discobal")


if __name__ == "__main__":
    main()
