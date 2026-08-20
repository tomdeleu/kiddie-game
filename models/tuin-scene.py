"""**De Tuin, assembled** — the shipping garden in one Blender scene.

Every ordinary model script in this folder builds one prop at the origin.
This one builds the room described by ``GardenLayout``, ``GardenRoomBuilder``
and ``GardenProps`` at their runtime coordinates. It exports nothing. It
exists so room-scale lighting questions can be measured against geometry
rather than inferred from one screenshot.

The still is a mid-round visit: the bed is sown, the can and basket sit on
the lawn, the jars stand on the bench. Transient water, sparkles, the halo
and the dynamic contact discs are absent.

    blender --background --python models/tuin-scene.py
"""

import importlib.util
import math
import os
import sys

import bmesh
import bpy
import mathutils

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import garden
import feest
import lowpoly


# ------------------------------------------------------------------- frames
def g(x, y, z):
    """The game's (x, y, z) in Blender's axes."""
    return (x, -z, y)


def gdir(x, y, z):
    return mathutils.Vector((x, -z, y))


# ------------------------------------------------------- RoomBox / camera
ROOM = 0.46
HALF = ROOM / 2
SLAB_T = 0.014
FLOOR_Y = 0.004

EYE = (0.636, 0.611, 0.636)
TARGET = (0.0, 0.06, 0.0)
FOV_V = 26.0
EXPOSURE = 0.15

# ------------------------------------------------------- GardenLayout
BED_CENTRE = (0.030, -0.075)
BED_SIZE = (0.250, 0.080)
BED_RIM_Y = 0.050
BED_SOIL_Y = 0.040
BED_RIM = 0.012
BED_POST = 0.016
PLOT_COUNT = 5
PLOT_RADIUS = 0.015

BENCH_CENTRE = (-0.178, -0.030)
BENCH_TOP = (0.048, 0.230)
BENCH_TOP_Y = 0.072
BENCH_BOARD = 0.008
BENCH_BACKBOARD = 0.018
BENCH_LEG = 0.012
BENCH_SHELF_Y = 0.030
BENCH_SHELF = (0.062, 0.230)
BENCH_SHELF_X = BENCH_CENTRE[0] + 0.014
JAR_SPACING = 0.054

CAN_HOME = (-0.090, FLOOR_Y, 0.150)
BASKET_HOME = (0.090, FLOOR_Y, 0.008)
MOLEHILL = (-0.085, FLOOR_Y, 0.050)
TREE_SPOT = (-0.115, FLOOR_Y, -0.172)
BUSH_SPOTS = [(-0.020, FLOOR_Y, -0.192), (0.170, FLOOR_Y, -0.185)]
POND_CENTRE = (0.180, 0.180)
GATE_CENTRE = (-0.212, FLOOR_Y, 0.160)
GATE_OPENING = 0.080
FLOWER_X = 0.185
FLOWER_FIRST_Z = -0.150
FLOWER_SPACING = 0.046

JAR_COLOURS = [
    garden.ROSE, 0x9BB2D2, garden.BUTTER_YELLOW, garden.SAGE_DEEP,
    garden.CREAM_LIGHT, garden.MINT_LIGHT, garden.LILAC, garden.CREAM_LIGHT,
]


def plot_spot(index):
    usable = BED_SIZE[0] - 2 * BED_RIM - BED_POST
    spacing = usable / float(PLOT_COUNT)
    first = BED_CENTRE[0] - usable / 2 + spacing / 2
    return (first + spacing * index, BED_SOIL_Y, BED_CENTRE[1])


def jar_spot(index):
    lower = index >= 4
    along = float(index % 4) - 1.5
    stagger = JAR_SPACING / 2 if lower else 0.0
    x = (BENCH_CENTRE[0] + BENCH_TOP[0] / 2 + 0.008) if lower else BENCH_CENTRE[0]
    y = (BENCH_SHELF_Y if lower else BENCH_TOP_Y) + BENCH_BOARD
    z = BENCH_CENTRE[1] + JAR_SPACING * along + stagger
    return (x, y, z)


# --------------------------------------------------------------- scaffolding
def collection(name):
    c = bpy.data.collections.get(name)
    if c is None:
        c = bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(c)
    return c


def move_to(objects, target):
    for ob in objects:
        for c in list(ob.users_collection):
            c.objects.unlink(ob)
        target.objects.link(ob)


def load_prop(stem):
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), stem + ".py")
    spec = importlib.util.spec_from_file_location(
        stem.replace("-", "_") + "_tuin", path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def game_box(name, material, size, centre=(0.0, 0.0, 0.0)):
    sx, sy, sz = size
    cx, cy, cz = centre
    bm = bmesh.new()
    lowpoly.add_box(
        bm,
        (cx - sx / 2, cx + sx / 2),
        (-cz - sz / 2, -cz + sz / 2),
        (cy - sy / 2, cy + sy / 2),
    )
    bm.normal_update()
    return lowpoly.flat_obj(name, bm, material)


def parent_local(parts, name, at=(0.0, 0.0, 0.0), turn=0.0):
    root = bpy.data.objects.new(name, None)
    root.empty_display_size = 0.02
    bpy.context.collection.objects.link(root)
    root.location = g(*at)
    root.rotation_euler = (0.0, 0.0, turn)
    for ob in parts:
        ob.parent = root
    return [root] + parts


def instance_asset(source, name, at, turn=0.0, scale=1.0):
    source_root = next((ob for ob in source if ob.type != "MESH"), None)
    root = bpy.data.objects.new(name, None)
    root.empty_display_size = 0.02
    bpy.context.collection.objects.link(root)

    matrix = mathutils.Matrix.Translation(g(*at))
    matrix @= mathutils.Matrix.Rotation(turn, 4, "Z")
    matrix @= mathutils.Matrix.Diagonal((scale, scale, scale, 1.0))
    if source_root is not None:
        matrix @= source_root.matrix_local
    root.matrix_world = matrix

    made = [root]
    for part in source:
        if part.type != "MESH":
            continue
        copy = part.copy()
        bpy.context.collection.objects.link(copy)
        copy.parent = root
        copy.matrix_local = part.matrix_local.copy()
        made.append(copy)
    return made


# ---------------------------------------------------------------- the shell
def build_shell():
    cream = garden.material("TuinSlab", garden.CREAM)
    mint = garden.material("TuinLawn", garden.MINT_LIGHT)
    return [
        feest.boxes("Slab", cream, [((-HALF - 0.015, HALF + 0.015),
                                     (-HALF - 0.015, HALF + 0.015),
                                     (-SLAB_T, 0.0))]),
        feest.boxes("Ground", mint, [((-HALF, HALF), (-HALF, HALF),
                                      (0.0, FLOOR_Y))]),
    ]


# --------------------------------------------------------------- furniture
def build_bench():
    wood = garden.material("BenchWood", garden.SANDY_WOOD)
    cream = garden.material("BenchCream", garden.CREAM)
    shelf_dx = BENCH_SHELF_X - BENCH_CENTRE[0]
    parts = [
        game_box("BenchTop", wood, (BENCH_TOP[0], BENCH_BOARD, BENCH_TOP[1]),
                 (0.0, BENCH_TOP_Y + BENCH_BOARD / 2, 0.0)),
        game_box("BenchBackboard", cream,
                 (0.006, BENCH_BACKBOARD, BENCH_TOP[1]),
                 (-BENCH_TOP[0] / 2 + 0.003,
                  BENCH_TOP_Y + BENCH_BOARD + BENCH_BACKBOARD / 2, 0.0)),
        game_box("BenchShelf", wood, (BENCH_SHELF[0], BENCH_BOARD, BENCH_SHELF[1]),
                 (shelf_dx, BENCH_SHELF_Y + BENCH_BOARD / 2, 0.0)),
    ]
    for i, (dx, dz) in enumerate(((-1, -1), (-1, 1), (1, -1), (1, 1))):
        parts.append(game_box(
            "BenchLeg%d" % i, cream,
            (BENCH_LEG, BENCH_TOP_Y - FLOOR_Y, BENCH_LEG),
            (shelf_dx + dx * (BENCH_SHELF[0] - BENCH_LEG) / 2,
             FLOOR_Y + (BENCH_TOP_Y - FLOOR_Y) / 2,
             dz * (BENCH_SHELF[1] - BENCH_LEG) / 2)))
    return parent_local(parts, "PottingBench",
                        (BENCH_CENTRE[0], 0.0, BENCH_CENTRE[1]))


def build_bushes():
    sage = garden.material("BushSage", garden.SAGE)
    deep = garden.material("BushSageDeep", garden.SAGE_DEEP)
    made = []
    radii = (0.026, 0.021)
    lobes = [
        ((0.0, 0.85, 0.0), 1.00),
        ((0.72, 0.55, 0.20), 0.70),
        ((-0.62, 0.50, -0.34), 0.66),
        ((0.10, 0.48, -0.74), 0.62),
    ]
    for i, (spot, radius) in enumerate(zip(BUSH_SPOTS, radii)):
        parts = []
        for j, (offset, scale) in enumerate(lobes):
            colour = sage if j % 2 == 0 else deep
            parts.append(feest.blob(
                "Bush%dLobe%d" % (i, j), colour, radius * scale, 1,
                at=g(offset[0] * radius, offset[1] * radius, offset[2] * radius)))
        made += parent_local(parts, "Bush%d" % i, spot)
    return made


def build_pond():
    pale = garden.material("PondPale", 0xE0E8F4)
    mid = garden.material("PondMid", garden.BERRY_BLUE if hasattr(garden, "BERRY_BLUE")
                          else 0xC2D2E8)
    deep = garden.material("PondDeep", 0x9BB2D2)
    stone = garden.material("PondStone", garden.CREAM_LIGHT)
    parts = [
        feest.blob("PondBand0", pale, 0.110, 1, scale=(1.35, 0.85, 0.04),
                   at=g(0.0, 0.007, 0.0)),
        feest.blob("PondBand1", mid, 0.078, 1, scale=(1.35, 0.85, 0.03),
                   at=g(0.0, 0.006, 0.0)),
        feest.blob("PondBand2", deep, 0.048, 1, scale=(1.35, 0.85, 0.02),
                   at=g(0.0, 0.005, 0.0)),
    ]
    for i, angle in enumerate((0.4, 0.9, 1.4, 1.9, 2.4, 3.4, 3.9, 4.4)):
        x = math.cos(angle) * 0.092
        z = math.sin(angle) * 0.062
        if x + POND_CENTRE[0] > 0.20 or z + POND_CENTRE[1] > 0.20:
            continue
        parts.append(feest.blob(
            "PondStone%d" % i, stone, 0.011, 0,
            at=g(x, 0.006, z)))
    return parent_local(parts, "Pond", (POND_CENTRE[0], 0.0, POND_CENTRE[1]))


def build_can():
    mint = garden.material("CanMint", garden.MINT)
    light = garden.material("CanMintLight", garden.MINT_LIGHT)
    parts = [
        garden.prism("CanBody", mint, 0.019, 0.030, 8, at=g(0.0, 0.015, 0.0)),
        game_box("CanSpout", mint, (0.0330, 0.0072, 0.0072), (0.0300, 0.0135, 0.0)),
        game_box("CanGrip", light, (0.0044, 0.0165, 0.0044), (-0.0250, 0.0175, 0.0)),
    ]
    return parent_local(parts, "WateringCan", CAN_HOME)


def build_jars():
    lid = garden.material("JarLid", garden.CREAM_LIGHT)
    made = []
    for i, colour in enumerate(JAR_COLOURS):
        body = garden.material("JarBody%d" % i, colour)
        parts = [
            garden.prism("JarBody%d" % i, body, 0.0085, 0.018, 8,
                         at=g(0.0, 0.009, 0.0)),
            garden.prism("JarLid%d" % i, lid, 0.010, 0.005, 8,
                         at=g(0.0, 0.0205, 0.0)),
        ]
        made += parent_local(parts, "SeedJar%d" % i, jar_spot(i))
    return made


def build_flowers():
    stem = garden.material("FlowerStem", garden.SAGE)
    petal = garden.material("FlowerPetal", garden.BLUSH_PINK)
    centre = garden.material("FlowerCentre", garden.BUTTER_YELLOW)
    made = []
    for i in range(5):
        z = FLOWER_FIRST_Z + FLOWER_SPACING * i
        height = 0.018 + i * 0.004
        parts = [
            garden.prism("FlowerStem%d" % i, stem, 0.0022, height, 6,
                         at=g(0.0, height / 2, 0.0)),
            feest.blob("FlowerHead%d" % i, petal, 0.007, 0,
                       at=g(0.0, height + 0.004, 0.0)),
            feest.blob("FlowerEye%d" % i, centre, 0.003, 0,
                       at=g(0.0, height + 0.006, 0.0)),
        ]
        made += parent_local(parts, "Flower%d" % i, (FLOWER_X, FLOOR_Y, z))
    return made


def build_gate():
    cream = garden.material("GateCream", garden.CREAM)
    light = garden.material("GateCreamLight", garden.CREAM_LIGHT)
    parts = [
        game_box("GateLeaf", cream, (0.013, 0.070, 0.072),
                 (0.0, 0.039, 0.0)),
        game_box("GateBrace", light, (0.008, 0.008, 0.070),
                 (0.0, 0.038, 0.0)),
    ]
    return parent_local(parts, "Gate", GATE_CENTRE)


def build_sprouts():
    soil = garden.material("SproutSoil", garden.WOOD_BROWN)
    leaf = garden.material("SproutLeaf", garden.SAGE)
    made = []
    for i in (1, 3):
        spot = plot_spot(i)
        parts = [
            feest.blob("SproutMound%d" % i, soil, 0.010, 0,
                       at=g(0.0, 0.004, 0.0)),
            garden.prism("SproutStem%d" % i, leaf, 0.0016, 0.016, 5,
                         at=g(0.0, 0.012, 0.0)),
            feest.blob("SproutLeaf%d" % i, leaf, 0.006, 0,
                       at=g(0.006, 0.018, 0.0)),
        ]
        made += parent_local(parts, "Sprout%d" % i, spot)
    return made


# ------------------------------------------------------------ camera / light
def build_camera():
    data = bpy.data.cameras.get("TuinCam") or bpy.data.cameras.new("TuinCam")
    data.sensor_fit = "VERTICAL"
    data.angle_y = math.radians(FOV_V)
    data.clip_start = 0.01
    data.clip_end = 20.0
    cam = bpy.data.objects.new("TuinCamera", data)
    bpy.context.collection.objects.link(cam)
    eye, target = mathutils.Vector(g(*EYE)), mathutils.Vector(g(*TARGET))
    cam.location = eye
    cam.rotation_euler = (target - eye).to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = cam
    return cam


def direction(elevation, azimuth):
    e, a = math.radians(elevation), math.radians(azimuth)
    return gdir(-math.cos(e) * math.sin(a), -math.sin(e),
                -math.cos(e) * math.cos(a)).normalized()


def blackbody(kelvin):
    t = max(1000.0, min(12000.0, float(kelvin))) / 100.0
    if t <= 66:
        r = 255.0
        gg = 99.4708025861 * math.log(max(t, 1.0)) - 161.1195681661
    else:
        r = 329.698727446 * (t - 60) ** -0.1332047592
        gg = 288.1221695283 * (t - 60) ** -0.0755148492
    if t >= 66:
        b = 255.0
    elif t <= 19:
        b = 0.0
    else:
        b = 138.5177312231 * math.log(t - 10) - 305.0447927307
    return [lowpoly.srgb_to_linear(max(0.0, min(255.0, c)) / 255.0)
            for c in (r, gg, b)]


LUX = 1 / 1000.0


def build_lights():
    spec = [("KeyLight", 1400.0, 62.0, 135.0, 6200, True),
            ("FillLight", 700.0, 18.0, 300.0, 7800, False),
            ("AmbientDome0", 800.0 / 3.0, 55.0, 30.0, 6500, False),
            ("AmbientDome1", 800.0 / 3.0, 55.0, 150.0, 6500, False),
            ("AmbientDome2", 800.0 / 3.0, 55.0, 270.0, 6500, False)]
    made = []
    for name, lux, elevation, azimuth, kelvin, casts in spec:
        data = bpy.data.lights.new(name, "SUN")
        data.energy = lux * LUX
        data.angle = math.radians(3.0)
        data.use_shadow = casts
        data.color = blackbody(kelvin)
        ob = bpy.data.objects.new(name, data)
        bpy.context.collection.objects.link(ob)
        d = direction(elevation, azimuth)
        ob.location = -d * 2.0
        ob.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        made.append(ob)
    return made


# The lawn and slab never cast. The fence does — GardenRoomBuilder is explicit.
SHADOWLESS = ("Slab", "Ground")


def apply_shadow_rules():
    hidden = 0
    for ob in bpy.data.objects:
        if ob.type != "MESH":
            continue
        node = ob
        while node.parent is not None:
            node = node.parent
        if node.name.startswith(SHADOWLESS):
            ob.visible_shadow = False
            hidden += 1
    return hidden


def wipe():
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob, do_unlink=True)
    for c in list(bpy.data.collections):
        bpy.data.collections.remove(c)
    for material in list(bpy.data.materials):
        bpy.data.materials.remove(material, do_unlink=True)
    for image in list(bpy.data.images):
        if image.name.startswith("AO_"):
            bpy.data.images.remove(image, do_unlink=True)
    bpy.context.view_layer.active_layer_collection = (
        bpy.context.view_layer.layer_collection)
    bpy.context.view_layer.update()


def prepare_assets():
    assets = {}
    for stem in ["garden-bed", "garden-fence", "garden-tree",
                 "harvest-basket", "molehill"]:
        assets[stem] = load_prop(stem).build()
    return assets


def discard_assets(assets):
    for source in assets.values():
        for ob in source:
            if ob.name in bpy.data.objects:
                bpy.data.objects.remove(ob, do_unlink=True)
    for ob in bpy.data.objects:
        if ob.parent is None and ob.name.endswith(".001"):
            base = ob.name[:-4]
            if bpy.data.objects.get(base) is None:
                ob.name = base


def assemble():
    wipe()
    assets = prepare_assets()
    groups = {}

    def into(name, builder):
        target = collection(name)
        before = set(bpy.data.objects)
        made = builder()
        made = [ob for ob in bpy.data.objects if ob not in before] or made
        move_to(made, target)
        groups[name] = made
        print("  %-12s %3d objects" % (name, len(made)))

    into("Schil", build_shell)
    into("Bed", lambda: instance_asset(assets["garden-bed"], "SeedBed",
                                       (BED_CENTRE[0], 0.0, BED_CENTRE[1])))
    into("Bank", build_bench)
    into("Hek", lambda: instance_asset(assets["garden-fence"], "Fence",
                                       (0.0, 0.0, 0.0)))
    into("Groen", lambda: instance_asset(assets["garden-tree"], "Tree", TREE_SPOT)
         + build_bushes())
    into("Vijver", build_pond)
    into("Props", lambda: (
        build_can()
        + instance_asset(assets["harvest-basket"], "Basket", BASKET_HOME)
        + instance_asset(assets["molehill"], "Molehill", MOLEHILL)
        + build_jars() + build_flowers() + build_gate() + build_sprouts()
    ))
    into("Camera", lambda: [build_camera()])
    into("Licht", build_lights)
    discard_assets(assets)

    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.render.resolution_x = 1400
    scene.render.resolution_y = 1050
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "Medium High Contrast"
    # Calibrated so open lawn luminance matches roombox.png. The kitchen
    # study's 0.5 blew this open garden to white and hid the AO gap.
    scene.view_settings.exposure = EXPOSURE
    scene.unit_settings.system = "METRIC"
    scene.cycles.samples = 64

    world = bpy.data.worlds.get("Tuin") or bpy.data.worlds.new("Tuin")
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    # Strength 0 so the world does not light the garden. The still is
    # composited over plate grey in `tuin-measure.render_still`.
    bg.inputs[0].default_value = (0.72, 0.72, 0.72, 1.0)
    bg.inputs[1].default_value = 0.0
    scene.world = world

    hidden = apply_shadow_rules()
    bpy.context.view_layer.update()
    total = sum(len(ob.data.polygons) for ob in bpy.data.objects
                if ob.type == "MESH")
    print("  %-12s %3d meshes out of the shadow map" % ("shadows", hidden))
    print("De Tuin: %d objects, %d faces" % (len(bpy.data.objects), total))
    return groups


def render_still(path, samples=64):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = samples
    scene.render.filepath = path
    scene.render.image_settings.file_format = "PNG"
    bpy.ops.render.render(write_still=True)
    print("wrote %s" % path)
    return path


if __name__ == "__main__":
    assemble()
