const std = @import("std");
const geom = @import("root.zig");

const math = std.math;

const Rotor3 = geom.Rotor3;
const Vec3 = geom.Vec3;

/// An three dimensional oriented area.
pub const Bivec3 = extern struct {
    /// The area on the yz plane. The sign represents the direction.
    yz: f32,
    /// The area on the xz plane. The sign represents the direction.
    xz: f32,
    /// The area on the yx plane. The sign represents the direction.
    yx: f32,

    pub const zero: Bivec3 = .{ .yz = 0.0, .xz = 0.0, .yx = 0.0 };
    pub const yz_pos: Bivec3 = .{ .yz = 1.0, .xz = 0.0, .yx = 0.0 };
    pub const yz_neg: Bivec3 = .{ .yz = -1.0, .xz = 0.0, .yx = 0.0 };
    pub const xz_pos: Bivec3 = .{ .yz = 0.0, .xz = 1.0, .yx = 0.0 };
    pub const xz_neg: Bivec3 = .{ .yz = 0.0, .xz = -1.0, .yx = 0.0 };
    pub const yx_pos: Bivec3 = .{ .yz = 0.0, .xz = 0.0, .yx = 1.0 };
    pub const yx_neg: Bivec3 = .{ .yz = 0.0, .xz = 0.0, .yx = -1.0 };

    /// Checks for equality.
    pub fn eql(self: Bivec3, other: Bivec3) bool {
        return std.meta.eql(self, other);
    }

    test eql {
        try std.testing.expect(Bivec3.zero.eql(.zero));
        try std.testing.expect(!Bivec3.zero.eql(.yz_pos));
        try std.testing.expect(!Bivec3.zero.eql(.yz_neg));
        try std.testing.expect(!Bivec3.zero.eql(.xz_pos));
        try std.testing.expect(!Bivec3.zero.eql(.xz_neg));
        try std.testing.expect(!Bivec3.zero.eql(.yx_pos));
        try std.testing.expect(!Bivec3.zero.eql(.yx_neg));
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
        try testExpVsPlaneAngle(yz_neg, 0.0);
        try testExpVsPlaneAngle(yz_pos, 0.0);
        try testExpVsPlaneAngle(xz_neg, 0.0);
        try testExpVsPlaneAngle(xz_pos, 0.0);
        try testExpVsPlaneAngle(yx_neg, 0.0);
        try testExpVsPlaneAngle(yx_pos, 0.0);

        // Test 90 degree rotations
        try testExpVsPlaneAngle(yz_pos, math.pi / 2.0);
        try testExpVsPlaneAngle(yz_pos, -math.pi / 2.0);
        try testExpVsPlaneAngle(yz_neg, math.pi / 2.0);
        try testExpVsPlaneAngle(yz_neg, -math.pi / 2.0);

        try testExpVsPlaneAngle(xz_pos, math.pi / 2.0);
        try testExpVsPlaneAngle(xz_pos, -math.pi / 2.0);
        try testExpVsPlaneAngle(xz_neg, math.pi / 2.0);
        try testExpVsPlaneAngle(xz_neg, -math.pi / 2.0);

        try testExpVsPlaneAngle(yx_pos, math.pi / 2.0);
        try testExpVsPlaneAngle(yx_pos, -math.pi / 2.0);
        try testExpVsPlaneAngle(yx_neg, math.pi / 2.0);
        try testExpVsPlaneAngle(yx_neg, -math.pi / 2.0);

        // Test 180 degree rotations
        try testExpVsPlaneAngle(yz_pos, math.pi);
        try testExpVsPlaneAngle(yz_pos, -math.pi);
        try testExpVsPlaneAngle(yz_neg, math.pi);
        try testExpVsPlaneAngle(yz_neg, -math.pi);

        try testExpVsPlaneAngle(xz_pos, math.pi);
        try testExpVsPlaneAngle(xz_pos, -math.pi);
        try testExpVsPlaneAngle(xz_neg, math.pi);
        try testExpVsPlaneAngle(xz_neg, -math.pi);

        try testExpVsPlaneAngle(yx_pos, math.pi);
        try testExpVsPlaneAngle(yx_pos, -math.pi);
        try testExpVsPlaneAngle(yx_neg, math.pi);
        try testExpVsPlaneAngle(yx_neg, -math.pi);

        // Test 360 degree rotations
        try testExpVsPlaneAngle(yz_pos, 2.0 * math.pi);
        try testExpVsPlaneAngle(yz_pos, -2.0 * math.pi);
        try testExpVsPlaneAngle(yz_neg, 2.0 * math.pi);
        try testExpVsPlaneAngle(yz_neg, -2.0 * math.pi);

        try testExpVsPlaneAngle(xz_pos, 2.0 * math.pi);
        try testExpVsPlaneAngle(xz_pos, -2.0 * math.pi);
        try testExpVsPlaneAngle(xz_neg, 2.0 * math.pi);
        try testExpVsPlaneAngle(xz_neg, -2.0 * math.pi);

        try testExpVsPlaneAngle(yx_pos, 2.0 * math.pi);
        try testExpVsPlaneAngle(yx_pos, -2.0 * math.pi);
        try testExpVsPlaneAngle(yx_neg, 2.0 * math.pi);
        try testExpVsPlaneAngle(yx_neg, -2.0 * math.pi);
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
