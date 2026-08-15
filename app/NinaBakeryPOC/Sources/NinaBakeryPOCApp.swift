import SwiftUI

/// Step 0 proof of concept for *Nina's Toverbakkerij*.
///
/// Answers one question: does the faceted pastel low-poly direction survive
/// real-time rendering **without** baked ambient occlusion? Everything here is
/// scaffolding for that question — there is no game in it.
///
/// Runs on iPad (the real verdict) and on the Mac (fast iteration for the
/// lighting panel). See `app/README.md` for the simulator caveat.
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
