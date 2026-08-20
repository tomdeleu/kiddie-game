"""Bake De Tuin's shipping lawn AO map.

The room-scale stills in ``app/ao-study-tuin/`` showed that per-pixel AO on
every material washes the pastel and barely moves ground contrast. The missing
app term is the mint quad under the statics, which a facet cannot shade.

    blender --background --python models/tuin-lightmaps.py

Assembles the shipping garden, hides movable props, bakes 45 mm Cycles AO
into one full-UV plane on the lawn, calibrates it to 0.40 strength, and
writes:

    app/NinaBakeryPOC/Resources/Lightmaps/TuinLawnAO.png

0.40 is below the kitchen's 0.55 so the open mint stays a colour. The can,
basket, flowers, pond and carried seeds do not cast into the map. The
pond's stones are smaller than the shadow they printed.
"""

import importlib.util
import os
import sys
import time

import bpy
import numpy as np


HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
OUTPUT = os.path.join(
    REPO, "app", "NinaBakeryPOC", "Resources", "Lightmaps")

SIZE = 512
SAMPLES = 256
REACH = 0.045
STRENGTH = 0.40

STATIC_OWNERS = (
    "Slab", "Ground", "SeedBed", "Bed", "PottingBench", "Fence",
    "Tree", "Bush", "Gate", "Molehill",
)


def load(stem, name):
    path = os.path.join(HERE, stem + ".py")
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def make_receiver(name, vertices):
    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata(vertices, [], [(0, 1, 2, 3)])
    mesh.update()

    uv = mesh.uv_layers.new(name="UVMap")
    coordinates = [(0, 0), (1, 0), (1, 1), (0, 1)]
    for loop in mesh.loops:
        uv.data[loop.index].uv = coordinates[loop.vertex_index]

    material = bpy.data.materials.new(name + "Material")
    material.use_nodes = True
    receiver = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(receiver)
    receiver.data.materials.append(material)
    return receiver, material


def bake(name, vertices, filename):
    receiver, material = make_receiver(name, vertices)
    image = bpy.data.images.new(
        name + "Image", SIZE, SIZE, alpha=False, float_buffer=False)
    image.generated_color = (1, 1, 1, 1)
    image.colorspace_settings.name = "Non-Color"

    node = material.node_tree.nodes.new("ShaderNodeTexImage")
    node.image = image
    material.node_tree.nodes.active = node

    bpy.ops.object.select_all(action="DESELECT")
    receiver.hide_render = False
    receiver.select_set(True)
    bpy.context.view_layer.objects.active = receiver

    started = time.time()
    bpy.ops.object.bake(type="AO", use_clear=True, margin=8)

    values = np.empty(len(image.pixels), dtype=np.float32)
    image.pixels.foreach_get(values)
    values = values.reshape((-1, 4))
    values[:, :3] = 1.0 - STRENGTH * (1.0 - values[:, :3])
    values[:, 3] = 1.0
    image.pixels.foreach_set(values.ravel())
    image.update()

    path = os.path.join(OUTPUT, filename)
    image.filepath_raw = path
    image.file_format = "PNG"
    image.save()
    bpy.data.objects.remove(receiver, do_unlink=True)
    print("  %-24s %5.2f s  %s" % (name, time.time() - started, path))


def main():
    os.makedirs(OUTPUT, exist_ok=True)
    scene_module = load("tuin-scene", "tuin_scene")
    ao = load("tuin-ao", "tuin_ao")
    scene_module.assemble()

    old_hidden = {}
    for ob in bpy.data.objects:
        if ob.type != "MESH":
            continue
        old_hidden[ob] = ob.hide_render
        ob.hide_render = not ao.owner(ob).startswith(STATIC_OWNERS)

    scene = bpy.context.scene
    old_engine = scene.render.engine
    scene.render.engine = "CYCLES"
    scene.cycles.samples = SAMPLES
    scene.cycles.bake_type = "AO"
    scene.world.light_settings.distance = REACH

    half = scene_module.HALF
    floor = scene_module.FLOOR_Y + 0.0002
    bake(
        "TuinLawnAOReceiver",
        [(-half, -half, floor), (half, -half, floor),
         (half, half, floor), (-half, half, floor)],
        "TuinLawnAO.png")

    for ob, hidden in old_hidden.items():
        if ob.name in bpy.data.objects:
            ob.hide_render = hidden
    scene.render.engine = old_engine
    bpy.context.view_layer.update()


if __name__ == "__main__":
    main()
