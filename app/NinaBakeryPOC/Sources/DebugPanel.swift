import SwiftUI

/// The corner overlay for tuning lighting live.
///
/// Deliberately not pretty. It exists to find numbers on a device and get them
/// back into source via **Copy settings** — nothing in here ships to Nina.
struct DebugPanel: View {
    @ObservedObject var settings: LightingSettings
    let iblAvailable: Bool
    let lightmapsAvailable: Bool

    @State private var expanded = true
    @State private var copied = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) { expanded.toggle() }
            } label: {
                Image(systemName: expanded ? "xmark.circle.fill" : "slider.horizontal.3")
                    .font(.title2)
                    .padding(8)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)

            if expanded {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        sceneSection
                        Divider()
                        keySection
                        Divider()
                        fillSection
                        Divider()
                        iblSection
                        Divider()
                        contactSection
                        Divider()
                        lightmapSection
                        Divider()
                        actions
                    }
                    .padding(14)
                }
                .frame(width: 290)
                .frame(maxHeight: 560)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(16)
        .font(.caption)
    }

    // MARK: - Sections

    private var sceneSection: some View {
        section("Scene") {
            Picker("Room", selection: $settings.roomSource) {
                ForEach(LightingSettings.RoomSource.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            Toggle("Flat shading", isOn: $settings.flatShading)
            Text(settings.flatShading
                 ? "Facets carry the shading. This is the direction."
                 : "Smooth normals — the \"before\" picture. Note how much flatter it reads.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Toggle("Grey backdrop", isOn: $settings.showBackdrop)
        }
    }

    private var keySection: some View {
        section("Key light") {
            Toggle("Enabled", isOn: $settings.keyEnabled)
            slider("Intensity", $settings.keyIntensity, 0...6000, "%.0f lx")
            slider("Elevation", $settings.keyElevation, 5...85, "%.0f°")
            slider("Azimuth", $settings.keyAzimuth, 0...360, "%.0f°")
            slider("Temperature", $settings.keyTemperature, 2000...10000, "%.0f K")
            Toggle("Cast shadows", isOn: $settings.shadowsEnabled)
            Text("The grounding shadow — AO's main job, done dynamically.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var fillSection: some View {
        section("Fill") {
            Toggle("Enabled", isOn: $settings.fillEnabled)
            slider("Intensity", $settings.fillIntensity, 0...3000, "%.0f lx")
            slider("Temperature", $settings.fillTemperature, 2000...10000, "%.0f K")
            Text("Stands in for bounced light. Too low and corners go dark — which is the look we are avoiding.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var iblSection: some View {
        section("Image-based light") {
            Toggle("Enabled", isOn: $settings.iblEnabled)
                .disabled(!iblAvailable)
            if iblAvailable {
                slider("Intensity", $settings.iblIntensity, -2...2, "%.2f")
            } else {
                Text("No environment bundled. Add `StudioNeutral` to Resources to enable — see README.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var contactSection: some View {
        section("Contact shadows") {
            Toggle("Enabled", isOn: $settings.contactShadowsEnabled)
            slider("Opacity", $settings.contactShadowOpacity, 0...0.6, "%.2f")
            slider("Scale", $settings.contactShadowScale, 0.5...2.5, "%.2f")
            Text("Blobs under the loose props. The one grounding cue a bake could never provide.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var lightmapSection: some View {
        section("Lightmap — Reality Composer Pro 3") {
            Picker("Mode", selection: $settings.lightmapMode) {
                ForEach(LightingSettings.LightmapMode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .disabled(!lightmapsAvailable)

            Text(settings.lightmapMode.explanation)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if !lightmapsAvailable {
                Label("Nothing baked yet", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                Text("Baking happens in Reality Composer Pro 3 on a Mac, not at runtime. Follow LIGHTMAPS.md, drop the results in Resources, and these modes light up. Needs the USDZ room — procedural meshes carry no UVs.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if settings.roomSource == .procedural && settings.lightmapMode != .off {
                Label("Procedural room has no UVs", systemImage: "info.circle")
                    .foregroundStyle(.orange)
                Text("Switch Room to USDZ for the lightmap to land.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var actions: some View {
        HStack {
            Button("Reset") { settings.reset() }
            Spacer()
            Button(copied ? "Copied" : "Copy settings") {
                Clipboard.set(settings.swiftSnippet)
                copied = true
                Task {
                    try? await Task.sleep(nanoseconds: 1_200_000_000)
                    copied = false
                }
            }
        }
        .buttonStyle(.bordered)
    }

    // MARK: - Building blocks

    private func section<Content: View>(_ title: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func slider(_ label: String, _ value: Binding<Float>,
                        _ range: ClosedRange<Float>, _ format: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                Spacer()
                Text(String(format: format, value.wrappedValue))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range)
        }
    }
}

/// Cross-platform clipboard, so Copy settings works on Mac and iPad alike.
enum Clipboard {
    static func set(_ string: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
        #else
        UIPasteboard.general.string = string
        #endif
    }
}
