"""De dansvloertegel — one tile of Het Feest's light-up floor.

    blender --background --python models/dance-tile.py

References: `references/feest/dansvloer.png` for what a tile is made of, and
`references/feest/roombox.png` for what thirty-six of them look like lit. Writes
`app/NinaBakeryPOC/Resources/Models/dance-tile.usdz`.

**This is now the failure fallback, not the shipping top surface.** The room-box
plate's falloff is genuinely smooth, so `FeestProps.danceFloor` generates one
128² rectangular gradient texture and maps it over a UV plane. If texture
creation fails, this model's three broad bands still leave a complete playable
floor rather than a missing surface.

**One tile, and the room lays a 6×6 grid of it.** `FeestProps.danceFloor` shares
one slab mesh, one UV plane and one generated gradient across all thirty-six.

## Why the fallback is not a second texture

The ask was for the soft square falloff the plates show — a tile brighter in the
middle than at its edge, which is most of what makes `roombox.png`'s floor read
as *lit* rather than as *painted*. The shipping UV plane now does exactly that.

This USDZ deliberately remains texture-free because it is the path used when
texture creation fails. It quantises the same direction into three broad
rectangular bands: no UV dependency, no missing surface, and a complete floor
instead of a bright untextured square.

## The bands are named for the machinery that already exists

They come out as `TegelVlak`, `TegelVlakShade1` and `TegelVlakShade2` — the
suffix `ModelLibrary` already reads to mean "this many steps darker". The centre
stays at the tile's colour and the two broad bands gently darken towards the
edge. `FeestRoom` preserves that same ladder when the tile lights; otherwise the
beat would erase the exact gradient this model exists to provide.

## This is the one prop here with no bake, and the zero is honest

A 59 mm slab lying on a floor has no crevice in it: there is nothing for
`bake_ao_facets` to measure and running it would produce nothing but a name
collision with the bands above. The fallback shading is **authored rather
than measured**, which is a real distinction and worth stating plainly — every
other model in `models/` earns its shading from geometry. Here the geometry is a
slab, and what the plate is showing is a lamp under frosted glass, which is not
occlusion at all.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import feest

NAME = "Tegel"

# `FeestLayout` — 59 mm square, 2.8 mm thick. Thin on purpose: a tile flush with
# the floor z-fights and one any thicker reads as a step she would trip on.
SIZE = 0.059
THICKNESS = 0.0028

#: How finely the top is split. Six gives three broad rectangular bands with a
#: 2×2 centre, matching the room-box plate's soft centre rather than drawing
#: several hard outlines. One facet is about 10 mm wide.
DIVISIONS = 6

#: How far the block's top sits below the bands, so no two faces are coplanar.
#: The booth's panel, the booth's rail and the speaker's baffle each cost a
#: render learning that; this one was built knowing it.
LIFT = 0.0002


def build():
    half = SIZE / 2
    # Three close tones so the `.blend` shows the room-box plate's soft
    # rectangular falloff. `Palette.occluded` computes the same ladder in Swift.
    base = feest.BLUSH_PINK
    tones = [(base, 2), (base, 1), (base, 0)]
    materials = []
    for colour, steps in tones:
        f = 0.88 ** steps
        rgb = [int(((colour >> s) & 255) * f) for s in (16, 8, 0)]
        materials.append(feest.material(
            "TegelTint%d" % steps, (rgb[0] << 16) | (rgb[1] << 8) | rgb[2]))

    parts = [
        # The slab. Closed, so its winding recalculates, and stopping short of
        # the bands rather than meeting them.
        feest.boxes("TegelBlok", materials[0], [
            ((-half, half), (-half, half), (0.0, THICKNESS - LIFT))]),
    ]

    # The three bands, outermost first, so the names line up with the number of
    # steps `ModelLibrary` will darken them by.
    for ring, name in enumerate(["TegelVlakShade2", "TegelVlakShade1",
                                 "TegelVlak"]):
        parts.append(feest.gradient_top(name, materials[ring], half, half,
                                        THICKNESS, DIVISIONS, ring))
    return parts


def main():
    feest.fresh(NAME, "Tegel")
    parts = build()

    faces = {ob.name: len(ob.data.polygons) for ob in parts}
    feest.check(faces["TegelVlakShade2"] == 20
                and faces["TegelVlakShade1"] == 12
                and faces["TegelVlak"] == 4,
                "the bands came out %r, not 20/12/4" % faces)
    top = max(v.co.z for ob in parts for v in ob.data.vertices)
    feest.check(abs(top - THICKNESS) < 1e-9,
                "the tile is %.5f m thick, not %.4f" % (top, THICKNESS))

    # **No bake**, and the docstring above argues it rather than assuming it.
    root = feest.root_for(NAME, parts)
    for ob in parts:
        print("  %-22s %3d faces" % (ob.name, len(ob.data.polygons)))
    feest.write([root] + parts, "dance-tile")


if __name__ == "__main__":
    main()
