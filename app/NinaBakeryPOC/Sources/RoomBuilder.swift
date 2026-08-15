import RealityKit
import simd

/// Builds the kitchen room box procedurally, matching
/// `references/plates/03-kitchen-roombox.png`.
///
/// Procedural rather than imported on purpose. The style is primitives —
/// boxes, prisms, faceted spheres — so code is a faster loop than a modelling
/// round-trip, and it removes the asset pipeline from the one question this
/// POC exists to answer. `RoomSource.importedUSDZ` covers the other path, and
/// is what the lightmap mode needs (see `LIGHTMAPS.md`).
enum RoomBuilder {

    /// Room box is 0.4 m across, per `POC.md`.
    static let roomSize: Float = 0.4
    static let wallHeight: Float = 0.22
    static let wallThickness: Float = 0.012
    static let slabThickness: Float = 0.014

    static func build(flat: Bool) -> Entity {
        let root = Entity()
        root.name = "RoomRoot"

        let half = roomSize / 2

        // Base slab — the footing every room sits on, from the cottage plate.
        let slab = model(.box([roomSize + 0.03, slabThickness, roomSize + 0.03]),
                         Palette.cream, flat: flat, name: "Slab")
        slab.position = [0, -slabThickness / 2, 0]
        root.addChild(slab)

        // Floor.
        let floor = model(.box([roomSize, 0.004, roomSize]),
                          Palette.blushPink, flat: flat, name: "Floor")
        floor.position = [0, 0.002, 0]
        root.addChild(floor)

        // Two walls, open on the two near sides.
        let backWall = model(.box([roomSize, wallHeight, wallThickness]),
                             Palette.creamLight, flat: flat, name: "WallBack")
        backWall.position = [0, wallHeight / 2, -half + wallThickness / 2]
        root.addChild(backWall)

        let leftWall = model(.box([wallThickness, wallHeight, roomSize]),
                             Palette.cream, flat: flat, name: "WallLeft")
        leftWall.position = [-half + wallThickness / 2, wallHeight / 2, 0]
        root.addChild(leftWall)

        root.addChild(buildOven(flat: flat))
        root.addChild(buildTable(flat: flat))
        root.addChild(buildShelf(flat: flat, height: 0.15, x: -half + 0.02))
        root.addChild(buildShelf(flat: flat, height: 0.105, x: -half + 0.02))

        return root
    }

    // MARK: - Props

    /// Faceted dome plus an arch, per `references/props/oven.png`.
    static func buildOven(flat: Bool) -> Entity {
        let oven = Entity()
        oven.name = "Oven"
        oven.position = [0.09, 0.004, -0.10]

        let dome = model(.dome(radius: 0.062, height: 0.075, sides: 8, rings: 4),
                         Palette.mint, flat: flat, name: "OvenDome")
        oven.addChild(dome)

        // Arch: a shallow ring of blocks reads as an opening at this scale and
        // stays honest to the low-poly count.
        let arch = Entity()
        arch.name = "OvenArch"
        let segments = 7
        for i in 0..<segments {
            let t = Float(i) / Float(segments - 1)
            let angle = .pi * t
            let r: Float = 0.036
            let block = model(.box([0.012, 0.016, 0.012]),
                              Palette.rose, flat: flat, name: "ArchBlock\(i)")
            block.position = [cos(angle) * r, sin(angle) * r + 0.002, 0.058]
            block.orientation = simd_quatf(angle: angle - .pi / 2, axis: [0, 0, 1])
            arch.addChild(block)
        }
        oven.addChild(arch)

        // Dark opening behind the arch.
        let mouth = model(.box([0.052, 0.040, 0.010]),
                          Palette.woodBrown, flat: flat, name: "OvenMouth")
        mouth.position = [0, 0.020, 0.052]
        oven.addChild(mouth)

        let chimney = model(.prism(radius: 0.011, height: 0.045, sides: 4),
                            Palette.creamLight, flat: flat, name: "Chimney")
        chimney.position = [0.028, 0.058, -0.030]
        oven.addChild(chimney)

        return oven
    }

    static func buildTable(flat: Bool) -> Entity {
        let table = Entity()
        table.name = "Table"
        table.position = [-0.055, 0.004, 0.045]

        let topY: Float = 0.062
        let top = model(.box([0.135, 0.012, 0.085]),
                        Palette.sandyWood, flat: flat, name: "TableTop")
        top.position = [0, topY, 0]
        table.addChild(top)

        for (i, offset) in [SIMD2<Float>(-0.055, -0.030), [0.055, -0.030],
                            [-0.055, 0.030], [0.055, 0.030]].enumerated() {
            let leg = model(.box([0.012, topY, 0.012]),
                            Palette.sandyWood, flat: flat, name: "TableLeg\(i)")
            leg.position = [offset.x, topY / 2, offset.y]
            table.addChild(leg)
        }
        return table
    }

    static func buildShelf(flat: Bool, height: Float, x: Float) -> Entity {
        let shelf = Entity()
        shelf.name = "Shelf\(Int(height * 1000))"

        let plank = model(.box([0.014, 0.008, 0.150]),
                          Palette.sandyWood, flat: flat, name: "ShelfPlank")
        plank.position = [x + 0.007, height, -0.03]
        shelf.addChild(plank)

        // Three jars, not six — the style wants fewer, bigger props.
        let jarColours = [Palette.mint, Palette.creamLight, Palette.blushPinkDeep]
        for (i, colour) in jarColours.enumerated() {
            let z = Float(-0.085) + Float(i) * 0.045
            let jar = model(.prism(radius: 0.010, height: 0.022, sides: 8),
                            colour, flat: flat, name: "Jar\(Int(height * 1000))_\(i)")
            jar.position = [x + 0.007, height + 0.004, z]
            shelf.addChild(jar)

            let lid = model(.prism(radius: 0.011, height: 0.005, sides: 8),
                            Palette.rose, flat: flat, name: "JarLid\(Int(height * 1000))_\(i)")
            lid.position = [x + 0.007, height + 0.026, z]
            shelf.addChild(lid)
        }
        return shelf
    }

    /// The two draggables and the bowl from `POC.md` Stage B. Kept separate
    /// from the room so they can carry contact shadows and, later, gestures.
    static func buildLooseProps(flat: Bool) -> [Entity] {
        let bowl = model(.taperedPrism(bottomRadius: 0.020, topRadius: 0.030,
                                       height: 0.024, sides: 12),
                         Palette.blushPink, flat: flat, name: "Bowl")
        bowl.position = [-0.055, 0.070, 0.045]

        let egg = model(.icosphere(radius: 0.011, subdivisions: 1),
                        Palette.creamLight, flat: flat, name: "Egg")
        egg.position = [-0.105, 0.079, 0.070]

        let berry = model(.icosphere(radius: 0.010, subdivisions: 1),
                          Palette.rose, flat: flat, name: "Berry")
        berry.position = [-0.010, 0.078, 0.068]

        return [bowl, egg, berry]
    }

    // MARK: - Helpers

    /// Geometry cases, so a prop is defined once and rebuilt in either shading
    /// mode when the debug toggle flips.
    enum Shape {
        case box(SIMD3<Float>)
        case prism(radius: Float, height: Float, sides: Int)
        case taperedPrism(bottomRadius: Float, topRadius: Float, height: Float, sides: Int)
        case icosphere(radius: Float, subdivisions: Int)
        case dome(radius: Float, height: Float, sides: Int, rings: Int)

        var geometry: FacetedMesh.Geometry {
            switch self {
            case .box(let size):
                return FacetedMesh.box(size)
            case .prism(let r, let h, let s):
                return FacetedMesh.prism(radius: r, height: h, sides: s)
            case .taperedPrism(let br, let tr, let h, let s):
                return FacetedMesh.taperedPrism(bottomRadius: br, topRadius: tr, height: h, sides: s)
            case .icosphere(let r, let sub):
                return FacetedMesh.icosphere(radius: r, subdivisions: sub)
            case .dome(let r, let h, let s, let rings):
                return FacetedMesh.dome(radius: r, height: h, sides: s, rings: rings)
            }
        }
    }

    static func model(_ shape: Shape, _ colour: UIColorLike,
                      flat: Bool, name: String) -> ModelEntity {
        let mesh = FacetedMesh.mesh(shape.geometry, flat: flat)
        let entity = ModelEntity(mesh: mesh, materials: [Palette.material(colour)])
        entity.name = name
        return entity
    }
}
