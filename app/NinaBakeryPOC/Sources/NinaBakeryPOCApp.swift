import SwiftUI

/// *Nina's Toverbakkerij* — **De Keuken**.
///
/// This began as the Step 0 proof of concept and now holds the first real room:
/// the kitchen from `GAMEPLAY.md` §6.3, with its required action (ingredients,
/// stir, pour, bake), its six toys, Otto, and Luna speaking Dutch. The target
/// name is still `NinaBakeryPOC` because the Xcode project builds and runs
/// under it, and renaming a working project buys nothing. What Nina sees under
/// the icon is `CFBundleDisplayName`, which is *Nina's Toverbakkerij*.
///
/// What the POC answered stays answered: the faceted pastel direction survives
/// real-time rendering with no baked ambient occlusion, and the approved
/// lighting is the committed default in `LightingSettings`.
///
/// Runs on iPad (the real verdict) and on the Mac (fast iteration). See
/// `app/README.md` for the simulator caveat — RealityKit does not render
/// reliably there, and nothing should be concluded from it.
@main
struct NinaBakeryPOCApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .defaultSize(width: 1280, height: 800)
        #endif
    }
}
