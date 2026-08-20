import CoreGraphics
import Foundation
import RealityKit
import simd

/// **The disco, in faceted primitives.**
///
/// Built from the twelve plates in `references/feest/`. Every one of them is a
/// handful of `FacetedMesh` shapes — the most complicated thing in here is the
/// DJ booth, which is nine boxes and two prisms.
///
/// ## The one rule this file exists to hold
///
/// **A disco is made of light, not of darkness.** `references/REFERENCES.md` §1
/// asks for soft even lighting, no dark corners and no occlusion, and none of
/// that changed for this room — the plaster is the same plaster and the key light
/// is the same key light. What the disco adds is **emissive surfaces**: the floor
/// tiles, the lamp lenses, the beams, the booth's front panel and the mirror
/// ball's facets are `Palette.glowMaterial` and `Palette.lightMaterial`, which
/// put a surface above white in the HDR buffer where a base colour cannot reach.
///
/// It is the halo's lesson (`Engine/Halo.swift`, four attempts) applied to a
/// whole room: **if it has to look like a light, make it one.** Dimming the room
/// to sell a disco would have thrown the art direction away for one room; six
/// emissive materials bought the same read for nothing, and the palette stayed
/// locked — every colour in here is one of the thirteen or one of the three the
/// kitchen derived.
enum FeestProps {

    /// How hard the glowing things glow. One number, because the whole room's
    /// disco-ness is a single dial. The first simulator pass at 2.6 pushed the
    /// floor, mirror ball and pale props into the same white register, and 1.6
    /// still left too much of the floor there. At 1.1 the lenses cross white,
    /// while a floor tile at `floorGlow` emits at 0.935 and retains its colour.
    static let glowPeak: Float = 1.1

    static func lit(_ colour: UIColorLike, _ amount: Float = 1) -> RealityKit.Material {
        Palette.glowMaterial(colour, intensity: glowPeak * max(0, amount))
    }

    /// **How hard a floor tile glows, and it is a third of everything else.**
    ///
    /// The floor came out white (owner, 2026-08-17). `glowPeak` is tuned for a
    /// lamp lens and a booth panel — small bright objects seen against pale
    /// plaster, where going above white is the whole point. A floor tile is 59 mm
    /// square and there are 36 of them, so the same intensity is not a highlight,
    /// it is the largest surface in the room, and above white it has no colour
    /// left at all.
    ///
    /// At 0.85 a lit tile sits just under white and keeps its hue — which is what
    /// makes the floor *coloured* rather than merely bright, and it is why this is
    /// a number of its own rather than another `amount` passed to `lit`.
    static let floorGlow: Float = 0.85

    /// **How hard a mirror-ball tile glints, and it is a quarter of a lamp.**
    ///
    /// The ball came back white (owner, 2026-08-18: *"it also has too much
    /// light. it looks white instead of like the plate."*), and it is the floor's
    /// mistake repeated on a smaller surface: a lit tile was
    /// `lit(.creamLight, 0.7)`, which is emission at **1.82** on a base colour
    /// already at 95% luminance. Anything that far above white has no colour left
    /// after tonemapping, so every glinting tile came back the same flat white
    /// and the ball read as a lamp rather than as a thing catching one.
    ///
    /// `references/feest/discobal.png` has **no glowing tile at all** — the whole
    /// prop sits in a narrow pale band and the glint is the game's own addition.
    /// So it should be the smallest emissive value in the room, not the largest,
    /// and it is applied to `butterYellow` rather than `creamLight`: a mid-tone
    /// has chroma left to survive the exposure, which is the same pairing
    /// `FeestLayout.floorLitColours` settled on.
    static let ballGlow: Float = 0.34

    // MARK: - The dance floor

    struct DanceFloor {
        let root: Entity
        /// Row-major, `tilesPerSide²` of them.
        ///
        /// The shipping path has one UV-mapped gradient plane per tile. The
        /// `shadeStep` remains for `models/dance-tile.py`'s three-band fallback,
        /// so either path can swap cached materials on the beat.
        let tiles: [[(mesh: ModelEntity, dark: RealityKit.Material, shadeStep: Int)]]
        /// One three-step ladder per entry in `FeestLayout.floorLitColours`.
        /// The direct index keeps the beat path branchless and the cache tiny.
        let glowing: [[RealityKit.Material]]
    }

    /// **Thirty-six tiles, and it is the whole disco.**
    ///
    /// `references/feest/dansvloer.png` came back with pastel tiles rather than a
    /// black-and-white chequer, and that is the version that belongs here: a lit
    /// floor in the room's own colours, with three or four brighter than the rest
    /// at any moment. A chequer would have been a second palette.
    ///
    /// ## The gradient is actually smooth
    ///
    /// `references/feest/roombox.png` shows one continuous rectangular falloff:
    /// a broad pale centre flowing into the tile colour at the edge. The former
    /// `Shade1/2` meshes drew two hard outlines and were not a gradient.
    ///
    /// This is the room's deliberate texture exception: one generated 128²
    /// greyscale superellipse, mapped over a shared plane and multiplied by each
    /// tile's tint. The same map drives emission, so the beat brightens the broad
    /// centre without flattening the falloff. It is generated once, has no file
    /// asset, and the modelled three-band tile remains the failure fallback.
    @MainActor
    static func danceFloor(flat: Bool) -> DanceFloor {
        let root = Entity()
        root.name = "Dansvloer"

        var tiles: [[(mesh: ModelEntity, dark: RealityKit.Material,
                      shadeStep: Int)]] = []
        let gradient = tileGradientTexture()
        let glowing = FeestLayout.floorLitColours.map { colour in
            (0...2).map { step in
                let shaded = Palette.occluded(colour, steps: step)
                if let gradient {
                    return tileGradientMaterial(shaded, texture: gradient,
                                                emission: glowPeak * floorGlow)
                }
                return lit(shaded, floorGlow)
            }
        }
        let size = FeestLayout.tileSize
        let slabMesh = FacetedMesh.mesh(
            FacetedMesh.box([size, FeestLayout.tileThickness, size]), flat: flat)
        let gradientMesh = gradient.map { _ in
            MeshResource.generatePlane(width: size, depth: size)
        }

        for row in 0..<FeestLayout.tilesPerSide {
            for column in 0..<FeestLayout.tilesPerSide {
                let colour = FeestLayout.tileColour(row: row, column: column)
                let spot = FeestLayout.tileSpot(row, column)
                var built: [(mesh: ModelEntity, dark: RealityKit.Material,
                             shadeStep: Int)] = []

                if let gradient, let gradientMesh {
                    let holder = Entity()
                    holder.name = "Tegel-\(row)-\(column)"
                    holder.position = [spot.x, RoomBox.floorY, spot.z]

                    let slab = ModelEntity(
                        mesh: slabMesh,
                        materials: [Palette.material(Palette.occluded(colour, steps: 1))])
                    slab.name = "TegelBlok"
                    slab.position.y = FeestLayout.tileThickness / 2
                    holder.addChild(slab)

                    let dark = tileGradientMaterial(colour, texture: gradient)
                    let top = ModelEntity(mesh: gradientMesh, materials: [dark])
                    top.name = "TegelVlak"
                    top.position.y = FeestLayout.tileThickness + 0.0002
                    holder.addChild(top)
                    holder.excludeFromShadowCasting()
                    root.addChild(holder)
                    built = [(top, dark, 0)]
                } else if flat, let modelled = ModelLibrary.load(
                    "dance-tile", tint: ["Tegel": colour]) {
                    // The model sits on its own floor, so it is placed by its
                    // base rather than by its middle.
                    modelled.position = [spot.x, RoomBox.floorY, spot.z]
                    modelled.name = "Tegel-\(row)-\(column)"
                    modelled.excludeFromShadowCasting()
                    root.addChild(modelled)
                    collectTileMeshes(modelled, into: &built)
                } else {
                    let material = Palette.material(colour)
                    let tile = ModelEntity(mesh: slabMesh, materials: [material])
                    tile.name = "Tegel-\(row)-\(column)"
                    tile.position = [
                        spot.x,
                        RoomBox.floorY + FeestLayout.tileThickness / 2,
                        spot.z,
                    ]
                    tile.excludeFromShadowCasting()
                    root.addChild(tile)
                    built = [(tile, material, 0)]
                }

                // A lit floor casting a shadow of itself onto the floor it is
                // lying on is the one shadow in this room that could only ever be
                // a stain. Same reasoning as `RoomBox.shell`.
                tiles.append(built)
            }
        }
        return DanceFloor(root: root, tiles: tiles, glowing: glowing)
    }

    @MainActor
    private static func tileGradientTexture() -> TextureResource? {
        let side = 128
        var pixels = [UInt8](repeating: 255, count: side * side * 4)

        for y in 0..<side {
            for x in 0..<side {
                let sx = abs((Double(x) + 0.5) / Double(side) * 2 - 1)
                let sy = abs((Double(y) + 0.5) / Double(side) * 2 - 1)
                // A high-order superellipse gives the plate's rectangular
                // contours without the mathematically sharp corners of max(x,y).
                let distance = pow(pow(sx, 8) + pow(sy, 8), 1.0 / 8.0)
                let t = max(0, min(1, (distance - 0.16) / 0.84))
                let smooth = t * t * (3 - 2 * t)
                let value = UInt8((255 * (1 - 0.22 * smooth)).rounded())
                let offset = (y * side + x) * 4
                pixels[offset] = value
                pixels[offset + 1] = value
                pixels[offset + 2] = value
            }
        }

        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
              let image = CGImage(
                width: side, height: side,
                bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: side * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: [.byteOrder32Big,
                             CGBitmapInfo(rawValue:
                                CGImageAlphaInfo.premultipliedLast.rawValue)],
                provider: provider, decode: nil, shouldInterpolate: true,
                intent: .defaultIntent)
        else { return nil }

        return try? TextureResource.generate(
            from: image, withName: "DanceTileRectangularGradient",
            options: .init(semantic: .color))
    }

    private static func tileGradientMaterial(
        _ colour: UIColorLike,
        texture: TextureResource,
        emission: Float = 0
    ) -> RealityKit.Material {
        let mapped = MaterialParameters.Texture(texture)
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: colour, texture: mapped)
        material.roughness = .init(floatLiteral: 0.9)
        material.metallic = .init(floatLiteral: 0)
        material.specular = .init(floatLiteral: 0.1)
        if emission > 0 {
            material.emissiveColor = .init(color: colour, texture: mapped)
            material.emissiveIntensity = emission
        }
        return material
    }

    /// Every mesh under a loaded tile, with the material the loader painted it.
    private static func collectTileMeshes(
        _ entity: Entity,
        into found: inout [(mesh: ModelEntity, dark: RealityKit.Material,
                            shadeStep: Int)]) {
        if let model = entity as? ModelEntity, let first = model.model?.materials.first {
            found.append((model, first, shadeStep(in: model.name)))
        }
        for child in entity.children { collectTileMeshes(child, into: &found) }
    }

    private static func shadeStep(in name: String) -> Int {
        guard let marker = name.range(of: "Shade", options: .backwards),
              marker.upperBound < name.endIndex,
              let step = Int(name[marker.upperBound...]) else { return 0 }
        return max(0, min(2, step))
    }

    // MARK: - The six pads

    struct Pad {
        let root: Entity
        /// The domed top, which is the part that lights when she hits it.
        let cap: ModelEntity
    }

    /// A squat cylinder with a domed glowing top, per
    /// `references/feest/knoppen.png`. She has to be able to see her finger land
    /// on it, so the cap is proud of the body rather than flush.
    static func pad(colour: UIColorLike, flat: Bool) -> Pad {
        let root = Entity()
        root.name = "Knop"

        let base = RoomBuilder.model(
            .prism(radius: FeestLayout.padGeometryRadius, height: FeestLayout.padHeight * 0.6,
                   sides: 8),
            Palette.creamLight, flat: flat, name: "KnopVoet")
        root.addChild(base)

        let cap = RoomBuilder.model(
            .dome(radius: FeestLayout.padGeometryRadius * 0.88,
                  height: FeestLayout.padHeight * 0.5, sides: 8, rings: 2),
            colour, flat: flat, name: "KnopKap")
        cap.position = [0, FeestLayout.padHeight * 0.6, 0]
        root.addChild(cap)

        return Pad(root: root, cap: cap)
    }

    // MARK: - The mirror ball

    struct MirrorBall {
        let root: Entity
        /// What spins. The cord does not.
        let ball: Entity
        /// Every tile, row-major. The room lights a rotating handful of these on
        /// the beat, which is the only thing about the ball that is not matte.
        let tiles: [ModelEntity]
        /// **Built once**, one per tile: what it wears when it is not catching
        /// the light.
        let dark: [RealityKit.Material]
        /// The one material a tile catching the light wears. There is only one,
        /// because a mirror tile with a lamp on it is white whatever it is
        /// painted underneath.
        let glowing: RealityKit.Material
    }

    // MARK: - The mirror ball's tiles

    static let ballRows = 7
    static let ballCols = 12
    /// How much of each tile's angular span is given up to the seam between it
    /// and its neighbours. The plate has a faint grout line and it is most of
    /// what makes the ball read as *tiled* rather than as faceted.
    private static let ballGrout: Float = 0.055
    private static let ballTileDepth: Float = 0.0022

    /// **The pale spread `references/feest/discobal.png` came back with.** Twelve
    /// tones rather than one, because a mirror ball whose tiles are all the same
    /// colour is a ball. Every one of them is already in the game.
    private static let ballTones: [UIColorLike] = [
        Palette.creamLight, Palette.cream, Palette.blushPink, Palette.rose,
        Palette.mintLight, Palette.mint, Palette.sage, Palette.lilac,
        Palette.berryBlue, Palette.butterYellow, Palette.sandyWood,
        Palette.blushPinkDeep,
    ]

    /// Deterministic, and deliberately not `random`: a ball that redealt its
    /// tiles every time the debug panel toggled flat shading would be a
    /// different ball each time. The multipliers are coprime with the row and
    /// column counts so the pattern does not fall into stripes or diagonals.
    private static func ballTone(row: Int, column: Int) -> UIColorLike {
        ballTones[(row * 5 + column * 7 + (row * column) % 11) % ballTones.count]
    }

    /// **One tile: a spherical quad with a little thickness.**
    ///
    /// Built as raw positions and indices rather than out of a `Shape`, because
    /// none of the primitives is a patch of a sphere — a box placed on the
    /// surface would not converge at the poles and would gap at the equator.
    ///
    /// Winding is counter-clockwise seen from outside, which `FacetedMesh`
    /// derives every normal from. The four side faces are the fiddly part: the
    /// obvious order (`a, b, b+4, a, b+4, a+4`) sends the top edge's normal
    /// *down*, so the seam faces are lit from inside the ball. Going round the
    /// other way is what makes them face out.
    ///
    /// At the top and bottom rows two corners coincide, so half the triangles
    /// are degenerate. `flatShaded` drops those rather than emitting NaNs, which
    /// is why a pole needs no special case.
    private static func ballTile(theta0: Float, theta1: Float,
                                 phi0: Float, phi1: Float,
                                 radius: Float) -> FacetedMesh.Geometry {
        func point(_ theta: Float, _ phi: Float, _ r: Float) -> SIMD3<Float> {
            [sin(theta) * cos(phi) * r, cos(theta) * r, sin(theta) * sin(phi) * r]
        }
        let corners = [(theta0, phi0), (theta0, phi1), (theta1, phi1), (theta1, phi0)]
        var p = corners.map { point($0.0, $0.1, radius) }
        p += corners.map { point($0.0, $0.1, radius - ballTileDepth) }

        var idx: [UInt32] = [0, 1, 2, 0, 2, 3,   // outer face
                             4, 6, 5, 4, 7, 6]   // inner face, wound the other way
        for i in 0..<4 {
            let a = UInt32(i), b = UInt32((i + 1) % 4)
            idx.append(contentsOf: [a, a + 4, b + 4, a, b + 4, b])
        }
        return (p, idx)
    }

    /// **A faceted sphere, and eight pools of light on the floor.**
    ///
    /// The ball itself is deliberately plain — a two-subdivision icosphere in
    /// cream, glowing gently. `references/feest/discobal.png` had to be told *no
    /// mirrored chrome, no metal reflections* to stay in the palette, and the
    /// finale plate, which was not, came back with a proper silver mirror ball
    /// that is the one thing in that picture off the direction. A chrome ball is
    /// not available in a style with no reflections in it, so **the spots do the
    /// work the mirror would have done.**
    ///
    /// The cord runs up past the wall tops and stops, because the room box has no
    /// ceiling (`references/REFERENCES.md` §1) and inventing a truss would put a
    /// surface between the camera and the room. What it runs into is the grey
    /// backdrop, which is the same thing the garden's fence shows over.
    static func mirrorBall(flat: Bool) -> MirrorBall {
        let root = Entity()
        root.name = "Discobal"
        root.position = FeestLayout.ballCentre

        let ball = Entity()
        ball.name = "DiscobalBol"
        root.addChild(ball)

        let radius = FeestLayout.ballRadius

        // **A core, so a seam never shows daylight.** The tiles stand off the
        // surface and have gaps between them; without something solid behind, the
        // ball is a colander seen against a grey backdrop.
        let core = RoomBuilder.model(.icosphere(radius: radius - ballTileDepth * 1.6,
                                                subdivisions: 1),
                                     Palette.cream, flat: flat, name: "DiscobalKern")
        ball.addChild(core)

        // **The tiles, and they are the whole prop.** It was one 320-face
        // icosphere painted a single glowing cream, with six 7 mm squares stuck
        // round the equator — which at this size is a smooth pale blob with
        // specks on it, and the owner called it (2026-08-17). What
        // `references/feest/discobal.png` actually shows is a **mosaic**: a
        // twelve-by-seven grid of small quads, each a different pale tone, with a
        // faint seam between them. That is the read, and it cannot come from one
        // mesh because one mesh has one material.
        // **One mesh per row, not one per tile.** Every tile in a row is the
        // same spherical quad turned about Y, so building it once and rotating
        // the entity takes the ball from 84 unique meshes to 7 — and 84 meshes
        // that cannot be batched is a real cost for a prop 60 mm across.
        var tiles: [ModelEntity] = []
        var dark: [RealityKit.Material] = []
        let span = 2 * Float.pi / Float(ballCols)
        for row in 0..<ballRows {
            let t0 = Float(row) / Float(ballRows) * .pi
            let t1 = Float(row + 1) / Float(ballRows) * .pi
            let dt = (t1 - t0) * ballGrout
            let dp = span * ballGrout
            let mesh = FacetedMesh.mesh(ballTile(theta0: t0 + dt, theta1: t1 - dt,
                                                 phi0: dp, phi1: span - dp,
                                                 radius: radius),
                                        flat: flat)
            for column in 0..<ballCols {
                let material = Palette.material(ballTone(row: row, column: column))
                dark.append(material)
                let tile = ModelEntity(mesh: mesh, materials: [material])
                tile.name = "Spiegeltje-\(row)-\(column)"
                tile.orientation = simd_quatf(angle: Float(column) * span, axis: [0, 1, 0])
                ball.addChild(tile)
                tiles.append(tile)
            }
        }

        // **The tiles are matte, and that is deliberate in a room made of light.**
        // The ball glowed before and that is exactly what turned it into a blob:
        // an emissive surface loses its own colour as it goes above white, so
        // every tile came back the same. A mirror ball is not a lamp — it is a
        // matte thing that *throws* light, and what it throws is
        // `ballSpots`. The room lights a rotating handful of tiles on the beat,
        // which is the sparkle, and the other eighty are shaded by their facets
        // like everything else in the game.

        // The ring it hangs from.
        let ring = RoomBuilder.model(.annulus(innerRadius: 0.0032, outerRadius: 0.0050,
                                              segments: 10),
                                     Palette.cream, flat: flat, name: "DiscobalRing")
        ring.position = [0, radius + 0.002, 0]
        root.addChild(ring)

        // **The cord runs up out of the frame, and 56 mm of it used to be
        // missing.** It stopped at y = 0.252, which is above the wall tops and
        // *inside the shot* — so it ended in mid-air and the ball read as
        // floating (owner, 2026-08-17). At this eye and a 26° vertical FOV a
        // point over the ball leaves the top of the frame at **y = 0.308**;
        // `FeestLayout.cordTopY` is well past that now, so where it comes from is
        // a question the picture never raises.
        let cordLength = FeestLayout.cordTopY - FeestLayout.ballCentre.y
        let cord = RoomBuilder.model(.box([0.0016, cordLength, 0.0016]),
                                     Palette.cream, flat: flat, name: "DiscobalKoord")
        cord.position = [0, radius + cordLength / 2, 0]
        root.addChild(cord)
        root.excludeFromShadowCasting()

        return MirrorBall(root: root, ball: ball, tiles: tiles, dark: dark,
                          glowing: lit(Palette.butterYellow, ballGlow))
    }

    /// The pools of light, built separately because they live on the **floor**
    /// rather than on the ball. Parented to their own node so one rotation moves
    /// all eight.
    static func ballSpots(flat: Bool) -> (root: Entity, spots: [ModelEntity]) {
        let root = Entity()
        root.name = "DiscobalVlekken"
        root.position = [FeestLayout.ballCentre.x,
                         FeestLayout.tileTopY + 0.0008,
                         FeestLayout.ballCentre.z]

        var spots: [ModelEntity] = []
        for i in 0..<FeestLayout.ballSpotCount {
            let angle = Float(i) / Float(FeestLayout.ballSpotCount) * 2 * .pi
            let colour = FeestLayout.discoColour(i)
            let geometry = FacetedMesh.prism(radius: FeestLayout.ballSpotRadius,
                                             height: 0.0006, sides: 10)
            let spot = ModelEntity(
                mesh: FacetedMesh.mesh(geometry, flat: flat),
                materials: [Palette.lightMaterial(colour, emission: colour,
                                                  intensity: glowPeak * 0.7, opacity: 0.55)])
            spot.name = "Vlek\(i)"
            spot.position = [cos(angle) * FeestLayout.ballSpotOrbit, 0,
                             sin(angle) * FeestLayout.ballSpotOrbit]
            spot.excludeFromShadowCasting()
            root.addChild(spot)
            spots.append(spot)
        }
        return (root, spots)
    }

    // MARK: - The light rig

    struct Lamp {
        let root: Entity
        /// What the beat recolours.
        let lens: ModelEntity
        /// What the beat squashes. **Not the same entity**: a loaded mesh's own
        /// transform belongs to the exporter, so scaling it scales about the
        /// prop's origin rather than the lens's. `ModelLibrary.pivot` hands back
        /// a holder standing where the lens stands, which is what a squash wants.
        let lensPivot: Entity
        let beam: ModelEntity
    }

    /// **Every colour a lamp can be, built once at build time.**
    ///
    /// Five lamps re-coloured on every beat is ten materials, and a
    /// `PhysicallyBasedMaterial` is not free to construct — it was ten of the 130
    /// the room was building twice a second. There are only six colours a lamp
    /// ever wears, so there only ever need to be twelve materials.
    static func lampMaterials() -> (lens: [RealityKit.Material], beam: [RealityKit.Material]) {
        let lens = FeestLayout.discoColours.map { lit($0) }
        let beam = FeestLayout.discoColours.map {
            Palette.lightMaterial($0, emission: $0, intensity: glowPeak * 0.5, opacity: 0.16)
        }
        return (lens, beam)
    }

    /// One stage lamp: a short faceted cone with a glowing lens, and a beam
    /// widening to a pool on the floor.
    ///
    /// **The beam is `Palette.lightMaterial`, which is the halo's material, not
    /// `Palette.waterMaterial`.** That distinction matters because
    /// `references/REFERENCES.md` bans transparency and `waterMaterial` is the one
    /// sanctioned exception to it — a beam is not a second exception. It is a
    /// *light*, and the halo already established that a light is a transparent
    /// emissive surface rather than a transparent coloured one.
    static func lamp(colour: UIColorLike, aimedAt target: SIMD3<Float>,
                     from origin: SIMD3<Float>, flat: Bool) -> Lamp {
        let root = Entity()
        root.name = "Lamp"
        root.position = origin
        // Point local −Y down the line to the target, so the housing, the lens
        // and the beam are one rotation rather than three.
        let down = simd_normalize(target - origin)
        root.orientation = simd_quatf(from: [0, -1, 0], to: down)

        // **The model needs no turn at all.** `models/stage-lamp.py` builds the
        // lantern looking down its own −Y — clamp straddling the bar, barrel
        // hanging under it — which is exactly the axis `root` has just been
        // rotated onto. The code version below turns its housing a further π
        // about X because a `FacetedMesh` lathe stands on +Y; a model built
        // pointing the right way does not.
        var lens: ModelEntity
        var lensPivot: Entity
        if flat, let modelled = ModelLibrary.load("stage-lamp",
                                                  tint: ["LampHuis": Palette.blushPink,
                                                         "LampLens": colour]),
           let mesh = ModelLibrary.mesh("LampLens", in: modelled),
           let pivot = ModelLibrary.pivot("LampLens", in: modelled) {
            root.addChild(modelled)
            mesh.model?.materials = [lit(colour)]
            lens = mesh
            lensPivot = pivot
        } else {
            let housing = RoomBuilder.model(
                .taperedPrism(bottomRadius: 0.0105, topRadius: 0.0068, height: 0.014, sides: 8),
                Palette.blushPink, flat: flat, name: "LampHuis")
            // The lathe stands on +Y, and local −Y is where it has to point.
            housing.orientation = simd_quatf(angle: .pi, axis: [1, 0, 0])
            housing.position = [0, 0.002, 0]
            root.addChild(housing)

            let built = RoomBuilder.model(.prism(radius: 0.0092, height: 0.0022, sides: 8),
                                          colour, flat: flat, name: "LampLens")
            built.model?.materials = [lit(colour)]
            built.position = [0, -0.014, 0]
            root.addChild(built)
            lens = built
            lensPivot = built
        }

        // **Narrow end first, and that is not obvious.** A `taperedPrism` puts
        // `bottomRadius` at y = 0, and the π turn about X below maps y = 0 to the
        // lens and y = +height to the floor — so the *bottom* radius is the end at
        // the lamp. Writing it the way it reads (wide at the bottom) builds a
        // beam that gets narrower the further it travels, which is a searchlight
        // seen from the wrong end.
        //
        // **And it is as long as the lamp is far away**, rather than a constant.
        // A fixed 175 mm was right for nothing: the three back lamps are 251 mm
        // from the spot they aim at and the two on the left wall are 294 mm, so
        // every beam in the room stopped between 75 and 120 mm above the floor
        // and hung there like a stalactite. What sells a beam is the *pool* at
        // the end of it landing on something.
        let reach = simd_distance(origin, target)
        let beamGeometry = FacetedMesh.taperedPrism(
            bottomRadius: FeestLayout.beamTopRadius,
            topRadius: FeestLayout.beamBottomRadius,
            height: max(0.02, reach - 0.017), sides: 8)
        let beam = ModelEntity(
            mesh: FacetedMesh.mesh(beamGeometry, flat: flat),
            materials: [Palette.lightMaterial(colour, emission: colour,
                                              intensity: glowPeak * 0.5, opacity: 0.16)])
        beam.name = "LampBundel"
        // The taper stands on +Y with its wide end at the bottom, and it has to
        // hang *down* from the lens with the wide end far away — so it is turned
        // over and pushed along −Y by its own length.
        beam.orientation = simd_quatf(angle: .pi, axis: [1, 0, 0])
        beam.position = [0, -0.015, 0]
        beam.excludeFromShadowCasting()
        root.addChild(beam)
        root.excludeFromShadowCasting()

        return Lamp(root: root, lens: lens, lensPivot: lensPivot, beam: beam)
    }

    /// The bar the lamps clamp on. Two of them, one per wall.
    ///
    /// **A round tube with a real bore**, from `models/light-bar.py` — the code
    /// version is `.box([length, 5 mm, 5 mm])`, a square batten, and every bar in
    /// `references/feest/lichtrek.png` is a round pastel-pink tube, not a pole.
    ///
    /// **It is the one prop in the game that is scaled on load**, which
    /// `models/README.md` otherwise forbids, and the exception is a geometric
    /// fact rather than a judgement: every facet on a tube's skin is a rectangle
    /// whose long edge runs down the axis, so lengthening it changes no angle, no
    /// normal and no silhouette. The two end annuli are perpendicular to the axis
    /// and do not scale at all. The alternative is a second 40-face file that
    /// differs in one number.
    static let lightBarLength: Float = 0.280

    static func lightBar(length: Float, flat: Bool) -> Entity {
        if flat, let modelled = ModelLibrary.load("light-bar",
                                                  tint: ["Lichtbalk": Palette.blushPink]) {
            modelled.scale = [length / lightBarLength, 1, 1]
            modelled.excludeFromShadowCasting()
            return modelled
        }
        let bar = RoomBuilder.model(.box([length, 0.005, 0.005]),
                                    Palette.blushPink, flat: flat, name: "Lichtbalk")
        bar.excludeFromShadowCasting()
        return bar
    }

    // MARK: - The DJ booth

    static func djPedestal(flat: Bool) -> Entity {
        RoomBuilder.model(
            .taperedPrism(
                bottomRadius: FeestLayout.djPedestalRadius,
                topRadius: FeestLayout.djPedestalRadius * 0.88,
                height: FeestLayout.djPedestalHeight,
                sides: 8),
            Palette.berryBlueDeep, flat: flat, name: "DJPodium")
    }

    struct Booth {
        let root: Entity
        /// The two platters, which turn on the beat.
        let decks: [Entity]
        /// The front panel, which is the room's biggest single emissive surface.
        let panel: ModelEntity
    }

    /// From `references/feest/dj-booth.png`: a low console, two flat round
    /// platters on the top, a small mixer between them, and one glowing panel
    /// across the front. The plate's knobs came back charcoal, which is off the
    /// palette; these are `woodBrown`, the darkest of the locked thirteen.
    static func booth(flat: Bool) -> Booth {
        let root = Entity()
        root.name = "DJBooth"
        root.position = [FeestLayout.boothCentre.x, RoomBox.floorY, FeestLayout.boothCentre.y]
        // The first build put the back rail towards the dance floor and left the
        // DJ standing against the lightbox side. Turn the complete console so he
        // stands behind its controls.
        root.orientation = simd_quatf(angle: .pi, axis: [0, 1, 0])

        if flat, let modelled = ModelLibrary.load("dj-booth", tint: boothTint),
           let panel = ModelLibrary.mesh("BoothPaneel", in: modelled) {
            root.addChild(modelled)
            // The room's biggest emissive surface. The loader paints everything
            // matte; this is the one mesh that is a light rather than a lit
            // thing, so it is overridden after the fact.
            panel.model?.materials = [lit(Palette.butterYellow, 0.8)]
            let decks = (0..<2).compactMap { ModelLibrary.pivot("Plaat\($0)", in: modelled) }
            return Booth(root: root, decks: decks, panel: panel)
        }
        return buildProceduralBooth(into: root, flat: flat)
    }

    /// Mesh name → palette colour for `models/dj-booth.py`.
    ///
    /// Matched by prefix, longest first, so `BoothKnop` can differ from
    /// `BoothKast` without either listing every knob. **The plate's charcoal
    /// knobs are `woodBrown` here**, which is the darkest of the locked thirteen
    /// — `dj-booth.png` puts them off-palette and `references/feest/README.md`
    /// already recorded the substitution.
    private static let boothTint: [String: UIColorLike] = [
        "BoothKast": Palette.berryBlue,
        "BoothVoet": Palette.berryBlueDeep,
        "BoothLijst": Palette.creamLight,
        "BoothPaneel": Palette.butterYellow,
        "BoothBlad": Palette.rose,
        "BoothRand": Palette.rose,
        "BoothStop": Palette.woodBrown,
        "BoothDek": Palette.berryBlue,
        "BoothMenger": Palette.berryBlue,
        "BoothScherm": Palette.woodBrown,
        "BoothKnop": Palette.woodBrown,
        "BoothFader": Palette.woodBrown,
        "BoothKanaal": Palette.creamLight,
        "BoothSchuif": Palette.woodBrown,
        "BoothLampje": Palette.rose,
        "Plaat": Palette.creamLight,
    ]

    /// The code-built console. See `booth(flat:)` for when it runs.
    private static func buildProceduralBooth(into root: Entity, flat: Bool) -> Booth {
        let size = FeestLayout.boothSize
        let height = FeestLayout.boothTopY - RoomBox.floorY

        let body = RoomBuilder.model(.box([size.x, height, size.y]),
                                     Palette.cream, flat: flat, name: "BoothKast")
        body.position = [0, height / 2, 0]
        root.addChild(body)

        // The top, in rose, standing a little proud all round so the console has
        // a lip — which is the detail that stops it reading as a sideboard.
        let top = RoomBuilder.model(.box([size.x + 0.006, 0.006, size.y + 0.006]),
                                    Palette.rose, flat: flat, name: "BoothBlad")
        top.position = [0, height + 0.003, 0]
        root.addChild(top)

        let panel = RoomBuilder.model(.box([size.x * 0.78, height * 0.52, 0.002]),
                                      Palette.butterYellow, flat: flat, name: "BoothPaneel")
        panel.model?.materials = [lit(Palette.butterYellow, 0.8)]
        panel.position = [0, height * 0.46, size.y / 2 + 0.001]
        root.addChild(panel)

        var decks: [Entity] = []
        for (i, dx) in [-FeestLayout.deckOffset, FeestLayout.deckOffset].enumerated() {
            let deck = Entity()
            deck.name = "Draaideck\(i)"
            deck.position = [dx, height + 0.006, 0]
            root.addChild(deck)

            let platter = RoomBuilder.model(
                .prism(radius: FeestLayout.deckRadius, height: 0.003, sides: 12),
                Palette.creamLight, flat: flat, name: "Plaat\(i)")
            deck.addChild(platter)

            // One mark on the rim, so a platter that is turning looks like it.
            let mark = RoomBuilder.model(.box([0.004, 0.0035, 0.008]),
                                         Palette.woodBrown, flat: flat, name: "PlaatMerk\(i)")
            mark.position = [0, 0.0006, FeestLayout.deckRadius * 0.6]
            deck.addChild(mark)

            decks.append(deck)
        }

        // The mixer between them: a small slab and four knobs.
        let mixer = RoomBuilder.model(.box([0.022, 0.005, 0.026]),
                                      Palette.mintLight, flat: flat, name: "Mengpaneel")
        mixer.position = [0, height + 0.0085, 0]
        root.addChild(mixer)
        for i in 0..<4 {
            let knob = RoomBuilder.model(.prism(radius: 0.0022, height: 0.003, sides: 6),
                                         Palette.woodBrown, flat: flat, name: "Knopje\(i)")
            knob.position = [Float(i % 2) * 0.010 - 0.005,
                             height + 0.011,
                             Float(i / 2) * 0.010 - 0.005]
            root.addChild(knob)
        }

        return Booth(root: root, decks: decks, panel: panel)
    }

    // MARK: - The speakers

    struct Speakers {
        let root: Entity
        /// The cones, which push in and out on the beat.
        let cones: [Entity]
    }

    /// **One modelled two-cabinet stack** — `models/speaker.py`, built from
    /// `references/feest/boxen.png` and measured off a 3× crop of it. Both
    /// cabinets share one AO bake, so the seam between them finally shades.
    ///
    /// **Takes its spot**, because there are two stacks — one in each back corner
    /// (owner, 2026-08-17). They are identical and they thump together; only the
    /// right-hand one is tappable, and `FeestLayout.speakerSpotFar` has why.
    ///
    /// ## What the model has that the code below does not
    ///
    /// The procedural version paints two pale discs on a plain brown box, and
    /// from across the room that is exactly what it reads as — owner, 2026-08-18,
    /// on seeing it in the game: *"that still looks like shit."* The plate has
    /// four things it cannot say, and `models/speaker.py` argues each:
    ///
    /// - **Every edge chamfered**, top and bottom rims included.
    /// - **A driver that stands proud of the baffle** as a raised boss, rather
    ///   than a disc lying on it.
    /// - **A deep funnel** behind a narrow rim lip.
    /// - **A dust cap that is a spherical cap standing on the throat**, which is
    ///   what puts a hard crease round it. A ball dropped into a cone cannot do
    ///   this at any size — there is always a height where the cone equals the
    ///   ball's radius, and the two blend into one dish.
    ///
    /// ## Two colours, because the plate has two
    ///
    /// `boxen.png` stacks a pale lavender cabinet on a peach one, and each is
    /// **one colour all over** — cone, surround and dust cap included. The code
    /// version painted the cone `creamLight` and the cap `woodBrown` against a
    /// `sandyWood` box, which is the clover's mistake (`models/README.md`): a
    /// tint standing in for a shape. With a real recess the facets do that job.
    static func speakers(at spot: SIMD3<Float>, flat: Bool) -> Speakers {
        let root = Entity()
        root.name = "Boxen"
        root.position = spot

        var cones: [Entity] = []
        if flat, let modelled = ModelLibrary.load(
            "speaker",
            tint: FeestAO.paintTints(["BoxOnder": Palette.sandyWood,
                                      "BoxBoven": Palette.lilac])) {
            root.addChild(modelled)
            for level in ["BoxOnder", "BoxBoven"] {
                for i in 0..<2 {
                    if let cone = driverPivot("\(level)Conus\(i)", in: modelled) {
                        cones.append(cone)
                    }
                }
            }
            return Speakers(root: root, cones: cones)
        }

        for level in 0..<2 {
            let y = Float(level) * (cabinetSize.y + 0.002)
            buildProceduralCabinet(into: root, level: level, y: y, flat: flat,
                                   cones: &cones)
        }
        return Speakers(root: root, cones: cones)
    }

    /// Put one driver — cone, dome and both of their baked shade meshes — on a
    /// single upright pivot, and hand the pivot back.
    ///
    /// **`ModelLibrary.pivot` cannot do this one**, and the reason is worth
    /// stating rather than working around silently: it collects a part by
    /// *exact* base name, which is right for the scale's pan and wrong here. A
    /// driver is two parts — e.g. `BoxOnderConus0` and
    /// `BoxOnderConus0Dop` — because
    /// `models/speaker.py` splits the dome out so the bake can darken the cone
    /// around it without darkening the dome. Matched exactly, the dome would be
    /// left behind on the baffle while its cone pushed out on the beat.
    ///
    /// So this matches by **prefix**. It is deliberately local to this file
    /// rather than a change to `ModelLibrary`: prefix matching is looser, and
    /// three other rooms rely on the exact-match behaviour.
    private static func driverPivot(_ prefix: String, in wrapper: Entity) -> Entity? {
        var family: [ModelEntity] = []
        collect(prefix, in: wrapper, into: &family)
        guard let first = family.first else { return nil }

        let holder = Entity()
        holder.name = prefix + "Pivot"
        holder.position = first.position(relativeTo: wrapper)
        wrapper.addChild(holder)
        for part in family {
            part.setParent(holder, preservingWorldTransform: true)
        }
        return holder
    }

    private static func collect(_ prefix: String, in entity: Entity,
                                into found: inout [ModelEntity]) {
        if let model = entity as? ModelEntity, model.model != nil,
           model.name.hasPrefix(prefix) {
            found.append(model)
        }
        for child in entity.children {
            collect(prefix, in: child, into: &found)
        }
    }

    /// The cabinet's envelope, kept in step with `models/speaker.py`.
    ///
    /// **42 × 56 × 30, where the code version was 44 × 38 × 30.** Every cabinet
    /// in `boxen.png` is taller than it is wide — 230 px across a 355 px face, a
    /// ratio of 0.65 — and the old box was the other way round at 1.16. A squat
    /// box with a small disc on it is most of why the built speaker did not look
    /// like the plate. Taken literally the plate gives a 68 mm cabinet; 56 keeps
    /// the stack just above a 102 mm guest without turning it into a tower.
    static let cabinetSize = SIMD3<Float>(0.042, 0.056, 0.030)

    /// The code-built cabinet. See `speakers(at:flat:)` for when it runs: the
    /// USDZ missing from the bundle, or the debug panel's flat-shading toggle
    /// turned off. A missing asset must not leave a dead patch of floor where a
    /// tap target was.
    private static func buildProceduralCabinet(into root: Entity, level: Int, y: Float,
                                               flat: Bool, cones: inout [Entity]) {
        let box = cabinetSize
        let colour = level == 0 ? Palette.sandyWood : Palette.lilac
        let cabinet = RoomBuilder.model(.box(box), colour, flat: flat,
                                        name: "Box\(level)")
        cabinet.position = [0, y + box.y / 2, 0]
        root.addChild(cabinet)

        for (i, spec) in [(Float(0.0158), Float(0.021)),
                          (Float(0.0058), Float(0.046))].enumerated() {
            let cone = Entity()
            cone.name = "Conus\(level)-\(i)"
            cone.position = [0, y + spec.1, box.z / 2 + 0.001]
            root.addChild(cone)

            let disc = RoomBuilder.model(
                .taperedPrism(bottomRadius: spec.0, topRadius: spec.0 * 0.45,
                              height: 0.004, sides: 12),
                colour, flat: flat, name: "ConusPlaat")
            disc.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
            cone.addChild(disc)

            let cap = RoomBuilder.model(.icosphere(radius: spec.0 * 0.30, subdivisions: 0),
                                        colour, flat: flat, name: "ConusDop")
            cap.position = [0, 0, -0.0035]
            cone.addChild(cap)

            cones.append(cone)
        }
    }

    // MARK: - The cake table

    /// A pedestal table, from `references/feest/taarttafel.png`. Round, because
    /// the cake is round and because a round table has no corner for a guest to
    /// stand behind.
    static func cakeTable(flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Feesttafel"
        root.position = [FeestLayout.tableCentre.x, RoomBox.floorY, FeestLayout.tableCentre.y]

        let foot = RoomBuilder.model(
            .taperedPrism(bottomRadius: FeestLayout.tableFootRadius,
                          topRadius: FeestLayout.tableFootRadius * 0.7,
                          height: 0.008, sides: 10),
            Palette.rose, flat: flat, name: "TafelVoet")
        root.addChild(foot)

        let stemHeight = FeestLayout.tableTopY - RoomBox.floorY
            - FeestLayout.tableTopThickness - 0.008
        let stem = RoomBuilder.model(
            .prism(radius: FeestLayout.tableStemRadius, height: stemHeight, sides: 8),
            Palette.rose, flat: flat, name: "TafelPoot")
        stem.position = [0, 0.008, 0]
        root.addChild(stem)

        let top = RoomBuilder.model(
            .prism(radius: FeestLayout.tableRadius, height: FeestLayout.tableTopThickness,
                   sides: 12),
            Palette.blushPink, flat: flat, name: "TafelBlad")
        top.position = [0, FeestLayout.tableTopY - RoomBox.floorY
                            - FeestLayout.tableTopThickness, 0]
        root.addChild(top)

        return root
    }

    // MARK: - Toys

    /// The confetti popper, from `references/feest/knaller.png`: a short wide cone
    /// standing on its narrow end, with a knob on top.
    static func popper(flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Knaller"
        root.position = FeestLayout.popperSpot

        let cone = RoomBuilder.model(
            .taperedPrism(bottomRadius: 0.009, topRadius: 0.018, height: 0.030, sides: 8),
            Palette.blushPinkDeep, flat: flat, name: "KnallerKegel")
        root.addChild(cone)

        let band = RoomBuilder.model(.prism(radius: 0.0195, height: 0.004, sides: 8),
                                     Palette.mintLight, flat: flat, name: "KnallerRand")
        band.position = [0, 0.028, 0]
        root.addChild(band)

        let knob = RoomBuilder.model(.icosphere(radius: 0.005, subdivisions: 0),
                                     Palette.butterYellow, flat: flat, name: "KnallerKnop")
        knob.position = [0, 0.036, 0]
        root.addChild(knob)

        return root
    }

    /// The balloon, from `references/feest/ballon.png`. A lathe rather than a
    /// sphere, because a balloon is a teardrop and a sphere on a string is a
    /// ball on a string.
    static func balloon(flat: Bool) -> Entity {
        let root = Entity()
        root.name = "Ballon"
        root.position = FeestLayout.balloonHome

        let skin = RoomBuilder.model(
            .lathe(profile: [[0, -0.020], [0.006, -0.016], [0.013, -0.006],
                             [0.014, 0.004], [0.009, 0.012], [0, 0.016]],
                   sides: 10),
            Palette.rose, flat: flat, name: "BallonVel")
        root.addChild(skin)

        let knot = RoomBuilder.model(.lathe(profile: [[0, -0.026], [0.0035, -0.021],
                                                      [0, -0.019]], sides: 6),
                                     Palette.blushPinkDeep, flat: flat, name: "BallonKnoop")
        root.addChild(knot)

        let string = RoomBuilder.model(.box([0.0012, 0.040, 0.0012]),
                                       Palette.creamLight, flat: flat, name: "BallonTouw")
        string.position = [0, -0.046, 0]
        root.addChild(string)
        root.excludeFromShadowCasting()

        return root
    }

    // MARK: - Confetti

    /// **Flat angular scraps, not sparkles.** `Sparkles.burst` throws five-point
    /// stars and is the game's reward vocabulary; confetti is *stuff*, the way
    /// flour is, and it wants to be paper. Small boxes at six colours, tumbling.
    @MainActor
    static func confetti(at position: SIMD3<Float>, in parent: Entity,
                         ticker: Ticker, count: Int = 26, flat: Bool = true) {
        for i in 0..<count {
            let colour = FeestLayout.discoColour(i)
            let scrap = RoomBuilder.model(.box([0.0042, 0.0007, 0.0030]),
                                          colour, flat: flat, name: "Confetti")
            scrap.position = position
            scrap.excludeFromShadowCasting()
            parent.addChild(scrap)

            let angle = Float.random(in: 0..<(2 * .pi))
            let spread = Float.random(in: 0.2...1.0)
            var velocity = SIMD3<Float>(cos(angle) * spread,
                                        Float.random(in: 0.9...1.6),
                                        sin(angle) * spread) * 0.13
            let spin = simd_quatf(angle: Float.random(in: 3...9),
                                  axis: simd_normalize(SIMD3<Float>(
                                    Float.random(in: -1...1),
                                    Float.random(in: -1...1),
                                    Float.random(in: -1...1))))
            let lifetime = Float.random(in: 1.6...2.6)
            var age: Float = 0

            ticker.add { [weak scrap] dt in
                guard let scrap else { return false }
                age += dt
                guard age < lifetime else {
                    scrap.removeFromParent()
                    return false
                }
                // Paper falls slowly and drifts, where a sparkle drops.
                velocity.y -= 0.10 * dt
                velocity.x *= 1 - 0.9 * dt
                velocity.z *= 1 - 0.9 * dt
                scrap.position += velocity * dt
                let identity = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
                scrap.orientation = simd_slerp(identity, spin, min(1, age / lifetime))
                return true
            }
        }
    }
}
