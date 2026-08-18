"""**Ambient occlusion measured against the room**, not against one prop.

`lowpoly.bake_ao_facets` is per-prop by construction: it builds its BVH out of
the prop being baked, in that prop's own space, and so it can only find the
creases a prop has *with itself* — a crown standing in its calyx, a board butted
into a post. Every occlusion that happens **between two objects** is invisible
to it, and in a room that is most of them:

  * six pairs of feet, four cabinet corners and three table legs on the floor
  * the DJ booth and the two speaker stacks against the plaster
  * the seam where the two walls meet, and where each meets the floor
  * thirty-six tiles, each of which shades the 3 mm gap round its neighbour
  * a 60 mm mirror ball hanging over the middle of the dance floor

This measures all of them, in world space, against the assembled scene from
`feest-scene.py`. It is the same algorithm as `lowpoly.bake_ao_facets` — a
cosine-weighted hemisphere of rays per facet, grazing rays discarded — with two
differences that are the whole point:

  * **The occluder set is the room.** Every mesh in the scene casts.
  * **The reach is room-scale.** A prop bake reaches 2–6 mm because it is
    shading a crease. A scene bake is shading the ground a guest stands on, and
    the distance that matters there is the size of the *gap*, not of the crease.

It paints per-face **material slots** rather than splitting off `ShadeN`
objects. `lowpoly` splits because `ModelLibrary` paints by entity name and a USD
GeomSubset is one more thing to trust across the round trip; here nothing is
exported, and slots keep the mesh — and therefore the render — comparable
face-for-face with the un-baked one.
"""

import math
import os
import sys

import bpy
import mathutils
import mathutils.bvhtree

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lowpoly


#: What a scene bake reaches, in metres.
#:
#: **Two orders of magnitude above a prop bake, and that is not a mistake.**
#: `models/README.md`'s rule is that the distance is chosen against the size of
#: the thing the shading has to sit inside, and for a prop that is a 2 mm groove
#: or a 4 mm board. Here it is the gap between a guest's foot and the tile she
#: stands on, which is nothing, spreading out over the 20–40 mm the eye reads as
#: contact. Below ~20 mm the shading hugs the silhouette so tightly it reads as
#: an outline; above ~80 mm the whole floor starts to measure as occluded
#: because the room has walls.
REACH = 0.045


def meshes(objects=None):
    return [ob for ob in (objects or bpy.data.objects)
            if ob.type == 'MESH' and len(ob.data.polygons)]


def owner(ob):
    """Which **prop** an object belongs to.

    Every prop in the scene hangs off one empty — `feest-scene.instance` puts
    it there — so the top of the parent chain names the thing a facet is part
    of. The shell's four pieces have no parent and are each their own prop,
    which is what makes the floor able to shade the wall it meets.
    """
    node = ob
    while node.parent is not None:
        node = node.parent
    return node.name


def occluder_tree(objects):
    """One BVH over the whole room, in world space, and who owns each polygon."""
    deps = bpy.context.evaluated_depsgraph_get()
    verts, polys, owners = [], [], []
    for ob in objects:
        evaluated = ob.evaluated_get(deps)
        me = evaluated.to_mesh()
        offset = len(verts)
        matrix = ob.matrix_world
        verts.extend([tuple(matrix @ v.co) for v in me.vertices])
        who = owner(ob)
        for p in me.polygons:
            polys.append([i + offset for i in p.vertices])
            owners.append(who)
        evaluated.to_mesh_clear()
    tree = mathutils.bvhtree.BVHTree.FromPolygons(verts, polys,
                                                  all_triangles=False)
    return tree, owners


#: How many times a ray will step past a hit on the facet's own prop before
#: giving up. Three is plenty — a ray leaving a guest's shoulder can clip her
#: own ear and then her own arm, and anything past that is inside her.
SELF_STEPS = 3


def measure(receivers, occluders, distance=REACH, samples=48, ignore_self=True):
    """Occlusion per face, for every receiver, against every occluder.

    Returns `{object: [ao, …]}` indexed by polygon.

    **`ignore_self` is the difference between a scene bake and a broken one.**
    The first run of this against the whole room came back with a mean
    occlusion of 0.57 on the guests and 0.54 on the props — nearly every facet
    in the room two steps dark — because at a 45 mm reach a 100 mm bear sees her
    own belly from her own arm, and a cabinet sees its own chamfer. That is not
    a measurement of the room, it is `lowpoly.bake_ao_facets` run at forty times
    its proper distance, and `models/README.md` already knows what it produces:
    *a part shaded uniformly is not shaded at all.*

    The two bakes are **two different measurements at two different scales**,
    and each should only see what it is for. The prop bake owns the crease, at
    2–6 mm, and it has already run — its results are in the `ShadeN` meshes this
    scene is built out of. This one owns what stands next to what, and it skips
    every hit on the facet's own prop rather than counting it twice.
    """
    bvh, owners = occluder_tree(occluders)
    dirs = lowpoly._cosine_hemisphere(samples)

    # **A much smaller lift than a prop bake wants.** `lowpoly` lifts the ray
    # start by 3% of the distance, which at a 4 mm reach is 0.12 mm and is
    # right. At a 45 mm reach it would be 1.35 mm — thicker than a dance tile,
    # so every ray would start *above* the tile it belongs to and the tile would
    # measure as unoccluded. The grazing cutoff is what keeps a facet from
    # hitting itself; the lift only has to clear floating point.
    lift = min(distance * 0.01, 1.5e-4)

    out = {}
    for ob in receivers:
        matrix = ob.matrix_world
        rotation = matrix.to_3x3()
        mine = owner(ob) if ignore_self else None
        values = []
        for poly in ob.data.polygons:
            centre = matrix @ poly.center
            normal = (rotation @ poly.normal).normalized()
            basis = lowpoly._basis(normal)
            origin = centre + normal * lift
            hit = 0
            for d in dirs:
                ray = basis @ mathutils.Vector(d)
                start, left = origin, distance
                for _ in range(SELF_STEPS):
                    where, _n, index, gap = bvh.ray_cast(start, ray, left)
                    if where is None:
                        break
                    if mine is None or owners[index] != mine:
                        hit += 1
                        break
                    # A hit on the facet's own prop: step past it and keep
                    # looking for something that is *not* this prop.
                    left -= gap + lift
                    if left <= 0:
                        break
                    start = where + ray * lift
            values.append(hit / float(len(dirs)))
        out[ob] = values
    return out


# ----------------------------------------------------------------- painting
def _base_colour(material):
    if material and material.use_nodes:
        bsdf = material.node_tree.nodes.get("Principled BSDF")
        if bsdf:
            return tuple(bsdf.inputs["Base Color"].default_value)[:3]
    return (0.8, 0.8, 0.8)


def _darkened(material, factor, suffix):
    name = "%s~%s" % (material.name, suffix)
    existing = bpy.data.materials.get(name)
    if existing:
        return existing
    made = material.copy()
    made.name = name
    r, g, b = _base_colour(material)
    value = (r * factor, g * factor, b * factor, 1.0)
    made.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = value
    made.diffuse_color = value
    return made


def paint(results, ladder=None, thresholds=(0.12, 0.30), strength=0.55,
          steps=10, min_faces=1):
    """Darken each face by how occluded it measured.

    Two modes, and the comparison between them is half the investigation:

    * **`ladder`** — the game's own. Two thresholds, `Palette.occlusionStep`
      per level, exactly what `lowpoly.bake_ao_facets` and `ModelLibrary`
      already do. Two extra materials per object, worst case.
    * **`steps`** — a finer ramp, `strength` × the measured occlusion quantised
      into that many rungs. It is what the ladder is an approximation *of*, and
      it is here to answer whether two rungs is enough.
    """
    painted = 0
    for ob, values in results.items():
        if not ob.data.materials:
            continue
        base = ob.data.materials[0]
        slots = {0: 0}
        ob.data.materials.clear()
        ob.data.materials.append(base)

        counts = {}
        levels = []
        for ao in values:
            if ladder:
                level = sum(1 for t in thresholds if ao >= t)
            else:
                level = int(round(min(1.0, ao) * strength * steps))
            levels.append(level)
            counts[level] = counts.get(level, 0) + 1

        # One facet a step darker than everything round it reads as a blemish,
        # not as occlusion — `lowpoly`'s rule, kept.
        for level in sorted(counts, reverse=True):
            if level > 0 and counts[level] < min_faces:
                levels = [l - 1 if l == level else l for l in levels]

        for poly, level in zip(ob.data.polygons, levels):
            if level <= 0:
                poly.material_index = 0
                continue
            if level not in slots:
                factor = (lowpoly.OCCLUSION_STEP ** level if ladder
                          else 1.0 - float(level) / steps)
                ob.data.materials.append(_darkened(base, factor, "ao%d" % level))
                slots[level] = len(ob.data.materials) - 1
            poly.material_index = slots[level]
            painted += 1
        ob.data.update()
    return painted


def strip():
    """Put every mesh back on its first material slot."""
    for ob in meshes():
        if len(ob.data.materials) > 1:
            base = ob.data.materials[0]
            ob.data.materials.clear()
            ob.data.materials.append(base)
        for poly in ob.data.polygons:
            poly.material_index = 0
        ob.data.update()
    for material in list(bpy.data.materials):
        if "~ao" in material.name and material.users == 0:
            bpy.data.materials.remove(material)


# ------------------------------------------------------------------ reporting
def report(results, groups=None, thresholds=(0.12, 0.30)):
    """What the bake found, per collection. Numbers, not adjectives."""
    where = {}
    for name, objects in (groups or {}).items():
        for ob in objects:
            where[ob.name] = name

    rows = {}
    for ob, values in results.items():
        key = where.get(ob.name, "?")
        row = rows.setdefault(key, [0, 0, 0, 0.0])
        row[0] += len(values)
        row[1] += sum(1 for v in values if v >= thresholds[0])
        row[2] += sum(1 for v in values if v >= thresholds[1])
        row[3] += sum(values)

    lines = ["%-10s %7s %8s %8s %7s" % ("group", "faces", "shade1", "shade2", "mean")]
    for key in sorted(rows):
        faces, one, two, total = rows[key]
        lines.append("%-10s %7d %8d %8d %7.3f"
                     % (key, faces, one - two, two, total / max(1, faces)))
    return "\n".join(lines)


# ------------------------------------------------------------- the upper bound
def pixel_ao(strength=0.55, distance=REACH, samples=16):
    """Multiply **real, per-pixel** occlusion into every material. Cycles only.

    This is not a shipping route — RealityKit has no ray-traced AO and nothing
    here survives an export. It is the *ceiling*: occlusion computed at every
    shaded point on the geometry the game already has, with no UVs, no
    subdivision and no quantising. Everything a bake can do is an approximation
    of this picture, so it is the thing to look at first and the thing every
    other render is compared against.

    Undo it with `plain()`.
    """
    for material in bpy.data.materials:
        if not material.use_nodes:
            continue
        tree = material.node_tree
        bsdf = tree.nodes.get("Principled BSDF")
        if bsdf is None or tree.nodes.get("FeestAO") is not None:
            continue
        socket = bsdf.inputs["Base Color"]
        colour = tuple(socket.default_value)

        occlusion = tree.nodes.new("ShaderNodeAmbientOcclusion")
        occlusion.name = occlusion.label = "FeestAO"
        occlusion.samples = samples
        occlusion.only_local = False
        occlusion.inputs["Distance"].default_value = distance
        occlusion.location = (bsdf.location.x - 620, bsdf.location.y - 260)

        # `1 - strength·(1 - ao)`: fully open stays exactly the palette colour,
        # fully enclosed comes down to `1 - strength` of it. Written this way
        # round so that turning `strength` to zero is provably a no-op.
        ramp = tree.nodes.new("ShaderNodeMapRange")
        ramp.name = "FeestAORamp"
        ramp.inputs["From Min"].default_value = 0.0
        ramp.inputs["From Max"].default_value = 1.0
        ramp.inputs["To Min"].default_value = 1.0 - strength
        ramp.inputs["To Max"].default_value = 1.0
        ramp.location = (bsdf.location.x - 420, bsdf.location.y - 260)

        tint = tree.nodes.new("ShaderNodeMixRGB")
        tint.name = "FeestAOMix"
        tint.blend_type = 'MULTIPLY'
        tint.inputs["Fac"].default_value = 1.0
        tint.inputs["Color1"].default_value = colour
        tint.location = (bsdf.location.x - 220, bsdf.location.y - 260)

        tree.links.new(occlusion.outputs["AO"], ramp.inputs["Value"])
        tree.links.new(ramp.outputs["Result"], tint.inputs["Color2"])
        tree.links.new(tint.outputs["Color"], socket)


def plain():
    """Take `pixel_ao` back out."""
    for material in bpy.data.materials:
        if not material.use_nodes:
            continue
        tree = material.node_tree
        dead = [tree.nodes[n] for n in ("FeestAO", "FeestAORamp", "FeestAOMix")
                if n in tree.nodes]
        if not dead:
            continue
        colour = tuple(tree.nodes["FeestAOMix"].inputs["Color1"].default_value)
        for node in dead:
            tree.nodes.remove(node)
        tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = colour


def measure_per_prop(objects, distance, samples=48):
    """Occlusion measured **prop by prop**, each against only itself.

    This is `lowpoly.bake_ao_facets`' own question — what does this prop shade
    on itself — asked at a distance an order of magnitude longer than any prop
    script passes it. `models/README.md` fixes the reach against the crease
    being shaded (2.2 mm on a berry, 5 mm on a tree), which finds the joins and
    nothing else. What the per-pixel render shows is that the reading occlusion
    on a 102 mm guest is not her joins at all: it is her belly under her chin,
    the gap between an arm and her side, and the shadow her body throws on her
    own feet. Those are 20–40 mm apart.

    It needs no scene and no room. Every prop in the game could have it
    tomorrow, through the `ShadeN` path that already ships.
    """
    by_prop = {}
    for ob in objects:
        by_prop.setdefault(owner(ob), []).append(ob)
    out = {}
    for parts in by_prop.values():
        out.update(measure(parts, parts, distance=distance, samples=samples,
                           ignore_self=False))
    return out


# ------------------------------------------------------- the texture route
def bake_texture(objects, size=1024, samples=64, distance=0.0):
    """UV-unwrap and bake **real** occlusion into one image per object.

    `app/LIGHTMAPS.md` describes this route and has never been run. It is the
    only one that can put occlusion on the **shell**: a 460 mm floor and a
    460 × 235 mm wall are one quad each, so a facet bake has exactly one tone
    available for the whole surface, and no amount of care with thresholds
    changes that. A texture has as many as it has texels.

    What it costs is what that file already warns about: UVs on the receiving
    mesh, a PNG in the bundle, and a re-bake whenever anything in the room
    moves. What is *new* since it was written is that the receiving mesh here is
    four boxes rather than a room full of props — box UVs are six planar
    rectangles, and `LightingRig.applyLightmap` is already wired to apply the
    result.

    `distance` of 0 means unlimited, which is what a room-corner gradient wants.
    """
    view_layer = bpy.context.view_layer
    scene = bpy.context.scene
    previous = scene.render.engine
    scene.render.engine = 'CYCLES'
    scene.cycles.bake_type = 'AO'
    scene.cycles.samples = samples
    scene.world.light_settings.distance = distance

    made = {}
    for ob in objects:
        bpy.ops.object.select_all(action='DESELECT')
        ob.select_set(True)
        view_layer.objects.active = ob

        # **One material per object, unconditionally.** The shell paints the
        # slab and the left wall the same cream, and a material can hold one
        # image node — so two objects sharing one would read back each other's
        # map. Copied every time rather than only when `users > 1`, because a
        # user count is a fact about the whole file and this is a fact about
        # this loop: the object baked before this one may have just taken the
        # count back down to 1 and left its own node behind.
        for slot in range(len(ob.data.materials)):
            if ob.data.materials[slot]:
                copy = ob.data.materials[slot].copy()
                copy.name = "%s@%s" % (ob.data.materials[slot].name, ob.name)
                for node in [n for n in copy.node_tree.nodes
                             if n.name.startswith("FeestAO")]:
                    copy.node_tree.nodes.remove(node)
                ob.data.materials[slot] = copy

        if not ob.data.uv_layers:
            bpy.ops.object.mode_set(mode='EDIT')
            bpy.ops.mesh.select_all(action='SELECT')
            bpy.ops.uv.smart_project(angle_limit=1.15, island_margin=0.02)
            bpy.ops.object.mode_set(mode='OBJECT')

        image = bpy.data.images.new("AO_" + ob.name, size, size, alpha=False,
                                    float_buffer=False)
        image.generated_color = (1, 1, 1, 1)
        for material in ob.data.materials:
            tree = material.node_tree
            node = tree.nodes.new("ShaderNodeTexImage")
            node.name = "FeestAOBake"
            node.image = image
            node.location = (-900, 400)
            tree.nodes.active = node
        bpy.ops.object.bake(type='AO', use_clear=True, margin=8)
        made[ob.name] = image

    scene.render.engine = previous
    return made


def apply_texture(objects, images, strength=0.65):
    """Multiply a baked map into the base colour, the way a shipped one would.

    `PhysicallyBasedMaterial.ambientOcclusion` in RealityKit multiplies the map
    into the surface's diffuse response, so multiplying into base colour here is
    the same picture by a different route — and it is the route EEVEE and Cycles
    both agree on, which keeps this comparable with every other render.
    """
    for ob in objects:
        image = images.get(ob.name)
        if image is None:
            continue
        for material in ob.data.materials:
            tree = material.node_tree
            bsdf = tree.nodes.get("Principled BSDF")
            node = tree.nodes.get("FeestAOBake")
            if bsdf is None or node is None:
                continue
            colour = tuple(bsdf.inputs["Base Color"].default_value)

            ramp = tree.nodes.new("ShaderNodeMapRange")
            ramp.name = "FeestAOTexRamp"
            ramp.inputs["To Min"].default_value = 1.0 - strength
            ramp.inputs["To Max"].default_value = 1.0
            ramp.location = (-620, 400)

            tint = tree.nodes.new("ShaderNodeMixRGB")
            tint.name = "FeestAOTexMix"
            tint.blend_type = 'MULTIPLY'
            tint.inputs["Fac"].default_value = 1.0
            tint.inputs["Color1"].default_value = colour
            tint.location = (-380, 400)

            tree.links.new(node.outputs["Color"], ramp.inputs["Value"])
            tree.links.new(ramp.outputs["Result"], tint.inputs["Color2"])
            tree.links.new(tint.outputs["Color"], bsdf.inputs["Base Color"])
