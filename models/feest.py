"""Shared shapes for Het Feest's modelled props.

`lowpoly.py` holds the rules every prop in this folder obeys — flat shading,
winding, the occlusion bake, the export. This holds the vocabulary **the disco**
needed on top of it.

**It imports the generic half of `garden.py` rather than copying it.** The
pointed lathe, the box-of-boxes, the faceted cluster and the `fresh` /
`root_for` / `finish` / `write` pipeline were written for De Tuin because De
Tuin needed them first, not because they are about plants — `models/README.md`
said "nothing outside the garden imports it" as a statement of fact, and this is
the fact changing. **Not one line of `garden.py` moved or changed**, so no
garden prop is affected.

That was checked rather than assumed, and the check turned up something worth
knowing: **a USDZ is not byte-reproducible.** Rebuilding `garden-fence` twice in
a row, with no edit of any kind in between, produces two different files —
`models/README.md`'s "the export is deterministic, so re-running with no edits
produces the same geometry" is true of the *geometry* and not of the *file*,
because a USDZ is a zip and a zip carries timestamps. So `git status` after a
rebuild is not evidence that anything changed, and a rebuilt garden prop should
be restored with `git checkout` rather than committed.

What the disco needed that nothing else did, and every one of them comes
straight off a plate in `references/feest/`:

  * `octa_column` — a **chamfered** box, of arbitrary section per station.
    `references/feest/boxen.png` cuts every vertical *and* top edge off both
    cabinets, and that chamfer is most of what stops a speaker reading as a
    cardboard carton. `garden.add_column` scales one section uniformly, which a
    cabinet 44 mm wide and 30 mm deep cannot use.
  * `sphere_tile` — one **chamfered patch of a sphere**, for the mirror ball's
    mosaic. `references/feest/discobal.png` is a twelve-by-seven grid of quads
    with a seam between them, and the seam is a real V-groove rather than a
    painted line: it is what the bake finds, and finding it is the whole reason
    the ball is worth modelling.
  * `gradient_top` — a square face split into **concentric rings of facets**, so
    a dance-floor tile can be brighter in the middle than at its edge without a
    texture. See the note on `dance-tile.py` for why this is not a texture.
  * `dish` — a **recessed** cone in a surround, which is a speaker driver and is
    the one shape in this room that is a genuine crevice.
  * `torus` — the eyelet the mirror ball hangs from, and the rim round a lamp's
    lens.

Blender is Z-up and the exporter maps (x, y, z) → (x, z, −y), so — exactly as
`garden.py` records it:

    Blender +Z  is the game's +Y   (up)
    Blender +X  is the game's +X
    Blender −Y  is the game's +Z   (towards the camera)
"""

import math
import os
import sys

import bmesh

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import garden
import lowpoly

# The generic half of De Tuin's vocabulary, re-exported so a disco script
# imports one module. Nothing here is about plants.
material = lowpoly.material
lathe = garden.lathe
prism = garden.prism
boxes = garden.boxes
balls = garden.balls
placed = garden.placed
chip = garden.chip
fresh = garden.fresh
root_for = garden.root_for
matrix = garden.matrix

# Long-reach per-prop AO settled by `app/AMBIENT-OCCLUSION.md`: 30 mm reads the
# chin/chest, arm/side and cabinet seams that the original 2–6 mm contact bake
# cannot reach. Two in-app passes still washed out under RealityKit's simulator
# lighting. Ten rungs at 0.80 preserve open facets and deepen only the enclosed
# joins; Shade10 bottoms out at 0.88 ** 10 = 0.279.
AO_REACH = 0.030
AO_STRENGTH = 0.80
AO_LEVELS = 10


def finish(name, parts, shade=None, min_faces=3):
    """Finish a Het Feest prop with the room's long-reach AO ramp."""
    return garden.finish(name, parts, distance=AO_REACH, shade=shade,
                         min_faces=min_faces, ramp_strength=AO_STRENGTH,
                         ramp_levels=AO_LEVELS)

# `Palette.swift` is the single source of truth — the app repaints every model
# on load. These exist so a model is reviewable in Blender.
BLUSH_PINK = garden.BLUSH_PINK
BLUSH_PINK_DEEP = garden.BLUSH_PINK_DEEP
ROSE = garden.ROSE
MINT_LIGHT = garden.MINT_LIGHT
MINT = garden.MINT
SAGE = garden.SAGE
SAGE_DEEP = garden.SAGE_DEEP
CREAM_LIGHT = garden.CREAM_LIGHT
CREAM = garden.CREAM
BUTTER_YELLOW = garden.BUTTER_YELLOW
SANDY_WOOD = garden.SANDY_WOOD
WOOD_BROWN = garden.WOOD_BROWN
HONEY_AMBER = garden.HONEY_AMBER
LILAC = garden.LILAC
LILAC_DEEP = garden.LILAC_DEEP
BERRY_BLUE = 0xC2D2E8
BERRY_BLUE_DEEP = 0x9BB2D2


def octagon_ring(half_x, half_y, chamfer):
    """A rectangle with its four corners cut, wound anticlockwise in XY.

    Unlike `garden.octagon` this takes the chamfer in metres and is happy with a
    different half-width on each axis, which is what a cabinet needs: 22 mm
    across and 15 mm deep, with the same 3 mm taken off every corner. Scaling
    one square section — `garden.add_column`'s model — would take 3 mm off the
    wide axis and 2 mm off the narrow one, and the cut would visibly not be 45°.
    """
    c = max(1e-5, min(chamfer, half_x * 0.98, half_y * 0.98))
    return [(half_x - c, -half_y), (half_x, -half_y + c),
            (half_x, half_y - c), (half_x - c, half_y),
            (-half_x + c, half_y), (-half_x, half_y - c),
            (-half_x, -half_y + c), (-half_x + c, -half_y)]


def octa_column(name, material, stations, at=None, rot=None):
    """A chamfered box, or a stack of them.

    `stations` is a list of `(half_x, half_y, chamfer, z)`. Every station has
    eight vertices, so a station may narrow the box, deepen the chamfer, or
    both — which is how one call builds a cabinet whose top edge is cut as well
    as its sides: repeat the section at the top with a bigger chamfer and a
    slightly lower z.
    """
    bm = bmesh.new()
    rings = []
    for half_x, half_y, chamfer, z in stations:
        section = octagon_ring(half_x, half_y, chamfer)
        rings.append([bm.verts.new((x, y, z)) for x, y in section])
    for lower, upper in zip(rings, rings[1:]):
        lowpoly.bridge(bm, lower, upper, 8)
    bm.faces.new(list(reversed(rings[0])))
    bm.faces.new(rings[-1])
    bm.normal_update()
    return placed(name, material, bm, at=at, rot=rot)


def torus(name, material, ring_radius, tube_radius, ring_sides=10, tube_sides=6,
          at=None, rot=None):
    """A faceted ring, lying in the XY plane.

    The mirror ball's eyelet and the bezel round a lamp's lens. Built from
    scratch rather than with `bpy.ops.mesh.primitive_torus_add`, which arrives
    smooth-shaded and with an operator's idea of where the origin is.
    """
    bm = bmesh.new()
    rings = []
    for i in range(ring_sides):
        a = 2 * math.pi * i / ring_sides
        cx, cy = math.cos(a) * ring_radius, math.sin(a) * ring_radius
        loop = []
        for j in range(tube_sides):
            b = 2 * math.pi * j / tube_sides
            r = ring_radius + math.cos(b) * tube_radius
            loop.append(bm.verts.new((math.cos(a) * r, math.sin(a) * r,
                                      math.sin(b) * tube_radius)))
        rings.append(loop)
    for i in range(ring_sides):
        lower, upper = rings[i], rings[(i + 1) % ring_sides]
        for j in range(tube_sides):
            k = (j + 1) % tube_sides
            bm.faces.new((lower[j], lower[k], upper[k], upper[j]))
    bm.normal_update()
    return placed(name, material, bm, at=at, rot=rot)


def sphere_tile(name, material, radius, theta0, theta1, phi0, phi1,
                depth, inset, at=None):
    """One **chamfered patch of a sphere** — a single mirror-ball tile.

    The top face sits on the sphere at `radius`, its angular span shrunk by
    `inset` (a fraction of the span) at all four edges. The base sits `depth`
    below it at the *full* span. So every tile is a little truncated pyramid
    lying on the sphere, and between two neighbours there is a **V-groove with
    two walls in it** rather than a painted seam.

    That groove is the point. `references/feest/discobal.png` reads as a mosaic
    and not as a faceted ball because its tiles have edges that catch shadow,
    and a facet cannot shade an edge that is not there — which is exactly the
    berry's crown, the case that started the occlusion bake
    (`models/README.md`). The bake is run over the assembled ball and finds
    these walls; nothing else on this prop has anything to find.

    Closed on purpose, so `lowpoly.flat_obj` recalculates the winding outward
    and no tile can be inside out. A single mis-wound tile is not a dark tile —
    it is a hole in the ball.
    """
    def point(theta, phi, r):
        return (math.sin(theta) * math.cos(phi) * r,
                math.sin(theta) * math.sin(phi) * r,
                math.cos(theta) * r)

    dt = (theta1 - theta0) * inset
    dp = (phi1 - phi0) * inset
    top = [(theta0 + dt, phi0 + dp), (theta0 + dt, phi1 - dp),
           (theta1 - dt, phi1 - dp), (theta1 - dt, phi0 + dp)]
    base = [(theta0, phi0), (theta0, phi1), (theta1, phi1), (theta1, phi0)]

    bm = bmesh.new()
    tv = [bm.verts.new(point(t, p, radius)) for t, p in top]
    bv = [bm.verts.new(point(t, p, radius - depth)) for t, p in base]
    bm.faces.new(tv)
    bm.faces.new(list(reversed(bv)))
    for i in range(4):
        j = (i + 1) % 4
        bm.faces.new((tv[i], tv[j], bv[j], bv[i]))
    bm.normal_update()
    return placed(name, material, bm, at=at)


def gradient_top(name, material, half_x, half_y, z, divisions, ring):
    """One concentric **ring of facets** out of a square face.

    A face split `divisions × divisions`, of which this returns only the quads
    whose Chebyshev distance from the centre puts them in band `ring` — 0 being
    the outermost. Call it once per band and you have a square face that can be
    painted brighter towards the middle, one flat tone per facet.

    **This is the answer to "the tile has a gradient in it" that is not a
    texture**, and the distinction is the whole art direction rather than a
    preference: `models/README.md` bans UVs and textures outright, and
    `lowpoly.export_usdz` passes `export_uvmaps=False`. Quantising the falloff
    onto facets keeps every rule — no UVs, no image, no runtime cost — and it is
    the same trick `bake_ao_facets` plays with occlusion, run the other way up.

    `references/feest/dansvloer.png` supports it directly: the mint tile's top
    is visibly a low-poly fan of triangles shading towards its middle, not a
    smooth wash.

    A flat quad is an **open shell**, so `flat_obj` leaves its winding alone and
    the order below is load-bearing: anticlockwise seen from +Z, which is the
    normal pointing up out of the floor.
    """
    bm = bmesh.new()
    half = (divisions - 1) / 2.0
    for row in range(divisions):
        for column in range(divisions):
            band = int(min(min(row, divisions - 1 - row),
                           min(column, divisions - 1 - column)))
            if band != ring:
                continue
            x0 = (column / divisions * 2 - 1) * half_x
            x1 = ((column + 1) / divisions * 2 - 1) * half_x
            y0 = (row / divisions * 2 - 1) * half_y
            y1 = ((row + 1) / divisions * 2 - 1) * half_y
            v = [bm.verts.new((x0, y0, z)), bm.verts.new((x1, y0, z)),
                 bm.verts.new((x1, y1, z)), bm.verts.new((x0, y1, z))]
            bm.faces.new(v)
    bm.normal_update()
    return lowpoly.flat_obj(name, bm, material)


def dish(name, material, outer_radius, throat_radius, depth, sides=12,
         at=None, rot=None):
    """A cone **recessed into** a surface: a speaker driver, seen from the front.

    Built as a closed solid so the winding recalculates: a rim ring on the face
    plane, a cone wall falling back to a throat ring at `depth`, and a floor.
    The wall is what the bake darkens, and `references/feest/boxen.png` shows
    exactly that — the far side of each cone is a full tone down on the cabinet
    around it, on a prop that is otherwise one colour.

    It is the only true crevice in the disco, which is worth saying plainly:
    everything else in this room is a box standing on a floor, and the bake
    honestly finds almost nothing on those. See `models/README.md` on the fence.
    """
    return lathe(name, material,
                 [(outer_radius, 0.0), (throat_radius, -depth),
                  (throat_radius * 0.98, -depth - 0.0006)],
                 sides, at=at, rot=rot)


def dome(name, material, radius, height, sides=10, rings=3, at=None, rot=None):
    """Half a faceted ball, standing on its flat face. Pads, dust caps, paws."""
    profile = []
    for i in range(rings + 1):
        t = i / rings
        profile.append((radius * math.cos(t * math.pi / 2),
                        height * math.sin(t * math.pi / 2)))
    return lathe(name, material, profile, sides, at=at, rot=rot)


def patch(name, material, profile, centre, lift=0.0005, thickness=0.0016,
          sides=10):
    """A shell that **follows a lathe's own surface** over a tapering sector.

    The belly panel every animal in `references/feest/beertjes.png` wears, and
    the reason it is not simply a squashed ball: an ellipsoid pressed onto a
    barrel is the wrong shape for the job at both ends. Sink it far enough in to
    stop it spilling out of the silhouette and its front no longer breaks the
    surface at all — the panel disappears; push it out far enough to be visible
    and its edges burst through the body's sides in jagged slivers. There is no
    setting in between, because a sphere and a barrel do not share a surface.

    `GuestCharacter` sinks it, and the panel is nearly invisible in the room.
    The first model pushed it out, and the render came back with white shards
    down the bear's flank.

    `profile` is `(radius, z, half_angle)` per station, so **the sector narrows
    towards the top and bottom** and the panel comes to a rounded point at each
    end. That taper is not a refinement: built at one constant angle the panel is
    a *band* with a hard horizontal edge top and bottom, which is what the second
    render showed and is nothing like the soft oval in the plate. A half-angle of
    zero closes the panel to a point.

    `thickness` gives it a back so the shell is closed and `lowpoly.flat_obj` can
    recalculate the winding — an open one would show its inside through the body.
    """
    import bmesh
    bm = bmesh.new()
    outer, inner = [], []
    for radius, z, half in profile:
        ring_o, ring_i = [], []
        for j in range(sides + 1):
            a = centre + half * (2.0 * j / sides - 1.0)
            for target, r in ((ring_o, radius + lift),
                              (ring_i, radius + lift - thickness)):
                target.append(bm.verts.new((math.cos(a) * r, math.sin(a) * r, z)))
        outer.append(ring_o)
        inner.append(ring_i)

    for lo, hi in zip(outer, outer[1:]):
        for j in range(sides):
            bm.faces.new((lo[j], lo[j + 1], hi[j + 1], hi[j]))
    for lo, hi in zip(inner, inner[1:]):
        for j in range(sides):
            bm.faces.new((lo[j], hi[j], hi[j + 1], lo[j + 1]))
    for j in range(sides):
        bm.faces.new((outer[0][j], inner[0][j], inner[0][j + 1], outer[0][j + 1]))
        bm.faces.new((outer[-1][j], outer[-1][j + 1], inner[-1][j + 1], inner[-1][j]))
    for lo, hi in zip(range(len(profile) - 1), range(1, len(profile))):
        bm.faces.new((outer[lo][0], outer[hi][0], inner[hi][0], inner[lo][0]))
        bm.faces.new((outer[lo][sides], inner[lo][sides],
                      inner[hi][sides], outer[hi][sides]))
    bm.normal_update()
    # Degenerate quads appear wherever a station closed to a point; they are
    # zero-area and the bake reads them as facing everywhere at once.
    bmesh.ops.dissolve_degenerate(bm, dist=1e-6, edges=bm.edges[:])
    return lowpoly.flat_obj(name, bm, material)


def blob(name, material, radius, subdivisions=1, scale=(1.0, 1.0, 1.0),
         at=(0.0, 0.0, 0.0)):
    """A faceted ball, squashed along any axis, baked into its vertices.

    `garden.balls` takes one uniform scale, and almost nothing on a teddy bear
    is a sphere: the belly patch is a disc pressed onto the front of a barrel,
    an ear is a flattened round, a snout is wider than it is tall. The plates in
    `references/feest/` draw all three.

    All three factors must stay positive — a negative one mirrors the mesh and a
    mirrored mesh is inside out, which `lowpoly.flat_obj` will not catch here
    because the result is still a closed shell.
    """
    import bmesh
    import mathutils
    check(all(s > 0 for s in scale), "blob %s has a mirrored scale" % name)
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=subdivisions, radius=radius)
    offset = mathutils.Vector(at)
    for v in bm.verts:
        v.co = mathutils.Vector((v.co.x * scale[0], v.co.y * scale[1],
                                 v.co.z * scale[2])) + offset
    bm.normal_update()
    return lowpoly.flat_obj(name, bm, material)


def barrel(name, material, stations, sides=10, at=None, rot=None):
    """A lathe written as `(radius, z)` with a **rounded top**, for a teddy body.

    Straight through to `garden.lathe`; it exists so a character script reads as
    anatomy rather than as a list of numbers, and so the one number worth
    protecting — the head at two fifths of the height,
    `references/feest/README.md` — is not buried in a call.
    """
    return lathe(name, material, stations, sides, at=at, rot=rot)


def join(name, material, objects, at=None):
    """Fold several built objects into one mesh, and drop the originals.

    Six knobs are six USD prims and six materials for one flat tone.
    `garden.boxes` already does this for boxes; this does it for anything the
    lathe made.

    `at` sets the result's **object transform** rather than baking it into the
    vertices, and that is not a stylistic choice — see `animated` below.

    **It deliberately does not re-run `recalc_face_normals`, and that is the
    whole reason this is not three lines at the call site.** `lowpoly.flat_obj`
    recalculates any mesh whose every edge has two faces, which is exactly what a
    pile of disjoint closed shells looks like — and over several shells at once
    the recalculation has no single answer. On the stage lamp it silently flipped
    **7 of 107 faces**, scattered across parts that were nowhere near each other,
    and the render came back with black holes through the middle of the lantern.

    Every object handed in here has already been through `flat_obj` once and is
    already wound correctly, and `bm.from_mesh` preserves that. So the union is
    right the moment it is assembled, and the second recalculation could only
    ever make it wrong.

    `garden.boxes` recalculates a multi-box mesh and is fine, which is worth
    knowing rather than contradicting: boxes are convex, identical in kind and
    built in one pass, and the crate has forty of them. It is the *mixture* — a
    lathe, a stack of boxes and two turned bolts — that has no consistent
    outside.
    """
    import bmesh
    import bpy
    bm = bmesh.new()
    for ob in objects:
        bm.from_mesh(ob.data)
        bpy.data.objects.remove(ob, do_unlink=True)
    bm.normal_update()

    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = False
    me.materials.append(material)
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    if at is not None:
        ob.location = at
    return ob


def animated(ob, at):
    """Give a part its position as an **object transform**, not baked geometry.

    `garden.py` opens by insisting every object comes back with a unit matrix and
    its placement baked into its vertices, and for a static prop that is right —
    nested transforms have cost this project an iteration on every prop with a
    front and a back.

    **A part the game moves is the exception, and `models/scale.py` already is
    one**: its pan is `ob.location = (...)`. The reason is `ModelLibrary.pivot`,
    which hangs a moving part on a holder placed at *the part's own position*. A
    part whose transform is baked reports a position of zero, so the holder lands
    on the prop's origin — and then `FeestRoom`'s `deck.orientation` spins the
    platters in a circle **around the middle of the booth** instead of turning
    them where they stand, and `cone.scale` stretches a speaker cone away from
    the cabinet's foot instead of pushing it out of its own baffle.

    Rotation and scale are what expose it. A part that is only ever translated —
    the scale's pan — survives a wrong pivot by luck.
    """
    ob.location = at
    return ob


def write(objects, stem_name, save=True):
    """`garden.write`, plus proof that a file actually appeared.

    `lowpoly.export_usdz` prints "wrote …" unconditionally, after an operator
    call whose failure it does not inspect. That is how `light-bar` shipped
    nothing at all while reporting success: its root empty collided with its one
    mesh's name, Blender renamed the root `Lichtbalk.001`, and a dot is not legal
    in the USD prim path the exporter was handed.

    A build that says it wrote a prop and did not is the worst kind of silent
    failure here, because the app falls back to the procedural version and looks
    merely *unchanged*.
    """
    garden.write(objects, stem_name, save=save)
    path = lowpoly.bundle_path(stem_name)
    check(os.path.exists(path) and os.path.getsize(path) > 0,
          "%s reported success but wrote no file — check for a name collision "
          "between the root empty and a part" % stem_name)


def check(condition, message):
    """Fail the build rather than export something visibly wrong.

    `garden-tree.py` earned this: an envelope asserted in the script caught a
    canopy lobe pushed through a fence post on the first run, and nothing in
    Blender would otherwise have said so. Every disco script that has a number
    it must stay inside says so here.
    """
    if not condition:
        raise SystemExit("feest: %s" % message)
