import SwiftUI
import simd

/// Everything the debug panel can tweak, in one observable object.
///
/// Defaults are the starting guess at matching
/// `references/plates/03-kitchen-roombox.png`. They are a guess — finding the
/// real numbers on a device is the entire point of this POC. Use
/// **Copy settings** in the panel to lift whatever you land on.
final class LightingSettings: ObservableObject {

    enum RoomSource: String, CaseIterable, Identifiable {
        case procedural = "Procedural"
        case importedUSDZ = "USDZ"
        var id: String { rawValue }
    }

    /// The Reality Composer Pro 3 light-baker exploration.
    ///
    /// Nothing here bakes at runtime — baking is an authoring step in RCP 3 on
    /// a Mac (see `LIGHTMAPS.md`). What this switches is whether the app
    /// *applies* a lightmap that has already been baked and bundled.
    enum LightmapMode: String, CaseIterable, Identifiable {
        case off = "Off"
        case ambientOcclusion = "AO"
        case beauty = "Beauty"
        var id: String { rawValue }

        var explanation: String {
            switch self {
            case .off:
                return "Pure real-time lighting. This is the direction's default — facets and one key light, no occlusion."
            case .ambientOcclusion:
                return "Multiplies a baked AO map into the material. The thing the art direction dropped — here to A/B whether it is missed."
            case .beauty:
                return "Full baked lighting. Kills real-time light response; included only to see the ceiling of what baking buys."
            }
        }
    }

    // MARK: Scene
    @Published var roomSource: RoomSource = .procedural
    @Published var flatShading: Bool = true
    @Published var showBackdrop: Bool = true

    // MARK: Key light
    @Published var keyEnabled: Bool = true
    @Published var keyIntensity: Float = 2200      // lux
    @Published var keyElevation: Float = 42        // degrees above horizon
    @Published var keyAzimuth: Float = 135         // degrees around Y
    @Published var keyTemperature: Float = 6200    // Kelvin
    @Published var shadowsEnabled: Bool = true

    // MARK: Fill
    @Published var fillEnabled: Bool = true
    @Published var fillIntensity: Float = 900
    @Published var fillTemperature: Float = 7800   // cooler bounce

    // MARK: Image-based lighting
    /// Disabled unless an environment asset is bundled — see `LightingRig`.
    @Published var iblEnabled: Bool = false
    @Published var iblIntensity: Float = 0.6       // intensityExponent

    // MARK: Contact shadows
    @Published var contactShadowsEnabled: Bool = true
    @Published var contactShadowOpacity: Float = 0.18
    @Published var contactShadowScale: Float = 1.15

    // MARK: Lightmap
    @Published var lightmapMode: LightmapMode = .off

    // MARK: - Derived

    /// Unit vector pointing *from* the light *towards* the scene.
    var keyDirection: SIMD3<Float> {
        Self.direction(elevationDegrees: keyElevation, azimuthDegrees: keyAzimuth)
    }

    /// Fill sits opposite the key and lower, standing in for bounced light.
    var fillDirection: SIMD3<Float> {
        Self.direction(elevationDegrees: 18, azimuthDegrees: keyAzimuth + 165)
    }

    static func direction(elevationDegrees: Float, azimuthDegrees: Float) -> SIMD3<Float> {
        let e = elevationDegrees * .pi / 180
        let a = azimuthDegrees * .pi / 180
        // Light is up at `e` and around at `a`; it shines downward/inward.
        return normalize(SIMD3<Float>(-cos(e) * sin(a), -sin(e), -cos(e) * cos(a)))
    }

    func reset() {
        roomSource = .procedural
        flatShading = true
        showBackdrop = true
        keyEnabled = true
        keyIntensity = 2200
        keyElevation = 42
        keyAzimuth = 135
        keyTemperature = 6200
        shadowsEnabled = true
        fillEnabled = true
        fillIntensity = 900
        fillTemperature = 7800
        iblEnabled = false
        iblIntensity = 0.6
        contactShadowsEnabled = true
        contactShadowOpacity = 0.18
        contactShadowScale = 1.15
        lightmapMode = .off
    }

    /// A paste-able Swift snippet of the current values, so a good setup found
    /// by fiddling survives into source.
    var swiftSnippet: String {
        """
        // Lighting found on device — \(Self.stamp())
        keyIntensity   = \(fmt(keyIntensity))
        keyElevation   = \(fmt(keyElevation))
        keyAzimuth     = \(fmt(keyAzimuth))
        keyTemperature = \(fmt(keyTemperature))
        shadowsEnabled = \(shadowsEnabled)
        fillEnabled    = \(fillEnabled)
        fillIntensity  = \(fmt(fillIntensity))
        fillTemperature = \(fmt(fillTemperature))
        iblEnabled     = \(iblEnabled)
        iblIntensity   = \(fmt(iblIntensity))
        contactShadowsEnabled = \(contactShadowsEnabled)
        contactShadowOpacity  = \(fmt(contactShadowOpacity))
        contactShadowScale    = \(fmt(contactShadowScale))
        flatShading    = \(flatShading)
        lightmapMode   = .\(lightmapMode == .ambientOcclusion ? "ambientOcclusion" : lightmapMode == .beauty ? "beauty" : "off")
        """
    }

    private func fmt(_ v: Float) -> String { String(format: "%.2f", v) }

    private static func stamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.string(from: Date())
    }
}
