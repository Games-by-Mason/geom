const std = @import("std");
const geom = @import("root.zig");

const Vec4 = geom.Vec4;
const Bivec4 = geom.Bivec4;

// XXX: add duals to vectors?
// XXX: document, used for plucker/homogenous coords I think? update consts?
// XXX: do we also need bivec4?
// XXX: check math
pub const Trivec4 = extern struct {
    yzw: f32,
    xzw: f32,
    yxw: f32,
    xyz: f32,

    pub const zero: Trivec4 = .{ .yzw = 0, .xzw = 0, .yxw = 0, .xyz = 0 };

    /// Checks for equality.
    pub fn eql(self: Trivec4, other: Trivec4) bool {
        return std.meta.eql(self, other);
    }
    test eql {
        const a: Trivec4 = .zero;
        const b: Trivec4 = .{
            .yzw = 0,
            .xzw = 0,
            .yxw = 0,
            .xyz = 1,
        };
        try std.testing.expect(a.eql(a));
        try std.testing.expect(!a.eql(b));
    }

    /// Returns self multiplied by wzyx, resulting in a vector orthogonal to the oriented volume.
    pub fn dual(self: Trivec4) Vec4 {
        // XXX: why did i get all these flipped? wait but if i DONT do that, then the dual dual works..?
        return .{
            .x = self.yzw,
            .y = -self.xzw,
            .z = -self.yxw,
            .w = -self.xyz,
        };
    }

    test dual {
        const a: Trivec4 = .{
            .yzw = 1,
            .xzw = 2,
            .yxw = 3,
            .xyz = 4,
        };
        // try std.testing.expectEqual(Vec4{
        //     .x = -1,
        //     .y = 2,
        //     .z = 3,
        //     .w = 4,
        // }, a.dual());
        try std.testing.expectEqual(a, a.dual().dual().dual().dual());
        // XXX: why does this fail?
        try std.testing.expectEqual(a.inverse(), a.dual().dual());
    }

    pub fn scaled(self: Trivec4, factor: f32) Trivec4 {
        return .{
            .yzw = self.yzw * factor,
            .xzw = self.xzw * factor,
            .yxw = self.yxw * factor,
            .xyz = self.xyz * factor,
        };
    }

    test scaled {
        const a: Trivec4 = .{
            .yzw = 2,
            .xzw = 3,
            .yxw = 1,
            .xyz = 4,
        };
        const b: Trivec4 = .{
            .yzw = 4,
            .xzw = 6,
            .yxw = 2,
            .xyz = 8,
        };
        try std.testing.expectEqual(b, a.scaled(2));
    }

    pub fn scale(self: *Trivec4, factor: f32) void {
        self.* = self.scaled(factor);
    }

    test scale {
        var a: Trivec4 = .{
            .yzw = 2,
            .xzw = 3,
            .yxw = 1,
            .xyz = 4,
        };
        a.scale(2);
        const b: Trivec4 = .{
            .yzw = 4,
            .xzw = 6,
            .yxw = 2,
            .xyz = 8,
        };
        try std.testing.expectEqual(b, a);
    }

    pub fn inverse(self: Trivec4) Trivec4 {
        return .{
            .yzw = -self.yzw,
            .xzw = -self.xzw,
            .yxw = -self.yxw,
            .xyz = -self.xyz,
        };
    }

    test inverse {
        const a: Trivec4 = .{
            .yzw = 2,
            .xzw = 3,
            .yxw = 1,
            .xyz = 4,
        };
        const b: Trivec4 = .{
            .yzw = -2,
            .xzw = -3,
            .yxw = -1,
            .xyz = -4,
        };
        try std.testing.expectEqual(b, a.inverse());
    }

    pub fn invert(self: *Trivec4) void {
        self.* = self.inverse();
    }

    test invert {
        var a: Trivec4 = .{
            .yzw = 2,
            .xzw = 3,
            .yxw = 1,
            .xyz = 4,
        };
        a.invert();
        const b: Trivec4 = .{
            .yzw = -2,
            .xzw = -3,
            .yxw = -1,
            .xyz = -4,
        };
        try std.testing.expectEqual(b, a);
    }

    pub fn magSq(self: Trivec4) f32 {
        return @mulAdd(f32, self.yxw, self.yxw, self.xzw * self.xzw) +
            @mulAdd(f32, self.yzw, self.yzw, self.xyz * self.xyz);
    }

    test magSq {
        const v: Trivec4 = .{ .yzw = 2, .xzw = 3, .yxw = 4, .xyz = 5 };
        try std.testing.expectEqual(54, v.magSq());
    }

    pub fn mag(self: Trivec4) f32 {
        return @sqrt(self.magSq());
    }

    test mag {
        const v: Trivec4 = .{ .yzw = 2, .xzw = 3, .yxw = 4, .xyz = 5 };
        try std.testing.expectEqual(@sqrt(54.0), v.mag());
    }

    /// Returns the vector renormalized. Assumes the input is already near normal.
    pub fn renormalized(self: Trivec4) Trivec4 {
        const mag_sq = self.magSq();
        if (mag_sq == 0) return self;
        return self.scaled(geom.invSqrtNearOne(mag_sq));
    }

    test renormalized {
        var v: Trivec4 = .{ .yzw = 0.0, .xzw = 0.0, .yxw = 1.05, .xyz = 0.0 };
        v = v.renormalized();
        try std.testing.expectEqual(v.yzw, 0.0);
        try std.testing.expectEqual(v.xzw, 0.0);
        try std.testing.expectApproxEqAbs(v.yxw, 1.0, 0.01);
        try std.testing.expectEqual(v.xyz, 0.0);
    }

    /// Renormalizes the vector. See `renormalized`.
    pub fn renormalize(self: *Trivec4) void {
        self.* = self.renormalized();
    }

    test renormalize {
        var v: Trivec4 = .{ .yzw = 0.0, .xzw = 0.0, .yxw = 1.05, .xyz = 0.0 };
        v.renormalize();
        try std.testing.expectEqual(v.yzw, 0.0);
        try std.testing.expectEqual(v.xzw, 0.0);
        try std.testing.expectApproxEqAbs(v.yxw, 1.0, 0.01);
        try std.testing.expectEqual(v.xyz, 0.0);
    }

    /// Returns the vector normalized. If the trivector is `.zero`, returns it unchanged. If your
    /// input is nearly normal already, consider using `renormalize` instead.
    pub fn normalized(self: Trivec4) Trivec4 {
        const mag_sq = self.magSq();
        if (mag_sq == 0) return self;
        return self.scaled(geom.invSqrt(mag_sq));
    }

    test normalized {
        var v: Trivec4 = .{ .yzw = 0.0, .xzw = 0.0, .yxw = 10.0, .xyz = 0.0 };
        v = v.normalized();
        try std.testing.expectEqual(Trivec4{ .yzw = 0.0, .xzw = 0.0, .yxw = 1.0, .xyz = 0.0 }, v);
        try std.testing.expectEqual(zero, normalized(.zero));
    }

    /// Normalizes the vector. See `normalized`.
    pub fn normalize(self: *Trivec4) void {
        self.* = self.normalized();
    }

    test normalize {
        var v: Trivec4 = .{ .yzw = 0.0, .xzw = 0.0, .yxw = 10.0, .xyz = 0.0 };
        v.normalize();
        try std.testing.expectEqual(Trivec4{ .yzw = 0.0, .xzw = 0.0, .yxw = 1.0, .xyz = 0.0 }, v);
        v = .zero;
        v.normalize();
        try std.testing.expectEqual(zero, v);
    }

    pub fn innerProduct(lhs: Trivec4, rhs: Trivec4) f32 {
        return @mulAdd(f32, -lhs.yxw, rhs.yxw, -lhs.xzw * rhs.xzw) -
            @mulAdd(f32, lhs.yzw, rhs.yzw, lhs.xyz * rhs.xyz);
    }

    test innerProduct {
        const a: Trivec4 = .{
            .yzw = 2,
            .xzw = 3,
            .yxw = 1,
            .xyz = 4,
        };
        const b: Trivec4 = .{
            .yzw = 6,
            .xzw = 7,
            .yxw = 5,
            .xyz = 8,
        };
        try std.testing.expectEqual(-70, a.innerProduct(b));
    }

    // XXX: test...name after what meeting with?
    pub fn meet(self: Trivec4, rhs: Bivec4) Vec4 {
        return self.join(rhs).dual();
    }

    // XXX: test...
    pub fn join(self: Trivec4, rhs: Bivec4) Trivec4 {
        return self.dual().outerProdBivec4(rhs.dual());
    }
};

// XXX: ...
// #[test]
// fn test_create_homogeneous_line() {
//     // Test creating a line from a normalized point on the origin and a normalized point off of it
//     let a = math::vec4(0.0, 0.0, 0.0, 1.0);
//     let b = math::vec4(1.0, 0.0, 0.0, 1.0);
//     std::assert(bivec4_eq(
//         vec4_vec4_outer_product(a, b),
//         Bivec4 { xy: 0.0, zx: 0.0, yz: 0.0, xw: -1.0, yw: 0.0, zw: 0.0 },
//     ));
//     std::assert(bivec4_eq(
//         vec4_vec4_outer_product(b, a),
//         Bivec4 { xy: 0.0, zx: 0.0, yz: 0.0, xw: 1.0, yw: 0.0, zw: 0.0 },
//     ));

//     let a = math::vec4(0.0, 0.0, 0.0, 1.0);
//     let b = math::vec4(0.0, 1.0, 0.0, 1.0);
//     std::assert(bivec4_eq(
//         vec4_vec4_outer_product(a, b),
//         Bivec4 { xy: 0.0, zx: 0.0, yz: 0.0, xw: 0.0, yw: -1.0, zw: 0.0 },
//     ));
//     std::assert(bivec4_eq(
//         vec4_vec4_outer_product(b, a),
//         Bivec4 { xy: 0.0, zx: 0.0, yz: 0.0, xw: 0.0, yw: 1.0, zw: 0.0 },
//     ));

//     let a = math::vec4(0.0, 0.0, 0.0, 1.0);
//     let b = math::vec4(0.0, 0.0, 1.0, 1.0);
//     std::assert(bivec4_eq(
//         vec4_vec4_outer_product(a, b),
//         Bivec4 { xy: 0.0, zx: 0.0, yz: 0.0, xw: 0.0, yw: 0.0, zw: -1.0 },
//     ));
//     std::assert(bivec4_eq(
//         vec4_vec4_outer_product(b, a),
//         Bivec4 { xy: 0.0, zx: 0.0, yz: 0.0, xw: 0.0, yw: 0.0, zw: 1.0 },
//     ));

//     let a = math::vec4(0.0, 0.0, 0.0, 1.0);
//     let b = math::vec4(1.0, 1.0, 1.0, 1.0);
//     std::assert(bivec4_eq(
//         vec4_vec4_outer_product(a, b),
//         Bivec4 { xy: 0.0, zx: 0.0, yz: 0.0, xw: -1.0, yw: -1.0, zw: -1.0 },
//     ));
//     std::assert(bivec4_eq(
//         vec4_vec4_outer_product(b, a),
//         Bivec4 { xy: 0.0, zx: 0.0, yz: 0.0, xw: 1.0, yw: 1.0, zw: 1.0 },
//     ));

//     // Test creating a line two normalized points off of the origin
//     let a = math::vec4(1.0, 0.0, 0.0, 1.0);
//     let b = math::vec4(1.0, 1.0, 0.0, 1.0);
//     std::assert(bivec4_eq(
//         vec4_vec4_outer_product(a, b),
//         Bivec4 { xy: 1.0, zx: 0.0, yz: 0.0, xw: 0.0, yw: -1.0, zw: 0.0 },
//     ));
//     std::assert(bivec4_eq(
//         vec4_vec4_outer_product(b, a),
//         Bivec4 { xy: -1.0, zx: 0.0, yz: 0.0, xw: 0.0, yw: 1.0, zw: 0.0 },
//     ));

//     let a = math::vec4(-1.0, 1.0, 0.0, 1.0);
//     let b = math::vec4(1.0, 1.0, 0.0, 1.0);
//     std::assert(bivec4_eq(
//         vec4_vec4_outer_product(a, b),
//         Bivec4 { xy: -2.0, zx: 0.0, yz: 0.0, xw: -2.0, yw: 0.0, zw: 0.0 },
//     ));
//     std::assert(bivec4_eq(
//         vec4_vec4_outer_product(b, a),
//         Bivec4 { xy: 2.0, zx: 0.0, yz: 0.0, xw: 2.0, yw: 0.0, zw: 0.0 },
//     ));

//     let a = math::vec4(3.0, 0.0, 0.0, 1.0);
//     let b = math::vec4(3.0, 0.0, 2.0, 1.0);
//     std::assert(bivec4_eq(
//         vec4_vec4_outer_product(a, b),
//         Bivec4 { xy: 0.0, zx: -6.0, yz: 0.0, xw: 0.0, yw: 0.0, zw: -2.0 },
//     ));
//     std::assert(bivec4_eq(
//         vec4_vec4_outer_product(b, a),
//         Bivec4 { xy: 0.0, zx: 6.0, yz: 0.0, xw: 0.0, yw: 0.0, zw: 2.0 },
//     ));

//     let a = math::vec4(0.0, 0.0, 1.0, 1.0);
//     let b = math::vec4(2.0, 0.0, 1.0, 1.0);
//     std::assert(bivec4_eq(
//         vec4_vec4_outer_product(a, b),
//         Bivec4 { xy: 0.0, zx: 2.0, yz: 0.0, xw: -2.0, yw: 0.0, zw: 0.0 },
//     ));
//     std::assert(bivec4_eq(
//         vec4_vec4_outer_product(b, a),
//         Bivec4 { xy: 0.0, zx: -2.0, yz: 0.0, xw: 2.0, yw: 0.0, zw: 0.0 },
//     ));

//     // Test creating a line from a point and a direction
//     let a = math::vec4(1.0, 0.0, 0.0, 1.0);
//     let b = math::vec4(1.0, 0.0, 0.0, 0.0);
//     std::assert(bivec4_eq(
//         vec4_vec4_outer_product(a, b),
//         Bivec4 { xy: 0.0, zx: 0.0, yz: 0.0, xw: -1.0, yw: 0.0, zw: 0.0 },
//     ));
//     std::assert(bivec4_eq(
//         vec4_vec4_outer_product(b, a),
//         Bivec4 { xy: 0.0, zx: 0.0, yz: 0.0, xw: 1.0, yw: 0.0, zw: 0.0 },
//     ));

//     let a = math::vec4(0.0, 0.0, 0.0, 1.0);
//     let b = math::vec4(0.0, 1.0, 0.0, 0.0);
//     std::assert(bivec4_eq(
//         vec4_vec4_outer_product(a, b),
//         Bivec4 { xy: 0.0, zx: 0.0, yz: 0.0, xw: 0.0, yw: -1.0, zw: 0.0 },
//     ));
//     std::assert(bivec4_eq(
//         vec4_vec4_outer_product(b, a),
//         Bivec4 { xy: 0.0, zx: 0.0, yz: 0.0, xw: 0.0, yw: 1.0, zw: 0.0 },
//     ));

//     let a = math::vec4(0.0, 0.0, 0.0, 1.0);
//     let b = math::vec4(0.0, 0.0, 2.0, 0.0);
//     std::assert(bivec4_eq(
//         vec4_vec4_outer_product(a, b),
//         Bivec4 { xy: 0.0, zx: 0.0, yz: 0.0, xw: 0.0, yw: 0.0, zw: -2.0 },
//     ));
//     std::assert(bivec4_eq(
//         vec4_vec4_outer_product(b, a),
//         Bivec4 { xy: 0.0, zx: 0.0, yz: 0.0, xw: 0.0, yw: 0.0, zw: 2.0 },
//     ));

//     let a = math::vec4(1.0, 1.0, 1.0, 1.0);
//     let b = math::vec4(1.0, 1.0, 1.0, 0.0);
//     std::assert(bivec4_eq(
//         vec4_vec4_outer_product(a, b),
//         Bivec4 { xy: 0.0, zx: 0.0, yz: 0.0, xw: -1.0, yw: -1.0, zw: -1.0 },
//     ));
//     std::assert(bivec4_eq(
//         vec4_vec4_outer_product(b, a),
//         Bivec4 { xy: 0.0, zx: 0.0, yz: 0.0, xw: 1.0, yw: 1.0, zw: 1.0 },
//     ));

//     let a = math::vec4(0.0, 1.0, 0.0, 1.0);
//     let b = math::vec4(1.0, 0.0, 0.0, 0.0);
//     std::assert(bivec4_eq(
//         vec4_vec4_outer_product(a, b),
//         Bivec4 { xy: -1.0, zx: 0.0, yz: 0.0, xw: -1.0, yw: 0.0, zw: 0.0 },
//     ));
//     std::assert(bivec4_eq(
//         vec4_vec4_outer_product(b, a),
//         Bivec4 { xy: 1.0, zx: 0.0, yz: 0.0, xw: 1.0, yw: 0.0, zw: 0.0 },
//     ));

//     // Test creating a line from points with non-normalized ws, and then normalizing the result
//     let a = math::vec4(2.0, 0.0, 0.0, 2.0);
//     let b = math::vec4(3.0, 3.0, 0.0, 3.0);
//     let ab = vec4_vec4_outer_product(a, b);
//     let ba = vec4_vec4_outer_product(b, a);
//     std::assert(bivec4_eq(
//         ab,
//         Bivec4 { xy: 6.0, zx: 0.0, yz: 0.0, xw: 0.0, yw: -6.0, zw: 0.0 },
//     ));
//     std::assert(bivec4_eq(
//         ba,
//         Bivec4 { xy: -6.0, zx: 0.0, yz: 0.0, xw: 0.0, yw: 6.0, zw: 0.0 },
//     ));
//     let root2over2 = rmath::f32_sqrt(2.0) / 2.0;
//     std::assert(bivec4_approx_eq(
//         bivec4_normalize(ab),
//         Bivec4 { xy: root2over2, zx: 0.0, yz: 0.0, xw: 0.0, yw: -root2over2, zw: 0.0 },
//         rmath::F32_EPSILON,
//     ));
//     std::assert(bivec4_approx_eq(
//         bivec4_normalize(ba),
//         Bivec4 { xy: -root2over2, zx: 0.0, yz: 0.0, xw: 0.0, yw: root2over2, zw: 0.0 },
//         rmath::F32_EPSILON,
//     ));

//     let a = math::vec4(0.0, 2.0, 0.0, 2.0);
//     let b = math::vec4(0.0, 3.0, 3.0, 3.0);
//     let ab = vec4_vec4_outer_product(a, b);
//     let ba = vec4_vec4_outer_product(b, a);
//     std::assert(bivec4_eq(
//         ab,
//         Bivec4 { xy: 0.0, zx: 0.0, yz: 6.0, xw: 0.0, yw: 0.0, zw: -6.0 },
//     ));
//     std::assert(bivec4_eq(
//         ba,
//         Bivec4 { xy: 0.0, zx: 0.0, yz: -6.0, xw: 0.0, yw: 0.0, zw: 6.0 },
//     ));
//     let root2over2 = rmath::f32_sqrt(2.0) / 2.0;
//     std::assert(bivec4_approx_eq(
//         bivec4_normalize(ab),
//         Bivec4 { xy: 0.0, zx: 0.0, yz: root2over2, xw: 0.0, yw: 0.0, zw: -root2over2 },
//         rmath::F32_EPSILON,
//     ));
//     std::assert(bivec4_approx_eq(
//         bivec4_normalize(ba),
//         Bivec4 { xy: 0.0, zx: 0.0, yz: -root2over2, xw: 0.0, yw: 0.0, zw: root2over2 },
//         rmath::F32_EPSILON,
//     ));

//     // Test that two directions results in just the bivector components being set
//     let a = math::vec4(0.0, 1.0, 0.0, 0.0);
//     let b = math::vec4(1.0, 0.0, 0.0, 0.0);
//     std::assert(bivec4_eq(
//         vec4_vec4_outer_product(a, b),
//         Bivec4 { xy: -1.0, zx: 0.0, yz: 0.0, xw: 0.0, yw: 0.0, zw: 0.0 },
//     ));
//     std::assert(bivec4_eq(
//         vec4_vec4_outer_product(b, a),
//         Bivec4 { xy: 1.0, zx: 0.0, yz: 0.0, xw: 0.0, yw: 0.0, zw: 0.0 },
//     ));

//     // Test creating a line with two identical points
//     let a = math::vec4(2.0, -3.0, 4.0, 1.0);
//     std::assert(bivec4_eq(
//         vec4_vec4_outer_product(a, a),
//         Bivec4 { xy: 0.0, zx: 0.0, yz: 0.0, xw: 0.0, yw: 0.0, zw: 0.0 },
//     ));
// }

// // XXX: ...
// // #[test]
// // fn test_create_homogeneous_plane() {
// //     // Test creating a plane from 3 vec4s in various orders, and normalizing it.
// //     fn test_plane(a: Vec4, b: Vec4, c: Vec4, expected: Trivec4, expected_normalized: Trivec4) {
// //         std::assert(trivec4_eq(expected, bivec4_vec4_outer_product(
// //             vec4_vec4_outer_product(a, b),
// //             c,
// //         )));
// //         std::assert(trivec4_eq(expected, bivec4_vec4_outer_product(
// //             vec4_vec4_outer_product(b, c),
// //             a,
// //         )));
// //         std::assert(trivec4_eq(expected, bivec4_vec4_outer_product(
// //             vec4_vec4_outer_product(c, a),
// //             b,
// //         )));
// //         std::assert(trivec4_eq(expected, vec4_bivec4_outer_product(
// //             a,
// //             vec4_vec4_outer_product(b, c),
// //         )));
// //         std::assert(trivec4_eq(expected, vec4_bivec4_outer_product(
// //             c,
// //             vec4_vec4_outer_product(a, b),
// //         )));
// //         std::assert(trivec4_eq(expected, vec4_bivec4_outer_product(
// //             b,
// //             vec4_vec4_outer_product(c, a),
// //         )));
// //         std::assert(trivec4_eq(expected, vec4_vec4_vec4_outer_product(a, b, c)));
// //         std::assert(trivec4_eq(expected, vec4_vec4_vec4_outer_product(c, a, b)));
// //         std::assert(trivec4_eq(expected, vec4_vec4_vec4_outer_product(b, c, a)));

// //         let expected_inv = trivec4_inverse(expected);

// //         std::assert(trivec4_eq(expected_inv, bivec4_vec4_outer_product(
// //             vec4_vec4_outer_product(a, c),
// //             b,
// //         )));
// //         std::assert(trivec4_eq(expected_inv, bivec4_vec4_outer_product(
// //             vec4_vec4_outer_product(c, b),
// //             a,
// //         )));
// //         std::assert(trivec4_eq(expected_inv, bivec4_vec4_outer_product(
// //             vec4_vec4_outer_product(b, a),
// //             c,
// //         )));
// //         std::assert(trivec4_eq(expected_inv, vec4_bivec4_outer_product(
// //             a,
// //             vec4_vec4_outer_product(c, b),
// //         )));
// //         std::assert(trivec4_eq(expected_inv, vec4_bivec4_outer_product(
// //             c,
// //             vec4_vec4_outer_product(b, a),
// //         )));
// //         std::assert(trivec4_eq(expected_inv, vec4_bivec4_outer_product(
// //             b,
// //             vec4_vec4_outer_product(a, c),
// //         )));
// //         std::assert(trivec4_eq(expected_inv, vec4_vec4_vec4_outer_product(b, a, c)));
// //         std::assert(trivec4_eq(expected_inv, vec4_vec4_vec4_outer_product(a, c, b)));
// //         std::assert(trivec4_eq(expected_inv, vec4_vec4_vec4_outer_product(c, b, a)));

// //         let normalized = trivec4_normalize(expected);
// //         if (normalized.xyw == normalized.xyw) {
// //             std::assert(trivec4_approx_eq(
// //                 trivec4_normalize(expected),
// //                 expected_normalized,
// //                 rmath::F32_EPSILON * 100.0,
// //             ));
// //         } else {
// //             std::assert(normalized.xyw != normalized.xyw);
// //             std::assert(normalized.xzw != normalized.xzw);
// //             std::assert(normalized.yzw != normalized.yzw);
// //             std::assert(normalized.xyz != normalized.xyz);
// //             std::assert(expected_normalized.xyw != expected_normalized.xyw);
// //             std::assert(expected_normalized.xzw != expected_normalized.xzw);
// //             std::assert(expected_normalized.yzw != expected_normalized.yzw);
// //             std::assert(expected_normalized.xyz != expected_normalized.xyz);
// //         }
// //     }

// //     // Test three points
// //     let root2over2 = rmath::f32_sqrt(2.0) / 2.0;
// //     test_plane(
// //         math::vec4(1.0, 1.0, 1.0, 1.0),
// //         math::vec4(2.0, 1.0, 1.0, 1.0),
// //         math::vec4(1.0, 2.0, 1.0, 1.0),
// //         Trivec4 { xyw: 1.0, xzw: 0.0, yzw: 0.0, xyz: 1.0 },
// //         Trivec4 { xyw: root2over2, xzw: 0.0, yzw: 0.0, xyz: root2over2 },
// //     );
// //     let m = 137.252504531;
// //     test_plane(
// //         math::vec4(10.0, 2.0, 7.0, 2.0),
// //         math::vec4(9.0, 2.0, 3.0, 0.5),
// //         math::vec4(3.0, 2.0, 4.0, 5.0),
// //         Trivec4 { xyw: 27.0, xzw: 120.5, yzw: -33.0, xyz: 50.0 },
// //         Trivec4 { xyw: 27.0/m, xzw: 120.5/m, yzw: -33.0/m, xyz: 50.0/m },
// //     );

// //     // Test two points and a direction
// //     test_plane(
// //         math::vec4(1.0, 1.0, 1.0, 0.0),
// //         math::vec4(1.0, 1.0, 1.0, 1.0),
// //         math::vec4(2.0, 2.0, -2.0, 1.0),
// //         Trivec4 { xyw: 0.0, xzw: -4.0, yzw: 4.0, xyz: 0.0 },
// //         Trivec4 { xyw: 0.0, xzw: -root2over2, yzw: root2over2, xyz: 0.0 },
// //     );

// //     // Test all the same point
// //     test_plane(
// //         math::vec4(1.0, 2.0, 3.0, 1.0),
// //         math::vec4(1.0, 2.0, 3.0, 1.0),
// //         math::vec4(1.0, 2.0, 3.0, 1.0),
// //         Trivec4 { xyw: 0.0, xzw: 0.0, yzw: 0.0, xyz: 0.0 },
// //         Trivec4 { xyw: NaN, xzw: NaN, yzw: NaN, xyz: NaN },
// //     );

// //     // Test a line and a point on the line
// //     test_plane(
// //         math::vec4(1.0, 1.0, 1.0, 0.0),
// //         math::vec4(1.0, 1.0, 1.0, 1.0),
// //         math::vec4(2.0, 2.0, -2.0, 1.0),
// //         Trivec4 { xyw: 0.0, xzw: -4.0, yzw: 4.0, xyz: 0.0 },
// //         Trivec4 { xyw: 0.0, xzw: -root2over2, yzw: root2over2, xyz: 0.0 },
// //     );

// //     // Test three collinear points
// //     test_plane(
// //         math::vec4(1.0, 1.0, 1.0, 1.0),
// //         math::vec4(2.0, 2.0, 2.0, 1.0),
// //         math::vec4(3.0, 3.0, 3.0, 1.0),
// //         Trivec4 { xyw: 0.0, xzw: 0.0, yzw: 0.0, xyz: 0.0 },
// //         Trivec4 { xyw: NaN, xzw: NaN, yzw: NaN, xyz: NaN },
// //     );

// //     // Test two of the same point and one different point
// //     test_plane(
// //         math::vec4(1.0, 1.0, 1.0, 1.0),
// //         math::vec4(1.0, 1.0, 1.0, 1.0),
// //         math::vec4(10.0, -10.0, 5.0, 1.0),
// //         Trivec4 { xyw: 0.0, xzw: 0.0, yzw: 0.0, xyz: 0.0 },
// //         Trivec4 { xyw: NaN, xzw: NaN, yzw: NaN, xyz: NaN },
// //     );
// // }

// // #[test]
// // fn test_meet_bivec4_trivec4() {
// //     // Test lines through the xy plane at the origin
// //     let plane = vec4_vec4_vec4_outer_product(
// //         math::vec4(1.0, 0.0, 0.0, 1.0),
// //         math::vec4(0.0, 1.0, 0.0, 1.0),
// //         math::vec4(0.0, 0.0, 0.0, 1.0),
// //     );

// //     let intersection = trivec4_bivec4_meet(plane, vec4_vec4_outer_product(
// //         math::vec4(0.0, 0.0, 0.0, 1.0),
// //         math::vec4(0.0, 0.0, 1.0, 1.0),
// //     ));
// //     std::assert(math::vec4_eq(intersection, math::vec4(0.0, 0.0, 0.0, -1.0)));

// //     let intersection = trivec4_bivec4_meet(plane, vec4_vec4_outer_product(
// //         math::vec4(0.0, 0.0, 1.0, 1.0),
// //         math::vec4(0.0, 0.0, 0.0, 1.0),
// //     ));
// //     std::assert(math::vec4_eq(intersection, math::vec4(0.0, 0.0, 0.0, 1.0)));

// //     let intersection = trivec4_bivec4_meet(plane, vec4_vec4_outer_product(
// //         math::vec4(2.0, 3.0, 1.0, 1.0),
// //         math::vec4(2.0, 3.0, 0.0, 1.0),
// //     ));
// //     std::assert(math::vec4_eq(intersection, math::vec4(2.0, 3.0, 0.0, 1.0)));

// //     // Test lines through the xy plane off the origin
// //     let plane = vec4_vec4_vec4_outer_product(
// //         math::vec4(1.0, 0.0, 10.0, 1.0),
// //         math::vec4(0.0, 1.0, 10.0, 1.0),
// //         math::vec4(0.0, 0.0, 10.0, 1.0),
// //     );
// //     let intersection = trivec4_bivec4_meet(plane, vec4_vec4_outer_product(
// //         math::vec4(2.0, 3.0, 1.0, 1.0),
// //         math::vec4(2.0, 3.0, 0.0, 1.0),
// //     ));
// //     std::assert(math::vec4_eq(intersection, math::vec4(2.0, 3.0, 10.0, 1.0)));

// //     // Test lines through the xz plane at the origin
// //     let plane = vec4_vec4_vec4_outer_product(
// //         math::vec4(1.0, 0.0, 0.0, 1.0),
// //         math::vec4(0.0, 0.0, 1.0, 1.0),
// //         math::vec4(0.0, 0.0, 0.0, 1.0),
// //     );

// //     let intersection = trivec4_bivec4_meet(plane, vec4_vec4_outer_product(
// //         math::vec4(0.0, 0.0, 0.0, 1.0),
// //         math::vec4(0.0, 1.0, 0.0, 1.0),
// //     ));
// //     std::assert(math::vec4_eq(intersection, math::vec4(0.0, 0.0, 0.0, 1.0)));

// //     let intersection = trivec4_bivec4_meet(plane, vec4_vec4_outer_product(
// //         math::vec4(0.0, 1.0, 0.0, 1.0),
// //         math::vec4(0.0, 0.0, 0.0, 1.0),
// //     ));
// //     std::assert(math::vec4_eq(intersection, math::vec4(0.0, 0.0, 0.0, -1.0)));

// //     let intersection = trivec4_bivec4_meet(plane, vec4_vec4_outer_product(
// //         math::vec4(2.0, 0.0, 3.0, 1.0),
// //         math::vec4(2.0, 1.0, 3.0, 1.0),
// //     ));
// //     std::assert(math::vec4_eq(intersection, math::vec4(2.0, 0.0, 3.0, 1.0)));

// //     // Test lines through the xz plane off the origin
// //     let plane = vec4_vec4_vec4_outer_product(
// //         math::vec4(1.0, 10.0, 0.0, 1.0),
// //         math::vec4(0.0, 10.0, 1.0, 1.0),
// //         math::vec4(0.0, 10.0, 0.0, 1.0),
// //     );
// //     let intersection = trivec4_bivec4_meet(plane, vec4_vec4_outer_product(
// //         math::vec4(2.0, 0.0, 3.0, 1.0),
// //         math::vec4(2.0, 1.0, 3.0, 1.0),
// //     ));
// //     std::assert(math::vec4_eq(intersection, math::vec4(2.0, 10.0, 3.0, 1.0)));

// //     // Test lines through the yz plane at the origin
// //     let plane = vec4_vec4_vec4_outer_product(
// //         math::vec4(0.0, 1.0, 0.0, 1.0),
// //         math::vec4(0.0, 0.0, 1.0, 1.0),
// //         math::vec4(0.0, 0.0, 0.0, 1.0),
// //     );

// //     let intersection = trivec4_bivec4_meet(plane, vec4_vec4_outer_product(
// //         math::vec4(0.0, 0.0, 0.0, 1.0),
// //         math::vec4(1.0, 0.0, 0.0, 1.0),
// //     ));
// //     std::assert(math::vec4_eq(intersection, math::vec4(0.0, 0.0, 0.0, -1.0)));

// //     let intersection = trivec4_bivec4_meet(plane, vec4_vec4_outer_product(
// //         math::vec4(1.0, 0.0, 0.0, 1.0),
// //         math::vec4(0.0, 0.0, 0.0, 1.0),
// //     ));
// //     std::assert(math::vec4_eq(intersection, math::vec4(0.0, 0.0, 0.0, 1.0)));

// //     let intersection = trivec4_bivec4_meet(plane, vec4_vec4_outer_product(
// //         math::vec4(0.0, 2.0, 3.0, 1.0),
// //         math::vec4(1.0, 2.0, 3.0, 1.0),
// //     ));
// //     std::assert(math::vec4_eq(intersection, math::vec4(0.0, -2.0, -3.0, -1.0)));

// //     // Test lines through the yz plane off the origin
// //     let plane = vec4_vec4_vec4_outer_product(
// //         math::vec4(15.0, 1.0, 0.0, 1.0),
// //         math::vec4(15.0, 0.0, 1.0, 1.0),
// //         math::vec4(15.0, 0.0, 0.0, 1.0),
// //     );
// //     let intersection = trivec4_bivec4_meet(plane, vec4_vec4_outer_product(
// //         math::vec4(0.0, 2.0, 3.0, 1.0),
// //         math::vec4(1.0, 2.0, 3.0, 1.0),
// //     ));
// //     std::assert(math::vec4_eq(intersection, math::vec4(-15.0, -2.0, -3.0, -1.0)));

// //     // Test a plane that doesn't line up with the axis
// //     let plane = vec4_vec4_vec4_outer_product(
// //         math::vec4(1.0, 0.0, 0.0, 1.0),
// //         math::vec4(0.0, 1.0, 0.0, 1.0),
// //         math::vec4(0.0, 0.0, 1.0, 1.0),
// //     );

// //     let intersection = trivec4_bivec4_meet(plane, vec4_vec4_outer_product(
// //         math::vec4(0.0, 0.0, 0.0, 1.0),
// //         math::vec4(1.0, 0.0, 0.0, 1.0),
// //     ));
// //     std::assert(math::vec4_eq(intersection, math::vec4(-1.0, 0.0, 0.0, -1.0)));

// //     let intersection = trivec4_bivec4_meet(plane, vec4_vec4_outer_product(
// //         math::vec4(0.0, 0.0, 0.0, 1.0),
// //         math::vec4(0.0, 1.0, 0.0, 1.0),
// //     ));
// //     std::assert(math::vec4_eq(intersection, math::vec4(0.0, -1.0, 0.0, -1.0)));

// //     let intersection = trivec4_bivec4_meet(plane, vec4_vec4_outer_product(
// //         math::vec4(0.0, 0.0, 0.0, 1.0),
// //         math::vec4(0.0, 0.0, 1.0, 1.0),
// //     ));
// //     std::assert(math::vec4_eq(intersection, math::vec4(0.0, 0.0, -1.0, -1.0)));

// //     let intersection = trivec4_bivec4_meet(plane, vec4_vec4_outer_product(
// //         math::vec4(0.0, 0.0, 0.0, 1.0),
// //         math::vec4(1.0, 1.0, 1.0, 1.0),
// //     ));
// //     std::assert(math::vec4_eq(intersection, math::vec4(-1.0, -1.0, -1.0, -3.0)));

// //     // Test the last case again, but with non-normalized inputs
// //     let plane = vec4_vec4_vec4_outer_product(
// //         math::vec4(1.0, 0.0, 0.0, 1.0),
// //         math::vec4(0.0, 2.0, 0.0, 2.0),
// //         math::vec4(0.0, 0.0, -3.0, -3.0),
// //     );

// //     let intersection = trivec4_bivec4_meet(plane, vec4_vec4_outer_product(
// //         math::vec4(0.0, 0.0, 0.0, -1.0),
// //         math::vec4(2.0, 0.0, 0.0, 2.0),
// //     ));
// //     std::assert(math::vec4_eq(intersection, math::vec4(-12.0, 0.0, 0.0, -12.0)));

// //     let intersection = trivec4_bivec4_meet(plane, vec4_vec4_outer_product(
// //         math::vec4(0.0, 0.0, 0.0, 1.0),
// //         math::vec4(0.0, -2.0, 0.0, -2.0),
// //     ));
// //     std::assert(math::vec4_eq(intersection, math::vec4(0.0, -12.0, 0.0, -12.0)));

// //     let intersection = trivec4_bivec4_meet(plane, vec4_vec4_outer_product(
// //         math::vec4(0.0, 0.0, 0.0, 3.0),
// //         math::vec4(0.0, 0.0, 3.0, 3.0),
// //     ));
// //     std::assert(math::vec4_eq(intersection, math::vec4(0.0, 0.0, 54.0, 54.0)));

// //     let intersection = trivec4_bivec4_meet(plane, vec4_vec4_outer_product(
// //         math::vec4(0.0, 0.0, 0.0, 1.0),
// //         math::vec4(2.0, 2.0, 2.0, -2.0),
// //     ));
// //     std::assert(math::vec4_eq(intersection, math::vec4(12.0, 12.0, 12.0, 36.0)));

// //     // Test trying to get the intersection when none exists
// //     let plane = vec4_vec4_vec4_outer_product(
// //         math::vec4(1.0, 0.0, 0.0, 1.0),
// //         math::vec4(0.0, 1.0, 0.0, 1.0),
// //         math::vec4(0.0, 0.0, 0.0, 1.0),
// //     );
// //     let intersection = trivec4_bivec4_meet(plane, vec4_vec4_outer_product(
// //         math::vec4(0.0, 0.0, 1.0, 1.0),
// //         math::vec4(1.0, 0.0, 1.0, 1.0),
// //     ));
// //     std::assert(math::vec4_eq(intersection, math::vec4(1.0, 0.0, 0.0, 0.0)));
// //     let intersection = trivec4_bivec4_meet(plane, vec4_vec4_outer_product(
// //         math::vec4(0.0, 0.0, 1.0, 1.0),
// //         math::vec4(0.0, 1.0, 1.0, 1.0),
// //     ));
// //     std::assert(math::vec4_eq(intersection, math::vec4(0.0, 1.0, 0.0, 0.0)));
// // }
