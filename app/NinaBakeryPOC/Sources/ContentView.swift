import SwiftUI
import RealityKit

struct ContentView: View {
    @StateObject private var settings = LightingSettings()
    @StateObject private var scene = SceneModel()

    var body: some View {
        ZStack(alignment: .topTrailing) {
            backdrop
            roomView
            DebugPanel(settings: settings,
                       iblAvailable: scene.rig.iblAvailable,
                       lightmapsAvailable: scene.rig.lightmapsAvailable)
        }
        .ignoresSafeArea()
    }

    private var backdrop: some View {
        // Matches the plates' studio grey. Toggleable, because a backdrop that
        // flatters the room is exactly the kind of thing that hides a problem.
        Group {
            if settings.showBackdrop {
                Color(Palette.backdropGrey)
            } else {
                Color.black
            }
        }
    }

    private var roomView: some View {
        RealityView { content in
            content.add(scene.root)
            scene.build(settings: settings)
            await scene.rig.loadOptionalAssets()
            scene.rig.apply(settings, to: scene.sceneRoot)
        } update: { _ in
            scene.rebuildIfNeeded(settings: settings)
            scene.rig.apply(settings, to: scene.sceneRoot)
            scene.refreshContactShadows(settings: settings)
        }
        // No `.id(...)` here on purpose: changing it would tear down and
        // rebuild the whole RealityView, re-parenting an already-parented
        // root. `rebuildIfNeeded` handles source and shading changes instead.
        // `settings` is observed, so any change re-runs `update` above.
    }
}

/// Holds the entity graph across SwiftUI updates.
///
/// Kept out of the view so a slider drag does not rebuild meshes — only the
/// flat/smooth toggle and the room source do, and those are tracked explicitly.
@MainActor
final class SceneModel: ObservableObject {
    let root = Entity()
    let sceneRoot = Entity()
    let rig = LightingRig()

    private var looseProps: [Entity] = []
    private var builtFlat: Bool?
    private var builtSource: LightingSettings.RoomSource?

    init() {
        root.addChild(sceneRoot)
        rig.install(in: root)
        installCamera()
    }

    /// Fixed isometric three-quarter angle. Never moved by the player — see
    /// `CONCEPT.md` §9.4. Here it is also never moved by the developer, so a
    /// lighting change is judged from the framing the game will actually use.
    private func installCamera() {
        let camera = PerspectiveCamera()
        camera.camera.fieldOfViewInDegrees = 26
        // Classic isometric-ish: equal on two axes, raised, looking at centre.
        let distance: Float = 0.95
        let position = SIMD3<Float>(distance * 0.62, distance * 0.60, distance * 0.62)
        camera.look(at: [0, 0.06, 0], from: position, relativeTo: nil)
        root.addChild(camera)
    }

    func build(settings: LightingSettings) {
        rebuild(settings: settings)
    }

    func rebuildIfNeeded(settings: LightingSettings) {
        guard builtFlat != settings.flatShading || builtSource != settings.roomSource else {
            return
        }
        rebuild(settings: settings)
    }

    private func rebuild(settings: LightingSettings) {
        sceneRoot.children.removeAll()
        looseProps.removeAll()

        switch settings.roomSource {
        case .procedural:
            sceneRoot.addChild(RoomBuilder.build(flat: settings.flatShading))
            for prop in RoomBuilder.buildLooseProps(flat: settings.flatShading) {
                sceneRoot.addChild(prop)
                looseProps.append(prop)
            }
        case .importedUSDZ:
            if let room = try? Entity.load(named: "KitchenRoom") {
                sceneRoot.addChild(room)
            } else {
                // No USDZ bundled yet — fall back rather than showing nothing,
                // and say so in the entity name for the debugger.
                let placeholder = RoomBuilder.build(flat: settings.flatShading)
                placeholder.name = "RoomRoot (USDZ missing — procedural fallback)"
                sceneRoot.addChild(placeholder)
            }
        }

        builtFlat = settings.flatShading
        builtSource = settings.roomSource
        refreshContactShadows(settings: settings)
    }

    func refreshContactShadows(settings: LightingSettings) {
        for prop in looseProps {
            ContactShadows.attach(to: prop, radius: radius(for: prop), settings: settings)
            // The two known surfaces in this scene: table top and floor.
            let surfaceY: Float = prop.position.y > 0.05 ? 0.070 : 0.004
            ContactShadows.update(for: prop, surfaceY: surfaceY, settings: settings)
        }
    }

    private func radius(for prop: Entity) -> Float {
        switch prop.name {
        case "Bowl": return 0.030
        case "Egg": return 0.012
        case "Berry": return 0.011
        default: return 0.015
        }
    }
}
