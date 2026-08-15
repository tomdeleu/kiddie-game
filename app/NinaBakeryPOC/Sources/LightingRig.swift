import RealityKit
import simd

/// Owns every light in the scene and rebuilds them from `LightingSettings`.
///
/// This is the thing the debug panel drives. It is deliberately the *only*
/// place lights are created, so "what is lighting this scene" has one answer.
@MainActor
final class LightingRig {

    private let keyLight = Entity()
    private let fillLight = Entity()
    private let iblAnchor = Entity()

    /// Set once at load. If no environment asset is bundled the IBL toggle
    /// stays disabled rather than silently doing nothing — see `iblAvailable`.
    private(set) var environment: EnvironmentResource?
    var iblAvailable: Bool { environment != nil }

    /// Baked lightmaps, if any have been produced in Reality Composer Pro 3
    /// and dropped into the bundle. Absent by default — that is the point of
    /// the exercise, not an oversight.
    private(set) var aoLightmap: TextureResource?
    private(set) var beautyLightmap: TextureResource?
    var lightmapsAvailable: Bool { aoLightmap != nil || beautyLightmap != nil }

    func install(in root: Entity) {
        keyLight.name = "KeyLight"
        fillLight.name = "FillLight"
        iblAnchor.name = "IBLAnchor"
        root.addChild(keyLight)
        root.addChild(fillLight)
        root.addChild(iblAnchor)
    }

    /// Load optional assets. Everything here is allowed to be missing.
    func loadOptionalAssets() async {
        environment = try? await EnvironmentResource(named: "StudioNeutral")
        aoLightmap = try? await TextureResource(named: "Lightmap_AO")
        beautyLightmap = try? await TextureResource(named: "Lightmap_Beauty")
    }

    // MARK: - Applying settings

    func apply(_ s: LightingSettings, to sceneRoot: Entity) {
        applyKey(s)
        applyFill(s)
        applyIBL(s, to: sceneRoot)
        applyLightmap(s, to: sceneRoot)
    }

    private func applyKey(_ s: LightingSettings) {
        guard s.keyEnabled else {
            keyLight.components.remove(DirectionalLightComponent.self)
            keyLight.components.remove(DirectionalLightComponent.Shadow.self)
            return
        }

        let light = DirectionalLightComponent(
            color: colour(kelvin: s.keyTemperature),
            intensity: s.keyIntensity
        )
        keyLight.components.set(light)

        if s.shadowsEnabled {
            // The grounding shadow. This is what replaces AO's main job, and
            // unlike a bake it stays correct when a prop moves.
            // If this initialiser does not resolve on your SDK, check the
            // current `DirectionalLightComponent.Shadow` signature — it is the
            // one API here most likely to have moved.
            keyLight.components.set(DirectionalLightComponent.Shadow())
        } else {
            keyLight.components.remove(DirectionalLightComponent.Shadow.self)
        }

        aim(keyLight, along: s.keyDirection)
    }

    private func applyFill(_ s: LightingSettings) {
        guard s.fillEnabled else {
            fillLight.components.remove(DirectionalLightComponent.self)
            return
        }
        let light = DirectionalLightComponent(
            color: colour(kelvin: s.fillTemperature),
            intensity: s.fillIntensity
        )
        fillLight.components.set(light)
        // Never a shadow caster — a second shadow immediately reads as wrong.
        fillLight.components.remove(DirectionalLightComponent.Shadow.self)
        aim(fillLight, along: s.fillDirection)
    }

    private func applyIBL(_ s: LightingSettings, to sceneRoot: Entity) {
        guard s.iblEnabled, let environment else {
            iblAnchor.components.remove(ImageBasedLightComponent.self)
            sceneRoot.components.remove(ImageBasedLightReceiverComponent.self)
            return
        }
        iblAnchor.components.set(
            ImageBasedLightComponent(source: .single(environment),
                                     intensityExponent: s.iblIntensity)
        )
        sceneRoot.components.set(
            ImageBasedLightReceiverComponent(imageBasedLight: iblAnchor)
        )
    }

    /// The Reality Composer Pro 3 exploration.
    ///
    /// Runtime cannot bake — this only *applies* a map baked beforehand. AO
    /// goes into the material's occlusion slot; beauty replaces base colour
    /// outright, which is why it kills real-time light response.
    private func applyLightmap(_ s: LightingSettings, to sceneRoot: Entity) {
        sceneRoot.forEachModel { model in
            guard var material = model.model?.materials.first as? PhysicallyBasedMaterial
            else { return }

            switch s.lightmapMode {
            case .off:
                // Fully unoccluded — the direction's default.
                material.ambientOcclusion = .init(scale: 1.0)
            case .ambientOcclusion:
                if let aoLightmap {
                    material.ambientOcclusion = .init(texture: .init(aoLightmap))
                }
            case .beauty:
                if let beautyLightmap {
                    material.baseColor = .init(tint: .white,
                                               texture: .init(beautyLightmap))
                }
            }
            model.model?.materials = [material]
        }
    }

    // MARK: - Helpers

    /// Orient an entity so its −Z axis (RealityKit's light direction) points
    /// along `direction`. Using `look(at:from:)` avoids hand-rolling a
    /// quaternion, which is where sign errors live.
    private func aim(_ entity: Entity, along direction: SIMD3<Float>) {
        let distance: Float = 2.0
        let position = -direction * distance
        entity.look(at: .zero, from: position, relativeTo: nil)
    }

    /// Rough blackbody approximation, good enough for a warm/cool slider.
    private func colour(kelvin: Float) -> UIColorLike {
        let t = max(1000, min(12000, kelvin)) / 100
        var r, g, b: Float

        if t <= 66 {
            r = 255
            g = 99.4708025861 * log(max(t, 1)) - 161.1195681661
        } else {
            r = 329.698727446 * pow(t - 60, -0.1332047592)
            g = 288.1221695283 * pow(t - 60, -0.0755148492)
        }
        if t >= 66 {
            b = 255
        } else if t <= 19 {
            b = 0
        } else {
            b = 138.5177312231 * log(t - 10) - 305.0447927307
        }

        func clamp(_ v: Float) -> Double { Double(max(0, min(255, v)) / 255) }
        return UIColorLike(red: clamp(r), green: clamp(g), blue: clamp(b), opacity: 1)
    }
}

extension Entity {
    /// Depth-first walk over every `ModelEntity` in the subtree.
    func forEachModel(_ body: (ModelEntity) -> Void) {
        if let model = self as? ModelEntity { body(model) }
        for child in children { child.forEachModel(body) }
    }
}
