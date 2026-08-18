"""De lichtbalk — the bar Het Feest's lamps clamp onto.

    blender --background --python models/light-bar.py

Reference: `references/feest/lichtrek.png`. Writes
`app/NinaBakeryPOC/Resources/Models/light-bar.usdz`.

A small prop with one idea in it. `FeestProps.lightBar` is `.box([length, 5 mm,
5 mm])` — a square batten — and every bar in the plate is a **round tube** with a
visible bore at the cut end. On a wall prop 280 mm long and 6 mm thick that is
the difference between a scaffolding pole and a skirting board, and it is the
only thing about the bar anybody will ever notice.

The open end is modelled, because the plate makes a point of it: the right-hand
bar in `lichtrek.png` runs past its last clamp and shows a dark bore. So the tube
is a real tube — an outer skin, an inner skin wound the other way, and an annulus
closing each end — rather than a capped rod. Ten sides, which is
`models/README.md`'s "enough to read as round at iPad size".

## The one scale in the game, and why it is allowed

`FeestLayout` wants two bars: 280 mm across the back wall and 230 mm down the
left. `models/README.md` is firm that a prop is modelled at the size it is used
at and nothing is scaled on load — the rule exists because scaling a prop changes
the proportion of every facet on it, which is the whole style.

**A prism scaled along its own axis is the exception, and it is a geometric fact
rather than a judgement call**: every facet on the tube's skin is a rectangle
whose long edge runs down the axis, so lengthening it changes no angle, no
normal and no silhouette. The only faces that would distort are the two end
annuli, and they are perpendicular to the axis, so they do not scale at all.

The alternative is a second 30-face file that differs from this one in a single
number. `FeestProps.lightBar` scales, and says this.
"""

import os
import sys

import bmesh

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import feest
import lowpoly

NAME = "Lichtbalk"

#: The back wall's bar. The left wall's is 230 mm and is this one scaled on X —
#: see the note above.
LENGTH = 0.280
OUTER = 0.0030
INNER = 0.0019
SIDES = 10


def build():
    timber = feest.material("BalkHout", feest.WOOD_BROWN)

    # A tube lying along X: four rings — outer and inner at each end — bridged
    # into a closed solid. Built by hand rather than with `garden.lathe` because
    # a lathe caps its ends with a disc, and a bar with a disc in it is a rod.
    bm = bmesh.new()
    half = LENGTH / 2
    rings = []
    for x in (-half, half):
        for radius in (OUTER, INNER):
            loop = lowpoly.ring(bm, radius, 0.0, SIDES)
            for v in loop:
                # `lowpoly.ring` builds in XY at a given z; turn it to face down
                # the bar's axis.
                v.co = (x, v.co.x, v.co.y)
            rings.append(loop)
    outer_lo, inner_lo, outer_hi, inner_hi = rings

    lowpoly.bridge(bm, outer_lo, outer_hi, SIDES)   # the skin
    lowpoly.bridge(bm, inner_hi, inner_lo, SIDES)   # the bore, wound inward
    lowpoly.bridge(bm, inner_lo, outer_lo, SIDES)   # the annulus at each end
    lowpoly.bridge(bm, outer_hi, inner_hi, SIDES)
    bm.normal_update()

    # **Not called `Lichtbalk`, which is this file's one hard-won line.**
    # `feest.root_for` makes an empty named `NAME` to be the USD root prim, and
    # Blender will not have two objects with one name — so a mesh that has
    # already taken `Lichtbalk` pushes the root to `Lichtbalk.001`, which becomes
    # `root_prim_path="/Lichtbalk.001"`, and **a dot is not legal in a USD prim
    # path**. The exporter fails, `export_usdz` prints "wrote …" anyway, and no
    # file appears. Every other prop here happens to avoid it by naming its parts
    # after the prop (`BoxKast` under `Box`); this one is a single part and did
    # not. `main` now checks the file exists rather than trusting the message.
    return [feest.placed("LichtbalkBuis", timber, bm)]


def main():
    feest.fresh(NAME, "Lichtbalk", "Balk")
    parts = build()

    span = max(v.co.x for v in parts[0].data.vertices) * 2
    feest.check(abs(span - LENGTH) < 1e-6,
                "the bar is %.4f m long, not the %.3f the room wants" % (span, LENGTH))

    # **Nothing to find, and that is the right answer.** A tube is convex
    # everywhere on its outside and its bore is a 3 mm hole 280 mm deep, so the
    # only faces in a crevice are the ones nobody can see into. It is the fence
    # again (`models/README.md`): a very large facet has nothing to quantise, and
    # the honest thing is to record the zero rather than raise the distance until
    # a number appears — which here would darken 280 mm of bar in one step.
    objects = feest.finish(NAME, parts, distance=0.002)
    for ob in objects:
        if ob.type == 'MESH':
            print("  %-22s %3d faces" % (ob.name, len(ob.data.polygons)))
    feest.write(objects, "light-bar")


if __name__ == "__main__":
    main()
