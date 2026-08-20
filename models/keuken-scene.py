"""**De Keuken, assembled** — the shipping kitchen in one Blender scene.

Every ordinary model script in this folder builds one prop at the origin.  This
one builds the room described by ``RoomBox``, ``KitchenLayout``, ``RoomBuilder``,
``KitchenProps`` and ``BakerCharacter`` at their runtime coordinates.  It
exports nothing; it exists so room-scale questions can be measured against
geometry rather than inferred from one screenshot.

The still is a valid visit-mode state: three completed cakes remain on the
plank while a fresh round has put five ingredients and the dough back in the
room.  That is the most populated ordinary kitchen state and therefore the
useful upper bound for occlusion and draw calls.  Transient water, batter,
sparkles, flour prints and halo geometry are deliberately absent.

Where a prop is modelled, this imports its shipping ``build()`` result — baked
``ShadeN`` pieces included.  Everything still procedural in Swift is rebuilt
from the same dimensions and facet counts.  Blender is Z-up and the exporter
maps ``(x, y, z) -> (x, z, -y)``, so the game's frame maps back through ``g``.

    blender --background --python models/keuken-scene.py
"""

import importlib.util
import math
import os
import sys

import bmesh
import bpy
import mathutils

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lowpoly
import garden
import feest


# ------------------------------------------------------------------- frames
def g(x, y, z):
    """The game's (x, y, z) in Blender's axes."""
    return (x, -z, y)


def gdir(x, y, z):
    return mathutils.Vector((x, -z, y))


# ------------------------------------------------------- RoomBox / camera
ROOM = 0.46
HALF = ROOM / 2
WALL_H = 0.235
WALL_T = 0.012
SLAB_T = 0.014
FLOOR_Y = 0.004

EYE = (0.636, 0.611, 0.636)
TARGET = (0.0, 0.06, 0.0)
FOV_V = 26.0


# ------------------------------------------------------- KitchenLayout
TABLE_Y = 0.072
TABLE_CENTRE = (-0.058, 0.052)
TABLE_SIZE = (0.280, 0.140)
TABLE_T = 0.012

COUNTER_Y = 0.058
COUNTER_CENTRE = (-0.092, -0.182)
COUNTER_SIZE = (0.230, 0.062)

OVEN_ORIGIN = (0.152, FLOOR_Y, -0.122)
OVEN_R = 0.062
OVEN_H = 0.075
MOUTH_INNER = 0.024
MOUTH_LEG = 0.012
MOUTH_DEPTH = 0.044
MOUTH_BACK = 0.042
MOUTH_FRONT = MOUTH_BACK + MOUTH_DEPTH

BASKET_HOME = (-0.170, TABLE_Y, 0.096)
BOWL_HOME = (-0.032, TABLE_Y, 0.062)
SPOON_HOME = (-0.092, TABLE_Y + 0.006, 0.026)
TIN_HOME = (0.052, TABLE_Y, 0.090)
PIN_HOME = (-0.148, TABLE_Y + 0.008, 0.008)
DOUGH_SPOT = (-0.150, TABLE_Y, 0.052)
BAKER_SPOT = (-0.145, FLOOR_Y, -0.072)

SHELF_DEPTH = 0.036
SHELF_X = -HALF + WALL_T + SHELF_DEPTH / 2

SINK_SPOT = (-0.174, COUNTER_Y, -0.182)
SCALE_SPOT = (-0.104, COUNTER_Y, -0.176)
FLOUR_SPOT = (-0.062, FLOOR_Y, 0.178)
CRATE_SPOT = (0.150, FLOOR_Y, 0.126)

PLANK_Y = 0.135
PLANK_CENTRE = (-0.095, -0.196)
PLANK_LENGTH = 0.190

PORTRAIT_CENTRE = (0.152, 0.175, -HALF + WALL_T)
DOOR_CENTRE = (-0.216, FLOOR_Y, 0.172)
DOOR_OPEN = (0.074, 0.140)
DOOR_JAMB = 0.010
DOOR_DEPTH = 0.016
DOOR_LEAF_T = 0.007
DOOR_AJAR = -0.20

SOURCES = [
    (SHELF_X, 0.154, 0.044),          # upper shelf
    (SHELF_X, 0.109, -0.104),         # lower shelf
    (-0.034, COUNTER_Y + 0.011, -0.174),
    (-0.170, TABLE_Y + 0.012, 0.096),
    (CRATE_SPOT[0], FLOOR_Y + 0.017, CRATE_SPOT[2]),
]


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
    spec = importlib.util.spec_from_file_location(stem.replace("-", "_") + "_kitchen", path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def game_box(name, material, size, centre=(0.0, 0.0, 0.0)):
    """One box specified in the game's local frame."""
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


def game_boxes(name, material, specs):
    bm = bmesh.new()
    for size, centre in specs:
        sx, sy, sz = size
        cx, cy, cz = centre
        lowpoly.add_box(
            bm,
            (cx - sx / 2, cx + sx / 2),
            (-cz - sz / 2, -cz + sz / 2),
            (cy - sy / 2, cy + sy / 2),
        )
    bm.normal_update()
    return lowpoly.flat_obj(name, bm, material)


def game_prism(name, material, radius, height, sides, at=(0.0, 0.0, 0.0)):
    return garden.prism(name, material, radius, height, sides, at=g(*at))


def game_lathe(name, material, profile, sides, at=(0.0, 0.0, 0.0)):
    return garden.lathe(name, material, profile, sides, at=g(*at))


def game_blob(name, material, radius, subdivisions=1,
              scale=(1.0, 1.0, 1.0), at=(0.0, 0.0, 0.0)):
    # `feest.blob` scales Blender XYZ; game Y and Z trade places.
    return feest.blob(name, material, radius, subdivisions,
                      scale=(scale[0], scale[2], scale[1]), at=g(*at))


def game_bowl(name, material, bottom, top, height, wall, floor, sides, rings):
    outer, inner = [], []
    for i in range(rings + 1):
        t = i / rings
        radius = bottom + (top - bottom) * math.sin(t * math.pi / 2)
        outer.append((radius, t * height))
        inner.append((max(0.0002, radius - wall),
                      floor + t * (height - floor)))
    # One closed revolution: outside up, rim across, inside down.
    return lowpoly.flat_obj(name, lowpoly.tube(outer + list(reversed(inner)), sides),
                            material)


def parent_local(parts, name, at=(0.0, 0.0, 0.0), turn=0.0):
    root = bpy.data.objects.new(name, None)
    root.empty_display_size = 0.02
    bpy.context.collection.objects.link(root)
    root.location = g(*at)
    root.rotation_euler = (0.0, 0.0, turn)
    for ob in parts:
        ob.parent = root
    return [root] + parts


def instance_asset(source, name, at, turn=0.0, tip_x=0.0, scale=1.0):
    """Copy a shipping prop, preserving the source root's authored transform."""
    source_root = next((ob for ob in source if ob.type != 'MESH'), None)
    root = bpy.data.objects.new(name, None)
    root.empty_display_size = 0.02
    bpy.context.collection.objects.link(root)

    matrix = mathutils.Matrix.Translation(g(*at))
    matrix @= mathutils.Matrix.Rotation(turn, 4, 'Z')
    matrix @= mathutils.Matrix.Rotation(tip_x, 4, 'X')
    matrix @= mathutils.Matrix.Diagonal((scale, scale, scale, 1.0))
    if source_root is not None:
        matrix @= source_root.matrix_local
    root.matrix_world = matrix

    made = [root]
    for part in source:
        if part.type != 'MESH':
            continue
        copy = part.copy()
        bpy.context.collection.objects.link(copy)
        copy.parent = root
        copy.matrix_local = part.matrix_local.copy()
        made.append(copy)
    return made


# ---------------------------------------------------------------- the shell
SUBDIV = 0


def _grid(name, material, spans, faces=None, subdiv=0):
    bm = bmesh.new()
    for span in spans:
        lowpoly.add_box(bm, *span)
    bm.normal_update()
    if subdiv > 1 and faces:
        chosen = [f for f in bm.faces
                  if any(f.normal.dot(mathutils.Vector(d)) > 0.99 for d in faces)]
        edges = list({e for f in chosen for e in f.edges})
        bmesh.ops.subdivide_edges(bm, edges=edges, cuts=subdiv - 1,
                                  use_grid_fill=True)
    bm.normal_update()
    return lowpoly.flat_obj(name, bm, material)


def build_shell(subdiv=None):
    subdiv = SUBDIV if subdiv is None else subdiv
    cream = feest.material("SchilCream", feest.CREAM)
    light = feest.material("SchilCreamLight", feest.CREAM_LIGHT)
    blush = feest.material("SchilBlush", feest.BLUSH_PINK)
    return [
        feest.boxes("Slab", cream, [((-HALF - 0.015, HALF + 0.015),
                                     (-HALF - 0.015, HALF + 0.015),
                                     (-SLAB_T, 0.0))]),
        _grid("Floor", blush, [((-HALF, HALF), (-HALF, HALF), (0.0, FLOOR_Y))],
              faces=[(0, 0, 1)], subdiv=subdiv),
        _grid("WallBack", light,
              [((-HALF, HALF), (HALF - WALL_T, HALF), (0.0, WALL_H))],
              faces=[(0, -1, 0)], subdiv=subdiv),
        _grid("WallLeft", cream,
              [((-HALF, -HALF + WALL_T), (-HALF, HALF), (0.0, WALL_H))],
              faces=[(1, 0, 0)], subdiv=subdiv),
    ]


# --------------------------------------------------------------- furniture
def build_furniture():
    wood = feest.material("MeubelHout", feest.SANDY_WOOD)
    cream = feest.material("MeubelCream", feest.CREAM_LIGHT)
    rose = feest.material("MeubelRose", feest.ROSE)
    deep = feest.material("MeubelRoseDeep", feest.BLUSH_PINK_DEEP)
    made = []

    # Table.
    top_cy = TABLE_Y - TABLE_T / 2
    parts = [game_box("TableTop", wood, (TABLE_SIZE[0], TABLE_T, TABLE_SIZE[1]),
                      (0.0, top_cy, 0.0))]
    leg_h = top_cy - TABLE_T / 2
    dx, dz = TABLE_SIZE[0] / 2 - 0.014, TABLE_SIZE[1] / 2 - 0.014
    for i, (x, z) in enumerate([(-dx, -dz), (dx, -dz), (-dx, dz), (dx, dz)]):
        parts.append(game_box("TableLeg%d" % i, wood, (0.012, leg_h, 0.012),
                              (x, leg_h / 2, z)))
    made += parent_local(parts, "Table",
                         (TABLE_CENTRE[0], 0.0, TABLE_CENTRE[1]))

    # Counter.
    body_h = COUNTER_Y - FLOOR_Y - 0.008
    parts = [
        game_box("CounterBody", cream,
                 (COUNTER_SIZE[0] - 0.012, body_h, COUNTER_SIZE[1] - 0.010),
                 (0.0, FLOOR_Y + body_h / 2, 0.0)),
        game_box("CounterTop", wood, (COUNTER_SIZE[0], 0.008, COUNTER_SIZE[1]),
                 (0.0, COUNTER_Y - 0.004, 0.0)),
    ]
    made += parent_local(parts, "Counter",
                         (COUNTER_CENTRE[0], 0.0, COUNTER_CENTRE[1]))

    # Two wall shelves, including the six jars that ship with them.
    for height, mirrored in [(0.150, False), (0.105, True)]:
        centre_z = -0.030
        parts = [game_box("ShelfPlank", wood, (SHELF_DEPTH, 0.008, 0.180),
                          (SHELF_X, height, centre_z))]
        colours = [feest.MINT, feest.CREAM_LIGHT, feest.BLUSH_PINK_DEEP]
        for i, colour in enumerate(colours):
            along = -0.102 + i * 0.054
            z = 2 * centre_z - along if mirrored else along
            parts.append(game_prism("Jar%d-%d" % (int(height * 1000), i),
                                    feest.material("JarM%d" % i, colour),
                                    0.010, 0.022, 8, (SHELF_X, height + 0.004, z)))
            parts.append(game_prism("JarLid%d-%d" % (int(height * 1000), i),
                                    rose, 0.011, 0.005, 8,
                                    (SHELF_X, height + 0.026, z)))
        made += parent_local(parts, "Shelf%d" % int(height * 1000))

    # Cake plank.
    parts = [game_box("CakePlankBoard", rose, (PLANK_LENGTH, 0.008, 0.030),
                      (PLANK_CENTRE[0], PLANK_Y, PLANK_CENTRE[1]))]
    inset = PLANK_LENGTH / 2 - 0.013
    for i, dx in enumerate([-inset, inset]):
        parts.append(game_box("CakePlankBracket%d" % i, deep,
                              (0.008, 0.020, 0.008),
                              (PLANK_CENTRE[0] + dx, PLANK_Y - 0.014,
                               PLANK_CENTRE[1] - 0.008)))
    made += parent_local(parts, "CakePlank")
    return made


# ------------------------------------------------------------------- Otto
def _arch_outline(radius, leg, segments):
    points = [(-radius, 0.0)]
    for s in range(segments + 1):
        a = math.pi * (1 - s / segments)
        points.append((math.cos(a) * radius, leg + math.sin(a) * radius))
    points.append((radius, 0.0))
    return points


def _arch(name, material, inner, outer, leg, depth):
    inn, out = _arch_outline(inner, leg, 6), _arch_outline(outer, leg, 6)
    bm = bmesh.new()
    stations = []
    for i in range(len(inn)):
        stations.append([
            bm.verts.new(g(inn[i][0], inn[i][1], depth / 2)),
            bm.verts.new(g(out[i][0], out[i][1], depth / 2)),
            bm.verts.new(g(out[i][0], out[i][1], -depth / 2)),
            bm.verts.new(g(inn[i][0], inn[i][1], -depth / 2)),
        ])
    for a, b in zip(stations, stations[1:]):
        for face in [(a[0], b[0], b[1], a[1]), (a[3], a[2], b[2], b[3]),
                     (a[1], b[1], b[2], a[2]), (a[0], a[3], b[3], b[0])]:
            bm.faces.new(face)
    bm.faces.new(stations[0])
    bm.faces.new(list(reversed(stations[-1])))
    bm.normal_update()
    return lowpoly.flat_obj(name, bm, material)


def _arch_plug(name, material, radius, leg, depth):
    outline = _arch_outline(radius, leg, 6)
    bm = bmesh.new()
    front = [bm.verts.new(g(x, y, depth / 2)) for x, y in outline]
    back = [bm.verts.new(g(x, y, -depth / 2)) for x, y in outline]
    for i in range(1, len(outline) - 1):
        bm.faces.new((front[0], front[i + 1], front[i]))
        bm.faces.new((back[0], back[i], back[i + 1]))
    for i in range(len(outline)):
        j = (i + 1) % len(outline)
        bm.faces.new((front[i], back[j], back[i]))
        bm.faces.new((front[i], front[j], back[j]))
    bm.normal_update()
    return lowpoly.flat_obj(name, bm, material)


def build_otto():
    mint = feest.material("OttoMint", feest.MINT)
    cream = feest.material("OttoCream", feest.CREAM)
    light = feest.material("OttoCreamLight", feest.CREAM_LIGHT)
    rose = feest.material("OttoRose", feest.ROSE)
    deep = feest.material("OttoRoseDeep", feest.BLUSH_PINK_DEEP)
    yellow = feest.material("OttoYellow", feest.BUTTER_YELLOW)
    brown = feest.material("OttoBrown", feest.WOOD_BROWN)
    dark = feest.material("OttoInside", 0x554C3F)

    parts = [feest.dome("OvenDome", mint, OVEN_R, OVEN_H, 8, 4)]
    arch = _arch("OvenArch", rose, MOUTH_INNER, 0.034, MOUTH_LEG, MOUTH_DEPTH)
    arch.location = g(0.0, 0.0, MOUTH_BACK + MOUTH_DEPTH / 2)
    parts.append(arch)
    mouth = _arch_plug("OvenMouth", dark, MOUTH_INNER + 0.002,
                       MOUTH_LEG + 0.002, 0.028)
    mouth.location = g(0.0, -0.002, MOUTH_FRONT - 0.023 - 0.014)
    parts.append(mouth)
    door = _arch_plug("OvenDoor", deep, MOUTH_INNER + 0.005,
                      MOUTH_LEG + 0.005, 0.005)
    door.location = g(0.0, 0.0, MOUTH_FRONT - 0.0015)
    parts.append(door)
    parts.append(game_box("OvenDoorHandle", yellow, (0.020, 0.004, 0.004),
                          (0.0, MOUTH_LEG + 0.026, MOUTH_FRONT + 0.003)))

    cx, cz = 0.028, -0.030
    parts += [
        game_box("Chimney", cream, (0.022, 0.096, 0.022), (cx, 0.048, cz)),
        game_box("ChimneyCap", light, (0.034, 0.006, 0.034), (cx, 0.099, cz)),
    ]
    rim_y = 0.106
    for i, (size, centre) in enumerate([
        ((0.030, 0.008, 0.007), (cx, rim_y, cz - 0.0115)),
        ((0.030, 0.008, 0.007), (cx, rim_y, cz + 0.0115)),
        ((0.007, 0.008, 0.016), (cx - 0.0115, rim_y, cz)),
        ((0.007, 0.008, 0.016), (cx + 0.0115, rim_y, cz)),
    ]):
        parts.append(game_box("ChimneyRim%d" % i, light, size, centre))
    parts.append(game_box("ChimneyFlue", brown, (0.017, 0.014, 0.017),
                          (cx, 0.100, cz)))

    for i, dx in enumerate([-0.018, 0.018]):
        eye = game_blob("OttoEye%d" % i, light, 0.008, 2,
                        at=(dx, 0.052, 0.042))
        pupil = game_blob("OttoPupil%d" % i, brown, 0.004, 2,
                          at=(dx, 0.052, 0.0475))
        parts += [eye, pupil]
    return parent_local(parts, "Otto", OVEN_ORIGIN)


# -------------------------------------------------------------------- Nina
def build_nina():
    skin = feest.material("NinaSkin", feest.BLUSH_PINK)
    dress = feest.material("NinaDress", feest.MINT)
    apron = feest.material("NinaApronM", feest.MINT_LIGHT)
    deep = feest.material("NinaDeep", feest.BLUSH_PINK_DEEP)
    brown = feest.material("NinaBrown", feest.WOOD_BROWN)
    parts = []

    for i, dx in enumerate([-0.011, 0.011]):
        parts.append(game_box("NinaLeg%d" % i, skin, (0.012, 0.030, 0.012),
                              (dx, 0.015, 0.0)))
        parts.append(game_box("NinaShoe%d" % i, deep, (0.014, 0.007, 0.017),
                              (dx, 0.0015, 0.002)))
    parts += [
        game_box("NinaTorso", dress, (0.034, 0.040, 0.020), (0.0, 0.050, 0.0)),
        game_box("NinaApron", apron, (0.026, 0.026, 0.004), (0.0, 0.044, 0.011)),
        game_box("NinaPocket", skin, (0.016, 0.010, 0.003), (0.0, 0.038, 0.014)),
        game_box("NinaHead", skin, (0.026, 0.024, 0.022), (0.0, 0.082, 0.0)),
    ]
    for i, dx in enumerate([-0.023, 0.023]):
        parts.append(game_box("NinaArm%d" % i, skin, (0.010, 0.032, 0.010),
                              (dx, 0.050, 0.002)))
    for i, dx in enumerate([-0.006, 0.006]):
        parts.append(game_blob("NinaEye%d" % i, brown, 0.0022, 1,
                               at=(dx, 0.084, 0.011)))
    parts.append(game_lathe("NinaHatBrim", dress,
                            [(0.017, 0.0), (0.014, 0.011)], 8,
                            (0.0, 0.094, 0.0)))
    parts.append(game_blob("NinaHatKnob", dress, 0.004, 1,
                           at=(0.0, 0.108, 0.0)))
    for i, dx in enumerate([-0.020, 0.020]):
        parts.append(game_blob("NinaWing%d" % i, apron, 0.013, 1,
                               scale=(1.0, 0.9, 0.18),
                               at=(dx + (-0.008 if dx < 0 else 0.008),
                                   0.066, -0.010)))
    return parent_local(parts, "Nina", BAKER_SPOT, turn=0.28)


# ----------------------------------------------------------- room props
def build_honey():
    cream = feest.material("HoningCream", feest.CREAM)
    light = feest.material("HoningLight", feest.CREAM_LIGHT)
    honey = feest.material("HoningAmber", feest.HONEY_AMBER)
    wood = feest.material("HoningWood", feest.SANDY_WOOD)
    parts = [
        game_lathe("HoningPot", cream,
                   [(0.0068, 0), (0.0092, 0.006), (0.010, 0.011),
                    (0.0088, 0.014)], 8),
        game_prism("HoningRim", light, 0.0106, 0.0022, 8,
                   (0.0, 0.0138, 0.0)),
        game_prism("HoningVulling", honey, 0.0072, 0.0012, 8,
                   (0.0, 0.0154, 0.0)),
        game_box("HoningStok", wood, (0.023, 0.0032, 0.0032),
                 (0.0015, 0.0176, 0.0016)),
    ]
    root = parent_local(parts, "TokenHoning")
    root[0].scale = (1.33, 1.33, 1.33)
    root[0].location = g(*SOURCES[4])
    return root


def build_props(assets):
    made = []
    # The four modelled ingredients plus the procedural honey pot make one
    # possible five-card deal, spread over all five runtime sources.
    made += instance_asset(assets["bosbes"], "TokenBosbes", SOURCES[0])
    made += instance_asset(assets["klaver"], "TokenKlaver", SOURCES[1],
                           turn=math.pi / 4)
    made += instance_asset(assets["maanstof"], "TokenMaanstof", SOURCES[2])
    made += instance_asset(assets["veertje"], "TokenVeertje", SOURCES[3],
                           turn=math.pi / 4)
    made += build_honey()

    basket = game_bowl("Basket", feest.material("BasketM", feest.SANDY_WOOD),
                       0.016, 0.022, 0.014, 0.003, 0.003, 8, 2)
    basket.location = g(*BASKET_HOME)
    made += parent_local([basket], "Mandje")
    pot = game_bowl("IngredientPot", feest.material("IngredientPotM", feest.MINT),
                    0.011, 0.014, 0.012, 0.0025, 0.0025, 8, 2)
    pot.location = g(-0.034, COUNTER_Y, -0.174)
    made += parent_local([pot], "IngredientPotRoot")

    dough = game_lathe("Dough", feest.material("DoughM", feest.CREAM),
                       [(0.0, 0.0), (0.0092, 0.0006), (0.0142, 0.0034),
                        (0.0150, 0.0068), (0.0131, 0.0105),
                        (0.0088, 0.0132), (0.0, 0.0148)], 7)
    made += parent_local([dough], "Deeg", DOUGH_SPOT)

    bowl = game_bowl("Bowl", feest.material("BowlM", feest.BLUSH_PINK),
                     0.021, 0.032, 0.026, 0.0028, 0.0035, 12, 3)
    made += parent_local([bowl], "Mengkom", BOWL_HOME)
    made += instance_asset(assets["spoon"], "SpoonRest", SPOON_HOME,
                           tip_x=math.pi / 2.2)

    tin = game_bowl("TinBody", feest.material("TinM", feest.BLUSH_PINK_DEEP),
                    0.019, 0.022, 0.013, 0.0025, 0.003, 8, 2)
    made += parent_local([tin], "Bakvorm", TIN_HOME)

    pin_parts = [
        game_prism("RollingPinBarrel", feest.material("PinCream", feest.CREAM_LIGHT),
                   0.008, 0.052, 8),
        game_prism("RollingPinHandle0", feest.material("PinWood", feest.SANDY_WOOD),
                   0.004, 0.014, 6),
        game_prism("RollingPinHandle1", feest.material("PinWood", feest.SANDY_WOOD),
                   0.004, 0.014, 6),
    ]
    # Prisms stand on Blender Z; rotate them onto game X and place the three
    # centres as KitchenProps does.
    for ob, x in zip(pin_parts, [0.0, -0.033, 0.033]):
        ob.rotation_euler = (0.0, math.pi / 2, 0.0)
        ob.location = (x, 0.0, 0.0)
    made += parent_local(pin_parts, "RollingPin", PIN_HOME)

    made += instance_asset(assets["sink"], "Sink", SINK_SPOT)
    made += instance_asset(assets["scale"], "Scale", SCALE_SPOT)
    made += instance_asset(assets["flour-sack"], "FlourSack", FLOUR_SPOT)
    made += instance_asset(assets["crate"], "Crate", CRATE_SPOT)

    # Three retained cakes: the state that opens the visit-mode door.
    spacing = PLANK_LENGTH / 4
    start = PLANK_CENTRE[0] - PLANK_LENGTH / 2 + spacing / 2
    for i in range(3):
        made += instance_asset(
            assets["cake"], "ShelfCake%d" % i,
            (start + spacing * i, PLANK_Y + 0.004, PLANK_CENTRE[1]),
            scale=0.62)
    return made


# --------------------------------------------------------- portrait and door
def build_architecture():
    rose = feest.material("ArchitectuurRose", feest.ROSE)
    wood = feest.material("ArchitectuurWood", feest.SANDY_WOOD)
    blush = feest.material("ArchitectuurBlush", feest.BLUSH_PINK)
    yellow = feest.material("ArchitectuurYellow", feest.BUTTER_YELLOW)
    cream = feest.material("ArchitectuurCream", feest.CREAM_LIGHT)
    brown = feest.material("ArchitectuurBrown", feest.WOOD_BROWN)
    lilac = feest.material("ArchitectuurLilac", feest.LILAC)
    made = []

    # The modelled fallback portrait; the private family photograph is not in
    # the repository and therefore cannot be part of a reproducible study.
    picture = (0.058, 0.074)
    rail, depth = 0.006, 0.012
    outer = (picture[0] + rail * 2, picture[1] + rail * 2)
    parts = [game_box("PortraitBacking", cream, (picture[0], picture[1], 0.003),
                      (0.0, 0.0, 0.0015))]
    for side in [-1, 1]:
        parts.append(game_box("PortraitFrameSide", rose, (rail, outer[1], depth),
                              (side * (outer[0] - rail) / 2, 0.0, depth / 2)))
        parts.append(game_box("PortraitFrameRail", rose, (picture[0], rail, depth),
                              (0.0, side * (outer[1] - rail) / 2, depth / 2)))
    # `KitchenProps.modelledSitter`: the repository-safe fallback used when the
    # family's private photograph is not bundled.  The relief matters to this
    # study — an empty frame is less geometry than the reproducible app state.
    parts += [
        game_box("PortraitShirt", lilac, (0.044, 0.022, 0.006),
                 (0.0, -0.026, 0.005)),
        game_box("PortraitHair", brown, (0.034, 0.034, 0.005),
                 (0.0, 0.002, 0.005)),
        game_box("PortraitFace", wood, (0.026, 0.028, 0.008),
                 (0.0, 0.000, 0.007)),
        game_box("PortraitFringe", brown, (0.028, 0.008, 0.008),
                 (0.001, 0.014, 0.0072)),
        game_blob("PortraitKnot", brown, 0.0055, 1,
                  at=(-0.017, 0.012, 0.0055)),
        game_box("PortraitMouth", blush, (0.013, 0.005, 0.0022),
                 (0.0, -0.0092, 0.0116)),
        game_box("PortraitTeeth", cream, (0.0106, 0.0018, 0.0024),
                 (0.0, -0.0076, 0.0118)),
    ]
    for i, dx in enumerate([-0.0062, 0.0062]):
        parts.append(game_blob("PortraitEye%d" % i, brown, 0.0024, 1,
                               at=(dx, 0.003, 0.0118)))
        cheek = game_prism("PortraitCheek%d" % i, blush, 0.004, 0.0012, 6,
                           (dx * 1.7, -0.004, 0.0116))
        cheek.rotation_euler = (math.pi / 2, 0.0, 0.0)
        parts.append(cheek)
    made += parent_local(parts, "Portrait", PORTRAIT_CENTRE)

    # Door frame and glow in the door's local XY plane.
    opening = DOOR_OPEN
    frame_parts = [game_box("DoorwayGlow", yellow,
                            (opening[0], opening[1], 0.002),
                            (0.0, opening[1] / 2, -0.002))]
    for side in [-1, 1]:
        frame_parts.append(game_box(
            "DoorwayJamb", rose, (DOOR_JAMB, opening[1], DOOR_DEPTH),
            (side * (opening[0] + DOOR_JAMB) / 2, opening[1] / 2, 0.002)))
    frame_parts.append(game_box(
        "DoorwayLintel", rose,
        (opening[0] + DOOR_JAMB * 2, DOOR_JAMB, DOOR_DEPTH),
        (0.0, opening[1] + DOOR_JAMB / 2, 0.002)))

    door_root = bpy.data.objects.new("Doorway", None)
    bpy.context.collection.objects.link(door_root)
    door_root.location = g(*DOOR_CENTRE)
    door_root.rotation_euler = (0.0, 0.0, math.pi / 2)
    for ob in frame_parts:
        ob.parent = door_root
    made += [door_root] + frame_parts

    hinge = bpy.data.objects.new("DoorHinge", None)
    bpy.context.collection.objects.link(hinge)
    hinge.parent = door_root
    hinge.location = g(-opening[0] / 2, 0.0, 0.003)
    hinge.rotation_euler = (0.0, 0.0, DOOR_AJAR)
    leaf = game_box("DoorLeaf", wood, (opening[0], opening[1], DOOR_LEAF_T),
                    (opening[0] / 2, opening[1] / 2, DOOR_LEAF_T / 2))
    leaf.parent = hinge
    for side in [-1, 1]:
        panel = game_box("DoorPanel", blush,
                         (opening[0] - 0.028, (opening[1] - 0.042) / 2, 0.002),
                         (opening[0] / 2,
                          opening[1] / 2 + side * (opening[1] - 0.014) / 4,
                          DOOR_LEAF_T / 2 + 0.001))
        panel.parent = hinge
        made.append(panel)
    knob = game_prism("DoorKnob", yellow, 0.006, 0.007, 8,
                      (opening[0] - 0.013, opening[1] / 2, DOOR_LEAF_T / 2))
    knob.rotation_euler = (math.pi / 2, 0.0, 0.0)
    knob.parent = hinge
    made += [hinge, leaf, knob]
    return made


# ------------------------------------------------------------ camera / light
def build_camera():
    data = bpy.data.cameras.get("KeukenCam") or bpy.data.cameras.new("KeukenCam")
    data.sensor_fit = 'VERTICAL'
    data.angle_y = math.radians(FOV_V)
    data.clip_start = 0.01
    data.clip_end = 20.0
    cam = bpy.data.objects.new("KeukenCamera", data)
    bpy.context.collection.objects.link(cam)
    eye, target = mathutils.Vector(g(*EYE)), mathutils.Vector(g(*TARGET))
    cam.location = eye
    cam.rotation_euler = (target - eye).to_track_quat('-Z', 'Y').to_euler()
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
            ("AmbientDome0", 400.0, 55.0, 30.0, 6500, False),
            ("AmbientDome1", 400.0, 55.0, 150.0, 6500, False),
            ("AmbientDome2", 400.0, 55.0, 270.0, 6500, False)]
    made = []
    for name, lux, elevation, azimuth, kelvin, casts in spec:
        data = bpy.data.lights.new(name, 'SUN')
        data.energy = lux * LUX
        data.angle = math.radians(3.0)
        data.use_shadow = casts
        data.color = blackbody(kelvin)
        ob = bpy.data.objects.new(name, data)
        bpy.context.collection.objects.link(ob)
        d = direction(elevation, azimuth)
        ob.location = -d * 2.0
        ob.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()
        made.append(ob)
    return made


# ------------------------------------------------------- shadow caster rules
SHADOWLESS = ("Slab", "Floor", "WallBack", "WallLeft", "Counter",
              "Shelf", "CakePlank", "Portrait", "Doorway")


def apply_shadow_rules():
    hidden = 0
    for ob in bpy.data.objects:
        if ob.type != 'MESH':
            continue
        node = ob
        while node.parent is not None:
            node = node.parent
        if node.name.startswith(SHADOWLESS):
            ob.visible_shadow = False
            hidden += 1
    return hidden


# ------------------------------------------------------------------- assembly
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
    bpy.context.view_layer.active_layer_collection = bpy.context.view_layer.layer_collection
    bpy.context.view_layer.update()


def prepare_assets():
    assets = {}
    for stem in ["bosbes", "klaver", "maanstof", "veertje", "spoon",
                 "sink", "scale", "flour-sack", "crate", "cake"]:
        assets[stem] = load_prop(stem).build()
    return assets


def discard_assets(assets):
    for source in assets.values():
        for ob in source:
            if ob.name in bpy.data.objects:
                bpy.data.objects.remove(ob, do_unlink=True)
    # Source roots temporarily own the unsuffixed Blender names while their
    # instances are made.  Once they are gone, normalise the instance names so
    # reports say `Sink`, not an implementation-leak `Sink.001`.
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
    into("Meubels", build_furniture)
    into("Otto", build_otto)
    into("Nina", build_nina)
    into("Props", lambda: build_props(assets))
    into("Architectuur", build_architecture)
    into("Camera", lambda: [build_camera()])
    into("Licht", build_lights)
    discard_assets(assets)

    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.render.resolution_x = 1400
    scene.render.resolution_y = 1050
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    scene.view_settings.view_transform = 'Standard'
    scene.view_settings.look = 'Medium High Contrast'
    scene.view_settings.exposure = 0.5
    scene.unit_settings.system = 'METRIC'

    world = bpy.data.worlds.get("Keuken") or bpy.data.worlds.new("Keuken")
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs[0].default_value = (0.72, 0.72, 0.72, 1.0)
    bg.inputs[1].default_value = 0.0
    scene.world = world

    hidden = apply_shadow_rules()
    bpy.context.view_layer.update()
    total = sum(len(ob.data.polygons) for ob in bpy.data.objects
                if ob.type == 'MESH')
    print("  %-12s %3d meshes out of the shadow map" % ("shadows", hidden))
    print("De Keuken: %d objects, %d faces" % (len(bpy.data.objects), total))
    return groups


if __name__ == "__main__":
    assemble()
