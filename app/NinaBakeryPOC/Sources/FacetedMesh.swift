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
            idx.append(contentsOf: [b0, b1, t1,  b0, t1, t0])   // wall
            idx.append(contentsOf: [centreBottom, b1, b0])       // bottom cap
            idx.append(contentsOf: [centreTop, t0, t1])          // top cap
        }
        return (p, idx)
    }

    /// Truncated cone / tapered prism — the bowl and the flowerpots.
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

        var idx: [UInt32] = []
        for i in 0..<sides {
            let n = (i + 1) % sides
            let b0 = UInt32(i * 2), t0 = UInt32(i * 2 + 1)
            let b1 = UInt32(n * 2), t1 = UInt32(n * 2 + 1)
            idx.append(contentsOf: [b0, b1, t1,  b0, t1, t0])
            idx.append(contentsOf: [centreBottom, b1, b0])
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
                idx.append(contentsOf: [base + s32, base + n, nextBase + n])
                idx.append(contentsOf: [base + s32, nextBase + n, nextBase + s32])
            }
        }
        // Cap ring to apex.
        let lastRing = UInt32((rings - 1) * sides)
        let apex = UInt32(p.count - 1)
        for s in 0..<sides {
            let n = UInt32((s + 1) % sides), s32 = UInt32(s)
            idx.append(contentsOf: [lastRing + s32, lastRing + n, apex])
        }
        return (p, idx)
    }

    // MARK: - Convenience

    static func mesh(_ geometry: Geometry, flat: Bool) -> MeshResource {
        flat ? flatShaded(positions: geometry.positions, indices: geometry.indices)
             : smoothShaded(positions: geometry.positions, indices: geometry.indices)
    }
}
