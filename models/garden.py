"""Shared shapes for De Tuin's modelled props.

`lowpoly.py` holds the rules every prop in this folder obeys — flat shading,
winding, the occlusion bake, the export. This holds the vocabulary **De Tuin**
needed on top of it, and nothing else uses it:

  * `lathe` — a revolved profile that may come to a **point** at either end. The
    kitchen's props never needed one, because `lowpoly.tube` builds a closed
    solid out of rings and a zero-radius ring is eight vertices in the same
    place. Half the garden's heads are pointed: a strawberry, a seed pod, a
    picket, a fence cap.
  * `leaf` — a **folded** lance leaf. It is the clover's crease again
    (`models/README.md`, "The toverklaver"), and it is the single biggest reason
    these plants are worth modelling: every plate in `references/garden/` draws
    its leaves creased along the midrib, and `FacetedMesh.extrude` makes a flat
    slab with one front face and one tone. The code version painted alternate
    leaves `sage` and `mint` — a tint standing in for a shape. With a real fold
    the facets do that job, so **every leaf here is one colour**, which is also
    what the plates show.
  * `sweep` — a polygon cross-section carried along a **bent** path. The garden
    is the first room to need a curve: `plant-aardbei.png` hangs its berry off
    an arched stalk and `plant-klaver.png` grows two curved stems out of one
    base. `GardenProps` fakes the first with three straight boxes and cannot
    say the second at all.
  * `balls`, `chip`, `wedge_ring` — a faceted cluster, a flat petal chip, and a
    ring of pointed teeth.

**Everything is built at identity.** A helper takes `at` and `rot` and bakes the
transform into its vertices rather than leaving it on the object, so every
object a garden script hands to `lowpoly.bake_ao_facets` and
`lowpoly.export_usdz` has a unit matrix. Nested transforms are the one thing
that has cost this project an iteration on every prop with a front and a back,
and a plant has a stem, a rosette, an arched stalk and a head.

Blender is Z-up and the exporter maps (x, y, z) → (x, z, −y), so:

    Blender +Z  is the game's +Y   (up)
    Blender +X  is the game's +X
    Blender −Y  is the game's +Z   (towards the camera)

and a turn of θ about Blender +Z is the game's `towardsCamera` turn of θ about
its own +Y. `FACING_CAMERA` is that turn.
"""

import math
import os
import sys

import bmesh
import bpy
import mathutils

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lowpoly


#: Straight through to `lowpoly.material`, so a garden script imports one module
#: rather than two to say what colour a thing is.
material = lowpoly.material


# ------------------------------------------------------------------- palette
# `Palette.swift` is the single source of truth — the app repaints every model
# on load. These exist so a model is reviewable in Blender rather than because
# the exported colour is used.
BLUSH_PINK = 0xFBD0CA
BLUSH_PINK_DEEP = 0xE3B1AE
ROSE = 0xEAB5AA
MINT_LIGHT = 0xD6F0DE
MINT = 0xC2DECF
SAGE = 0xA7C0AC
SAGE_DEEP = 0x7E9A88
CREAM_LIGHT = 0xF2E6DC
CREAM = 0xE4DACA
BUTTER_YELLOW = 0xDCC994
SANDY_WOOD = 0xC79C86
WOOD_BROWN = 0x8A7A66
HONEY_AMBER = 0xD2A868
LILAC = 0xD3C6E4
LILAC_DEEP = 0xAE9CC9
OVEN_INSIDE = 0x554C3F
#: `Palette.mix(.creamLight, .woodBrown, 0.45)`, which is what `GardenProps`
#: paints Mo with. The plate draws him grey; this is the palette's nearest.
MOLE_GREY = 0xC3B5A6
#: `Palette.mix(.woodBrown, .sandyWood, 0.35)` — the bed's hole rings.
HOLE_EDGE = 0x9F8671


#: The turn that puts a flat prop's face on the room's fixed camera, which sits
#: on the game's +X+Z diagonal. A constant, not a billboard — nothing ever moves
#: the camera (`CONCEPT.md` §9.4).
FACING_CAMERA = math.pi / 4


# ---------------------------------------------------------------- transforms
def matrix(at=(0.0, 0.0, 0.0), rot=(0.0, 0.0, 0.0), scale=1.0):
    """A transform to bake into a shape's vertices.

    `rot` is an XYZ Euler in the same order Blender's own `rotation_euler` uses
    (X first), so a number copied off an object in the viewport still means what
    it meant there.
    """
    m = mathutils.Matrix.Translation(at)
    m @= mathutils.Euler(rot, 'XYZ').to_matrix().to_4x4()
    if scale != 1.0:
        m @= mathutils.Matrix.Scale(scale, 4)
    return m


def _place(bm, m):
    if m is not None:
        bmesh.ops.transform(bm, matrix=m, verts=bm.verts[:])
    bm.normal_update()
    return bm


# -------------------------------------------------------------------- solids
def lathe(name, material, profile, sides, at=None, rot=None, scale=1.0,
          cap_bottom=True, cap_top=True):
    """A revolved profile that may come to a **point** at either end.

    `profile` is a list of `(radius, z)`. A station with radius 0 becomes a
    single apex vertex rather than a ring of coincident ones — which is the
    whole reason this exists next to `lowpoly.tube`. A cone of eight zero-length
    faces is not a point: it is eight degenerate triangles that the occlusion
    bake reads as facing every direction at once.
    """
    bm = bmesh.new()
    layers = []
    for radius, z in profile:
        if radius <= 1e-9:
            layers.append(("apex", bm.verts.new((0.0, 0.0, z))))
        else:
            layers.append(("ring", lowpoly.ring(bm, radius, z, sides)))
    _stack(bm, layers, sides, cap_bottom, cap_top)

    _place(bm, _transform(at, rot, scale))
    return lowpoly.flat_obj(name, bm, material)


def _stack(bm, layers, sides, cap_bottom=True, cap_top=True):
    """Bridge a list of `("ring", verts)` / `("apex", vert)` layers into a solid."""
    for (lower_kind, lower), (upper_kind, upper) in zip(layers, layers[1:]):
        if lower_kind == "ring" and upper_kind == "ring":
            lowpoly.bridge(bm, lower, upper, sides)
        elif lower_kind == "apex" and upper_kind == "ring":
            for i in range(sides):
                bm.faces.new((lower, upper[(i + 1) % sides], upper[i]))
        elif lower_kind == "ring" and upper_kind == "apex":
            for i in range(sides):
                bm.faces.new((lower[i], lower[(i + 1) % sides], upper))
    if cap_bottom and layers[0][0] == "ring":
        bm.faces.new(list(reversed(layers[0][1])))
    if cap_top and layers[-1][0] == "ring":
        bm.faces.new(layers[-1][1])
    return bm


def add_column(bm, section, stations, at=(0.0, 0.0, 0.0)):
    """One column of an **arbitrary** cross-section, appended to `bm`.

    `section` is a list of `(x, y)` wound anticlockwise; `stations` a list of
    `(scale, z)`, where a scale of zero comes to a point. It is `lathe` with the
    circle taken out, and the fence is what wanted it: a picket in
    `references/garden/garden-fence.png` is a **chamfered column with a faceted
    point on it**, not the flat board `GardenRoomBuilder` cuts, and forty of
    them have to end up in one mesh or the fence is forty prims.
    """
    ox, oy, oz = at
    n = len(section)
    layers = []
    for scale, z in stations:
        if scale <= 1e-9:
            layers.append(("apex", bm.verts.new((ox, oy, oz + z))))
        else:
            layers.append(("ring", [bm.verts.new((ox + x * scale, oy + y * scale, oz + z))
                                    for x, y in section]))
    return _stack(bm, layers, n)


def octagon(half_x, half_y, chamfer):
    """A rectangle with its four corners cut off, wound anticlockwise.

    The picket cross-section. A plain box gives a picket two faces from any
    angle and both of them flat; the cut corners give it four, which is what
    makes the plate's pickets read as turned timber rather than as slats.
    """
    return [(half_x, -half_y + chamfer), (half_x, half_y - chamfer),
            (half_x - chamfer, half_y), (-half_x + chamfer, half_y),
            (-half_x, half_y - chamfer), (-half_x, -half_y + chamfer),
            (-half_x + chamfer, -half_y), (half_x - chamfer, -half_y)]


def prism(name, material, radius, height, sides, at=None, rot=None):
    """A flat-topped drum. The `FacetedMesh.prism` every garden prop is made of."""
    return lathe(name, material, [(radius, 0.0), (radius, height)], sides,
                 at=at, rot=rot)


def chip(name, material, radius, thickness, sides=6, at=None, rot=None):
    """One flat petal chip lying in the XY plane.

    `references/garden/flower-row.png` and `plant-honing.png` both make their
    petals **chips rather than points**, which is what stops a ring of them
    reading as a star.
    """
    return prism(name, material, radius, thickness, sides, at=at, rot=rot)


def balls(name, material, blobs, subdivisions=1, at=None, rot=None):
    """A cluster of faceted spheres in one mesh.

    Several disjoint closed shells in one bmesh is still a closed mesh — every
    edge has two faces — so a cloud is one object with one material rather than
    five. `plant-wolkenroom.png` and `garden-tree.png` are both built this way,
    and `models/README.md` records why a single sphere never works: it is a
    lollipop, and the cluster is the shape.
    """
    bm = bmesh.new()
    for radius, centre in blobs:
        bmesh.ops.create_icosphere(bm, subdivisions=subdivisions, radius=radius,
                                   matrix=mathutils.Matrix.Translation(centre))
    _place(bm, _transform(at, rot, 1.0))
    return lowpoly.flat_obj(name, bm, material)


def placed(name, material, bm, at=None, rot=None):
    """Bake a transform into a hand-built bmesh and flat-shade it.

    The way out for a shape none of the helpers above says — a feather's vane, a
    clover's heart. It keeps the rule that matters: whatever a script builds by
    hand still comes back as an object with a **unit matrix**.
    """
    _place(bm, _transform(at, rot, 1.0))
    return lowpoly.flat_obj(name, bm, material)


def solidify(ob, thickness):
    """Give an open shell a thickness, and bake it in immediately.

    Baked rather than left on the object because `lowpoly.bake_ao_facets`
    measures against evaluated geometry and splits the stored mesh — leave a
    solidify unapplied and the shaded faces come out paper-thin.
    """
    solid = ob.modifiers.new("Thickness", 'SOLIDIFY')
    solid.thickness = thickness
    solid.offset = 0.0
    lowpoly.apply_modifiers(ob)
    return ob


def boxes(name, material, spans, at=None, rot=None):
    """Several axis-aligned boxes in one mesh. `spans` is a list of `(x, y, z)`
    triples of `(min, max)` pairs — `lowpoly.add_box`'s arguments.

    A fence is forty pickets and a bed is eight boards; one object per board
    would be forty USD prims and forty materials for one flat tone.
    """
    bm = bmesh.new()
    for span in spans:
        lowpoly.add_box(bm, *span)
    _place(bm, _transform(at, rot, 1.0))
    return lowpoly.flat_obj(name, bm, material)


def sweep(name, material, points, radii, sides=5, up=(0.0, 0.0, 1.0),
          at=None, rot=None):
    """A polygon cross-section carried along a **bent** path.

    The garden is the first room that needed a curve. `GardenProps` fakes the
    strawberry's arched stalk with three rotated boxes — which is honest at
    10 mm and visibly three boxes at any size above it — and cannot say the
    clover plate's two curved stems at all.

    `radii` is a number or one per point, so a stalk can taper as it arches.
    The frame is carried from a fixed reference `up` rather than transported
    along the curve: every path here is a plane curve, so there is no twist to
    accumulate, and a fixed reference is one fewer thing to be wrong.
    """
    pts = [mathutils.Vector(p) for p in points]
    if not hasattr(radii, "__len__"):
        radii = [radii] * len(pts)

    tangents = []
    for i in range(len(pts)):
        if i == 0:
            step = pts[1] - pts[0]
        elif i == len(pts) - 1:
            step = pts[-1] - pts[-2]
        else:
            step = pts[i + 1] - pts[i - 1]
        tangents.append(step.normalized())

    reference = mathutils.Vector(up)
    bm = bmesh.new()
    rings = []
    for point, tangent, radius in zip(pts, tangents, radii):
        across = reference.cross(tangent)
        if across.length < 1e-6:
            across = mathutils.Vector((1.0, 0.0, 0.0)).cross(tangent)
        across.normalize()
        along = tangent.cross(across).normalized()
        ring = []
        for k in range(sides):
            a = 2 * math.pi * k / sides
            offset = across * (math.cos(a) * radius) + along * (math.sin(a) * radius)
            ring.append(bm.verts.new(point + offset))
        rings.append(ring)

    for lower, upper in zip(rings, rings[1:]):
        lowpoly.bridge(bm, lower, upper, sides)
    bm.faces.new(list(reversed(rings[0])))
    bm.faces.new(rings[-1])

    _place(bm, _transform(at, rot, 1.0))
    return lowpoly.flat_obj(name, bm, material)


def wedge_ring(name, material, count, base_radius, base_width, tip_radius,
               height, thickness=0.0022, at=None, rot=None, phase=0.0):
    """A ring of pointed teeth splaying up and out — a seed pod's split mouth.

    `plant-maanstof.png` is the only plate that asks for it, and it is what
    turns a ball on a stem into something that has opened. Each tooth is a
    four-sided pyramid: a rectangle on the rim, coming to one point above and
    outside it. A tooth with a flat top is a battlement.
    """
    bm = bmesh.new()
    for i in range(count):
        a = phase + 2 * math.pi * i / count
        out = mathutils.Vector((math.cos(a), math.sin(a), 0.0))
        side = mathutils.Vector((-math.sin(a), math.cos(a), 0.0))
        centre = out * base_radius
        inner = centre - out * (thickness / 2)
        outer = centre + out * (thickness / 2)
        base = [bm.verts.new(inner - side * (base_width / 2)),
                bm.verts.new(outer - side * (base_width / 2)),
                bm.verts.new(outer + side * (base_width / 2)),
                bm.verts.new(inner + side * (base_width / 2))]
        apex = bm.verts.new(out * tip_radius + mathutils.Vector((0.0, 0.0, height)))
        bm.faces.new(base)
        for j in range(4):
            bm.faces.new((base[j], base[(j + 1) % 4], apex))
    _place(bm, _transform(at, rot, 1.0))
    return lowpoly.flat_obj(name, bm, material)


def ridged_star(name, material, points, outer_radius, inner_radius, depth,
                back_depth=None, at=None, rot=None):
    """A star with a **ridge running out to every point**, not an extruded slab.

    `plant-sterrensuiker.png` is emphatic: the centre stands proud and a hard
    crease runs from it to each of the five tips, with a valley between every
    pair. `FacetedMesh.star` extrudes a flat outline, so its whole front is one
    tone and the arms are told apart only by their silhouette.

    It is the blueberry crown's lesson upside down (`models/README.md`): there
    the centre had to be the *low* point, because a raised middle turned five
    spikes into one hat. Here the plate wants exactly that hat, because a sugar
    star is a solid object rather than a crown standing in a calyx.

    Built in the XZ plane with its depth along Y, so the finished prop faces the
    game's +Z before `FACING_CAMERA` turns it.
    """
    back_depth = depth * 0.55 if back_depth is None else back_depth
    bm = bmesh.new()
    rim = []
    for i in range(points):
        tip_a = math.pi / 2 + 2 * math.pi * i / points
        dip_a = tip_a + math.pi / points
        rim.append(bm.verts.new((math.cos(tip_a) * outer_radius, 0.0,
                                 math.sin(tip_a) * outer_radius)))
        rim.append(bm.verts.new((math.cos(dip_a) * inner_radius, 0.0,
                                 math.sin(dip_a) * inner_radius)))
    front = bm.verts.new((0.0, -depth, 0.0))
    back = bm.verts.new((0.0, back_depth, 0.0))
    for i in range(len(rim)):
        j = (i + 1) % len(rim)
        bm.faces.new((front, rim[i], rim[j]))
        bm.faces.new((back, rim[j], rim[i]))
    _place(bm, _transform(at, rot, 1.0))
    return lowpoly.flat_obj(name, bm, material)


# ------------------------------------------------------------------ the leaf
#: Up a lance leaf: `(height, half-width, ridge)`, each as a fraction of the
#: leaf's length, its widest half-width and its ridge height. It is the outline
#: `GardenProps.leafShape` already uses — the plates all draw the same lance —
#: with a crease added down the middle.
LEAF_STATIONS = [(0.00, 0.00, 0.00),
                 (0.28, 0.55, 0.70),
                 (0.62, 1.00, 1.00),
                 (0.90, 0.62, 0.50),
                 (1.00, 0.00, 0.00)]


def leaf(name, material, length, width=0.29, ridge=0.13, thickness=0.0010,
         at=None, rot=None):
    """One **folded** lance leaf, standing along +Z with its ridge towards +Y.

    Two fans meeting on the crease, exactly as `models/klaver.py` builds a
    petal: each triangle takes its own angle off the fold, and that is where the
    shading comes from. Flat on both sides of a slab, there is nothing to shade.

    The ridge points at +Y so that a leaf tipped out of upright by a rotation
    about +X — which is how every rosette here is splayed — ends up with its
    crease facing the sky. Get that backwards and every leaf in the bed is a
    gutter.

    **Narrower than `GardenProps.leafShape`'s 0.34.** A folded leaf reads wider
    than a flat one of the same outline, because the crease turns half of its
    width towards the light and the other half away, and at 0.34 the first
    render came back with a rosette of petals rather than of leaves. The plates
    all draw a long lance; 0.29 is what gets the fold and that proportion at
    once.

    Returned with a solidify modifier already applied, so the caller gets a
    closed solid it can hand straight to the occlusion bake.
    """
    half = length * width
    peak = length * ridge

    bm = bmesh.new()
    spine = [bm.verts.new((0.0, h * peak, z * length))
             for z, _, h in LEAF_STATIONS]
    for side in (1, -1):
        edge = {}
        for i, (z, w, _) in enumerate(LEAF_STATIONS):
            if w > 0:
                edge[i] = bm.verts.new((side * w * half, 0.0, z * length))
        for i in range(len(LEAF_STATIONS) - 1):
            if i not in edge:
                face = (spine[i], spine[i + 1], edge[i + 1])
            elif i + 1 not in edge:
                face = (spine[i], spine[i + 1], edge[i])
            else:
                face = (spine[i], spine[i + 1], edge[i + 1], edge[i])
            bm.faces.new(face if side > 0 else tuple(reversed(face)))

    _place(bm, _transform(at, rot, 1.0))
    ob = lowpoly.flat_obj(name, bm, material)
    solid = ob.modifiers.new("Thickness", 'SOLIDIFY')
    solid.thickness = thickness
    solid.offset = 0.0
    lowpoly.apply_modifiers(ob)
    return ob


# ---------------------------------------------------------------- the clover
#: Half of a heart, tip at the origin, growing along +Z, mirrored across X — and
#: it is `models/klaver.py`'s outline unchanged. The clover the kitchen puts in
#: the bowl and the clover growing on this plant have to be the same leaf.
CLOVER_HALF = [(-0.0024, 0.0022),
               (-0.0045, 0.0050),
               (-0.0050, 0.0078),
               (-0.0038, 0.0098),
               (-0.0016, 0.0092)]
CLOVER_NOTCH = 0.0076
CLOVER_SPINE = 0.0050
CLOVER_RIDGE = 0.0022
CLOVER_THICKNESS = 0.0009


def clover_head(name, material, at, rot=(0.0, 0.0, 0.0), count=4, first=0):
    """Four folded hearts meeting at one hub.

    Built in the head's own XZ plane and spun about its Y, so the four tips all
    land on the hub with no compensation — the tip is the petal's origin. The
    fold is the whole point and `models/klaver.py` has the argument: each half
    of a heart is a fan around the crease, so the two halves catch the light
    differently and four petals read as leaves rather than as stickers.
    """
    base = matrix(at, rot)
    made = []
    for i in range(count):
        spin = mathutils.Matrix.Rotation(math.pi / 4 + i * 2 * math.pi / count,
                                         4, 'Y')
        bm = bmesh.new()
        tip = bm.verts.new((0.0, 0.0, 0.0))
        mid = bm.verts.new((0.0, -CLOVER_RIDGE, CLOVER_SPINE))
        notch = bm.verts.new((0.0, -CLOVER_RIDGE * 0.45, CLOVER_NOTCH))
        for side in (-1, 1):
            edge = [bm.verts.new((side * x, 0.0, z)) for x, z in CLOVER_HALF]
            chain = [tip] + edge + [notch]
            for a, b in zip(chain, chain[1:]):
                bm.faces.new((mid, a, b) if side < 0 else (mid, b, a))
        _place(bm, base @ spin)
        made.append(solidify(
            lowpoly.flat_obj("%s%d" % (name, first + i), bm, material),
            CLOVER_THICKNESS))
    return made


# ---------------------------------------------------------------- the plant
#: **The plant's anatomy, and it is `GardenProps.plant`'s, number for number.**
#:
#: The four growth stages are one object growing rather than four objects, which
#: is what makes watering read as growth. Only the ripe stage is modelled here;
#: stages 0–2 stay in Swift, so the mound the model stands on has to be the
#: mound they leave behind — same radius, same height, same nine sides — or the
#: last sweep of the can would move the earth.
MOUND_RADIUS = 0.0125
MOUND_HEIGHT = 0.0055
MOUND_SIDES = 9
STEM_BASE = 0.0045
STEM_HEIGHT = 0.026
STEM_RADIUS = (0.0016, 0.0012)
ROSETTE_Z = STEM_BASE + STEM_HEIGHT * 0.30
ROSETTE_COUNT = 6
ROSETTE_LENGTH = 0.0135
ROSETTE_TILT = 1.15
#: Where a head sits: the top of the stem.
HEAD_Z = STEM_BASE + STEM_HEIGHT


def mound(material, name="PlantMound"):
    """The turned earth every stage stands in.

    **A dome, not a cone.** `references/garden/sprout-early.png` is emphatic
    about it and the reason is eleven centimetres away: this room also has a
    molehill, and a cone is what that is.
    """
    fall = math.sqrt(0.5)
    return lathe(name, material,
                 [(MOUND_RADIUS, 0.0),
                  (MOUND_RADIUS * fall, MOUND_HEIGHT * fall),
                  (0.0, MOUND_HEIGHT)],
                 MOUND_SIDES)


def rosette(material, count=ROSETTE_COUNT, length=ROSETTE_LENGTH,
            tilt=ROSETTE_TILT, z=ROSETTE_Z, phase=0.0, name="PlantLeaf"):
    """The ring of splayed leaves, one object per leaf.

    **One colour for all of them.** The code version alternates `sage` and
    `mint` because a flat slab has one tone and needed the difference painted
    on; the fold does it here, and every plate in `references/garden/` draws a
    rosette in a single green.
    """
    leaves = []
    for i in range(count):
        around = phase + 2 * math.pi * i / count
        leaves.append(leaf("%s%d" % (name, i), material, length,
                           at=(0.0, 0.0, z), rot=(tilt, 0.0, around)))
    return leaves


def stem(material, height=STEM_HEIGHT, base=STEM_BASE, radii=STEM_RADIUS,
         sides=5, name="PlantStem"):
    """The straight stem, from just inside the mound to the head."""
    return lathe(name, material,
                 [(radii[0], base), (radii[1], base + height)], sides)


def plant_base(leaf_material, stem_material, earth, with_stem=True,
               **rosette_args):
    """Mound, rosette and stem — everything a ripe plant has below its head.

    Every one of the seven plants is this plus what its plate hangs on top, and
    that is the point: the bed grows five at once, and five silhouettes that
    share nothing read as five different games rather than as one garden.
    """
    parts = [mound(earth)]
    parts += rosette(leaf_material, **rosette_args)
    if with_stem:
        parts.append(stem(stem_material))
    return parts


# ------------------------------------------------------------------ plumbing
def _transform(at, rot, scale):
    if at is None and rot is None and scale == 1.0:
        return None
    return matrix(at or (0.0, 0.0, 0.0), rot or (0.0, 0.0, 0.0), scale)


def fresh(*prefixes):
    """Empty the scene of anything this script is about to rebuild.

    Blender's startup file arrives with a cube, a camera and a lamp in it. None
    of them reach the USDZ — the export is selection-only — but they do land in
    the `.blend`, and a `.blend` is meant to be the thing somebody opens to look
    at the prop.
    """
    for ob in list(bpy.data.objects):
        if ob.name in ("Cube", "Camera", "Light") or \
                any(ob.name.startswith(p) for p in prefixes):
            bpy.data.objects.remove(ob, do_unlink=True)


def root_for(name, parts):
    """Parent every part to one empty and hand back the export list.

    The empty is what `lowpoly.export_usdz` names the USD root prim after, and
    the Swift side loads a wrapper around it — so its name is the prop's name
    and nothing else's.
    """
    root = bpy.data.objects.new(name, None)
    root.empty_display_size = 0.02
    bpy.context.collection.objects.link(root)
    for ob in parts:
        ob.parent = root
    bpy.context.view_layer.update()
    return root


def finish(name, parts, distance, shade=None, min_faces=3):
    """Bake the contact shading and return everything the export wants.

    `distance` is short by design and is chosen against the size of the part it
    has to stay inside — `models/README.md` has the argument, and every number
    passed in here is defended at its call site.

    `shade` narrows **what may be darkened** while the whole prop still casts
    into the bake. It is the cake's `occluders` argument turned round the useful
    way: a part that is small, enclosed and *the bright note of the prop* comes
    back uniformly dark, which is correct as physics and wrong as a picture. The
    honey pool is the case that wanted it.
    """
    root = root_for(name, parts)
    shades = lowpoly.bake_ao_facets(parts if shade is None else shade,
                                    distance=distance, occluders=parts,
                                    min_faces=min_faces)
    return [root] + parts + shades


def write(objects, stem_name, save=True):
    """Export the USDZ and, unless told not to, save the matching `.blend`."""
    lowpoly.export_usdz(objects, lowpoly.bundle_path(stem_name))
    if save and "--no-save" not in sys.argv:
        bpy.ops.wm.save_as_mainfile(
            filepath=os.path.join(lowpoly.REPO, "models", stem_name + ".blend"))
