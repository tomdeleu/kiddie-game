import RealityKit
import simd

/// Flat-shaded primitive geometry.
///
/// This is the technical heart of the art direction. RealityKit's built-in
/// `MeshResource.generateSphere` / `.generateBox(cornerRadius:)` produce smooth
/// or rounded surfaces, which is exactly what the style must not have. So the
/// primitives are built by hand and shaded flat: every triangle gets its own
/// three vertices carrying the face normal, so no normal is ever shared between
/// adjacent faces.
///
/// That is what makes a faceted sphere return ~20 distinct tones under a single
/// light, and it is why the direction needs no ambient occlusion.
enum FacetedMesh {

    // MARK: - Shading

    /// Explode an indexed mesh into independent triangles with face normals.
    static func flatShaded(positions: [SIMD3<Float>], indices: [UInt32]) -> MeshResource {
        var outPositions: [SIMD3<Float>] = []
        var outNormals: [SIMD3<Float>] = []
        var outIndices: [UInt32] = []
        outPositions.reserveCapacity(indices.count)
        outNormals.reserveCapacity(indices.count)
        outIndices.reserveCapacity(indices.count)

        var i = 0
        while i + 2 < indices.count {
            let a = positions[Int(indices[i])]
            let b = positions[Int(indices[i + 1])]
            let c = positions[Int(indices[i + 2])]

            // Face normal. Degenerate triangles are skipped rather than
            // producing NaNs that blow up the whole mesh.
            let raw = cross(b - a, c - a)
            let len = length(raw)
            guard len > 1e-8 else { i += 3; continue }
            let n = raw / len

            let base = UInt32(outPositions.count)
            outPositions.append(contentsOf: [a, b, c])
            outNormals.append(contentsOf: [n, n, n])
            outIndices.append(contentsOf: [base, base + 1, base + 2])
            i += 3
        }

        var descriptor = MeshDescriptor(name: "faceted")
        descriptor.positions = MeshBuffers.Positions(outPositions)
        descriptor.normals = MeshBuffers.Normals(outNormals)
        descriptor.primitives = .triangles(outIndices)
        return (try? MeshResource.generate(from: [descriptor]))
            ?? MeshResource.generateBox(size: 0.01)
    }

    /// Same geometry, normals averaged per position. Only exists so the debug
    /// UI can A/B it against the flat version — this is the "before" picture.
    static func smoothShaded(positions: [SIMD3<Float>], indices: [UInt32]) -> MeshResource {
        var accumulated = [SIMD3<Float>](repeating: .zero, count: positions.count)

        var i = 0
        while i + 2 < indices.count {
            let ia = Int(indices[i]), ib = Int(indices[i + 1]), ic = Int(indices[i + 2])
            let raw = cross(positions[ib] - positions[ia], positions[ic] - positions[ia])
            if length(raw) > 1e-8 {
                accumulated[ia] += raw
                accumulated[ib] += raw
                accumulated[ic] += raw
            }
            i += 3
        }

        let normals = accumulated.map { v -> SIMD3<Float> in
            let l = length(v)
            return l > 1e-8 ? v / l : SIMD3<Float>(0, 1, 0)
        }

        var descriptor = MeshDescriptor(name: "smooth")
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.normals = MeshBuffers.Normals(normals)
        descriptor.primitives = .triangles(indices)
        return (try? MeshResource.generate(from: [descriptor]))
            ?? MeshResource.generateBox(size: 0.01)
    }

    // MARK: - Geometry sources
    //
    // Each returns raw (positions, indices). Shading is applied separately so
    // the same geometry can be built flat or smooth from one definition.
    //
    // Winding is counter-clockwise seen from outside. That is not cosmetic
    // here: `flatShaded` derives every normal from it, and RealityKit culls
    // back faces, so a reversed triangle is both unlit and invisible — the
    // surface behind it shows through instead.

    typealias Geometry = (positions: [SIMD3<Float>], indices: [UInt32])

    /// Axis-aligned box centred on the origin.
    static func box(_ size: SIMD3<Float>) -> Geometry {
        let h = size / 2
        let p: [SIMD3<Float>] = [
            [-h.x, -h.y,  h.z], [ h.x, -h.y,  h.z], [ h.x,  h.y,  h.z], [-h.x,  h.y,  h.z],
            [-h.x, -h.y, -h.z], [ h.x, -h.y, -h.z], [ h.x,  h.y, -h.z], [-h.x,  h.y, -h.z],
        ]
        let idx: [UInt32] = [
            0, 1, 2,  0, 2, 3,   // front
            5, 4, 7,  5, 7, 6,   // back
            4, 0, 3,  4, 3, 7,   // left
            1, 5, 6,  1, 6, 2,   // right
            3, 2, 6,  3, 6, 7,   // top
            4, 5, 1,  4, 1, 0,   // bottom
        ]
        return (p, idx)
    }

    /// N-sided prism, standing on Y, base at y = 0. `sides` low on purpose —
    /// 6 to 8 reads as faceted, 32 reads as a smooth cylinder and is wrong.
    static func prism(radius: Float, height: Float, sides: Int = 8) -> Geometry {
        precondition(sides >= 3)
        var p: [SIMD3<Float>] = []
        for i in 0..<sides {
            let a = Float(i) / Float(sides) * 2 * .pi
            let x = cos(a) * radius, z = sin(a) * radius
            p.append([x, 0, z])
            p.append([x, height, z])
        }
        let centreBottom = UInt32(p.count); p.append([0, 0, 0])
        let centreTop = UInt32(p.count);    p.append([0, height, 0])

        var idx: [UInt32] = []
        for i in 0..<sides {
            let n = (i + 1) % sides
            let b0 = UInt32(i * 2),  t0 = UInt32(i * 2 + 1)
            let b1 = UInt32(n * 2),  t1 = UInt32(n * 2 + 1)
            idx.append(contentsOf: [b0, t1, b1,  b0, t0, t1])   // wall
            idx.append(contentsOf: [centreBottom, b0, b1])       // bottom cap
            idx.append(contentsOf: [centreTop, t1, t0])          // top cap
        }
        return (p, idx)
    }

    /// Truncated cone — a closed solid, capped at both ends.
    ///
    /// It is deliberately *not* the bowl: an uncapped version of this is an
    /// open shell with no interior, which back-face culling turns into a
    /// see-through prop. Vessels use `bowl`.
    static func taperedPrism(bottomRadius: Float, topRadius: Float,
                             height: Float, sides: Int = 10) -> Geometry {
        precondition(sides >= 3)
        var p: [SIMD3<Float>] = []
        for i in 0..<sides {
            let a = Float(i) / Float(sides) * 2 * .pi
            p.append([cos(a) * bottomRadius, 0, sin(a) * bottomRadius])
            p.append([cos(a) * topRadius, height, sin(a) * topRadius])
        }
        let centreBottom = UInt32(p.count); p.append([0, 0, 0])
        let centreTop = UInt32(p.count);    p.append([0, height, 0])

        var idx: [UInt32] = []
        for i in 0..<sides {
            let n = (i + 1) % sides
            let b0 = UInt32(i * 2), t0 = UInt32(i * 2 + 1)
            let b1 = UInt32(n * 2), t1 = UInt32(n * 2 + 1)
            idx.append(contentsOf: [b0, t1, b1,  b0, t0, t1])
            idx.append(contentsOf: [centreBottom, b0, b1])
            idx.append(contentsOf: [centreTop, t1, t0])
        }
        return (p, idx)
    }

    /// Hollow vessel of revolution — the bowl from `references/props/bowl.png`.
    ///
    /// A bowl is not a cone. A single-walled `taperedPrism` has no inside: the
    /// far half of the wall faces away from the camera, gets back-face culled,
    /// and you look straight through the pot. So this is a closed shell —
    /// outer wall, rim, inner wall back down, inner floor.
    ///
    /// The profile swells low and flattens towards the rim, per the plate,
    /// which is why radius follows `sin` rather than a straight taper.
    static func bowl(bottomRadius: Float, topRadius: Float, height: Float,
                     wallThickness: Float, floorThickness: Float,
                     sides: Int = 12, rings: Int = 3) -> Geometry {
        precondition(sides >= 3 && rings >= 1)
        precondition(wallThickness > 0 && wallThickness < bottomRadius)
        precondition(floorThickness > 0 && floorThickness < height)

        var p: [SIMD3<Float>] = []

        /// Appends one horizontal ring of `sides` vertices, returns its base index.
        func ring(radius: Float, y: Float) -> UInt32 {
            let base = UInt32(p.count)
            for s in 0..<sides {
                let a = Float(s) / Float(sides) * 2 * .pi
                p.append([cos(a) * radius, y, sin(a) * radius])
            }
            return base
        }

        var outer: [UInt32] = []
        var inner: [UInt32] = []
        for r in 0...rings {
            let t = Float(r) / Float(rings)
            let radius = bottomRadius + (topRadius - bottomRadius) * sin(t * .pi / 2)
            outer.append(ring(radius: radius, y: t * height))
            // The inner wall rises from the floor, not from y = 0.
            inner.append(ring(radius: max(0.0002, radius - wallThickness),
                              y: floorThickness + t * (height - floorThickness)))
        }
        let outerFloorCentre = UInt32(p.count); p.append([0, 0, 0])
        let innerFloorCentre = UInt32(p.count); p.append([0, floorThickness, 0])

        var idx: [UInt32] = []
        func quad(_ a: UInt32, _ b: UInt32, _ c: UInt32, _ d: UInt32) {
            idx.append(contentsOf: [a, b, c,  a, c, d])
        }

        for r in 0..<rings {
            let ol = outer[r], oh = outer[r + 1]
            let il = inner[r], ih = inner[r + 1]
            for s in 0..<sides {
                let n = UInt32((s + 1) % sides), s32 = UInt32(s)
                quad(ol + s32, oh + s32, oh + n, ol + n)   // outer wall, faces out
                quad(il + s32, il + n, ih + n, ih + s32)   // inner wall, faces in
            }
        }

        let rimOuter = outer[rings], rimInner = inner[rings]
        for s in 0..<sides {
            let n = UInt32((s + 1) % sides), s32 = UInt32(s)
            quad(rimOuter + s32, rimInner + s32, rimInner + n, rimOuter + n)  // rim, up
            idx.append(contentsOf: [outerFloorCentre, outer[0] + s32, outer[0] + n])
            idx.append(contentsOf: [innerFloorCentre, inner[0] + n, inner[0] + s32])
        }
        return (p, idx)
    }

    /// The two halves of the oven mouth, sharing one outline: a semicircle on
    /// two straight legs. `archRing` is the pink surround, `archPlug` the solid
    /// that fills its opening.
    ///
    /// Sharing the outline is the point. The plug's silhouette is the ring's
    /// opening by construction, so no amount of fiddling with the oven's
    /// proportions can make a dark corner poke out past the pink.
    private static func archOutline(radius: Float, legHeight: Float,
                                    segments: Int) -> [SIMD2<Float>] {
        var points: [SIMD2<Float>] = [[-radius, 0]]
        for s in 0...segments {
            let a = Float.pi * (1 - Float(s) / Float(segments))
            points.append([cos(a) * radius, legHeight + sin(a) * radius])
        }
        points.append([radius, 0])
        return points
    }

    /// Archway — an inverted U with a hole through it, extruded along Z.
    /// Centred on Z, standing on Y = 0. The oven's mouth surround.
    static func archRing(innerRadius: Float, outerRadius: Float, legHeight: Float,
                         depth: Float, segments: Int = 6) -> Geometry {
        precondition(segments >= 2 && outerRadius > innerRadius && innerRadius > 0)
        let inner2 = archOutline(radius: innerRadius, legHeight: legHeight, segments: segments)
        let outer2 = archOutline(radius: outerRadius, legHeight: legHeight, segments: segments)
        let hz = depth / 2

        // Four vertices per station: inner/outer × front/back.
        var p: [SIMD3<Float>] = []
        for i in 0..<inner2.count {
            p.append([inner2[i].x, inner2[i].y,  hz])   // +0 inner front
            p.append([outer2[i].x, outer2[i].y,  hz])   // +1 outer front
            p.append([outer2[i].x, outer2[i].y, -hz])   // +2 outer back
            p.append([inner2[i].x, inner2[i].y, -hz])   // +3 inner back
        }

        var idx: [UInt32] = []
        func quad(_ a: UInt32, _ b: UInt32, _ c: UInt32, _ d: UInt32) {
            idx.append(contentsOf: [a, b, c,  a, c, d])
        }

        for i in 0..<(inner2.count - 1) {
            let a = UInt32(i * 4), b = UInt32((i + 1) * 4)
            quad(a + 0, b + 0, b + 1, a + 1)   // front face
            quad(a + 3, a + 2, b + 2, b + 3)   // back face
            quad(a + 1, b + 1, b + 2, a + 2)   // outer wall
            quad(a + 0, a + 3, b + 3, b + 0)   // inner wall (the soffit)
        }

        // Cap the two leg bottoms, or the solid is open at the floor.
        let last = UInt32((inner2.count - 1) * 4)
        quad(0, 1, 2, 3)
        quad(last + 0, last + 3, last + 2, last + 1)
        return (p, idx)
    }

    /// Solid version of the same outline — the oven's dark mouth. Fanned from
    /// the first vertex, which is safe because a semicircle on a rectangle is
    /// convex.
    static func archPlug(radius: Float, legHeight: Float, depth: Float,
                         segments: Int = 6) -> Geometry {
        precondition(segments >= 2 && radius > 0)
        let outline = archOutline(radius: radius, legHeight: legHeight, segments: segments)
        let hz = depth / 2

        var p: [SIMD3<Float>] = []
        for point in outline { p.append([point.x, point.y,  hz]) }
        for point in outline { p.append([point.x, point.y, -hz]) }
        let n = UInt32(outline.count)

        var idx: [UInt32] = []
        for i in 1..<(n - 1) {
            idx.append(contentsOf: [0, i + 1, i])                    // front fan
            idx.append(contentsOf: [n, n + i, n + i + 1])            // back fan
        }
        for i in 0..<n {
            let j = (i + 1) % n
            idx.append(contentsOf: [i, n + j, n + i,  i, j, n + j])  // side wall
        }
        return (p, idx)
    }

    /// Icosphere. `subdivisions: 1` gives 80 faces — the sweet spot where a
    /// sphere still reads as faceted. Going above 2 loses the look.
    static func icosphere(radius: Float, subdivisions: Int = 1) -> Geometry {
        let t = Float((1.0 + 5.0.squareRoot()) / 2.0)
        var verts: [SIMD3<Float>] = [
            [-1,  t, 0], [ 1,  t, 0], [-1, -t, 0], [ 1, -t, 0],
            [0, -1,  t], [0,  1,  t], [0, -1, -t], [0,  1, -t],
            [ t, 0, -1], [ t, 0,  1], [-t, 0, -1], [-t, 0,  1],
        ].map { normalize($0) }

        var faces: [(UInt32, UInt32, UInt32)] = [
            (0,11,5),(0,5,1),(0,1,7),(0,7,10),(0,10,11),
            (1,5,9),(5,11,4),(11,10,2),(10,7,6),(7,1,8),
            (3,9,4),(3,4,2),(3,2,6),(3,6,8),(3,8,9),
            (4,9,5),(2,4,11),(6,2,10),(8,6,7),(9,8,1),
        ]

        for _ in 0..<max(0, subdivisions) {
            var cache: [UInt64: UInt32] = [:]
            func midpoint(_ a: UInt32, _ b: UInt32) -> UInt32 {
                let key = a < b ? (UInt64(a) << 32 | UInt64(b)) : (UInt64(b) << 32 | UInt64(a))
                if let hit = cache[key] { return hit }
                let m = normalize((verts[Int(a)] + verts[Int(b)]) / 2)
                verts.append(m)
                let index = UInt32(verts.count - 1)
                cache[key] = index
                return index
            }
            var next: [(UInt32, UInt32, UInt32)] = []
            next.reserveCapacity(faces.count * 4)
            for f in faces {
                let a = midpoint(f.0, f.1), b = midpoint(f.1, f.2), c = midpoint(f.2, f.0)
                next.append(contentsOf: [(f.0, a, c), (f.1, b, a), (f.2, c, b), (a, b, c)])
            }
            faces = next
        }

        let positions = verts.map { $0 * radius }
        let indices = faces.flatMap { [$0.0, $0.1, $0.2] }
        return (positions, indices)
    }

    /// Faceted dome — the oven body. A hemisphere of stacked rings, low counts
    /// on both axes so the facets stay large and readable.
    ///
    /// Open at the base on purpose. It sits on the floor, so the base is never
    /// seen, and a disc there would be coplanar with the floor and z-fight.
    /// This is the one primitive here that is not a closed solid.
    static func dome(radius: Float, height: Float, sides: Int = 8, rings: Int = 3) -> Geometry {
        precondition(sides >= 3 && rings >= 1)
        var p: [SIMD3<Float>] = []
        for r in 0...rings {
            let v = Float(r) / Float(rings)          // 0 at base, 1 at apex
            let theta = v * (.pi / 2)
            let ringRadius = cos(theta) * radius
            let y = sin(theta) * height
            if r == rings {
                p.append([0, y, 0])                   // single apex vertex
            } else {
                for s in 0..<sides {
                    let a = Float(s) / Float(sides) * 2 * .pi
                    p.append([cos(a) * ringRadius, y, sin(a) * ringRadius])
                }
            }
        }

        var idx: [UInt32] = []
        for r in 0..<(rings - 1) {
            let base = UInt32(r * sides), nextBase = UInt32((r + 1) * sides)
            for s in 0..<sides {
                let n = UInt32((s + 1) % sides), s32 = UInt32(s)
                idx.append(contentsOf: [base + s32, nextBase + n, base + n])
                idx.append(contentsOf: [base + s32, nextBase + s32, nextBase + n])
            }
        }
        // Cap ring to apex.
        let lastRing = UInt32((rings - 1) * sides)
        let apex = UInt32(p.count - 1)
        for s in 0..<sides {
            let n = UInt32((s + 1) % sides), s32 = UInt32(s)
            idx.append(contentsOf: [lastRing + s32, apex, lastRing + n])
        }
        return (p, idx)
    }

    // MARK: - Convenience

    static func mesh(_ geometry: Geometry, flat: Bool) -> MeshResource {
        flat ? flatShaded(positions: geometry.positions, indices: geometry.indices)
             : smoothShaded(positions: geometry.positions, indices: geometry.indices)
    }
}
