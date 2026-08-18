"""De DJ-booth — the console Het Feest's DJ stands behind.

    blender --background --python models/dj-booth.py

Reference: `references/feest/dj-booth.png` for what it is made of,
`references/feest/roombox.png` for how it sits in the room. Writes
`app/NinaBakeryPOC/Resources/Models/dj-booth.usdz`.

**Nine boxes and two prisms is what it was**, and the plate draws about twenty
things. What the code version could not say, in the order the plate says it:

  * **A lip with an underside.** The top slab stands 3 mm proud all round, and
    that overhang is the only shadow on this prop that reads from across the
    room. In code it was a wider box with nothing under it — the facets on its
    edge and the facets on the cabinet below face the same way and come back the
    same tone, which is the flour sack's collar again.
  * **A framed panel, not a painted rectangle.** In the plate the glowing front
    is *set into* a pale surround standing proud of it. `BoothPaneel` was a
    2 mm-thick box floating 1 mm off the cabinet face, which at this camera is a
    sticker. The frame is what makes it a window.
  * **A back rail.** The plate stands a rail along the back edge with a taller
    block at each end, and it is most of what makes the silhouette a *console*
    rather than a sideboard — the one job the code's proud top was doing alone.
  * **An inset deck plate.** The platters and the mixer stand on a paler panel
    let into the top, not directly on it.
  * **Faders and a screen.** Two slider bars beside the platters and an angled
    display on the mixer. Small, and they are what a plate is for.

**The colours are the room's, not the studio plate's**, and the two disagree:
`dj-booth.png` paints a blue-grey cabinet, `roombox.png` a cream one. The room
box wins for the same reason it won about the size of the mirror ball — it is
the picture with the room in it — and it is also what the game already ships.
Every colour here is repainted from `Palette.swift` on load anyway; these exist
so the `.blend` is reviewable.

**The two platters are one mesh each, mark included, and that is the rig talking
rather than a saving.** They spin, so `FeestProps` hangs each on
`ModelLibrary.pivot` — which collects a part *and the shade siblings the bake
split off it* by exact base name. A mark modelled as `Plaat0Merk` has a different
base, so it would be left behind turning nothing, which is the scale's pan trap
one level up. Folding it in makes the platter a single part with a single name
and the bake is then free to shade it like anything else.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import feest

NAME = "DJBooth"

# ------------------------------------------------------ what `FeestLayout` says
# `boothSize` is 110 × 48 mm and `boothTopY` is 0.070 against a floor at 0.004,
# so the cabinet is 66 mm tall and the slab goes on top of that. Transcribed
# rather than guessed, and `check` below fails the build if they drift apart.
HALF_X = 0.110 / 2
HALF_Y = 0.048 / 2
HEIGHT = 0.070 - 0.004

FOOT = 0.004
SLAB = 0.006
SLAB_PROUD = 0.003
DECK_OFFSET = 0.030
#: **21 mm, up from `FeestLayout.deckRadius`'s 17.** In `dj-booth.png` the two
#: platters are the console: each is close to 40% of its width and they leave
#: only a slim channel between them for the mixer. At 17 mm they read as a pair
#: of coasters on a large empty deck, which is what the first render showed —
#: most of the top was bare lilac. `FeestLayout.deckRadius` follows this when the
#: Swift side is wired up; it is only used to build the code version.
DECK_RADIUS = 0.021


def build():
    cream = feest.material("BoothCream", feest.CREAM)
    cream_light = feest.material("BoothCreamLight", feest.CREAM_LIGHT)
    rose = feest.material("BoothRose", feest.ROSE)
    lilac = feest.material("BoothLilac", feest.LILAC)
    butter = feest.material("BoothButter", feest.BUTTER_YELLOW)
    wood = feest.material("BoothWood", feest.WOOD_BROWN)

    parts = []

    # ---------------------------------------------------------------- the base
    # Four feet, which the plate puts at the corners and which lift the cabinet
    # off the floor. Without them the box sits in the floor and the room's
    # contact shadow is the only thing saying it is an object.
    inset = 0.008
    parts.append(feest.boxes("BoothVoet", wood, [
        ((sx * HALF_X - sx * inset - 0.005, sx * HALF_X - sx * inset + 0.005),
         (sy * HALF_Y - sy * inset - 0.005, sy * HALF_Y - sy * inset + 0.005),
         (0.0, FOOT))
        for sx in (-1, 1) for sy in (-1, 1)]))

    # The cabinet. A crisp box, because the plate's cabinet is crisp — the
    # chamfer that `feest.octa_column` exists for belongs to the speakers.
    parts.append(feest.boxes("BoothKast", cream,
                             [((-HALF_X, HALF_X), (-HALF_Y, HALF_Y),
                               (FOOT, HEIGHT))]))

    # --------------------------------------------------------- the front window
    # Blender +Y is the game's −Z, so the face towards the camera is at −Y.
    front = -HALF_Y
    panel_x, panel_z0, panel_z1 = 0.040, 0.018, 0.052
    frame = 0.004
    parts.append(feest.boxes("BoothLijst", cream_light, [
        # left, right, bottom, top — four bars standing 1.5 mm proud of the
        # cabinet, with the panel let into the well between them.
        ((-panel_x - frame, -panel_x), (front - 0.0015, front),
         (panel_z0 - frame, panel_z1 + frame)),
        ((panel_x, panel_x + frame), (front - 0.0015, front),
         (panel_z0 - frame, panel_z1 + frame)),
        ((-panel_x, panel_x), (front - 0.0015, front),
         (panel_z0 - frame, panel_z0)),
        ((-panel_x, panel_x), (front - 0.0015, front),
         (panel_z1, panel_z1 + frame)),
    ]))
    # **It has to cross the cabinet face rather than sit on it.** Built flush —
    # front face exactly on the cabinet's — the two are coplanar, and a coplanar
    # pair inside solid geometry is the fence's bug (`models/README.md`): the
    # render came back with a **black** window where a glowing one belongs. It
    # now stands 0.5 mm proud, which leaves it 1 mm down the well the frame
    # makes. It is the room's biggest emissive surface and Swift gives it
    # `FeestProps.lit` on load.
    parts.append(feest.boxes("BoothPaneel", butter, [
        ((-panel_x, panel_x), (front - 0.0005, front + 0.0020),
         (panel_z0, panel_z1))]))

    # ------------------------------------------------------------------ the top
    parts.append(feest.boxes("BoothBlad", rose, [
        ((-HALF_X - SLAB_PROUD, HALF_X + SLAB_PROUD),
         (-HALF_Y - SLAB_PROUD, HALF_Y + SLAB_PROUD),
         (HEIGHT, HEIGHT + SLAB))]))

    # The rail along the back, with a taller block at each end — straight off
    # the plate, and the reason the silhouette is a console.
    #
    # **The blocks are stacked on the rail, not overlapped with it.** Written the
    # obvious way — three boxes all starting at `rail_z`, two of them taller —
    # the ends share a volume with the run, and `lowpoly.add_box` puts several
    # shells in one mesh without unioning them. That leaves faces buried inside
    # solid geometry, which is the fence's bug again and which rendered as two
    # **black** blocks. Stacking is the fix and it is also the plate's own
    # profile: a step, not a lump.
    rail_z = HEIGHT + SLAB
    back = HALF_Y + SLAB_PROUD
    parts.append(feest.boxes("BoothRand", rose, [
        ((-HALF_X - SLAB_PROUD, HALF_X + SLAB_PROUD), (back - 0.007, back),
         (rail_z, rail_z + 0.006)),
        ((-HALF_X - SLAB_PROUD, -HALF_X + 0.010), (back - 0.007, back),
         (rail_z + 0.006, rail_z + 0.011)),
        ((HALF_X - 0.010, HALF_X + SLAB_PROUD), (back - 0.007, back),
         (rail_z + 0.006, rail_z + 0.011)),
    ]))

    # The deck plate let into the top: everything on the console stands on this
    # rather than on the rose slab. It stops 1 mm short of the rail's foot, so
    # the two never share a face.
    deck_z = rail_z
    parts.append(feest.boxes("BoothDek", lilac, [
        ((-0.050, 0.050), (-0.0215, back - 0.008), (deck_z, deck_z + 0.0015))]))
    top = deck_z + 0.0015

    # ------------------------------------------------------------- the platters
    # **Offset in depth as well as across**, which is the plate: one deck sits
    # back and the other forward, and two platters in a row read as a pair of
    # coasters. The 30 mm across is `FeestLayout.deckOffset` and stays.
    #
    # **1.5 mm of that offset, not the 5 the plate suggests.** A 17 mm platter at
    # ±5 mm reaches y = ±22, and the deck plate stops at 19 — the first render
    # had both of them hanging over its back edge into the rose. The plate is
    # drawn on a console with nothing behind it; this one has a rail there.
    for i, (dx, dy) in enumerate([(-DECK_OFFSET, 0.0015), (DECK_OFFSET, -0.0015)]):
        # **The platter is one mesh, mark and all, and that is a rig constraint
        # rather than a saving.** It turns, so `FeestProps` hangs it on
        # `ModelLibrary.pivot`, which collects a part *and its baked shade
        # siblings* by exact base name — a mark called `Plaat0Merk` has a
        # different base and would stay behind, spinning nothing. It is the
        # scale's pan trap in `ModelLibrary.pivot`'s own doc, one level up.
        #
        # It is also what the plate shows: the platters there are plain cream
        # with a raised spindle, and the grey bar beside each one is a **tonearm
        # on the deck**, which does not turn. That is `BoothFader` below.
        # **Built at the origin and given a location**, rather than baked in
        # place like everything else here. `feest.animated` has the argument: a
        # platter whose transform is baked reports a position of zero, so
        # `ModelLibrary.pivot` puts its holder on the booth's origin and
        # `FeestRoom` then swings both platters in a circle round the middle of
        # the console instead of turning them where they stand.
        platter = feest.lathe(
            "PlaatSchijf%d" % i, cream_light,
            [(DECK_RADIUS, 0.0), (DECK_RADIUS, 0.0022),
             (DECK_RADIUS * 0.34, 0.0026), (DECK_RADIUS * 0.34, 0.0034),
             (DECK_RADIUS * 0.12, 0.0038)],
            12)
        mark = feest.boxes("PlaatMerk%d" % i, cream_light, [
            ((-0.0016, 0.0016), (DECK_RADIUS * 0.52, DECK_RADIUS * 0.86),
             (0.0022, 0.0035))])
        parts.append(feest.join("Plaat%d" % i, cream_light, [platter, mark],
                                at=(dx, dy, top)))

        # The tonearm beside it — a slim bar on the deck, which is where the
        # plate puts it. It does not turn.
        sx = 1 if dx < 0 else -1
        parts.append(feest.boxes("BoothFader%d" % i, wood, [
            ((dx + sx * 0.019 - 0.0022, dx + sx * 0.019 + 0.0022),
             (dy - 0.009, dy + 0.009), (0.0, 0.0016))], at=(0, 0, top)))

    # ---------------------------------------------------------------- the mixer
    # Slim and low, because the platters are the console and this is the channel
    # between them. It was 22 mm across and stood 4.5 mm proud, which beside a
    # 42 mm platter is a block in the way rather than a mixer.
    parts.append(feest.boxes("BoothMenger", cream_light, [
        ((-0.0075, 0.0075), (-0.013, 0.013), (top, top + 0.0030))]))
    # The angled display on its back half. A wedge rather than a flat plate: in
    # the plate the screen leans back towards the DJ, and a screen lying flat is
    # a dark rectangle painted on the console.
    parts.append(feest.placed("BoothScherm", wood, _screen(top + 0.0030)))

    # Six knobs in two rows on the front half, and they are `woodBrown` rather
    # than the plate's charcoal, which is off the palette.
    knobs = []
    for row in range(2):
        for column in range(3):
            knobs.append(feest.lathe(
                "BoothKnop-%d-%d" % (row, column), wood,
                [(0.0013, 0.0), (0.0016, 0.0014), (0.0011, 0.0023)], 6,
                at=(-0.0044 + column * 0.0044, -0.0100 + row * 0.0048,
                    top + 0.0030)))
    parts.append(feest.join("BoothKnoppen", wood, knobs))

    return parts


def _screen(z):
    """The mixer's display, leaning back towards the DJ."""
    import bmesh
    bm = bmesh.new()
    # A wedge: low at the front (−Y, the camera side), high at the back.
    x0, x1 = -0.0062, 0.0062
    y0, y1 = 0.0015, 0.0110
    v = [bm.verts.new(c) for c in
         ((x0, y0, z), (x1, y0, z), (x1, y1, z), (x0, y1, z),
          (x0, y0, z + 0.0008), (x1, y0, z + 0.0008),
          (x1, y1, z + 0.0042), (x0, y1, z + 0.0042))]
    for face in ((0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4),
                 (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)):
        bm.faces.new([v[i] for i in face])
    bm.normal_update()
    return bm


def main():
    feest.fresh(NAME, "Booth", "Plaat")
    parts = build()

    # The envelope `FeestLayout` promises. A booth that outgrew its own footprint
    # would push the DJ into the wall — `FeestLayout.boothCentre` records that
    # the last 30 mm of clearance was paid for once already.
    # In world coordinates, because the platters carry their placement on the
    # object rather than in their vertices — `feest.animated` says why.
    corners = [ob.matrix_world @ v.co for ob in parts for v in ob.data.vertices]
    top = max(p.z for p in corners)
    wide = max(abs(p.x) for p in corners)
    deep = max(abs(p.y) for p in corners)
    feest.check(abs(top - 0.083) < 0.002, "the console stands %.4f m tall" % top)
    feest.check(wide <= HALF_X + SLAB_PROUD + 1e-6,
                "the booth is %.4f m wider than its half-width" % wide)
    feest.check(deep <= HALF_Y + SLAB_PROUD + 1e-6,
                "the booth is %.4f m deeper than its half-depth" % deep)

    # 3 mm, against the 3 mm the top slab overhangs by — the number is chosen
    # against the part the shading has to stay inside, which is
    # `models/README.md`'s rule and the tree is what taught it.
    #
    # **The platters are baked like everything else**, because folding the mark
    # into `Plaat<i>` made them a single part with a single base name, which is
    # what `ModelLibrary.pivot` needs to carry a moving part's shading with it.
    objects = feest.finish(NAME, parts, distance=0.003)
    for ob in objects:
        if ob.type == 'MESH':
            print("  %-22s %3d faces" % (ob.name, len(ob.data.polygons)))
    feest.write(objects, "dj-booth")


if __name__ == "__main__":
    main()
