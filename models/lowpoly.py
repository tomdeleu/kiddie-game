"""Shared machinery for the props modelled in Blender.

Every rule in `models/README.md` that Blender would otherwise break by default
lives here, in one place, so a new prop gets them by importing rather than by
remembering: flat shading on every face, palette colours converted properly,
and the export flags that keep the facets and the up-axis right.

A prop script is then only the shape — which is the point.

Import it from a sibling script with:

    import sys, os
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import lowpoly
"""

import math
import os

import bpy
import bmesh
import mathutils
import mathutils.bvhtree


# ---------------------------------------------------------------- materials
def srgb_to_linear(c):
    """The palette is sampled in sRGB; Blender's base colour wants linear."""
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def material(name, hexval):
    """A matte, non-metallic material in a palette colour.

    It matches `Palette.material` in Swift, which is what the prop is actually
    painted with at runtime — this exists so the model is reviewable in
    Blender, not because the exported colour is used.
    """
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    rgb = [((hexval >> s) & 255) / 255 for s in (16, 8, 0)]
    lin = tuple(srgb_to_linear(c) for c in rgb) + (1.0,)
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = lin
    bsdf.inputs["Roughness"].default_value = 0.9
    bsdf.inputs["Metallic"].default_value = 0.0
    m.diffuse_color = lin
    return m


# -------------------------------------------------------------------- meshes
def flat_obj(name, bm, mat):
    """Turn a bmesh into an object with **every face flat-shaded**.

    Two things that must never be forgotten, which is why they are here rather
    than in each prop script:

    - **Flat shading.** Smooth normals collapse the facets into a blob, which
      is the whole style gone.
    - **Outward winding.** The normal comes from the winding, and RealityKit
      culls back faces, so a face wound the wrong way is not a dark face — it
      is a hole you can see through. Any closed mesh is recalculated outward;
      an open shell is left alone, since there is no outside to recalculate to.
    """
    if all(len(e.link_faces) == 2 for e in bm.edges):
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])

    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = False
    me.materials.append(mat)
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    return ob


def ring(bm, radius, z, n, jitter=0.0):
    """One horizontal ring of `n` verts.

    `jitter` alternates the radius vertex by vertex. It is how a revolved shape
    stops looking revolved — gather folds in cloth, dimples in fruit.
    """
    verts = []
    for i in range(n):
        a = 2 * math.pi * i / n
        r = radius * (1 + (jitter if i % 2 == 0 else -jitter))
        verts.append(bm.verts.new((math.cos(a) * r, math.sin(a) * r, z)))
    return verts


def bridge(bm, lo, hi, n):
    """Quad-band between two rings of the same vertex count."""
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((lo[i], lo[j], hi[j], hi[i]))


def tube(rings, n, cap_bottom=True, cap_top=True):
    """A stack of rings bridged into a closed solid.

    `rings` is a list of `(radius, z)` or `(radius, z, jitter)`. Closed is not
    optional by default: the flat-shading trick takes its normal from the
    winding, so an open shell shows you the inside of itself.
    """
    bm = bmesh.new()
    built = [ring(bm, r[0], r[1], n, r[2] if len(r) > 2 else 0.0) for r in rings]
    for lo, hi in zip(built, built[1:]):
        bridge(bm, lo, hi, n)
    if cap_bottom:
        bm.faces.new(list(reversed(built[0])))
    if cap_top:
        bm.faces.new(built[-1])
    bm.normal_update()
    return bm


# ------------------------------------------------------------ occlusion bake
def _cosine_hemisphere(samples):
    """A fixed, cosine-weighted set of directions in the +Z hemisphere.

    Deterministic on purpose — `Math.random` would make the export differ run
    to run, and a model that changes when you rebuild it is a model nobody can
    review a diff of.
    """
    golden = math.pi * (3 - math.sqrt(5))
    dirs = []
    for k in range(samples):
        r = math.sqrt((k + 0.5) / samples)
        a = golden * k
        dirs.append((r * math.cos(a), r * math.sin(a), math.sqrt(max(0.0, 1 - r * r))))
    return dirs


def _basis(n):
    """An orthonormal basis with `n` as its third axis."""
    up = mathutils.Vector((0, 0, 1)) if abs(n.z) < 0.9 else mathutils.Vector((1, 0, 0))
    t = n.cross(up).normalized()
    b = n.cross(t)
    return mathutils.Matrix((t, b, n)).transposed()


def bake_ao_facets(objects, thresholds=(0.12, 0.30), distance=0.005, samples=48,
                   min_faces=3):
    """Bake ambient occlusion **into the facets**, and split by how dark.

    Every face gets rays cast over its hemisphere against the whole prop; the
    fraction that hit something within `distance` is its occlusion. Faces above
    the first threshold move into a new object named `<Name>Shade1`, above the
    second into `<Name>Shade2`, and `ModelLibrary` paints those that many steps
    darker than the prop's palette colour.

    **This is AO without a texture, and it is the only AO in the game.**
    `references/REFERENCES.md` bans occlusion outright because the facets are
    supposed to do the shading, and a lightmap needs UVs, a bake and a texture —
    none of which this project has. Quantising the bake onto the facets keeps
    all of that: no UVs, no textures, no runtime cost, and the result is still a
    flat tone per face, which is what the whole style is made of.

    `distance` is short by design. This is contact shading between two parts
    that touch — a crown standing in its calyx — not global darkening of a prop,
    which is the thing that was rejected.

    `min_faces` demotes a level that catches fewer faces than that into the one
    below. One facet a step darker than everything around it does not read as
    occlusion, it reads as a blemish on the model.
    """
    deps = bpy.context.evaluated_depsgraph_get()
    verts, polys = [], []
    for ob in objects:
        ev = ob.evaluated_get(deps)
        me = ev.to_mesh()
        offset = len(verts)
        verts.extend([tuple(ob.matrix_world @ v.co) for v in me.vertices])
        polys.extend([[i + offset for i in p.vertices] for p in me.polygons])
        ev.to_mesh_clear()
    bvh = mathutils.bvhtree.BVHTree.FromPolygons(verts, polys, all_triangles=False)

    dirs = _cosine_hemisphere(samples)
    produced = []
    for ob in objects:
        rotation = ob.matrix_world.to_3x3()
        buckets = {}
        for poly in ob.data.polygons:
            centre = ob.matrix_world @ poly.center
            normal = (rotation @ poly.normal).normalized()
            basis = _basis(normal)
            origin = centre + normal * 2e-5
            hit = 0
            for d in dirs:
                if bvh.ray_cast(origin, basis @ mathutils.Vector(d), distance)[0] is not None:
                    hit += 1
            ao = hit / float(samples)
            level = sum(1 for t in thresholds if ao >= t)
            buckets.setdefault(level, []).append(poly.index)

        # Demote thin levels, darkest first, so a straggler joins the band below
        # it rather than standing out on its own.
        for level in sorted(buckets, reverse=True):
            if level > 0 and len(buckets[level]) < min_faces:
                buckets.setdefault(level - 1, []).extend(buckets.pop(level))

        produced.extend(_split_levels(ob, buckets))
    return produced


# How much darker one step of occlusion is. **Kept in step with
# `Palette.occluded` in Swift** — the app repaints the model from the palette,
# so this factor only exists so the model looks in Blender like it will look in
# the game. If one moves, move the other.
OCCLUSION_STEP = 0.88


def _shade_material(base, level):
    name = "%sShade%d" % (base.name, level)
    existing = bpy.data.materials.get(name)
    if existing:
        return existing
    m = base.copy()
    m.name = name
    f = OCCLUSION_STEP ** level
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    c = bsdf.inputs["Base Color"].default_value
    darker = (c[0] * f, c[1] * f, c[2] * f, 1.0)
    bsdf.inputs["Base Color"].default_value = darker
    m.diffuse_color = darker
    return m


def _split_levels(ob, buckets):
    """Move every occluded face out of `ob` into one new object per level.

    **All levels in one pass.** Deleting faces renumbers the ones that remain,
    so splitting level 1 and then looking level 2 up by index reads the wrong
    faces — or runs off the end of the list, which is how this was caught.

    Separate objects rather than material slots on one mesh: a slot becomes a
    USD GeomSubset whose order across the round trip is one more thing to trust,
    and the Swift side already paints by entity name.
    """
    levels = sorted(k for k in buckets if k > 0)
    if not levels:
        return []

    src = bmesh.new()
    src.from_mesh(ob.data)
    src.faces.ensure_lookup_table()
    base_material = ob.data.materials[0]

    produced, removing = [], []
    for level in levels:
        chosen = [src.faces[i] for i in buckets[level]]
        removing.extend(chosen)

        out = bmesh.new()
        remap = {}
        for f in chosen:
            vs = []
            for v in f.verts:
                if v.index not in remap:
                    remap[v.index] = out.verts.new(v.co)
                vs.append(remap[v.index])
            out.faces.new(vs)
        # Winding is inherited from the source face, which is already right, and
        # `flat_obj` leaves an open shell's normals alone — so it stays right.
        out.normal_update()

        shade = flat_obj("%sShade%d" % (ob.name, level), out,
                         _shade_material(base_material, level))
        shade.parent = ob.parent
        shade.matrix_local = ob.matrix_local
        produced.append(shade)

    bmesh.ops.delete(src, geom=removing, context='FACES')
    src.to_mesh(ob.data)
    src.free()
    for p in ob.data.polygons:
        p.use_smooth = False
    ob.data.update()
    return produced


def clear(prefix):
    """Remove any objects from a previous run, so a script is re-runnable."""
    for ob in list(bpy.data.objects):
        if ob.name.startswith(prefix):
            bpy.data.objects.remove(ob, do_unlink=True)


# -------------------------------------------------------------------- export
def export_usdz(objects, path):
    """Write the USDZ the app loads.

    Three of these flags are load-bearing and `models/README.md` says why:
    `convert_orientation` (Blender is Z-up, USDZ is Y-up), `export_normals`
    (without it the facets are gone) and `evaluation_mode='RENDER'` (applies
    modifiers, e.g. the flour sack collar's solidify).
    """
    bpy.ops.object.select_all(action='DESELECT')
    for ob in objects:
        ob.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.wm.usd_export(
        filepath=path,
        selected_objects_only=True,
        export_animation=False,
        export_uvmaps=False,          # nothing here is textured
        export_normals=True,          # one normal per face: the facets
        export_materials=True,
        export_lights=False,
        export_cameras=False,
        generate_preview_surface=True,
        convert_orientation=True,
        export_global_up_selection='Y',
        export_global_forward_selection='NEGATIVE_Z',
        evaluation_mode='RENDER',
        # Named after the prop's own root object, not the filename: the mesh
        # names are what the Swift side tints by, and they should agree.
        root_prim_path="/" + objects[0].name,
    )
    print("wrote %s" % path)


REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def bundle_path(name):
    """Where a prop's USDZ ships: `Resources/Models/` in the app."""
    return os.path.join(REPO, "app", "NinaBakeryPOC", "Resources", "Models", name + ".usdz")
