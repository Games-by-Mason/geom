const std = @import("std");
const geom = @import("root.zig");

const math = std.math;

const Rotor3 = geom.Rotor3;
const Vec3 = geom.Vec3;

/// A three dimensional oriented area.
pub const Bivec3 = extern struct {
    /// The area on the yz plane. The sign represents the direction.
    yz: f32,
    /// The area on the xz plane. The sign represents the direction.
    xz: f32,
    /// The area on the yx plane. The sign represents the direction.
    yx: f32,

    pub const zero: Bivec3 = .{ .yz = 0.0, .xz = 0.0, .yx = 0.0 };
    pub const yz_plane: Bivec3 = .{ .yz = 1.0, .xz = 0.0, .yx = 0.0 };
    pub const zy_plane: Bivec3 = .{ .yz = -1.0, .xz = 0.0, .yx = 0.0 };
    pub const xz_plane: Bivec3 = .{ .yz = 0.0, .xz = 1.0, .yx = 0.0 };
    pub const zx_plane: Bivec3 = .{ .yz = 0.0, .xz = -1.0, .yx = 0.0 };
    pub const yx_plane: Bivec3 = .{ .yz = 0.0, .xz = 0.0, .yx = 1.0 };
    pub const xy_plane: Bivec3 = .{ .yz = 0.0, .xz = 0.0, .yx = -1.0 };

    /// Checks for equality.
    pub fn eql(self: Bivec3, other: Bivec3) bool {
        return std.meta.eql(self, other);
    }

    test eql {
        try std.testing.expect(Bivec3.zero.eql(.zero));
        try std.testing.expect(!Bivec3.zero.eql(.yz_plane));
        try std.testing.expect(!Bivec3.zero.eql(.zy_plane));
        try std.testing.expect(!Bivec3.zero.eql(.xz_plane));
        try std.testing.expect(!Bivec3.zero.eql(.zx_plane));
        try std.testing.expect(!Bivec3.zero.eql(.yx_plane));
        try std.testing.expect(!Bivec3.zero.eql(.xy_plane));
    }

    /// Returns the bivector scaled by `factor`.
    pub fn scaled(self: Bivec3, factor: f32) Bivec3 {
        return .{
            .yz = self.yz * factor,
            .xz = self.xz * factor,
            .yx = self.yx * factor,
        };
    }

    test scaled {
        var b: Bivec3 = .{ .yz = 1.0, .xz = 2.0, .yx = 3.0 };
        b = b.scaled(2.0);
        try std.testing.expectEqual(Bivec3{ .yz = 2.0, .xz = 4.0, .yx = 6.0 }, b);
    }

    /// Scales the bivector by factor.
    pub fn scale(self: *Bivec3, factor: f32) void {
        self.* = self.scaled(factor);
    }

    test scale {
        var b: Bivec3 = .{ .yz = 1.0, .xz = 2.0, .yx = 3.0 };
        b.scale(2.0);
        try std.testing.expectEqual(Bivec3{ .yz = 2.0, .xz = 4.0, .yx = 6.0 }, b);
    }

    /// Returns the bivector renormalized. Assumes the input is already near normal.
    pub fn renormalized(self: Bivec3) Bivec3 {
        const mag_sq = self.magSq();
        return self.scaled(geom.invSqrtNearOne(mag_sq));
    }

    test renormalized {
        var b: Bivec3 = .{ .yz = 1.05, .xz = 0.0, .yx = 0.0 };
        b = b.renormalized();
        try std.testing.expectApproxEqAbs(b.yz, 1.0, 0.01);
        try std.testing.expectEqual(b.xz, 0.0);
        try std.testing.expectEqual(b.yx, 0.0);
    }

    /// Normalizes the bivector. See `normalized`.
    pub fn renormalize(self: *Bivec3) void {
        self.* = self.normalized();
    }

    test renormalize {
        var b: Bivec3 = .{ .yz = 1.05, .xz = 0.0, .yx = 0.0 };
        b.renormalize();
        try std.testing.expectApproxEqAbs(b.yz, 1.0, 0.01);
        try std.testing.expectEqual(b.xz, 0.0);
        try std.testing.expectEqual(b.yx, 0.0);
    }

    /// Returns the normalized bivector. If the bivector is 0, it is returned unchanged. If your
    /// input is nearly normal already, consider using `renormalized` instead.
    pub fn normalized(self: Bivec3) Bivec3 {
        const mag_sq = self.magSq();
        if (mag_sq == 0) return self;
        return self.scaled(geom.invSqrt(mag_sq));
    }

    test normalized {
        var b: Bivec3 = .{ .yz = 10.0, .xz = 0.0, .yx = 0.0 };
        b = b.normalized();
        try std.testing.expectEqual(Bivec3{ .yz = 1.0, .xz = 0.0, .yx = 0.0 }, b);
        try std.testing.expectEqual(Bivec3.zero, Bivec3.zero.normalized());
    }

    /// Normalizes the bivector. See `normalized`.
    pub fn normalize(self: *Bivec3) void {
        self.* = self.normalized();
    }

    test normalize {
        var b: Bivec3 = .{ .yz = 10.0, .xz = 0.0, .yx = 0.0 };
        b.normalize();
        try std.testing.expectEqual(Bivec3{ .yz = 1.0, .xz = 0.0, .yx = 0.0 }, b);
        b = .zero;
        b.normalize();
        try std.testing.expectEqual(Bivec3.zero, b);
    }

    pub fn magSq(self: Bivec3) f32 {
        return @mulAdd(f32, self.yz, self.yz, @mulAdd(f32, self.xz, self.xz, self.yx * self.yx));
    }

    test magSq {
        const b: Bivec3 = .{ .yz = 2.0, .xz = 3.0, .yx = 4.0 };
        try std.testing.expectEqual(29.0, b.magSq());
    }

    /// Returns the magnitude of the bivector.
    pub fn mag(self: Bivec3) f32 {
        return @sqrt(self.magSq());
    }

    test mag {
        const b: Bivec3 = .{ .yz = 2.0, .xz = 3.0, .yx = 4.0 };
        try std.testing.expectEqual(@sqrt(29.0), b.mag());
    }

    /// Returns the inner product of two bivectors, which results in a scalar representing the
    /// extent to which they occupy the same plane. This is similar to the dot product.
    pub fn innerProd(lhs: Bivec3, rhs: Bivec3) f32 {
        return @mulAdd(f32, -lhs.yz, rhs.yz, @mulAdd(f32, -lhs.xz, rhs.xz, -lhs.yx * rhs.yx));
    }

    test innerProd {
        const a: Bivec3 = .{ .yz = 2.0, .xz = 3.0, .yx = 4.0 };
        const b: Bivec3 = .{ .yz = 5.0, .xz = 6.0, .yx = 7.0 };
        try std.testing.expectEqual(-56, a.innerProd(b));
    }

    /// Raises `e` to the given bivector, resulting in a rotor that rotates on the plane of the
    /// given bivector by twice its magnitude in radians.
    pub fn exp(self: Bivec3) Rotor3 {
        const half = self.mag();
        if (half == 0) return .identity;
        const sin_half = @sin(half);
        const cos_half = @cos(half);
        return .{
            .yz = sin_half * self.yz / half,
            .xz = sin_half * self.xz / half,
            .yx = sin_half * self.yx / half,
            .a = cos_half,
        };
    }

    test exp {
        // Test 0 degree rotations
        try testExpVsPlaneAngle(zy_plane, 0.0);
        try testExpVsPlaneAngle(yz_plane, 0.0);
        try testExpVsPlaneAngle(zx_plane, 0.0);
        try testExpVsPlaneAngle(xz_plane, 0.0);
        try testExpVsPlaneAngle(xy_plane, 0.0);
        try testExpVsPlaneAngle(yx_plane, 0.0);

        // Test 90 degree rotations
        try testExpVsPlaneAngle(yz_plane, math.pi / 2.0);
        try testExpVsPlaneAngle(yz_plane, -math.pi / 2.0);
        try testExpVsPlaneAngle(zy_plane, math.pi / 2.0);
        try testExpVsPlaneAngle(zy_plane, -math.pi / 2.0);

        try testExpVsPlaneAngle(xz_plane, math.pi / 2.0);
        try testExpVsPlaneAngle(xz_plane, -math.pi / 2.0);
        try testExpVsPlaneAngle(zx_plane, math.pi / 2.0);
        try testExpVsPlaneAngle(zx_plane, -math.pi / 2.0);

        try testExpVsPlaneAngle(yx_plane, math.pi / 2.0);
        try testExpVsPlaneAngle(yx_plane, -math.pi / 2.0);
        try testExpVsPlaneAngle(xy_plane, math.pi / 2.0);
        try testExpVsPlaneAngle(xy_plane, -math.pi / 2.0);

        // Test 180 degree rotations
        try testExpVsPlaneAngle(yz_plane, math.pi);
        try testExpVsPlaneAngle(yz_plane, -math.pi);
        try testExpVsPlaneAngle(zy_plane, math.pi);
        try testExpVsPlaneAngle(zy_plane, -math.pi);

        try testExpVsPlaneAngle(xz_plane, math.pi);
        try testExpVsPlaneAngle(xz_plane, -math.pi);
        try testExpVsPlaneAngle(zx_plane, math.pi);
        try testExpVsPlaneAngle(zx_plane, -math.pi);

        try testExpVsPlaneAngle(yx_plane, math.pi);
        try testExpVsPlaneAngle(yx_plane, -math.pi);
        try testExpVsPlaneAngle(xy_plane, math.pi);
        try testExpVsPlaneAngle(xy_plane, -math.pi);

        // Test 360 degree rotations
        try testExpVsPlaneAngle(yz_plane, 2.0 * math.pi);
        try testExpVsPlaneAngle(yz_plane, -2.0 * math.pi);
        try testExpVsPlaneAngle(zy_plane, 2.0 * math.pi);
        try testExpVsPlaneAngle(zy_plane, -2.0 * math.pi);

        try testExpVsPlaneAngle(xz_plane, 2.0 * math.pi);
        try testExpVsPlaneAngle(xz_plane, -2.0 * math.pi);
        try testExpVsPlaneAngle(zx_plane, 2.0 * math.pi);
        try testExpVsPlaneAngle(zx_plane, -2.0 * math.pi);

        try testExpVsPlaneAngle(yx_plane, 2.0 * math.pi);
        try testExpVsPlaneAngle(yx_plane, -2.0 * math.pi);
        try testExpVsPlaneAngle(xy_plane, 2.0 * math.pi);
        try testExpVsPlaneAngle(xy_plane, -2.0 * math.pi);
    }

    // XXX: name inverse vs negate?
    /// Returns bivector negated.
    pub fn negated(self: Bivec3) Bivec3 {
        return self.scaled(-1);
    }

    test negated {
        var v: Bivec3 = .{
            .yz = 1,
            .xz = 2,
            .yx = 3,
        };
        v = v.negated();
        try std.testing.expectEqual(Bivec3{
            .yz = -1,
            .xz = -2,
            .yx = -3,
        }, v);
    }

    /// Negates the bivector.
    pub fn negate(self: *Bivec3) void {
        self.* = self.negated();
    }

    test negate {
        var v: Bivec3 = .{
            .yz = 1,
            .xz = 2,
            .yx = 3,
        };
        v.negate();
        try std.testing.expectEqual(Bivec3{
            .yz = -1,
            .xz = -2,
            .yx = -3,
        }, v);
    }

    /// Returns self multiplied by zyx, results in the orthogonal vector with a magnitude of the
    /// oriented area.
    pub fn dual(self: Bivec3) Vec3 {
        return .{
            .x = self.yz,
            .y = -self.xz,
            .z = -self.yx,
        };
    }

    test dual {
        const a: Bivec3 = .{
            .yz = 1,
            .xz = 2,
            .yx = 3,
        };
        try std.testing.expectEqual(Vec3{ .x = 1, .y = -2, .z = -3 }, a.dual());
        try std.testing.expectEqual(a, a.dual().dual().dual().dual());
        try std.testing.expectEqual(a.negated(), a.dual().dual());
    }

    // XXX: document, test, implement for other types?
    pub fn meet(lhs: Bivec3, rhs: Bivec3) Vec3 {
        return lhs.join(rhs).dual();
    }

    test meet {
        try std.testing.expectEqual(Vec3.zero, xy_plane.meet(xy_plane));
        try std.testing.expectEqual(Vec3.zero, yx_plane.meet(yx_plane));
        try std.testing.expectEqual(Vec3.zero, xy_plane.meet(xy_plane));
        try std.testing.expectEqual(Vec3.zero, yx_plane.meet(xy_plane));

        try std.testing.expectEqual(Vec3.x_pos, xy_plane.meet(xz_plane));
        try std.testing.expectEqual(Vec3.x_pos, yx_plane.meet(zx_plane));
        try std.testing.expectEqual(Vec3.x_neg, xy_plane.meet(zx_plane));
        try std.testing.expectEqual(Vec3.x_neg, yx_plane.meet(xz_plane));

        try std.testing.expectEqual(Vec3.y_pos, yz_plane.meet(yx_plane));
        try std.testing.expectEqual(Vec3.y_pos, zy_plane.meet(xy_plane));
        try std.testing.expectEqual(Vec3.y_neg, yz_plane.meet(xy_plane));
        try std.testing.expectEqual(Vec3.y_neg, zy_plane.meet(yx_plane));

        try std.testing.expectEqual(Vec3.z_pos, zx_plane.meet(zy_plane));
        try std.testing.expectEqual(Vec3.z_pos, xz_plane.meet(yz_plane));
        try std.testing.expectEqual(Vec3.z_neg, zx_plane.meet(yz_plane));
        try std.testing.expectEqual(Vec3.z_neg, xz_plane.meet(zy_plane));
    }

    // XXX: document, test, implement for other types?
    pub fn join(lhs: Bivec3, rhs: Bivec3) Bivec3 {
        return lhs.dual().outerProd(rhs.dual());
    }

    test join {
        try std.testing.expectEqual(zero, xy_plane.join(xy_plane));
        try std.testing.expectEqual(zero, yx_plane.join(yx_plane));
        try std.testing.expectEqual(zero, xy_plane.join(yx_plane));
        try std.testing.expectEqual(zero, yx_plane.join(xy_plane));

        try std.testing.expectEqual(zy_plane, xy_plane.join(zx_plane));
        try std.testing.expectEqual(yz_plane, xy_plane.join(xz_plane));
    }
};

fn testExpVsPlaneAngle(plane: Bivec3, rad: f32) !void {
    const exp = plane.scaled(rad / 2.0).exp();
    const from_plane_angle: Rotor3 = .fromPlaneAngle(plane, rad);
    try std.testing.expectApproxEqAbs(exp.yz, from_plane_angle.yz, 0.01);
    try std.testing.expectApproxEqAbs(exp.xz, from_plane_angle.xz, 0.01);
    try std.testing.expectApproxEqAbs(exp.yx, from_plane_angle.yx, 0.01);
    try std.testing.expectApproxEqAbs(exp.a, from_plane_angle.a, 0.01);
}
