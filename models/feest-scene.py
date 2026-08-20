"""**Het Feest, assembled** — the whole disco in one Blender scene.

Every other script in this folder builds **one prop** at the origin and exports
it. This one builds **the room**: the shell, the thirty-six tiles, the props at
`FeestLayout`'s own coordinates, the seven friends, the camera at `CameraRig.eye`
and the five lights `LightingRig` installs.

It exports nothing. It exists so that a question about the *scene* — is there
occlusion between two props, does the wall corner want darkening, what does a
contact shadow actually look like here — can be asked of geometry rather than
of a screenshot.

**Why the room and not the props.** `lowpoly.bake_ao_facets` already bakes
occlusion, and it is per-prop by construction: it measures a prop against
itself, in the prop's own space, and knows nothing about the floor it stands on
or the wall behind it. Everything that occludes *across* two objects — a booth
against plaster, a table leg on a tile, the seam between two walls, six pairs of
feet — is invisible to it, and that is most of the occlusion in
`references/feest/roombox.png`.

Run it with the room already open, or from scratch:

    blender --background --python models/feest-scene.py

Numbers come from four Swift files and are named after them, so a change there
is a grep away from a change here:

    RoomBox.swift        the box, the walls, the slab, floorY
    CameraRig.swift      the eye, the target, the 26° vertical FOV
    LightingSettings     key / fill / ambient dome, at the approved defaults
    FeestLayout.swift    where every prop in this room stands

Blender is Z-up and the exporter maps (x, y, z) → (x, z, −y), so the game's
(x, y, z) is Blender's (x, −z, y) — `g()` below is the one place that is done.
"""

import importlib.util
import math
import os
import sys

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


# ------------------------------------------------------- RoomBox.swift
ROOM = 0.46
HALF = ROOM / 2
WALL_H = 0.235
WALL_T = 0.012
SLAB_T = 0.014
FLOOR_Y = 0.004

# ------------------------------------------------------- CameraRig.swift
EYE = (0.636, 0.611, 0.636)
TARGET = (0.0, 0.06, 0.0)
FOV_V = 26.0

# ------------------------------------------------------- FeestLayout.swift
ALONG = (0.7071, -0.7071)
BACK = (-0.7071, -0.7071)
FLOOR_CENTRE = (0.020, -0.030)

TILES = 6
TILE_SIZE = 0.059
TILE_GAP = 0.003
TILE_PITCH = TILE_SIZE + TILE_GAP
TILE_T = 0.0028
TILE_TOP_Y = FLOOR_Y + TILE_T

PAD_COUNT = 6
PAD_ROW_CENTRE = (0.095, 0.095)
PAD_PITCH = 0.065
PAD_R = 0.020
PAD_H = 0.011

GUESTS = 6
BALL_CENTRE = (0.020, 0.180, -0.030)
BALL_R = 0.030
CORD_TOP_Y = 0.45

BACK_BAR_Y = 0.190
BACK_BAR_Z = -HALF + WALL_T + 0.012
LEFT_BAR_X = -HALF + WALL_T + 0.012
BACK_LAMP_X = [-0.110, 0.000, 0.110]
LEFT_LAMP_Z = [-0.090, 0.010]

BOOTH_CENTRE = (0.100, -0.140)
DJ_SPOT = (0.100, FLOOR_Y, -0.185)

TABLE_CENTRE = (-0.148, 0.086)
TABLE_TOP_Y = 0.072
TABLE_R = 0.042
TABLE_TOP_T = 0.006
TABLE_FOOT_R = 0.026
TABLE_STEM_R = 0.012
CAKE_SCALE = 1.8

SPEAKER_SPOT = (0.196, FLOOR_Y, -0.190)
SPEAKER_SPOT_FAR = (-0.190, FLOOR_Y, -0.190)
CABINET = (0.042, 0.048, 0.030)

POPPER_SPOT = (-0.196, FLOOR_Y, 0.132)
BALLOON_HOME = (-0.150, 0.150, -0.120)
BAKER_SPOT = (-0.196, FLOOR_Y, 0.030)

#: `FeestLayout.discoColours`, and the pads, the floor and the lamps share them.
DISCO = [feest.BLUSH_PINK, feest.MINT, feest.BUTTER_YELLOW,
         feest.BERRY_BLUE, feest.LILAC, feest.SAGE]

#: Which six friends turn up, and what they are painted. The party deals them;
#: a still needs one deal. `(soort, coat, accent)` off `Friend.swift`.
GUESTS_TODAY = [("beer", feest.HONEY_AMBER, feest.BUTTER_YELLOW),      # Bas
                ("muis", feest.CREAM_LIGHT, feest.BLUSH_PINK),         # Pip
                ("kat", feest.BLUSH_PINK, feest.BLUSH_PINK_DEEP),      # Kiki
                ("kikker", feest.SAGE, feest.SAGE_DEEP),               # Bram
                ("schaap", feest.CREAM, feest.CREAM_LIGHT),            # Wolkje
                ("egel", feest.ROSE, feest.BLUSH_PINK_DEEP)]           # Roos
DJ_TODAY = ("vogel", feest.BERRY_BLUE, feest.BERRY_BLUE_DEEP)          # Bo


def spot(centre, along, back):
    return (centre[0] + ALONG[0] * along + BACK[0] * back,
            centre[1] + ALONG[1] * along + BACK[1] * back)


# --------------------------------------------------------------- scaffolding
def collection(name, parent=None):
    c = bpy.data.collections.get(name)
    if c is None:
        c = bpy.data.collections.new(name)
        (parent or bpy.context.scene.collection).children.link(c)
    return c


def move_to(objects, target):
    for ob in objects:
        for c in list(ob.users_collection):
            c.objects.unlink(ob)
        target.objects.link(ob)


def instance(parts, name, at, turn=0.0, scale=1.0, tilt=None):
    """Copy a built prop, hang the copies on one empty, and place it.

    The prop scripts build at the origin with unit matrices, which is
    `garden.py`'s rule and is what makes this cheap: a copy shares the mesh
    data, so thirty-six dance tiles are one mesh and thirty-six transforms.

    `at` is in the **game's** frame; `turn` is the game's rotation about Y,
    which is Blender's about Z with the same sign.
    """
    root = bpy.data.objects.new(name, None)
    root.empty_display_size = 0.02
    bpy.context.collection.objects.link(root)
    root.location = g(*at)
    root.rotation_euler = tilt if tilt is not None else (0.0, 0.0, turn)
    if scale != 1.0:
        root.scale = (scale, scale, scale)

    made = [root]
    for part in parts:
        # Prop scripts hand back their own root empty along with the meshes —
        # `cake.build()` does. One root per instance is enough.
        if part.type != 'MESH':
            continue
        copy = part.copy()
        bpy.context.collection.objects.link(copy)
        copy.parent = root
        made.append(copy)
    return made


def load_prop(stem):
    """Import a prop script **without running its `main()`**.

    The scripts are written so that `build()` is the shape and `main()` is the
    check-and-export around it, which is what lets a scene reuse the shipping
    geometry rather than keep a second description of it. The filenames have
    dashes in them, so this goes through `importlib.util` rather than `import`.
    """
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), stem + ".py")
    spec = importlib.util.spec_from_file_location(stem.replace("-", "_"), path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


# ---------------------------------------------------------------- the shell
#: How many cells across each inward face of the shell is cut into.
#:
#: **Zero is what the game ships**, and it is the single most important number
#: in the AO investigation. `RoomBox.shell` builds the floor as one box, so the
#: surface every prop in the room stands on is **one 460 mm quad** and each wall
#: is one 460 × 235 mm quad. A facet bake can only give a facet one tone, so on
#: the shipping shell the only answer available to "how dark is the floor under
#: the DJ booth" is *the whole floor*. It is `models/README.md`'s fence, at room
#: scale: "very large facets have nothing to quantise".
#:
#: At 24 a cell is 19 mm, which is about the width of a guest's foot.
SUBDIV = 0


def _grid(name, material, spans, faces=None, subdiv=0):
    """Boxes, with the named faces cut into a `subdiv` × `subdiv` grid.

    Only the faces that **receive** are cut — the outsides of the walls and the
    underside of the floor are never seen and cutting them would triple the
    bake for nothing.
    """
    import bmesh
    bm = bmesh.new()
    for span in spans:
        lowpoly.add_box(bm, *span)
    # **Before selecting by normal, not after.** A bmesh face built by hand
    # reports a zero normal until the mesh is updated, so a selection made first
    # matches nothing and the box comes back uncut — silently, because an uncut
    # box is a perfectly good box.
    bm.normal_update()
    if subdiv > 1 and faces:
        bm.faces.ensure_lookup_table()
        chosen = [f for f in bm.faces
                  if any(f.normal.dot(mathutils.Vector(d)) > 0.99 for d in faces)]
        if chosen:
            edges = list({e for f in chosen for e in f.edges})
            bmesh.ops.subdivide_edges(bm, edges=edges, cuts=subdiv - 1,
                                      use_grid_fill=True)
    bm.normal_update()
    return lowpoly.flat_obj(name, bm, material)


def build_shell(subdiv=None):
    """`RoomBox.shell` — two walls, a floor and a slab."""
    subdiv = SUBDIV if subdiv is None else subdiv
    cream = feest.material("SchilCream", feest.CREAM)
    cream_light = feest.material("SchilCreamLight", feest.CREAM_LIGHT)
    blush = feest.material("SchilBlush", feest.BLUSH_PINK)

    parts = [
        feest.boxes("Slab", cream, [((-HALF - 0.015, HALF + 0.015),
                                     (-HALF - 0.015, HALF + 0.015),
                                     (-SLAB_T, 0.0))]),
        _grid("Floor", blush, [((-HALF, HALF), (-HALF, HALF), (0.0, FLOOR_Y))],
              faces=[(0, 0, 1)], subdiv=subdiv),
        # **Blender +Y is the game's −Z.** The back wall stands on the game's
        # far edge, so its span is the *top* of the Y range, not the bottom —
        # writing it the way it reads in `RoomBox.shell` puts it across the open
        # front edge, between the camera and the room.
        _grid("WallBack", cream_light,
              [((-HALF, HALF), (HALF - WALL_T, HALF), (0.0, WALL_H))],
              faces=[(0, -1, 0)], subdiv=subdiv),
        _grid("WallLeft", cream,
              [((-HALF, -HALF + WALL_T), (-HALF, HALF), (0.0, WALL_H))],
              faces=[(1, 0, 0)], subdiv=subdiv),
    ]
    return parts


# ----------------------------------------------------------- the dance floor
def build_dance_floor():
    tile = load_prop("dance-tile")
    parts = tile.build()
    made = []
    half = (TILES - 1) / 2
    for row in range(TILES):
        for column in range(TILES):
            x = (column - half) * TILE_PITCH
            z = (row - half) * TILE_PITCH
            made += instance(parts, "Tegel-%d-%d" % (row, column),
                             (x, FLOOR_Y, z))
    for ob in parts:
        bpy.data.objects.remove(ob, do_unlink=True)
    return made


# ------------------------------------------------------------------ the pads
def build_pads():
    """`FeestProps.pad` — a squat drum with a domed cap proud of it."""
    made = []
    for i in range(PAD_COUNT):
        offset = (i - (PAD_COUNT - 1) / 2) * PAD_PITCH
        p = spot(PAD_ROW_CENTRE, offset, 0.0)
        colour = DISCO[i % len(DISCO)]
        base = garden.prism("KnopVoet%d" % i,
                            feest.material("KnopVoetM", feest.CREAM_LIGHT),
                            PAD_R, PAD_H * 0.6, 8)
        cap = garden.lathe(
            "KnopKap%d" % i, feest.material("KnopKap%d" % i, colour),
            [(PAD_R * 0.88, 0.0),
             (PAD_R * 0.88 * math.cos(math.pi / 6), PAD_H * 0.5 * math.sin(math.pi / 6)),
             (PAD_R * 0.88 * math.cos(math.pi / 3), PAD_H * 0.5 * math.sin(math.pi / 3)),
             (0.0, PAD_H * 0.5)], 8, at=(0.0, 0.0, PAD_H * 0.6))
        made += instance([base, cap], "Knop%d" % i, (p[0], FLOOR_Y, p[1]))
        bpy.data.objects.remove(base, do_unlink=True)
        bpy.data.objects.remove(cap, do_unlink=True)
    return made


# ----------------------------------------------------------- the mirror ball
def build_ball():
    ball = load_prop("discobal")
    parts, keep, scratch = ball.build()
    for ob in scratch:
        bpy.data.objects.remove(ob, do_unlink=True)
    body = parts + keep

    made = instance(body, "Discobal", BALL_CENTRE)
    for ob in body:
        bpy.data.objects.remove(ob, do_unlink=True)

    cream = feest.material("KoordM", feest.CREAM)
    cord_length = CORD_TOP_Y - BALL_CENTRE[1]
    cord = feest.boxes("DiscobalKoord", cream,
                       [((-0.0008, 0.0008), (-0.0008, 0.0008),
                         (BALL_R, BALL_R + cord_length))])
    cord.location = g(*BALL_CENTRE)
    made.append(cord)
    return made


# --------------------------------------------------------------- the lights
def build_rig():
    """Two bars and five lamps, aimed at the middle of the dance floor."""
    made = []
    bar = load_prop("light-bar")
    bar_parts = bar.build()

    made += instance(bar_parts, "LichtbalkAchter", (0.0, BACK_BAR_Y, BACK_BAR_Z))
    left = instance(bar_parts, "LichtbalkLinks", (LEFT_BAR_X, BACK_BAR_Y, -0.040),
                    turn=math.pi / 2)
    left[0].scale = (0.230 / 0.280, 1.0, 1.0)
    made += left
    for ob in bar_parts:
        bpy.data.objects.remove(ob, do_unlink=True)

    lamp = load_prop("stage-lamp")
    lamp_parts = lamp.build()
    aim = mathutils.Vector(g(FLOOR_CENTRE[0], TILE_TOP_Y, FLOOR_CENTRE[1]))

    origins = [(x, BACK_BAR_Y - 0.005, BACK_BAR_Z) for x in BACK_LAMP_X]
    origins += [(LEFT_BAR_X, BACK_BAR_Y - 0.005, z) for z in LEFT_LAMP_Z]
    for i, origin in enumerate(origins):
        here = mathutils.Vector(g(*origin))
        # The model looks down its own game −Y, which is Blender −Z.
        down = (aim - here).normalized()
        tilt = mathutils.Vector((0.0, 0.0, -1.0)).rotation_difference(down).to_euler()
        made += instance(lamp_parts, "Lamp%d" % i, origin, tilt=tilt)
    for ob in lamp_parts:
        bpy.data.objects.remove(ob, do_unlink=True)
    return made


# ----------------------------------------------------------------- the booth
def build_booth():
    booth = load_prop("dj-booth")
    parts = booth.build()
    made = instance(parts, "DJBooth", (BOOTH_CENTRE[0], FLOOR_Y, BOOTH_CENTRE[1]))
    for ob in parts:
        bpy.data.objects.remove(ob, do_unlink=True)
    return made


# -------------------------------------------------------------- the speakers
def build_speakers():
    box = load_prop("speaker")
    parts = box.build()
    made = []
    # `FeestProps.speakers` stacks a lilac cabinet on a sandy one, which is
    # `references/feest/boxen.png`. The model carries one coat; the app repaints
    # it per level, so the scene has to as well.
    for level, colour in enumerate([feest.SANDY_WOOD, feest.LILAC]):
        repaint(parts, {"BoxCoat": colour}, suffix=str(level))
        for stack, at in enumerate([SPEAKER_SPOT, SPEAKER_SPOT_FAR]):
            y = at[1] + level * (CABINET[1] + 0.0015)
            made += instance(parts, "Box%d-%d" % (stack, level), (at[0], y, at[2]))
    for ob in parts:
        bpy.data.objects.remove(ob, do_unlink=True)
    return made


# ------------------------------------------------------- the cake, on its table
def build_table_and_cake():
    """`FeestProps.cakeTable`, and `models/cake.py` at 1.8×."""
    rose = feest.material("TafelRose", feest.ROSE)
    blush = feest.material("TafelBlush", feest.BLUSH_PINK)

    foot = garden.lathe("TafelVoet", rose,
                        [(TABLE_FOOT_R, 0.0), (TABLE_FOOT_R * 0.7, 0.008)], 10)
    stem_h = TABLE_TOP_Y - FLOOR_Y - TABLE_TOP_T - 0.008
    stem = garden.prism("TafelPoot", rose, TABLE_STEM_R, stem_h, 8,
                        at=(0.0, 0.0, 0.008))
    top = garden.prism("TafelBlad", blush, TABLE_R, TABLE_TOP_T, 12,
                       at=(0.0, 0.0, TABLE_TOP_Y - FLOOR_Y - TABLE_TOP_T))
    made = instance([foot, stem, top], "Feesttafel",
                    (TABLE_CENTRE[0], FLOOR_Y, TABLE_CENTRE[1]))
    for ob in (foot, stem, top):
        bpy.data.objects.remove(ob, do_unlink=True)

    cake = load_prop("cake")
    parts = cake.build()
    made += instance(parts, "Taart",
                     (TABLE_CENTRE[0], TABLE_TOP_Y, TABLE_CENTRE[1]),
                     scale=CAKE_SCALE)
    for ob in parts:
        bpy.data.objects.remove(ob, do_unlink=True)
    return made


# ---------------------------------------------------------------- the friends
def repaint(parts, mapping, suffix=""):
    """Re-tint a built prop the way `ModelLibrary.load(tint:)` does on load.

    **The `ShadeN` suffix is the whole reason this is not one line.** The bake
    splits an occluded facet into its own object with its own material, and the
    app repaints those a step darker per level out of the palette rather than
    keeping whatever Blender wrote. A repaint that ignored the suffix would
    throw the existing per-prop occlusion away — which is precisely the thing
    this scene is here to measure against.
    """
    for ob in parts:
        if ob.type != 'MESH' or not ob.data.materials:
            continue
        name = ob.data.materials[0].name
        base, steps = name, 0
        marker = base.rfind("Shade")
        if marker >= 0:
            suffix = base[marker + len("Shade"):]
            if suffix.isdigit():
                base, steps = base[:marker], int(suffix)
        if base not in mapping:
            continue
        colour = mapping[base]
        f = lowpoly.OCCLUSION_STEP ** steps
        rgb = [int(((colour >> shift) & 255) * f) for shift in (16, 8, 0)]
        ob.data.materials[0] = feest.material(
            "%s%s%s" % (base, suffix, "Shade%d" % steps if steps else ""),
            (rgb[0] << 16) | (rgb[1] << 8) | rgb[2])


def build_guests():
    beertje = load_prop("beertje")
    made = []
    for index, (soort, coat, accent) in enumerate(GUESTS_TODAY):
        parts = beertje.build(soort)
        repaint(parts, {"GastCoat": coat, "GastAccent": accent}, suffix=soort)
        front = index < 3
        a = [-0.084, 0.000, 0.084][index] if front \
            else [-0.126, -0.042, 0.042][index - 3]
        b = -0.030 if front else 0.082
        p = spot(FLOOR_CENTRE, a, b)
        made += instance(parts, "Gast-%s" % soort, (p[0], FLOOR_Y, p[1]),
                         turn=0.42)
        for ob in parts:
            bpy.data.objects.remove(ob, do_unlink=True)

    soort, coat, accent = DJ_TODAY
    parts = beertje.build(soort)
    repaint(parts, {"GastCoat": coat, "GastAccent": accent,
                    "GastGold": feest.BUTTER_YELLOW,
                    "GastRose": feest.ROSE}, suffix=soort)
    made += instance(parts, "DJ-%s" % soort, DJ_SPOT, turn=0.10)
    for ob in parts:
        bpy.data.objects.remove(ob, do_unlink=True)

    # The DJ is one of the eleven friends with one separate modelled accessory,
    # parented to the head pivot in the app. Stage it at that same pivot here so
    # the room render does not silently review a guest without his headphones.
    headphones = load_prop("dj-headphones")
    phone_parts, _ = headphones.build()
    repaint(phone_parts, {"DJMint": feest.MINT_LIGHT,
                          "DJDark": feest.WOOD_BROWN,
                          "DJCream": feest.CREAM_LIGHT,
                          "DJRose": feest.ROSE}, suffix="dj")
    made += instance(
        phone_parts, "DJ-Koptelefoon",
        (DJ_SPOT[0], DJ_SPOT[1] + beertje.BODY_BASE + beertje.HEAD_Y, DJ_SPOT[2]),
        turn=0.10)
    for ob in phone_parts:
        bpy.data.objects.remove(ob, do_unlink=True)
    return made


# ------------------------------------------------------------------- the toys
def build_toys():
    made = []
    cone = garden.lathe("KnallerKegel",
                        feest.material("KnallerM", feest.BLUSH_PINK_DEEP),
                        [(0.009, 0.0), (0.018, 0.030)], 8)
    band = garden.prism("KnallerRand",
                        feest.material("KnallerRandM", feest.MINT_LIGHT),
                        0.0195, 0.004, 8, at=(0.0, 0.0, 0.028))
    knob = garden.balls("KnallerKnop",
                        feest.material("KnallerKnopM", feest.BUTTER_YELLOW),
                        [(0.005, (0.0, 0.0, 0.036))], subdivisions=0)
    made += instance([cone, band, knob], "Knaller", POPPER_SPOT)
    for ob in (cone, band, knob):
        bpy.data.objects.remove(ob, do_unlink=True)

    skin = garden.lathe("BallonVel", feest.material("BallonM", feest.ROSE),
                        [(0.0, -0.020), (0.006, -0.016), (0.013, -0.006),
                         (0.014, 0.004), (0.009, 0.012), (0.0, 0.016)], 10)
    knot = garden.lathe("BallonKnoop",
                        feest.material("BallonKnoopM", feest.BLUSH_PINK_DEEP),
                        [(0.0, -0.026), (0.0035, -0.021), (0.0, -0.019)], 6)
    string = feest.boxes("BallonTouw",
                         feest.material("BallonTouwM", feest.CREAM_LIGHT),
                         [((-0.0006, 0.0006), (-0.0006, 0.0006),
                           (-0.066, -0.026))])
    made += instance([skin, knot, string], "Ballon", BALLOON_HOME)
    for ob in (skin, knot, string):
        bpy.data.objects.remove(ob, do_unlink=True)
    return made


# ------------------------------------------------------------ camera and light
def build_camera():
    data = bpy.data.cameras.get("FeestCam") or bpy.data.cameras.new("FeestCam")
    data.sensor_fit = 'VERTICAL'
    data.angle_y = math.radians(FOV_V)
    data.clip_start = 0.01
    data.clip_end = 20.0
    cam = bpy.data.objects.get("FeestCamera")
    if cam is None:
        cam = bpy.data.objects.new("FeestCamera", data)
        bpy.context.collection.objects.link(cam)
    cam.data = data
    eye = mathutils.Vector(g(*EYE))
    target = mathutils.Vector(g(*TARGET))
    cam.location = eye
    cam.rotation_euler = (target - eye).to_track_quat('-Z', 'Y').to_euler()
    bpy.context.scene.camera = cam
    return cam


def direction(elevation, azimuth):
    """`LightingSettings.direction` — where the light shines, in Blender axes."""
    e = math.radians(elevation)
    a = math.radians(azimuth)
    return gdir(-math.cos(e) * math.sin(a), -math.sin(e),
                -math.cos(e) * math.cos(a)).normalized()


#: lux → W/m². RealityKit's intensities are photometric and Blender's are
#: radiometric, so the *ratio* between the five lights is the thing that
#: transfers; the constant is set by eye against the plates and is the one
#: number in this file that is not read off a Swift source.
LUX = 1 / 1000.0


def build_lights(shadows=True):
    """`LightingRig` — key, fill, and the three-light ambient dome.

    Five suns, at the approved defaults in `LightingSettings`. The dome is what
    stands in for a sky in the app, and reproducing it here is the point: an AO
    comparison against a *different* lighting setup measures the lighting.
    """
    spec = [("KeyLight", 1400.0, 62.0, 135.0, 6200, shadows),
            ("FillLight", 700.0, 18.0, 135.0 + 165.0, 7800, False),
            ("AmbientDome0", 400.0, 55.0, 30.0, 6500, False),
            ("AmbientDome1", 400.0, 55.0, 150.0, 6500, False),
            ("AmbientDome2", 400.0, 55.0, 270.0, 6500, False)]

    made = []
    for name, lux, elevation, azimuth, kelvin, casts in spec:
        data = bpy.data.lights.get(name) or bpy.data.lights.new(name, 'SUN')
        data.type = 'SUN'
        data.energy = lux * LUX
        data.angle = math.radians(3.0)
        data.use_shadow = casts
        data.color = blackbody(kelvin)
        ob = bpy.data.objects.get(name)
        if ob is None:
            ob = bpy.data.objects.new(name, data)
            bpy.context.collection.objects.link(ob)
        ob.data = data
        d = direction(elevation, azimuth)
        ob.location = -d * 2.0
        ob.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()
        made.append(ob)
    return made


def blackbody(kelvin):
    """`LightingRig.colour`, so a warm key stays a warm key."""
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
    out = []
    for c in (r, gg, b):
        c = max(0.0, min(255.0, c)) / 255.0
        out.append(lowpoly.srgb_to_linear(c))
    return out


# ------------------------------------------------------- what casts a shadow
#: **Which props are kept out of the key light's shadow map**, mirroring every
#: `excludeFromShadowCasting()` call in `RoomBox.shell`, `FeestProps` and
#: `Entity.excludeFromShadowCasting`. Matched against the name of the prop's
#: root, so an instance's parts are covered by the one entry.
#:
#: **This is not a detail and leaving it out makes the room look worse than it
#: is.** The first pass of this scene had every prop casting, and what came back
#: was a hard dark band raking across the plaster from the light bar and the five
#: lamps — which is precisely the artefact `LightingSettings`' own history
#: records the owner rejecting twice on device in 2026-08-15, and precisely why
#: the bars, the lamps, the ball, the tiles, the balloon and the shell were all
#: taken out of the shadow map in the first place. A study that reintroduces it
#: is measuring a room the game does not have.
#:
#: What still casts, and should: the pads, the booth, both speaker stacks, the
#: cake and its table, the popper, the six guests and the DJ. Their shadows are
#: the grounding the rig exists to provide.
SHADOWLESS = ("Slab", "Floor", "WallBack", "WallLeft",   # RoomBox.shell
              "Tegel",                                    # the 36 dance tiles
              "Discobal",                                 # ball, ring and cord
              "Lichtbalk", "Lamp",                        # the rig
              "Ballon")


def apply_shadow_rules():
    """Take everything in `SHADOWLESS` out of the key light's shadow map."""
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
    """Empty the file, and **put the active collection back**.

    Removing the collection the view layer is pointing at leaves
    `bpy.context.collection` as `None` for the rest of the call, and
    `lowpoly.flat_obj` links every object it builds into it. Resetting the
    pointer to the scene's own master collection is what makes the very next
    line work.
    """
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob, do_unlink=True)
    for c in list(bpy.data.collections):
        bpy.data.collections.remove(c)

    # **The materials go too, and forgetting them cost a whole render set.**
    # `lowpoly.material` looks a material up *by name* and hands back the
    # existing one, so a palette colour survives any number of rebuilds — which
    # is normally a feature and is poison here: `feest-ao.pixel_ao` rewires
    # Base Color through an occlusion node, and a scene reassembled afterwards
    # picks that wiring straight back up. The symptom is a "baseline" render
    # that quietly already has ambient occlusion in it, which is the one thing
    # this whole study must not have. Purged, so every assemble starts from the
    # palette.
    for material in list(bpy.data.materials):
        bpy.data.materials.remove(material, do_unlink=True)
    for image in list(bpy.data.images):
        if image.name.startswith("AO_"):
            bpy.data.images.remove(image, do_unlink=True)

    view_layer = bpy.context.view_layer
    view_layer.active_layer_collection = view_layer.layer_collection
    view_layer.update()


def assemble():
    wipe()
    scene = bpy.context.scene
    groups = {}

    def into(name, builder):
        target = collection(name)
        before = set(bpy.data.objects)
        made = builder()
        made = [ob for ob in bpy.data.objects if ob not in before] or made
        move_to(made, target)
        groups[name] = made
        print("  %-12s %3d objects" % (name, len(made)))
        return made

    into("Schil", build_shell)
    into("Vloer", build_dance_floor)
    into("Props", lambda: build_pads() + build_ball() + build_booth()
         + build_speakers() + build_table_and_cake() + build_toys())
    into("Rig", build_rig)
    into("Gasten", build_guests)
    into("Camera", lambda: [build_camera()])
    into("Licht", lambda: build_lights())

    scene.render.engine = 'CYCLES'
    scene.render.resolution_x = 1400
    scene.render.resolution_y = 1050
    scene.render.film_transparent = True
    scene.view_settings.view_transform = 'Standard'
    # Half a stop, and it is a display setting rather than a change to
    # any light: the five suns stay at `LightingSettings`' own numbers so
    # the *ratios* between them — which is what shapes the room — are the
    # app's, and only the exposure is chosen to sit the render where the
    # plates sit.
    scene.view_settings.exposure = 0.5
    world = bpy.data.worlds.get("Feest") or bpy.data.worlds.new("Feest")
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    # The plates' plain neutral grey backdrop. **Zero by default**: a grey world
    # in Cycles is an ambient light, and an ambient light is where occlusion
    # comes from — so it is a dial the investigation turns rather than a
    # constant, and it must be off for the render that stands for the app.
    bg.inputs[0].default_value = (0.72, 0.72, 0.72, 1.0)
    bg.inputs[1].default_value = 0.0
    scene.world = world

    hidden = apply_shadow_rules()
    print("  %-12s %3d meshes out of the shadow map" % ("shadows", hidden))

    bpy.context.view_layer.update()
    total = sum(len(ob.data.polygons) for ob in bpy.data.objects
                if ob.type == 'MESH')
    print("Het Feest: %d objects, %d faces" % (len(bpy.data.objects), total))
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
