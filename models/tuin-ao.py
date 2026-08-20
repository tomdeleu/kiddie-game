"""Ambient-occlusion measurements for De Tuin.

Same shared rays as Het Feest and De Keuken. ``tuin-scene.py`` supplies the
garden geometry; this file does not grow a third AO algorithm.

    scene = load("tuin-scene", "tuin_scene")
    ao = load("tuin-ao", "tuin_ao")
    groups = scene.assemble()
    every = ao.meshes()
    truth = ao.measure(every, every, distance=ao.REACH)
"""

import importlib.util
import os


def _load_shared():
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "feest-ao.py")
    spec = importlib.util.spec_from_file_location("room_ao_shared", path)
    module = importlib.util.module_from_spec(spec)
    sys_name = spec.name
    import sys
    sys.modules[sys_name] = module
    spec.loader.exec_module(module)
    return module


_shared = _load_shared()

REACH = _shared.REACH
meshes = _shared.meshes
owner = _shared.owner
occluder_tree = _shared.occluder_tree
measure = _shared.measure
paint = _shared.paint
strip = _shared.strip
report = _shared.report
pixel_ao = _shared.pixel_ao
plain = _shared.plain
measure_per_prop = _shared.measure_per_prop
bake_texture = _shared.bake_texture
apply_texture = _shared.apply_texture
