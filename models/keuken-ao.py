"""Ambient-occlusion measurements for De Keuken.

The ray casting, per-pixel ceiling, facet painting and texture bake are room
independent.  Het Feest paid for that implementation first in ``feest-ao.py``;
this module deliberately re-exports the same measured code instead of growing
a second AO algorithm that could quietly disagree with it.

``keuken-scene.py`` supplies the kitchen geometry and ownership hierarchy.  A
typical interactive session is:

    scene = load("keuken-scene", "keuken_scene")
    ao = load("keuken-ao", "keuken_ao")
    groups = scene.assemble()
    every = ao.meshes()
    truth = ao.measure(every, every, distance=ao.REACH)

The dynamic import is necessary because both source filenames contain a dash.
"""

import importlib.util
import os
import sys


def _load_shared():
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "feest-ao.py")
    spec = importlib.util.spec_from_file_location("room_ao_shared", path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


_shared = _load_shared()

# Keep one public surface for both room studies.  REACH is repeated as an alias
# so an interactive kitchen session reads without knowing which room established
# the implementation.
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
