import SwiftUI

/// **The 2D hub.** Not a room, not in the world — a picture she picks a room
/// from. `GAMEPLAY.md` §6.1 (2026-08-23): the bakery stopped being the menu,
/// and this is the menu instead.
///
/// Drawn after `references/start-screen/F-layout-16x9.png`: a flat sage field,
/// four cream hex frames in a centred 2×2, no cottage photo underneath.
/// Locked tiles are empty frames (sage showing through the hex), not a grey
/// overlay. They still squash when tapped. No words on them.
struct StartScreen: View {

    let unlocked: Set<RoomID>
    var onPick: (RoomID) -> Void

    var body: some View {
        GeometryReader { geometry in
            let shortest = min(geometry.size.width, geometry.size.height)
            let tileSize = shortest * 0.42
            let gap = tileSize * 0.08

            ZStack {
                Color("LaunchBackground")

                VStack(spacing: gap) {
                    Spacer()
                    HStack(spacing: gap) {
                        tile(for: .tuin, size: tileSize)
                        tile(for: .keuken, size: tileSize)
                    }
                    HStack(spacing: gap) {
                        tile(for: .versieren, size: tileSize)
                        tile(for: .feest, size: tileSize)
                    }
                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
    }

    private func tile(for room: RoomID, size: CGFloat) -> some View {
        HubTile(room: room, unlocked: unlocked.contains(room), size: size) {
            onPick(room)
        }
    }
}

/// One room on the hub. A cream hex frame, as on plate F. The Higgsfield
/// plate (`HubTuin` and friends) fills the inside when the room is open;
/// a locked room is the same frame with sage showing through.
private struct HubTile: View {
    let room: RoomID
    let unlocked: Bool
    let size: CGFloat
    var onPick: () -> Void

    @State private var bump = false

    /// How much of the hex is cream rim rather than picture, matching F's
    /// thick diorama frames (~12% of the tile).
    private var rim: CGFloat { size * 0.12 }

    var body: some View {
        Button {
            if unlocked {
                onPick()
            } else {
                bump.toggle()
            }
        } label: {
            ZStack {
                HubHexagon()
                    .fill(Color(uiColor: Palette.creamLight))
                    .shadow(color: .black.opacity(0.14), radius: 8, y: 4)
                inner
                    .padding(rim)
            }
            .frame(width: size, height: size)
            .contentShape(HubHexagon())
            .scaleEffect(bump ? 0.94 : 1)
            .animation(.easeOut(duration: 0.12), value: bump)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(unlocked ? room.hubName : "Nog op slot")
        .accessibilityAddTraits(unlocked ? .isButton : .isImage)
    }

    @ViewBuilder
    private var inner: some View {
        if unlocked, let picture = UIImage(named: room.hubAsset) {
            Image(uiImage: picture)
                .resizable()
                .scaledToFill()
                .scaleEffect(1.18)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .clipShape(HubHexagon())
        } else if unlocked {
            HubHexagon()
                .fill(Color(uiColor: room.hubTone.face))
                .overlay {
                    Image(systemName: room.hubSymbol)
                        .font(.system(size: size * 0.28, weight: .bold))
                        .foregroundStyle(.white)
                }
        } else {
            HubHexagon()
                .fill(Color("LaunchBackground"))
        }
    }
}

/// Flat-top hexagon, as on plate F. The chrome buttons stay octagons;
/// only these hub frames are six-sided.
private struct HubHexagon: Shape {
    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3
            let point = CGPoint(x: center.x + radius * cos(angle),
                                y: center.y + radius * sin(angle))
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

extension RoomID {
    /// The four rooms on the hub, in the order they unlock. The bakery is
    /// parked — it is not a tile.
    static let hubOrder: [RoomID] = [.tuin, .keuken, .versieren, .feest]

    var hubAsset: String {
        switch self {
        case .tuin: return "HubTuin"
        case .keuken: return "HubKeuken"
        case .versieren: return "HubVersieren"
        case .feest: return "HubFeest"
        case .bakkerij: return "HubBakkerij"
        }
    }

    var hubSymbol: String {
        switch self {
        case .tuin: return "leaf.fill"
        case .keuken: return "oven.fill"
        case .versieren: return "paintbrush.pointed.fill"
        case .feest: return "sparkles"
        case .bakkerij: return "house.fill"
        }
    }

    /// Spoken only — VoiceOver. Never drawn.
    var hubName: String {
        switch self {
        case .tuin: return "De tuin"
        case .keuken: return "De keuken"
        case .versieren: return "Versieren"
        case .feest: return "Het feest"
        case .bakkerij: return "De bakkerij"
        }
    }

    var hubTone: FacetTone {
        switch self {
        case .tuin: return .sage
        case .keuken: return .sandy
        case .versieren: return .rose
        case .feest: return .berry
        case .bakkerij: return .sandy
        }
    }

    /// The room that lights up after this one is finished. Nil after the party.
    var hubUnlocks: RoomID? {
        switch self {
        case .tuin: return .keuken
        case .keuken: return .versieren
        case .versieren: return .feest
        default: return nil
        }
    }
}

/// The start screen's voice. `audio/script-hub.json`.
enum HubLine {
    /// The first time the hub is uncovered. Short explanation: the tiles are
    /// rooms, and we begin in the garden.
    static let eerste = "nina.hub.eerste"
    /// Every later visit, including the house button.
    static let terug = "nina.hub.terug"
}
