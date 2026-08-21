/// Shading for the cast — the eleven friends, Mo the mole, and Het Feest's
/// balloon.
///
/// These ship smooth in every room. Nina stays faceted and follows the debug
/// flat-shading toggle like every other prop. Props, shells and the room box
/// do the same.
enum CharacterShading {

    static let smooth = true

    static func faceted(_ roomFlat: Bool) -> Bool {
        roomFlat && !smooth
    }

    /// Procedural head icospheres — one more subdivision than the first guest
    /// pass so smooth normals have enough vertices to round out.
    static let headSubdivisions = 2

    /// Lathe side count for torsos and short limbs when smooth.
    static let torsoSides = 14
    static let limbSides = 12
}
