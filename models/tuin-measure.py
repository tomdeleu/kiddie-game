"""Frozen lighting ruler for De Tuin's plate-matching hillclimb.

One command, two jobs:

    python3 models/tuin-measure.py plate
    blender --background --python models/tuin-measure.py -- still NAME.png

The first prints the lighting signature of
``references/garden/roombox.png`` — the plate the owner named. The second
assembles the shipping garden, renders it from the game camera, and prints the
same numbers. Changing this file after a baseline is recorded invalidates
every earlier row.

Signature, on every non-backdrop pixel:

  open_L     90th-percentile luminance (the bright lawn / plaster)
  shadow_L   10th-percentile luminance (contact and crevice)
  contrast   open_L / shadow_L
  sat        mean chroma of pixels whose chroma exceeds 0.08

Primary metric: contrast, higher toward the plate.
Hard floor: open_L must stay at least 90% of the as-it-ships baseline, so a
win that muddies the mint is a revert.
"""

from __future__ import annotations

import json
import os
import sys
from collections import deque


HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
PLATE = os.path.join(REPO, "references", "garden", "roombox.png")
STUDY = os.path.join(REPO, "app", "ao-study-tuin")

# Backdrop of every plate and of the Blender stills. Sampled from
# Palette.backdropGrey. Distance is in 0–1 sRGB.
BACKDROP = (0.811, 0.808, 0.811)
BACKDROP_RADIUS = 0.075


def _percentile(values, pct):
    if not values:
        raise RuntimeError("no samples")
    ordered = sorted(values)
    if len(ordered) == 1:
        return ordered[0]
    rank = (len(ordered) - 1) * (pct / 100.0)
    lo = int(rank)
    hi = min(lo + 1, len(ordered) - 1)
    frac = rank - lo
    return ordered[lo] * (1.0 - frac) + ordered[hi] * frac


def _backdrop_mask(pixels, width, height):
    """True on the grey void. Flood-fill from the four corners."""
    similar = [False] * (width * height)
    greys = (BACKDROP, (0.72, 0.72, 0.72), (0.0, 0.0, 0.0))
    radius2 = BACKDROP_RADIUS * BACKDROP_RADIUS
    for i, (r, g, b) in enumerate(pixels):
        luma = r * 0.2126 + g * 0.7152 + b * 0.0722
        if luma < 0.04:
            similar[i] = True
            continue
        for br, bg, bb in greys:
            dr, dg, db = r - br, g - bg, b - bb
            if (dr * dr + dg * dg + db * db) < radius2:
                similar[i] = True
                break
    seen = [False] * (width * height)
    stack = deque([0, width - 1, (height - 1) * width, height * width - 1])
    while stack:
        i = stack.pop()
        if seen[i] or not similar[i]:
            continue
        seen[i] = True
        y, x = divmod(i, width)
        if y > 0:
            stack.append(i - width)
        if y + 1 < height:
            stack.append(i + width)
        if x > 0:
            stack.append(i - 1)
        if x + 1 < width:
            stack.append(i + 1)
    return seen


def crop_to_room(path, dest):
    """Cut a simulator still down to the room. The iPad frame is mostly lawn
    and chrome; the plate and the Blender stills are already tight."""
    pixels, width, height = _load_pixels(path)
    backdrop = _backdrop_mask(pixels, width, height)
    xs = [i % width for i, flag in enumerate(backdrop) if not flag]
    ys = [i // width for i, flag in enumerate(backdrop) if not flag]
    if len(xs) < 100:
        raise RuntimeError("%s: backdrop ate the picture" % path)
    pad = 8
    x0 = max(0, min(xs) - pad)
    x1 = min(width, max(xs) + pad + 1)
    y0 = max(0, min(ys) - pad)
    y1 = min(height, max(ys) + pad + 1)
    try:
        from PIL import Image
        image = Image.open(path).convert("RGB")
        image.crop((x0, y0, x1, y1)).save(dest)
    except ImportError:
        import bpy
        image = bpy.data.images.load(path)
        image.scale(width, height)
        cropped = bpy.data.images.new("TuinCrop", x1 - x0, y1 - y0)
        src = list(image.pixels)
        dst = [0.0] * ((x1 - x0) * (y1 - y0) * 4)
        for y in range(y0, y1):
            for x in range(x0, x1):
                si = (y * width + x) * 4
                di = ((y - y0) * (x1 - x0) + (x - x0)) * 4
                dst[di:di + 4] = src[si:si + 4]
        cropped.pixels = dst
        cropped.filepath_raw = dest
        cropped.file_format = "PNG"
        cropped.save()
    return dest


def _load_pixels(path):
    try:
        from PIL import Image
        image = Image.open(path).convert("RGB")
        width, height = image.size
        return [(r / 255.0, g / 255.0, b / 255.0) for r, g, b in image.getdata()], width, height
    except ImportError:
        import bpy
        image = bpy.data.images.load(path)
        width, height = image.size
        raw = list(image.pixels)
        pixels = [(raw[i], raw[i + 1], raw[i + 2])
                  for i in range(0, len(raw), 4)]
        return pixels, width, height


def signature(path):
    pixels, width, height = _load_pixels(path)
    backdrop = _backdrop_mask(pixels, width, height)
    luma = []
    chroma = []
    for i, (r, g, b) in enumerate(pixels):
        if backdrop[i]:
            continue
        luma.append(r * 0.2126 + g * 0.7152 + b * 0.0722)
        chroma.append(max(r, g, b) - min(r, g, b))
    if len(luma) < 100:
        raise RuntimeError("%s: backdrop ate the picture" % path)
    colourful = [c for c in chroma if c > 0.08]
    open_l = _percentile(luma, 90)
    shadow_l = _percentile(luma, 10)
    # Soil and bark are dark by albedo, not by occlusion. Contact on the
    # bright shell (lawn, plaster, fence) is the plate's actual AO read.
    ground = [l for l in luma if l > 0.55]
    ground_open = _percentile(ground, 90) if len(ground) >= 100 else open_l
    ground_shadow = _percentile(ground, 10) if len(ground) >= 100 else shadow_l
    return {
        "path": path,
        "pixels": width * height,
        "kept": len(luma),
        "open_L": float(open_l),
        "shadow_L": float(shadow_l),
        "contrast": float(open_l / max(shadow_l, 1e-4)),
        "ground_open_L": float(ground_open),
        "ground_shadow_L": float(ground_shadow),
        "ground_contrast": float(ground_open / max(ground_shadow, 1e-4)),
        "sat": float(sum(colourful) / len(colourful)) if colourful else 0.0,
    }


def format_signature(row):
    return (
        "open_L=%.4f  shadow_L=%.4f  contrast=%.3f  ground=%.3f  sat=%.4f  kept=%d/%d"
        % (row["open_L"], row["shadow_L"], row["contrast"], row["ground_contrast"],
           row["sat"], row["kept"], row["pixels"])
    )


def score(current, plate, baseline=None):
    """Plate distance. Contrast alone passed a blown-white still.

    Primary: mean of relative errors on contrast, open_L, shadow_L, sat.
    Hard floors: open_L must stay within 0.08 of the plate (not blown, not
    muddy) and, once a baseline exists, must not fall more than 10% below it.
    """
    contrast_err = abs(current["ground_contrast"] - plate["ground_contrast"]) / plate["ground_contrast"]
    open_err = abs(current["ground_open_L"] - plate["ground_open_L"])
    shadow_err = abs(current["ground_shadow_L"] - plate["ground_shadow_L"])
    sat_err = abs(current["sat"] - plate["sat"]) / max(plate["sat"], 1e-4)
    plate_err = (contrast_err + open_err + shadow_err + sat_err) / 4.0
    open_drop = 0.0
    if baseline is not None:
        open_drop = max(0.0, (baseline["open_L"] - current["open_L"]) / baseline["open_L"])
    result = {
        "contrast_err": float(contrast_err),
        "open_err": float(open_err),
        "shadow_err": float(shadow_err),
        "sat_err": float(sat_err),
        "plate_err": float(plate_err),
        "open_drop": float(open_drop),
        "pass_contrast": contrast_err <= 0.15,
        "pass_open": open_err <= 0.08 and open_drop <= 0.10,
        "pass_shadow": shadow_err <= 0.08,
        "pass_sat": sat_err <= 0.20,
    }
    result["pass"] = (
        result["pass_contrast"]
        and result["pass_open"]
        and result["pass_shadow"]
        and result["pass_sat"]
    )
    return result


def write_json(row, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as handle:
        json.dump(row, handle, indent=2)
        handle.write("\n")


def _rewrite_png(src, dest, map_rgb):
    import bpy
    image = bpy.data.images.load(src)
    pixels = list(image.pixels)
    for i in range(0, len(pixels), 4):
        r, g, b = map_rgb(pixels[i], pixels[i + 1], pixels[i + 2])
        pixels[i], pixels[i + 1], pixels[i + 2] = r, g, b
    image.pixels = pixels
    image.filepath_raw = dest
    image.file_format = "PNG"
    image.save()


def prove_sensitivity():
    """The ruler must move the right way on a washed and a deepened plate."""
    os.makedirs(STUDY, exist_ok=True)
    plate = signature(PLATE)
    washed = os.path.join(STUDY, "ruler-washed.png")
    deep = os.path.join(STUDY, "ruler-deepened.png")

    def wash(r, g, b):
        return (r + 0.45 * (1 - r), g + 0.45 * (1 - g), b + 0.45 * (1 - b))

    def deepen(r, g, b):
        luma = r * 0.2126 + g * 0.7152 + b * 0.0722
        if luma < 0.70:
            return (r * 0.62, g * 0.62, b * 0.62)
        return (r, g, b)

    _rewrite_png(PLATE, washed, wash)
    _rewrite_png(PLATE, deep, deepen)
    w_row = signature(washed)
    d_row = signature(deep)
    print("plate   %s" % format_signature(plate))
    print("washed  %s" % format_signature(w_row))
    print("deep    %s" % format_signature(d_row))
    if w_row["contrast"] >= plate["contrast"] - 0.05:
        raise RuntimeError("ruler cannot see a washed plate")
    if d_row["contrast"] <= plate["contrast"] + 0.05:
        raise RuntimeError("ruler cannot see a deepened plate")
    print("ruler separates washed < plate < deepened")
    return plate, w_row, d_row


def measure_plate():
    row = signature(PLATE)
    os.makedirs(STUDY, exist_ok=True)
    write_json(row, os.path.join(STUDY, "plate-signature.json"))
    print("plate  %s" % format_signature(row))
    return row


def _load_scene():
    import importlib.util
    path = os.path.join(HERE, "tuin-scene.py")
    spec = importlib.util.spec_from_file_location("tuin_scene", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _composite_backdrop(path):
    """Put the plate's grey void behind a transparent Cycles still."""
    import bpy
    image = bpy.data.images.load(path)
    pixels = list(image.pixels)
    br, bg, bb = BACKDROP
    changed = False
    for i in range(0, len(pixels), 4):
        alpha = pixels[i + 3]
        if alpha >= 0.999:
            continue
        keep = max(0.0, min(1.0, alpha))
        pixels[i] = pixels[i] * keep + br * (1.0 - keep)
        pixels[i + 1] = pixels[i + 1] * keep + bg * (1.0 - keep)
        pixels[i + 2] = pixels[i + 2] * keep + bb * (1.0 - keep)
        pixels[i + 3] = 1.0
        changed = True
    if changed:
        image.pixels = pixels
        image.filepath_raw = path
        image.file_format = "PNG"
        image.save()


def render_still(name):
    scene = _load_scene()
    scene.assemble()
    path = os.path.join(STUDY, name)
    scene.render_still(path)
    _composite_backdrop(path)
    row = signature(path)
    write_json(row, path.replace(".png", "-signature.json"))
    plate = signature(PLATE)
    print("still  %s" % format_signature(row))
    print("plate  %s" % format_signature(plate))
    print("score  %s" % json.dumps(score(row, plate), sort_keys=True))
    return row


def _load_ao():
    import importlib.util
    path = os.path.join(HERE, "tuin-ao.py")
    spec = importlib.util.spec_from_file_location("tuin_ao", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _score_path(path, plate, label):
    row = signature(path)
    write_json(row, path.replace(".png", "-signature.json"))
    print("%-8s %s" % (label, format_signature(row)))
    print("%-8s %s" % ("score", json.dumps(score(row, plate), sort_keys=True)))
    return row


def render_pair():
    """As-it-ships and the per-pixel AO ceiling, one assemble."""
    scene = _load_scene()
    ao = _load_ao()
    scene.assemble()
    plate = signature(PLATE)
    write_json(plate, os.path.join(STUDY, "plate-signature.json"))
    print("plate    %s" % format_signature(plate))

    ships = os.path.join(STUDY, "01-as-it-ships.png")
    scene.render_still(ships)
    _composite_backdrop(ships)
    ships_row = _score_path(ships, plate, "ships")

    ao.pixel_ao()
    ceiling = os.path.join(STUDY, "02-real-ao.png")
    scene.render_still(ceiling)
    _composite_backdrop(ceiling)
    ceil_row = _score_path(ceiling, plate, "ao")
    write_json(
        {"ships": score(ships_row, plate), "ao": score(ceil_row, plate)},
        os.path.join(STUDY, "baseline-score.json"),
    )
    return ships_row, ceil_row


def render_lawn_overlay():
    """As-it-ships plus the shipping lawn map, one assemble."""
    import bpy
    scene = _load_scene()
    scene.assemble()
    path = os.path.join(
        REPO, "app", "NinaBakeryPOC", "Resources", "Lightmaps", "TuinLawnAO.png")
    image = bpy.data.images.load(path)
    image.colorspace_settings.name = "Non-Color"

    mint = (0.702, 0.871, 0.737, 1.0)  # Palette.mintLight, linear-ish
    material = bpy.data.materials.new("TuinLawnAOPreview")
    material.use_nodes = True
    tree = material.node_tree
    bsdf = tree.nodes["Principled BSDF"]
    tex = tree.nodes.new("ShaderNodeTexImage")
    tex.image = image
    mix = tree.nodes.new("ShaderNodeMixRGB")
    mix.blend_type = "MULTIPLY"
    mix.inputs["Fac"].default_value = 1.0
    mix.inputs["Color1"].default_value = mint
    tree.links.new(tex.outputs["Color"], mix.inputs["Color2"])
    tree.links.new(mix.outputs["Color"], bsdf.inputs["Base Color"])

    half = 0.23
    floor = 0.0042
    mesh = bpy.data.meshes.new("TuinLawnAOPreviewMesh")
    mesh.from_pydata(
        [(-half, -half, floor), (half, -half, floor),
         (half, half, floor), (-half, half, floor)],
        [], [(0, 1, 2, 3)])
    mesh.update()
    uv = mesh.uv_layers.new(name="UVMap")
    for loop in mesh.loops:
        uv.data[loop.index].uv = [(0, 0), (1, 0), (1, 1), (0, 1)][loop.vertex_index]
    overlay = bpy.data.objects.new("TuinLawnAOPreview", mesh)
    overlay.data.materials.append(material)
    overlay.visible_shadow = False
    bpy.context.collection.objects.link(overlay)

    plate = signature(PLATE)
    still = os.path.join(STUDY, "03-lawn-map.png")
    scene.render_still(still)
    _composite_backdrop(still)
    _score_path(still, plate, "lawn")


def _add_lawn_overlay():
    import bpy
    path = os.path.join(
        REPO, "app", "NinaBakeryPOC", "Resources", "Lightmaps", "TuinLawnAO.png")
    if not os.path.exists(path):
        return
    image = bpy.data.images.load(path)
    image.colorspace_settings.name = "Non-Color"
    mint = (0.702, 0.871, 0.737, 1.0)
    material = bpy.data.materials.new("TuinLawnAOPreview")
    material.use_nodes = True
    tree = material.node_tree
    bsdf = tree.nodes["Principled BSDF"]
    tex = tree.nodes.new("ShaderNodeTexImage")
    tex.image = image
    mix = tree.nodes.new("ShaderNodeMixRGB")
    mix.blend_type = "MULTIPLY"
    mix.inputs["Fac"].default_value = 1.0
    mix.inputs["Color1"].default_value = mint
    tree.links.new(tex.outputs["Color"], mix.inputs["Color2"])
    tree.links.new(mix.outputs["Color"], bsdf.inputs["Base Color"])
    half = 0.23
    floor = 0.0042
    mesh = bpy.data.meshes.new("TuinLawnAOPreviewMesh")
    mesh.from_pydata(
        [(-half, -half, floor), (half, -half, floor),
         (half, half, floor), (-half, half, floor)],
        [], [(0, 1, 2, 3)])
    mesh.update()
    uv = mesh.uv_layers.new(name="UVMap")
    for loop in mesh.loops:
        uv.data[loop.index].uv = [(0, 0), (1, 0), (1, 1), (0, 1)][loop.vertex_index]
    overlay = bpy.data.objects.new("TuinLawnAOPreview", mesh)
    overlay.data.materials.append(material)
    overlay.visible_shadow = False
    bpy.context.collection.objects.link(overlay)


# Lawn, foliage and timber stay pale so bushes still read on the mint.
# Everything else is a plate pastel and may be punched.
_PUNCH_SKIP = (
    "Ground", "Slab", "TuinLawn", "Tree", "Bush", "Fence", "BedSoil",
    "BedHole", "Mole", "Soil",
)


def _scale_chroma(color, factor):
    r, g, b = color[0], color[1], color[2]
    luma = 0.2126 * r + 0.7152 * g + 0.0722 * b
    return (
        max(0.0, min(1.0, luma + factor * (r - luma))),
        max(0.0, min(1.0, luma + factor * (g - luma))),
        max(0.0, min(1.0, luma + factor * (b - luma))),
        color[3] if len(color) > 3 else 1.0,
    )


def _punch_materials(factor):
    import bpy
    for ob in bpy.data.objects:
        if not ob.data or not getattr(ob.data, "materials", None):
            continue
        if ob.name.startswith(_PUNCH_SKIP):
            continue
        for material in ob.data.materials:
            if material is None or not material.use_nodes:
                continue
            bsdf = material.node_tree.nodes.get("Principled BSDF")
            if bsdf is None:
                continue
            socket = bsdf.inputs["Base Color"]
            if socket.links:
                continue
            socket.default_value = _scale_chroma(socket.default_value, factor)


def sweep_punch():
    """Raise prop chroma. The lawn stays mintLight so the bushes still read."""
    scene = _load_scene()
    scene.assemble()
    _add_lawn_overlay()
    plate = signature(PLATE)
    print("plate    %s" % format_signature(plate))
    best = None
    for factor in (1.0, 1.4, 1.6, 1.8, 2.0):
        _punch_materials(factor)
        path = os.path.join(STUDY, "05-punch-%.1f.png" % factor)
        scene.render_still(path, samples=32)
        _composite_backdrop(path)
        row = _score_path(path, plate, "p%.1f" % factor)
        err = score(row, plate)
        # Re-assemble would be slower; punch is cumulative, so restore by
        # punching the inverse... easier to re-assemble each factor.
        if best is None or err["plate_err"] < best[0]:
            best = (err["plate_err"], factor, err)
        # Next factor would stack. Rebuild.
        scene.assemble()
        _add_lawn_overlay()
    print("best punch %.1f plate_err=%.4f" % (best[1], best[0]))
    return best


def sweep_ambient():
    """Lower the dome and see whether saturation moves toward the plate."""
    import bpy
    scene = _load_scene()
    scene.assemble()
    _add_lawn_overlay()
    plate = signature(PLATE)
    print("plate    %s" % format_signature(plate))
    lux = scene.LUX
    best = None
    for total in (1200.0, 800.0, 500.0, 300.0):
        share = total / 3.0 * lux
        for name in ("AmbientDome0", "AmbientDome1", "AmbientDome2"):
            bpy.data.objects[name].data.energy = share
        path = os.path.join(STUDY, "04-ambient-%.0f.png" % total)
        scene.render_still(path, samples=32)
        _composite_backdrop(path)
        row = _score_path(path, plate, "a%.0f" % total)
        err = score(row, plate)
        if best is None or err["plate_err"] < best[0]:
            best = (err["plate_err"], total, err)
    print("best ambient %.0f plate_err=%.4f" % (best[1], best[0]))
    return best


def calibrate_exposure():
    import bpy
    scene = _load_scene()
    scene.assemble()
    plate = signature(PLATE)
    best = None
    for exp in (0.15, 0.25, 0.30, 0.35, 0.40):
        bpy.context.scene.view_settings.exposure = exp
        path = os.path.join(STUDY, "calibrate-e%.2f.png" % exp)
        scene.render_still(path, samples=32)
        _composite_backdrop(path)
        row = signature(path)
        err = abs(row["open_L"] - plate["open_L"])
        print("e=%.2f  %s  open_err=%.4f" % (exp, format_signature(row), err))
        if best is None or err < best[0]:
            best = (err, exp, row)
    print("best exposure %.2f open_err=%.4f" % (best[1], best[0]))
    return best


def _script_args():
    # Blender leaves its own flags in sys.argv. Everything after `--` is ours.
    if "--" in sys.argv:
        return sys.argv[sys.argv.index("--") + 1:]
    return [a for a in sys.argv[1:] if not a.startswith("-") and not a.endswith(".py")]


def main():
    args = _script_args()
    if not args or args[0] == "plate":
        measure_plate()
        return
    if args[0] == "still":
        name = args[1] if len(args) > 1 else "01-as-it-ships.png"
        render_still(name)
        return
    if args[0] == "prove":
        prove_sensitivity()
        return
    if args[0] == "calibrate":
        calibrate_exposure()
        return
    if args[0] == "baseline":
        render_pair()
        return
    if args[0] == "lawn":
        render_lawn_overlay()
        return
    if args[0] == "ambient":
        sweep_ambient()
        return
    if args[0] == "punch":
        sweep_punch()
        return
    if args[0] == "crop" and len(args) >= 3:
        crop_to_room(args[1], args[2])
        print("cropped %s" % args[2])
        return
    if args[0] == "compare" and len(args) >= 2:
        plate = signature(PLATE)
        current = signature(args[1])
        baseline = signature(args[2]) if len(args) > 2 else None
        print("image  %s" % format_signature(current))
        print("plate  %s" % format_signature(plate))
        print("score  %s" % json.dumps(score(current, plate, baseline), sort_keys=True))
        return
    raise SystemExit(
        "usage: tuin-measure.py [plate|prove|calibrate|baseline|lawn|ambient|punch|still NAME.png|compare IMAGE [BASELINE]]")


if __name__ == "__main__":
    main()
