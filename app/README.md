# Nina's Toverbakkerij — Step 0 POC

A RealityKit proof of concept for one question: **does the faceted pastel
low-poly direction survive real-time rendering without baked ambient
occlusion?**

There is no game in here. One room, three loose props, and a debug panel for
tuning the lighting until it matches — or fails to match —
`references/plates/03-kitchen-roombox.png`.

> **Builds and runs on device** as of 2026-08-15 (iPadOS, Xcode 26.5). It was
> originally authored blind in a Linux container with no Swift toolchain, so the
> first build needed two fixes: `PhysicallyBasedMaterial.AmbientOcclusion` takes
> only a texture, not a `scale`, and `ContactShadows` called a helper that was
> never written.

## Approved lighting

**Settled on iPad, 2026-08-15.** The values in `LightingSettings.swift` are the
approved ones — every slider was judged good where it started, so the committed
defaults *are* the result.

| | |
|---|---|
| Key | 2200 lx, 42° elevation, 135° azimuth, 6200 K, shadows **on** |
| Fill | 900 lx, 7800 K, opposite the key at 18° |
| IBL | off — no environment bundled, and it is not missed |
| Contact shadows | on, opacity 0.18, scale 1.15 |
| Lightmap | off |

This answers the POC's main question in the affirmative: **the faceted direction
holds with real-time light only, no baked AO.** The key light's cast shadow does
the grounding that AO was there for, and it stays correct when a prop moves.

Changing these is an art-direction decision, not a tweak. Lift any new setup
with **Copy settings** before overwriting.

## Read this before opening it: the simulator

**RealityKit does not render reliably in the iOS Simulator.** That is a
long-standing limitation, not a setup problem — AR-backed RealityKit is
unsupported there outright, and non-AR `RealityView` has a history of crashing
in the simulator (reports go back to the iOS 18 betas).

So the target is built **multiplatform — iOS *and* macOS**:

| Where | Use it for | Reliability |
|---|---|---|
| **My Mac** | Tuning the lighting panel. Fast, no device, instant rebuild. | Good — this is the intended loop |
| **iPad, on device** | The actual verdict. `POC.md` says judge at arm's length. | The real answer |
| **iOS Simulator** | Try it; it may work in non-AR mode. | Unreliable — do not conclude anything from it |

The lighting panel is the reason macOS is worth having: the whole point is
turning knobs and watching, and doing that on the Mac is several times faster
than deploying to a device. Confirm the result on the iPad before believing it.

## Opening the project

```
open app/NinaBakeryPOC/NinaBakeryPOC.xcodeproj
```

The project uses Xcode's file-system-synchronized groups, so `Sources/` and
`Resources/` are picked up by folder — no file lists to maintain.

**If the project file will not open** (it was hand-written and never opened by
Xcode), rebuilding it takes under a minute and loses nothing:

1. Xcode → New → Project → Multiplatform → App, name it `NinaBakeryPOC`.
2. Delete the generated `ContentView.swift` and `…App.swift`.
3. Drag `Sources/` into the project, "Create groups", add to target.
4. Set the deployment targets to iOS 18 / macOS 15.

Everything is plain Swift in one folder precisely so this fallback is trivial.

## What is in it

| File | What |
|---|---|
| `FacetedMesh.swift` | **The core.** Flat-shaded primitive builders — box, prism, tapered prism, icosphere, dome, bowl, archway — plus the smooth variant for A/B. |
| `Palette.swift` | The 13 locked base colours from `references/REFERENCES.md` §4. |
| `RoomBuilder.swift` | The kitchen room box and props, in metres, at the 0.4 m scale from `POC.md`. |
| `LightingRig.swift` | Every light in the scene. Key, fill, IBL, and the lightmap application. |
| `ContactShadows.swift` | The fake dynamic AO — blobs under loose props, scaled by proximity. |
| `LightingSettings.swift` | The tunables, plus **Copy settings** snippet generation. |
| `DebugPanel.swift` | The corner overlay. |
| `ContentView.swift` | Scene assembly and the fixed isometric camera. |

### The flat-shading trick

`FacetedMesh` exists because RealityKit's built-in primitives are all smooth or
rounded, which is exactly what this style must not be. Every triangle gets its
own three vertices carrying the face normal, so no normal is shared between
adjacent faces. That is what makes a 80-face sphere return ~80 distinct tones
under a single light — and it is the whole argument for not needing AO.

Because the normal comes from the winding, **winding is load-bearing** — a
reversed triangle is both unlit and invisible, and you see the surface behind
it. Two rounds of see-through props came from exactly that. Every primitive is
now a closed solid wound outward (the dome's base is the one deliberate
exception; it sits on the floor, and a disc there would z-fight). A hollow
vessel needs a real inner wall — a single-walled cone has no inside, which is
why `bowl` exists and `taperedPrism` is not it.

The **Flat shading** toggle in the panel switches to averaged normals. That is
the "before" picture, and it is the single most informative control in the app:
if the smooth version looks just as good, the art direction is not earning its
keep.

## The debug panel

Top-right, collapsible.

- **Scene** — room source (procedural / USDZ), flat vs smooth shading, backdrop
- **Key light** — intensity, elevation, azimuth, temperature, shadows on/off
- **Fill** — intensity and temperature, standing in for bounced light
- **Image-based light** — disabled until an environment is bundled
- **Contact shadows** — opacity and scale
- **Lightmap (RCP 3)** — Off / AO / Beauty, disabled until something is baked
- **Copy settings** — puts the current values on the clipboard as Swift, so a
  setup found by fiddling survives into source

## Assets

Concept plates for the props are in `references/props/`, generated in the locked
style. They are modelling references — the geometry in `RoomBuilder.swift` was
built from them.

### What we learned trying Higgsfield's image-to-3D

`generate_3d` (`image_to_3d`, 20 credits) was run once on the oven plate. The
result is in `references/props/oven.glb`. It is **not usable for this style**:

| | Generated | Procedural equivalent |
|---|---|---|
| Faces | 26,780 | 56 |
| Median adjacent-face angle | 5° | large, regular |
| After aggressive decimation | floors at 2,053 faces | — |
| Watertight | no | yes |

It reconstructs the *silhouette* faithfully and then throws away the one thing
that defines the look: large, deliberate, regular facets. Decimation does not
rescue it — it bottoms out at 2,053 faces with irregular scattered creases,
which reads as a damaged smooth mesh rather than a low-poly one.

**Conclusion: generate images for reference, model the geometry.** For primitives
this simple, code is faster than a modelling round-trip and gives exactly the
facet counts the style wants. `generate_3d` may still earn its place on
something organic later — a character body — but not on a dome.

## What this POC may not conclude

Per `POC.md`: nothing about whether the game is fun. There is no game in it.
Legitimate conclusions are whether the art direction holds without AO, and what
the lighting numbers should be.
