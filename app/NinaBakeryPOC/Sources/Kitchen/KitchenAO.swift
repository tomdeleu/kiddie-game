import Foundation
import RealityKit
import simd

/// De Keuken's measured room-scale ambient occlusion.
///
/// `models/keuken-scene.py` found that a longer bake on the imported props
/// reaches the wrong part of the image: most missing depth is the table, Otto
/// and wall furniture against the three broad shell surfaces. A facet cannot
/// hold that answer — each wall and the floor are one quad — so the measured
/// route is one planar AO map per visible shell face.
///
/// These planes replace only the shell's visible skin. They still receive the
/// live key shadow, while `excludeFromShadowCasting()` keeps them from adding a
/// second architectural shadow. If any texture is missing the whole overlay is
/// omitted and `RoomBox.shell` remains the complete fallback.
enum KitchenAO {

    static func shellOverlay() -> Entity? {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-no-kitchen-ao") {
            return nil
        }
        #endif
        guard let floorTexture = load("KeukenFloorAO"),
              let backTexture = load("KeukenBackWallAO"),
              let leftTexture = load("KeukenLeftWallAO") else { return nil }

        let root = Entity()
        root.name = "KitchenAO"

        let floor = ModelEntity(
            mesh: .generatePlane(width: RoomBox.roomSize, depth: RoomBox.roomSize),
            materials: [material(Palette.blushPink, texture: floorTexture)])
        floor.name = "KitchenAOFloor"
        floor.position = [0, RoomBox.floorY + 0.0002, 0]
        root.addChild(floor)

        let wallMesh = MeshResource.generatePlane(width: RoomBox.roomSize,
                                                  height: RoomBox.wallHeight)
        let back = ModelEntity(
            mesh: wallMesh,
            materials: [material(Palette.creamLight, texture: backTexture)])
        back.name = "KitchenAOBackWall"
        back.position = [0,
                         RoomBox.wallHeight / 2,
                         -RoomBox.half + RoomBox.wallThickness + 0.0002]
        root.addChild(back)

        let left = ModelEntity(
            mesh: wallMesh,
            materials: [material(Palette.cream, texture: leftTexture)])
        left.name = "KitchenAOLeftWall"
        left.position = [-RoomBox.half + RoomBox.wallThickness + 0.0002,
                         RoomBox.wallHeight / 2,
                         0]
        left.orientation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
        root.addChild(left)

        root.excludeFromShadowCasting()
        return root
    }

    private static func load(_ name: String) -> TextureResource? {
        try? TextureResource.load(named: name)
    }

    private static func material(_ colour: UIColorLike,
                                 texture: TextureResource) -> RealityKit.Material {
        var material = PhysicallyBasedMaterial()
        // The bundled texture is already calibrated to `1 - 0.55·AO`, so
        // multiplying it into the tint is the same diffuse response as the
        // material's AO slot. It deliberately goes through base colour:
        // `LightingRig` clears the AO slot whenever the global lightmap debug
        // switch is off, which would erase this kitchen-authored map immediately
        // after the room was built.
        material.baseColor = .init(tint: colour, texture: .init(texture))
        material.roughness = .init(floatLiteral: 0.9)
        material.metallic = .init(floatLiteral: 0)
        material.specular = .init(floatLiteral: 0.1)
        return material
    }
}
