# Resources

Empty on purpose. Three optional assets slot in here, and the debug panel
detects each one and enables the matching control.

| Drop in | Filename | Enables |
|---|---|---|
| Environment for image-based lighting | `StudioNeutral.skybox` (or `.exr`) | **Image-based light** section |
| Baked AO lightmap | `Lightmap_AO.png` | Lightmap → **AO** |
| Baked beauty lightmap | `Lightmap_Beauty.png` | Lightmap → **Beauty** |
| Room model with UVs | `KitchenRoom.usdz` | Room source → **USDZ**, and the lightmap modes |

Nothing here is required. The app runs on the procedural room with real-time
lighting only — which is the direction's default, and the thing the POC is
actually testing.

See [`../../LIGHTMAPS.md`](../../LIGHTMAPS.md) for how to produce the lightmaps.
