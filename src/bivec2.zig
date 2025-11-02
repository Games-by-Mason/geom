const std = @import("std");
const geom = @import("root.zig");

const math = std.math;

const Rotor2 = geom.Rotor2;
const Vec2 = geom.Vec2;

/// An two dimensional oriented area.
pub const Bivec2 = extern struct {
    /// The area on the yx plane, incidentally the only plane in two dimensions. The sign represents
    /// the direction.
    yx: f32,

    pub const zero: Bivec2 = .{ .yx = 0.0 };
    pub const yx_plane: Bivec2 = .{ .yx = 1.0 };
    pub const xy_plane: Bivec2 = .{ .yx = -1.0 };

    /// Checks for equality.
    pub fn eql(self: Bivec2, other: Bivec2) bool {
        return std.meta.eql(self, other);
    }

    test eql {
        try std.testing.expect(Bivec2.zero.eql(Bivec2{ .yx = 0.0 }));
        try std.testing.expect(!Bivec2.zero.eql(.yx_plane));
        try std.testing.expect(!Bivec2.zero.eql(.xy_plane));
    }

    /// Returns the bivector scaled by `factor`.
    pub fn scaled(self: Bivec2, factor: f32) Bivec2 {
        return .{ .yx = self.yx * factor };
    }

    test scaled {
        var b: Bivec2 = .{ .yx = 1.0 };
        b = b.scaled(2.0);
        try std.testing.expectEqual(Bivec2{ .yx = 2.0 }, b);
    }

    /// Scales the bivector by factor.
    pub fn scale(self: *Bivec2, factor: f32) void {
        self.* = self.scaled(factor);
    }

    test scale {
        var b: Bivec2 = .{ .yx = 1.0 };
        b.scale(2.0);
        try std.testing.expectEqual(Bivec2{ .yx = 2.0 }, b);
    }

    /// Returns the normalized bivector. If the bivector is 0, it is returned unchanged.
    pub fn normalized(self: Bivec2) Bivec2 {
        if (self.yx == 0.0) return self;
        return .{ .yx = self.yx / self.yx };
    }

    test normalized {
        var b: Bivec2 = .{ .yx = 10.0 };
        b = b.normalized();
        try std.testing.expectEqual(Bivec2{ .yx = 1.0 }, b);
        try std.testing.expectEqual(Bivec2.zero, Bivec2.zero.normalized());
    }

    /// Normalizes the bivector. See `normalized`.
    pub fn normalize(self: *Bivec2) void {
        self.* = self.normalized();
    }

    test normalize {
        var b: Bivec2 = .{ .yx = 10.0 };
        b.normalize();
        try std.testing.expectEqual(Bivec2{ .yx = 1.0 }, b);
        b = .zero;
        b.normalize();
        try std.testing.expectEqual(Bivec2.zero, b);
    }

    /// Returns the magnitude of the bivector.
    pub fn mag(self: Bivec2) f32 {
        return @abs(self.yx);
    }

    test mag {
        const b: Bivec2 = .{ .yx = 3.0 };
        try std.testing.expectEqual(3.0, b.mag());
    }

    /// Returns the inner product of two bivectors, which results in a scalar representing the
    /// extent to which they occupy the same plane. This is similar to the dot product.
    pub fn innerProd(lhs: Bivec2, rhs: Bivec2) f32 {
        return -lhs.yx * rhs.yx;
    }

    test innerProd {
        const a: Bivec2 = .{ .yx = 3.0 };
        const b: Bivec2 = .{ .yx = 2.0 };
        try std.testing.expectEqual(-6.0, a.innerProd(b));
    }

    /// Raises `e` to the given bivector, resulting in a rotor that rotates on the plane of the
    /// given bivector by twice its magnitude in radians.
    pub fn exp(self: Bivec2) Rotor2 {
        return .{
            .yx = @sin(self.yx),
            .a = @cos(self.yx),
        };
    }

    test exp {
        // Test 0 degree rotations
        try testExpVsAngle(yx_plane, 0.0);
        try testExpVsAngle(xy_plane, 0.0);

        // Test 90 degree rotations
        try testExpVsAngle(yx_plane, -math.pi / 2.0);
        try testExpVsAngle(yx_plane, math.pi / 2.0);
        try testExpVsAngle(xy_plane, -math.pi / 2.0);
        try testExpVsAngle(xy_plane, math.pi / 2.0);

        // Test 180 degree rotations
        try testExpVsAngle(yx_plane, -math.pi);
        try testExpVsAngle(yx_plane, math.pi);
        try testExpVsAngle(xy_plane, -math.pi);
        try testExpVsAngle(xy_plane, math.pi);

        // Test 360 degree rotations
        try testExpVsAngle(yx_plane, -2.0 * math.pi);
        try testExpVsAngle(yx_plane, 2.0 * math.pi);
        try testExpVsAngle(xy_plane, -2.0 * math.pi);
        try testExpVsAngle(xy_plane, 2.0 * math.pi);
    }
};

fn testExpVsAngle(plane: Bivec2, angle: f32) !void {
    const exp = plane.scaled(angle / 2.0).exp();
    const from_angle: Rotor2 = .fromAngle(if (plane.yx < 0.0) -angle else angle);
    try std.testing.expectApproxEqAbs(exp.yx, from_angle.yx, 0.01);
    try std.testing.expectApproxEqAbs(exp.a, from_angle.a, 0.01);
}
