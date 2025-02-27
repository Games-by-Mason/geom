const std = @import("std");
const geom = @import("root.zig");

const Rotor2 = geom.Rotor2;
const Vec2 = geom.Vec2;

/// An two dimensional oriented area.
pub const Bivec2 = extern struct {
    /// The area on the xy plane, incidentally the only plane in two dimensions. The sign represents
    /// the direction.
    xy: f32,

    /// The zero bivector.
    pub const zero: Bivec2 = .{ .xy = 0.0 };

    /// Checks for equality.
    pub fn eql(self: Bivec2, other: Bivec2) bool {
        return std.meta.eql(self, other);
    }

    test eql {
        try std.testing.expect(Bivec2.zero.eql(Bivec2{ .xy = 0.0 }));
        try std.testing.expect(!Bivec2.zero.eql(Bivec2{ .xy = 1.0 }));
    }

    /// Returns the bivector scaled by `factor`.
    pub fn scaled(self: Bivec2, factor: f32) Bivec2 {
        return .{ .xy = self.xy * factor };
    }

    test scaled {
        var b: Bivec2 = .{ .xy = 1.0 };
        b = b.scaled(2.0);
        try std.testing.expectEqual(Bivec2{ .xy = 2.0 }, b);
    }

    /// Scales the bivector by factor.
    pub fn scale(self: *Bivec2, factor: f32) void {
        self.* = self.scaled(factor);
    }

    test scale {
        var b: Bivec2 = .{ .xy = 1.0 };
        b.scale(2.0);
        try std.testing.expectEqual(Bivec2{ .xy = 2.0 }, b);
    }

    /// Returns the normalized bivector. If the bivector is 0, it is returned unchanged.
    pub fn normalized(self: Bivec2) Bivec2 {
        if (self.xy == 0.0) return self;
        return .{ .xy = self.xy / self.xy };
    }

    test normalized {
        var b: Bivec2 = .{ .xy = 10.0 };
        b = b.normalized();
        try std.testing.expectEqual(Bivec2{ .xy = 1.0 }, b);
        try std.testing.expectEqual(Bivec2.zero, Bivec2.zero.normalized());
    }

    /// Normalizes the bivector. See `normalized`.
    pub fn normalize(self: *Bivec2) void {
        self.* = self.normalized();
    }

    test normalize {
        var b: Bivec2 = .{ .xy = 10.0 };
        b.normalize();
        try std.testing.expectEqual(Bivec2{ .xy = 1.0 }, b);
        b = .zero;
        b.normalize();
        try std.testing.expectEqual(Bivec2.zero, b);
    }

    /// Returns the magnitude of the bivector.
    pub fn mag(self: Bivec2) f32 {
        return @abs(self.xy);
    }

    test mag {
        const b: Bivec2 = .{ .xy = 3.0 };
        try std.testing.expectEqual(3.0, b.mag());
    }

    /// Returns the inner product of two bivectors, which results in a scalar representing the
    /// extent to which they occupy the same plane. This is similar to the dot product.
    pub fn innerProd(lhs: Bivec2, rhs: Bivec2) f32 {
        return -lhs.xy * rhs.xy;
    }

    test innerProd {
        const a: Bivec2 = .{ .xy = 3.0 };
        const b: Bivec2 = .{ .xy = 2.0 };
        try std.testing.expectEqual(-6.0, a.innerProd(b));
    }

    /// Raises `e` to the given bivector, resulting in a rotor that rotates on the plane of the
    /// given bivector by twice its magnitude in radians.
    pub fn exp(self: Bivec2) Rotor2 {
        return .{
            .xy = -@sin(self.xy),
            .a = @cos(self.xy),
        };
    }

    test exp {
        const pi = std.math.pi / 2.0;
        const xy: Bivec2 = Vec2.x_pos.outerProd(.y_pos);
        const yx: Bivec2 = Vec2.y_pos.outerProd(.x_pos);

        // Test 0 degree rotations
        try testExpVsAngle(xy, 0.0);
        try testExpVsAngle(yx, 0.0);

        // Test 90 degree rotations
        try testExpVsAngle(xy, pi / 2.0);
        try testExpVsAngle(xy, -pi / 2.0);
        try testExpVsAngle(yx, pi / 2.0);
        try testExpVsAngle(yx, -pi / 2.0);

        // Test 180 degree rotations
        try testExpVsAngle(xy, pi);
        try testExpVsAngle(xy, -pi);
        try testExpVsAngle(yx, pi);
        try testExpVsAngle(yx, -pi);

        // Test 360 degree rotations
        try testExpVsAngle(xy, 2.0 * pi);
        try testExpVsAngle(xy, -2.0 * pi);
        try testExpVsAngle(yx, 2.0 * pi);
        try testExpVsAngle(yx, -2.0 * pi);
    }
};

fn testExpVsAngle(plane: Bivec2, angle: f32) !void {
    const exp = plane.scaled(angle / 2.0).exp();
    const from_angle: Rotor2 = .fromAngle(if (plane.xy < 0.0) -angle else angle);
    try std.testing.expectApproxEqAbs(exp.xy, from_angle.xy, 0.01);
    try std.testing.expectApproxEqAbs(exp.a, from_angle.a, 0.01);
}
