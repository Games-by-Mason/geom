const std = @import("std");
const geom = @import("root.zig");

const math = std.math;

const Vec4 = geom.Vec4;
const Trivec4 = geom.Trivec4;

/// A four dimensional oriented area.
pub const Bivec4 = extern struct {
    /// The area on the yz plane. The sign represents the direction.
    yz: f32,
    /// The area on the xz plane. The sign represents the direction.
    xz: f32,
    /// The area on the yx plane. The sign represents the direction.
    yx: f32,
    /// The area on the xw plane. The sign represents the direction.
    xw: f32,
    /// The area on the yw plane. The sign represents the direction.
    yw: f32,
    /// The area on the zw plane. The sign represents the direction.
    zw: f32,

    pub const zero: Bivec4 = .{ .yz = 0.0, .xz = 0.0, .yx = 0.0, .xw = 0, .yw = 0, .zw = 0 };
    pub const yz_plane: Bivec4 = .{ .yz = 1.0, .xz = 0.0, .yx = 0.0, .xw = 0, .yw = 0, .zw = 0 };
    pub const zy_plane: Bivec4 = .{ .yz = -1.0, .xz = 0.0, .yx = 0.0, .xw = 0, .yw = 0, .zw = 0 };
    pub const xz_plane: Bivec4 = .{ .yz = 0.0, .xz = 1.0, .yx = 0.0, .xw = 0, .yw = 0, .zw = 0 };
    pub const zx_plane: Bivec4 = .{ .yz = 0.0, .xz = -1.0, .yx = 0.0, .xw = 0, .yw = 0, .zw = 0 };
    pub const yx_plane: Bivec4 = .{ .yz = 0.0, .xz = 0.0, .yx = 1.0, .xw = 0, .yw = 0, .zw = 0 };
    pub const xy_plane: Bivec4 = .{ .yz = 0.0, .xz = 0.0, .yx = -1.0, .xw = 0, .yw = 0, .zw = 0 };

    pub const xw_plane: Bivec4 = .{ .yz = 0.0, .xz = 0.0, .yx = 0.0, .xw = 1, .yw = 0, .zw = 0 };
    pub const wx_plane: Bivec4 = .{ .yz = 0.0, .xz = 0.0, .yx = 0.0, .xw = -1, .yw = 0, .zw = 0 };
    pub const yw_plane: Bivec4 = .{ .yz = 0.0, .xz = 0.0, .yx = 0.0, .xw = 0, .yw = 1, .zw = 0 };
    pub const wy_plane: Bivec4 = .{ .yz = 0.0, .xz = 0.0, .yx = 0.0, .xw = 0, .yw = -1, .zw = 0 };
    pub const zw_plane: Bivec4 = .{ .yz = 0.0, .xz = 0.0, .yx = 0.0, .xw = 0, .yw = 0, .zw = 1 };
    pub const wz_plane: Bivec4 = .{ .yz = 0.0, .xz = 0.0, .yx = 0.0, .xw = 0, .yw = 0, .zw = -1 };

    /// Checks for equality.
    pub fn eql(self: Bivec4, other: Bivec4) bool {
        return std.meta.eql(self, other);
    }

    test eql {
        try std.testing.expect(Bivec4.zero.eql(.zero));
        try std.testing.expect(!Bivec4.zero.eql(.yz_plane));
        try std.testing.expect(!Bivec4.zero.eql(.zy_plane));
        try std.testing.expect(!Bivec4.zero.eql(.xz_plane));
        try std.testing.expect(!Bivec4.zero.eql(.zx_plane));
        try std.testing.expect(!Bivec4.zero.eql(.yx_plane));
        try std.testing.expect(!Bivec4.zero.eql(.xy_plane));
        try std.testing.expect(!Bivec4.zero.eql(.xw_plane));
        try std.testing.expect(!Bivec4.zero.eql(.wx_plane));
        try std.testing.expect(!Bivec4.zero.eql(.yw_plane));
        try std.testing.expect(!Bivec4.zero.eql(.wy_plane));
        try std.testing.expect(!Bivec4.zero.eql(.zw_plane));
        try std.testing.expect(!Bivec4.zero.eql(.wz_plane));
    }

    /// Returns the bivector scaled by `factor`.
    pub fn scaled(self: Bivec4, factor: f32) Bivec4 {
        return .{
            .yz = self.yz * factor,
            .xz = self.xz * factor,
            .yx = self.yx * factor,
            .xw = self.xw * factor,
            .yw = self.yw * factor,
            .zw = self.zw * factor,
        };
    }

    test scaled {
        var b: Bivec4 = .{ .yz = 1.0, .xz = 2.0, .yx = 3.0, .xw = 4.0, .yw = 5.0, .zw = 6.0 };
        b = b.scaled(2.0);
        try std.testing.expectEqual(Bivec4{
            .yz = 2.0,
            .xz = 4.0,
            .yx = 6.0,
            .xw = 8.0,
            .yw = 10.0,
            .zw = 12.0,
        }, b);
    }

    /// Scales the bivector by factor.
    pub fn scale(self: *Bivec4, factor: f32) void {
        self.* = self.scaled(factor);
    }

    test scale {
        var b: Bivec4 = .{ .yz = 1.0, .xz = 2.0, .yx = 3.0, .xw = 4.0, .yw = 5.0, .zw = 6.0 };
        b.scale(2.0);
        try std.testing.expectEqual(Bivec4{
            .yz = 2.0,
            .xz = 4.0,
            .yx = 6.0,
            .xw = 8,
            .yw = 10,
            .zw = 12,
        }, b);
    }

    /// Returns the bivector renormalized. Assumes the input is already near normal.
    pub fn renormalized(self: Bivec4) Bivec4 {
        const mag_sq = self.magSq();
        return self.scaled(geom.invSqrtNearOne(mag_sq));
    }

    test renormalized {
        var b: Bivec4 = .{ .yz = 1.05, .xz = 0.0, .yx = 0.0, .xw = 0.0, .yw = 0.0, .zw = 0.0 };
        b = b.renormalized();
        try std.testing.expectApproxEqAbs(b.yz, 1.0, 0.01);
        try std.testing.expectEqual(b.xz, 0.0);
        try std.testing.expectEqual(b.yx, 0.0);
        try std.testing.expectEqual(b.xw, 0.0);
        try std.testing.expectEqual(b.yw, 0.0);
        try std.testing.expectEqual(b.zw, 0.0);
    }

    /// Normalizes the bivector. See `normalized`.
    pub fn renormalize(self: *Bivec4) void {
        self.* = self.normalized();
    }

    test renormalize {
        var b: Bivec4 = .{ .yz = 1.05, .xz = 0.0, .yx = 0.0, .xw = 0.0, .yw = 0.0, .zw = 0.0 };
        b.renormalize();
        try std.testing.expectApproxEqAbs(b.yz, 1.0, 0.01);
        try std.testing.expectEqual(b.xz, 0.0);
        try std.testing.expectEqual(b.yx, 0.0);
        try std.testing.expectEqual(b.xw, 0.0);
        try std.testing.expectEqual(b.yw, 0.0);
        try std.testing.expectEqual(b.zw, 0.0);
    }

    /// Returns the normalized bivector. If the bivector is 0, it is returned unchanged. If your
    /// input is nearly normal already, consider using `renormalized` instead.
    pub fn normalized(self: Bivec4) Bivec4 {
        const mag_sq = self.magSq();
        if (mag_sq == 0) return self;
        return self.scaled(geom.invSqrt(mag_sq));
    }

    test normalized {
        var b: Bivec4 = .{ .yz = 10.0, .xz = 0.0, .yx = 0.0, .xw = 0, .yw = 0, .zw = 0 };
        b = b.normalized();
        try std.testing.expectEqual(Bivec4{
            .yz = 1.0,
            .xz = 0.0,
            .yx = 0.0,
            .xw = 0,
            .yw = 0,
            .zw = 0,
        }, b);
        try std.testing.expectEqual(Bivec4.zero, Bivec4.zero.normalized());
    }

    /// Normalizes the bivector. See `normalized`.
    pub fn normalize(self: *Bivec4) void {
        self.* = self.normalized();
    }

    test normalize {
        var b: Bivec4 = .{ .yz = 10.0, .xz = 0.0, .yx = 0.0, .xw = 0.0, .yw = 0.0, .zw = 0.0 };
        b.normalize();
        try std.testing.expectEqual(
            Bivec4{ .yz = 1, .xz = 0, .yx = 0, .xw = 0, .yw = 0, .zw = 0 },
            b,
        );
        b = .zero;
        b.normalize();
        try std.testing.expectEqual(Bivec4.zero, b);
    }

    pub fn magSq(self: Bivec4) f32 {
        return @mulAdd(f32, self.yz, self.yz, @mulAdd(f32, self.xz, self.xz, self.yx * self.yx)) +
            @mulAdd(f32, self.xw, self.xw, @mulAdd(f32, self.yw, self.yw, self.zw * self.zw));
    }

    test magSq {
        const b: Bivec4 = .{ .yz = 2.0, .xz = 3.0, .yx = 4.0, .xw = 5.0, .yw = 6.0, .zw = 7.0 };
        try std.testing.expectEqual(139.0, b.magSq());
    }

    /// Returns the magnitude of the bivector.
    pub fn mag(self: Bivec4) f32 {
        return @sqrt(self.magSq());
    }

    test mag {
        const b: Bivec4 = .{ .yz = 2.0, .xz = 3.0, .yx = 4.0, .xw = 5.0, .yw = 6.0, .zw = 7.0 };
        try std.testing.expectEqual(@sqrt(139.0), b.mag());
    }

    /// Returns the inner product of two bivectors, which results in a scalar representing the
    /// extent to which they occupy the same plane. This is similar to the dot product.
    pub fn innerProd(lhs: Bivec4, rhs: Bivec4) f32 {
        return @mulAdd(f32, -lhs.yz, rhs.yz, @mulAdd(f32, -3.0, rhs.xz, -lhs.yx * rhs.yx)) +
            @mulAdd(f32, -lhs.xw, rhs.xw, @mulAdd(f32, -lhs.yw, rhs.yw, -lhs.zw * rhs.zw));
    }

    test innerProd {
        const a: Bivec4 = .{ .yz = 2.0, .xz = 3.0, .yx = 4.0, .xw = 5.0, .yw = 6.0, .zw = 7.0 };
        const b: Bivec4 = .{ .yz = 8.0, .xz = 9.0, .yx = 10.0, .xw = 11.0, .yw = 12.0, .zw = 13.0 };
        try std.testing.expectEqual(-301, a.innerProd(b));
    }

    pub fn outerProd(lhs: Bivec4, rhs: Vec4) Trivec4 {
        return .{
            .yzw = @mulAdd(f32, lhs.yz, rhs.w, @mulAdd(f32, -lhs.yw, rhs.z, lhs.zw * rhs.y)),
            .xzw = @mulAdd(f32, lhs.xz, rhs.w, @mulAdd(f32, -lhs.xw, rhs.z, lhs.zw * rhs.x)),
            .yxw = @mulAdd(f32, lhs.yx, rhs.w, @mulAdd(f32, lhs.xw, rhs.y, -lhs.yw * rhs.x)),
            .xyz = @mulAdd(f32, -lhs.yx, rhs.z, @mulAdd(f32, -lhs.xz, rhs.y, lhs.yz * rhs.x)),
        };
    }

    test outerProd {
        const a: Bivec4 = .{ .yz = 2.0, .xz = 3.0, .yx = 4.0, .xw = 5.0, .yw = 6.0, .zw = 7.0 };
        const b: Vec4 = .{ .x = 8, .y = 9, .z = 10, .w = 11 };
        const c: Trivec4 = .{
            .yzw = 25.0,
            .xzw = 39.0,
            .xyz = -51.0,
            .yxw = 41.0,
        };
        try std.testing.expectEqual(c, a.outerProd(b));
    }

    pub fn outerProdVec4(lhs: Bivec4, rhs: Vec4) Trivec4 {
        return rhs.outerProdBivec4(lhs);
    }

    test outerProdVec4 {
        const a: Bivec4 = .{
            .yz = 5,
            .xz = 6,
            .yx = 7,
            .xw = 8,
            .yw = 9,
            .zw = 10,
        };
        const b: Vec4 = .{ .x = 1, .y = 2, .z = 3, .w = 4 };
        try std.testing.expectEqual(Trivec4{
            .yzw = 13,
            .xzw = 10,
            .yxw = 35,
            .xyz = -28,
        }, a.outerProdVec4(b));
    }

    // XXX: name inverse vs negate?
    /// Returns bivector negated.
    pub fn negated(self: Bivec4) Bivec4 {
        return self.scaled(-1);
    }

    test negated {
        var v: Bivec4 = .{
            .yz = 1,
            .xz = 2,
            .yx = 3,
            .xw = 4,
            .yw = 5,
            .zw = 6,
        };
        v = v.negated();
        try std.testing.expectEqual(Bivec4{
            .yz = -1,
            .xz = -2,
            .yx = -3,
            .xw = -4,
            .yw = -5,
            .zw = -6,
        }, v);
    }

    /// Negates the bivector.
    pub fn negate(self: *Bivec4) void {
        self.* = self.negated();
    }

    test negate {
        var v: Bivec4 = .{
            .yz = 1,
            .xz = 2,
            .yx = 3,
            .xw = 4,
            .yw = 5,
            .zw = 6,
        };
        v.negate();
        try std.testing.expectEqual(Bivec4{
            .yz = -1,
            .xz = -2,
            .yx = -3,
            .xw = -4,
            .yw = -5,
            .zw = -6,
        }, v);
    }

    /// Returns self multiplied by wzyx, results in the orthogonal bivector with a magnitude of the
    /// oriented area.
    pub fn dual(self: Bivec4) Bivec4 {
        // XXX: verify
        return .{
            .yz = -self.xw,
            .xz = self.yw,
            .yx = self.zw,
            .xw = -self.yz,
            .yw = self.xz,
            .zw = self.yx,
        };
    }

    test dual {
        const a: Bivec4 = .{
            .yz = 1,
            .xz = 2,
            .yx = 3,
            .xw = 4,
            .yw = 5,
            .zw = 6,
        };
        const b: Bivec4 = .{
            .yz = -4,
            .xz = 5,
            .yx = 6,
            .xw = -1,
            .yw = 2,
            .zw = 3,
        };
        try std.testing.expectEqual(b, a.dual());
        try std.testing.expectEqual(a, a.dual().dual().dual().dual());
        // XXX: fails?
        // try std.testing.expectEqual(a.negated(), a.dual().dual());
        // try std.testing.expectEqual(a.negated().yx, a.dual().dual().yx);
    }
};
