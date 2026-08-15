# Prop references

Concept plates for the kitchen props, generated in the locked faceted style
against the scene reference `../plates/01-cottage-exterior.png`. They are
**modelling references** — the geometry in
`app/NinaBakeryPOC/Sources/RoomBuilder.swift` was built from them.

| File | Job ID | Reads as |
|---|---|---|
| `oven.png` | `fd306e12-6e28-4e27-9e24-852af52746f9` | Faceted dome, ~8 sides × 4 rings, plus a block arch |
| `bowl.png` | `1c744ca8-9561-4e9c-85d9-a65a681a4ea1` | Tapered prism, ~12 sides |
| `table.png` | `ea575cad-2979-402c-b618-c8dbd95c8a64` | Four box legs, thick slab top |
| `jar.png` | `4bf27563-db0c-4ec6-b1f3-c2db51516f05` | 8-sided prism with a flat lid |

All `flux_2` / `pro` / `1k`, prompt and seed on the job record. The style prompt
is in [`../REFERENCES.md`](../REFERENCES.md) §3.

The useful thing about these plates is that they name their own facet counts.
"~8 sides × 4 rings" is directly the arguments to `FacetedMesh.dome`.

## `oven.glb` — the image-to-3D experiment, and why it failed

`generate_3d` (`image_to_3d`, **20 credits**) was run once on `oven.png` to test
whether Higgsfield can supply geometry rather than just reference. It cannot,
for this style.

| | Generated `oven.glb` | `FacetedMesh.dome(sides: 8, rings: 4)` |
|---|---|---|
| Faces | 26,780 | 56 |
| Median adjacent-face angle | 5° | large and regular |
| Watertight | no | yes |
| Faces after aggressive decimation | floors at 2,053 | — |

The reconstruction gets the **silhouette** right and then destroys the thing
that defines the look. A 5° median crease is a smooth surface; this style needs
large deliberate facets. Quadric decimation does not rescue it — it bottoms out
around 2,053 faces and the creases that survive are irregular and scattered, so
it reads as a damaged smooth mesh rather than a low-poly one.

**Rule: generate images for reference, model the geometry.** For primitives this
simple, code is faster than a modelling round-trip and gives exactly the facet
counts the style asks for.

`generate_3d` may still earn its 20 credits on something genuinely organic — a
character body, where the rig only splits off the legs — but not on a dome, a
jar or a table.

The GLB is kept as evidence, not as an asset. It is not in the app bundle.
