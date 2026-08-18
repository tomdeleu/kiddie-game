"""De dansvloertegel — one tile of Het Feest's light-up floor.

    blender --background --python models/dance-tile.py

References: `references/feest/dansvloer.png` for what a tile is made of, and
`references/feest/roombox.png` for what thirty-six of them look like lit. Writes
`app/NinaBakeryPOC/Resources/Models/dance-tile.usdz`.

**One tile, and the room lays a 6×6 grid of it.** `FeestProps.danceFloor` already
builds one mesh and shares it across all thirty-six, which is right and is kept.

## The gradient, and why it is not a texture

The ask was for the soft square falloff the plates show — a tile brighter in the
middle than at its edge, which is most of what makes `roombox.png`'s floor read
as *lit* rather than as *painted*. The obvious way to get that is an image.

**There are no textures in this game and this is not the prop to start with.**
`models/README.md` bans UVs and texture maps outright, `lowpoly.export_usdz`
passes `export_uvmaps=False`, and the reason is the whole art direction:
`references/REFERENCES.md` §1 says shading comes from facet normals and nothing
else. A textured floor would also be the single largest surface in the room, so
it is the worst possible place to make an exception.

The in-style answer is the one `bake_ao_facets` already uses for occlusion, run
the other way up: **quantise the falloff onto facets.** The tile's top is split
6×6 and grouped into three concentric bands, each its own mesh and its own flat
tone. No UVs, no image, no runtime cost, and the result is still one flat colour
per facet — which is what the style is made of.

`dansvloer.png` supports it directly rather than merely permitting it: the mint
tile in that plate is visibly a low-poly fan shading towards its middle, not a
smooth wash.

## The bands are named for the machinery that already exists

They come out as `TegelVlak`, `TegelVlakShade1` and `TegelVlakShade2` — the
suffix `ModelLibrary` already reads to mean "this many steps darker". So the
centre band is the tile's colour, the middle band is one step down and the outer
band two, and **the entire gradient is delivered by the occlusion path with no
new Swift at all.** `FeestRoom` lights a tile by swapping three materials instead
of one, and gets the same ladder in the lit colour.

## This is the one prop here with no bake, and the zero is honest

A 59 mm slab lying on a floor has no crevice in it: there is nothing for
`bake_ao_facets` to measure and running it would produce nothing but a name
collision with the bands above. The gradient on this prop is **authored rather
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

#: How finely the top is split. Six is the smallest number that gives three
#: bands with a 2×2 centre, and thirty-six facets on a 59 mm tile is one facet
#: per 10 mm — comfortably above the point where a facet stops being visible.
DIVISIONS = 6

#: How far the block's top sits below the bands, so no two faces are coplanar.
#: The booth's panel, the booth's rail and the speaker's baffle each cost a
#: render learning that; this one was built knowing it.
LIFT = 0.0002


def build():
    half = SIZE / 2
    # Three tones so the `.blend` shows the gradient. `Palette.occluded` computes
    # the same ladder in Swift and is what actually ships — these are 0.88 and
    # 0.88² of the base, kept in step with `lowpoly.OCCLUSION_STEP`.
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
    feest.check(faces["TegelVlakShade2"] == 20 and faces["TegelVlakShade1"] == 12
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
