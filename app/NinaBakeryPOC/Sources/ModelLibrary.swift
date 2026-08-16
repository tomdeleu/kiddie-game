import Foundation
import RealityKit

/// USDZ props modelled in Blender, loaded out of the app bundle.
///
/// **This is the second way to make a prop.** Everything else in the room is
/// built in code by `FacetedMesh` — a profile, a side count, and the mesh comes
/// out the other end. That is fast to tune and costs nothing to ship, but it
/// can only make what the shape vocabulary already knows how to make, and cloth
/// is not on that list: the flour sack's pinched neck and fanned collar were
/// four stacked lathes pretending to be one object.
///
/// The Blender route buys shapes the vocabulary cannot express, at the cost of
/// a round trip through a file. The sources live in `models/` at the repo root
/// and are re-exported into `Resources/Models/` — see `models/README.md`.
///
/// Three rules keep an imported model on style:
///
/// - **The palette wins.** Whatever material Blender wrote is thrown away on
///   load and replaced with `Palette.material`. The colours the exporter
///   carries are close but not identical, they are not matte the way the room
///   is matte, and a second source of truth for a palette colour is how a
///   pastel drifts. `tint` maps a mesh name to the colour it should be.
/// - **Facets, not smoothing.** The export authors one normal per face and no
///   subdivision scheme. The mesh arrives flat-shaded and stays that way.
/// - **Game scale, Y-up, origin on the floor.** A prop is modelled at the size
///   it is used at, so `position` alone places it. Nothing is scaled on load.
enum ModelLibrary {

    /// Loaded files, keyed by name. A round rebuilds its props, and reading a
    /// USDZ off disk to build the same sack again is work with a known answer.
    private static var cache: [String: Entity] = [:]

    /// Load `name.usdz` and return a fresh copy of it, or `nil` if it is not
    /// in the bundle or will not parse.
    ///
    /// **Returning `nil` is a real outcome, not a failure to handle later.**
    /// Every caller has a procedural prop to fall back on, because a missing
    /// asset must not leave a hole where a tap target was — a dead patch of
    /// floor is exactly the "every tap does something" rule broken.
    ///
    /// **What comes back is a wrapper, not the file's own root.** The exporter
    /// writes the Blender Z-up to USDZ Y-up conversion as a rotation on the
    /// root prim, and `Ticker.squash` scales a prop along its own local Y — on
    /// a rotated root that is world Z, so a tap would squash the prop sideways.
    /// The wrapper is upright and identity, so an imported prop animates like
    /// any other. This is the single place that has to know, which is why the
    /// wrapping lives here and not at the two call sites.
    ///
    /// - Parameter tint: mesh name → palette colour. Matched by prefix, longest
    ///   first, so `BosbesCrown` can differ from `Bosbes`.
    /// - Parameter material: how a colour becomes a surface. The default is the
    ///   room's matte one; the cake passes `Palette.glowMaterial` when the round
    ///   asked for a cake that glows, which is a material change and not a mesh
    ///   change — so one model covers both.
    static func load(_ name: String,
                     tint: [String: UIColorLike] = [:],
                     material: @escaping (UIColorLike) -> RealityKit.Material
                        = { Palette.material($0) }) -> Entity? {
        let source: Entity
        if let cached = cache[name] {
            source = cached
        } else {
            guard let url = url(for: name), let loaded = try? Entity.load(contentsOf: url) else {
                return nil
            }
            cache[name] = loaded
            source = loaded
        }

        let model = source.clone(recursive: true)
        if !tint.isEmpty {
            let rules = tint.sorted { $0.key.count > $1.key.count }
            apply(rules, to: model, material: material)
        }
        model.name = name + "Model"

        let wrapper = Entity()
        wrapper.name = name
        wrapper.addChild(model)
        return wrapper
    }

    /// **Two places to look, on purpose.** `Resources/` is a synchronised group
    /// in the Xcode project, and whether a subfolder inside one survives into
    /// the built bundle as a directory or is flattened into its root is not
    /// something this code should depend on. Ask for both.
    private static func url(for name: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: "usdz", subdirectory: "Models")
            ?? Bundle.main.url(forResource: name, withExtension: "usdz")
    }

    private static func apply(_ rules: [(key: String, value: UIColorLike)],
                              to entity: Entity,
                              material: (UIColorLike) -> RealityKit.Material) {
        if let model = entity as? ModelEntity, model.model != nil {
            let (base, steps) = occlusion(in: entity.name)
            if let rule = rules.first(where: { base.hasPrefix($0.key) }) {
                let surface = material(Palette.occluded(rule.value, steps: steps))
                model.model?.materials = Array(repeating: surface,
                                               count: max(1, model.model?.materials.count ?? 1))
            }
        }
        for child in entity.children {
            apply(rules, to: child, material: material)
        }
    }

    /// The first `ModelEntity` under `entity` with this name.
    ///
    /// **Not `findEntity(named:)`.** A USD prop arrives as an `Xform` wrapping a
    /// `Mesh`, and the exporter gives both the same name — so the built-in
    /// search finds the `Xform` first and a cast to `ModelEntity` fails on a
    /// prop that is perfectly present. The sink needs its basin this way.
    static func mesh(_ name: String, in entity: Entity) -> ModelEntity? {
        if let model = entity as? ModelEntity, model.model != nil, model.name == name {
            return model
        }
        for child in entity.children {
            if let found = mesh(name, in: child) { return found }
        }
        return nil
    }

    /// Split a mesh name into its prop name and how occluded it is.
    ///
    /// `"BosbesCrownShade2"` → `("BosbesCrown", 2)`. The suffix is written by
    /// `bake_ao_facets` in `models/lowpoly.py`, which measures the occlusion at
    /// model time and moves the faces in a crevice into their own mesh. It is
    /// the only ambient occlusion in the game — `Palette.occluded` has the
    /// argument for why it is allowed to exist.
    ///
    /// A name with no suffix, or a suffix that is not a number, comes back
    /// whole and unshaded. A model naming a mesh `…ShadeX` gets painted its
    /// plain colour rather than nothing.
    private static func occlusion(in name: String) -> (base: String, steps: Int) {
        guard let marker = name.range(of: "Shade", options: .backwards),
              marker.upperBound < name.endIndex,
              let steps = Int(name[marker.upperBound...]) else {
            return (name, 0)
        }
        return (String(name[name.startIndex..<marker.lowerBound]), steps)
    }
}
