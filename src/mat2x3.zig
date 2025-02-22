const std = @import("std");
const geom = @import("root.zig");

const Vec2 = geom.Vec2;
const Vec3 = geom.Vec3;
const Rotor2 = geom.Rotor2;

/// A row major affine transformation matrix for working in two dimensions.
pub const Mat2x3 = extern struct {
    /// Row 0, the x basis vector.
    r0: Vec3,
    /// Row 1, the y basis vector.
    r1: Vec3,

    /// The identity matrix. Has no effect.
    pub const identity: @This() = .{
        .r0 = .{ .x = 1, .y = 0, .z = 0 },
        .r1 = .{ .x = 0, .y = 1, .z = 0 },
    };

    /// Create a rotation matrix from a rotor.
    pub fn rotation(rotor: Rotor2) @This() {
        const inverse = rotor.inverse();
        const x = inverse.timesVec2(.x_pos);
        const y = inverse.timesVec2(.y_pos);
        return .{
            .r0 = x.dir(),
            .r1 = y.dir(),
        };
    }

    /// Create a translation matrix from a vector.
    pub fn translation(delta: Vec2) @This() {
        return .{
            .r0 = .{ .x = 1, .y = 0, .z = delta.x },
            .r1 = .{ .x = 0, .y = 1, .z = delta.y },
        };
    }

    /// Create a scale matrix from a vector.
    pub fn scale(amount: Vec2) @This() {
        return .{
            .r0 = .{ .x = amount.x, .y = 0, .z = 0.0 },
            .r1 = .{ .x = 0, .y = amount.y, .z = 0.0 },
        };
    }

    /// Returns `lhs` multiplied by `rhs`.
    pub fn times(lhs: @This(), rhs: @This()) @This() {
        return .{
            .r0 = .{
                .x = @mulAdd(f32, lhs.r0.x, rhs.r0.x, lhs.r0.y * rhs.r1.x),
                .y = @mulAdd(f32, lhs.r0.x, rhs.r0.y, lhs.r0.y * rhs.r1.y),
                .z = @mulAdd(f32, lhs.r0.x, rhs.r0.z, @mulAdd(f32, lhs.r0.y, rhs.r1.z, lhs.r0.z)),
            },
            .r1 = .{
                .x = @mulAdd(f32, lhs.r1.x, rhs.r0.x, lhs.r1.y * rhs.r1.x),
                .y = @mulAdd(f32, lhs.r1.x, rhs.r0.y, lhs.r1.y * rhs.r1.y),
                .z = @mulAdd(f32, lhs.r1.x, rhs.r0.z, @mulAdd(f32, lhs.r1.y, rhs.r1.z, lhs.r1.z)),
            },
        };
    }

    /// Multiplies the matrix by `other`.
    pub fn mul(self: *@This(), other: @This()) void {
        self.* = self.times(other);
    }

    /// The same as `times`, but the arguments are reversed. This is often more intuitive and less
    /// verbose.
    pub fn applied(self: @This(), other: @This()) @This() {
        return other.times(self);
    }

    /// The same as `mul`, but the arguments are reversed. This is often more intuitive and less
    /// verbose.
    pub fn apply(self: *@This(), other: @This()) void {
        self.* = self.applied(other);
    }

    /// Gets the rotation of the matrix in radians. Useful for human readable output, use for
    /// computation is discouraged.
    pub fn getRotation(self: @This()) f32 {
        const cos = self.r0.x;
        const sin = self.r0.y;
        return std.math.atan2(sin, cos);
    }

    /// Gets the translation of the matrix. Useful for human readable output, use for computation is
    /// discouraged.
    pub fn getTranslation(self: @This()) Vec2 {
        return .{ .x = self.r0.z, .y = self.r1.z };
    }

    /// Returns a vector representing a point transformed by this matrix.
    pub fn timesPoint(self: @This(), v: Vec2) Vec2 {
        return .{
            .x = self.r0.innerProd(v.point()),
            .y = self.r1.innerProd(v.point()),
        };
    }

    /// Returns a vector representing a direction transformed by this matrix.
    pub fn timesDir(self: @This(), v: Vec2) Vec2 {
        return self.timesVec3(v.dir()).xy();
    }

    /// Returns a vector representing a direction transformed by this matrix.
    pub fn timesVec3(self: @This(), v: Vec3) Vec3 {
        return .{
            .x = self.r0.innerProd(v),
            .y = self.r1.innerProd(v),
            .z = Vec3.z_pos.innerProd(v),
        };
    }
};

fn expectVec2ApproxEql(expected: Vec2, actual: Vec2) !void {
    try std.testing.expectApproxEqAbs(expected.x, actual.x, 0.01);
    try std.testing.expectApproxEqAbs(expected.y, actual.y, 0.01);
}

test "mat" {
    // Test multiplying and being able to access all fields
    const a: Mat2x3 = .{
        .r0 = .{ .x = 1, .y = 2, .z = 3 },
        .r1 = .{ .x = 4, .y = 5, .z = 6 },
    };
    const b: Mat2x3 = .{
        .r0 = .{ .x = 10, .y = 20, .z = 30 },
        .r1 = .{ .x = 40, .y = 50, .z = 60 },
    };
    try std.testing.expectEqual(
        Mat2x3{
            .r0 = .{ .x = 90, .y = 120, .z = 153 },
            .r1 = .{ .x = 240, .y = 330, .z = 426 },
        },
        a.times(b),
    );

    // Identity only
    const p1: Vec2 = .{ .x = 2.0, .y = 3.0 };
    const p2: Vec2 = .{ .x = 4.0, .y = -2.0 };
    try std.testing.expectEqual(Mat2x3.identity, Mat2x3.identity.times(.identity));
    try std.testing.expectEqual(p1, Mat2x3.identity.timesPoint(p1));
    try std.testing.expectEqual(p2, Mat2x3.identity.timesPoint(p2));

    // Translate only
    try std.testing.expectEqual(Mat2x3{
        .r0 = .{ .x = 1, .y = 0, .z = 1 },
        .r1 = .{ .x = 0, .y = 1, .z = 2 },
    }, Mat2x3.translation(.{ .x = 1, .y = 2 }));
    try std.testing.expectEqual(
        Vec2{ .x = 3, .y = 5 },
        Mat2x3.translation(.{ .x = 1, .y = 2 }).timesPoint(.{ .x = 2, .y = 3 }),
    );
    try std.testing.expectEqual(
        Vec2{ .x = 7, .y = 5 },
        Mat2x3.translation(.{ .x = -1, .y = 3 }).timesPoint(.{ .x = 8, .y = 2 }),
    );
    try std.testing.expectEqual(
        Vec2{ .x = 2, .y = 3 },
        Mat2x3.translation(.{ .x = 1, .y = 2 }).timesDir(.{ .x = 2, .y = 3 }),
    );
    try std.testing.expectEqual(
        Vec2{ .x = 8, .y = 2 },
        Mat2x3.translation(.{ .x = -1, .y = 3 }).timesDir(.{ .x = 8, .y = 2 }),
    );
    try std.testing.expectEqual(0, Mat2x3.translation(.{ .x = -1, .y = 3 }).getRotation());

    // Rotate only
    {
        const m = Mat2x3.rotation(Rotor2.fromTo(.y_pos, .x_pos).nlerp(.identity, 0.5));
        try std.testing.expectApproxEqAbs(std.math.pi / 4.0, m.getRotation(), 0.01);
        try std.testing.expectEqual(Vec2.zero, m.getTranslation());

        try std.testing.expectApproxEqAbs(@cos(std.math.pi / 4.0), m.r0.x, 0.01);
        try std.testing.expectApproxEqAbs(@sin(std.math.pi / 4.0), m.r0.y, 0.01);
        try std.testing.expectApproxEqAbs(-@sin(std.math.pi / 4.0), m.r1.x, 0.01);
        try std.testing.expectApproxEqAbs(@cos(std.math.pi / 4.0), m.r1.y, 0.01);
    }

    try expectVec2ApproxEql(
        Vec2.y_pos,
        Mat2x3.rotation(.fromTo(.x_pos, .y_pos)).timesPoint(.x_pos),
    );
    try expectVec2ApproxEql(
        Vec2.x_neg,
        Mat2x3.rotation(.fromTo(.x_pos, .y_pos)).timesPoint(.y_pos),
    );
    try expectVec2ApproxEql(
        Vec2.x_pos,
        Mat2x3.rotation(.fromTo(.x_neg, .x_pos)).timesPoint(.x_neg),
    );
    try expectVec2ApproxEql(
        Vec2.y_neg,
        Mat2x3.rotation(.fromTo(.x_neg, .x_pos)).timesPoint(.y_pos),
    );

    try expectVec2ApproxEql(
        Vec2.y_pos,
        Mat2x3.rotation(.fromTo(.x_pos, .y_pos)).timesDir(.x_pos),
    );
    try expectVec2ApproxEql(
        Vec2.x_neg,
        Mat2x3.rotation(.fromTo(.x_pos, .y_pos)).timesDir(.y_pos),
    );
    try expectVec2ApproxEql(
        Vec2.x_pos,
        Mat2x3.rotation(.fromTo(.x_neg, .x_pos)).timesDir(.x_neg),
    );
    try expectVec2ApproxEql(
        Vec2.y_neg,
        Mat2x3.rotation(.fromTo(.x_neg, .x_pos)).timesDir(.y_pos),
    );

    // Scale only
    try std.testing.expectEqual(
        Mat2x3{
            .r0 = .{ .x = 0.5, .y = 0.0, .z = 0 },
            .r1 = .{ .x = 0.0, .y = 1.7, .z = 0 },
        },
        Mat2x3.scale(.{ .x = 0.5, .y = 1.7 }),
    );
    try std.testing.expectEqual(
        Vec2{ .x = 0.5, .y = -6.0 },
        Mat2x3.scale(.{ .x = 0.5, .y = -2.0 }).timesPoint(.{ .x = 1.0, .y = 3.0 }),
    );
    try std.testing.expectEqual(
        Vec2{ .x = 0.5, .y = -6.0 },
        Mat2x3.scale(.{ .x = 0.5, .y = -2.0 }).timesDir(.{ .x = 1.0, .y = 3.0 }),
    );
    try std.testing.expectEqual(0.0, Mat2x3.scale(.{ .x = 0.5, .y = -2.0 }).getRotation());
    try std.testing.expectEqual(Vec2.zero, Mat2x3.scale(.{ .x = 0.5, .y = -2.0 }).getTranslation());

    // Apply translation, rotation, and then scale
    const t: Mat2x3 = .translation(.{ .x = 1.0, .y = 2.0 });
    const r: Mat2x3 = .rotation(.fromTo(.y_pos, .x_pos));
    const s: Mat2x3 = .scale(.{ .x = 0.5, .y = 3.0 });
    {
        const m = s.times(r).times(t);

        try expectVec2ApproxEql(Vec2{ .x = 1.0, .y = -3.0 }, m.timesPoint(.zero));
        try expectVec2ApproxEql(Vec2{ .x = 0.0, .y = 0.0 }, m.timesDir(.zero));

        try expectVec2ApproxEql(Vec2{ .x = 1.5, .y = -3.0 }, m.timesPoint(.y_pos));
        try expectVec2ApproxEql(Vec2{ .x = 0.5, .y = 0.0 }, m.timesDir(.y_pos));
    }

    // The same thing, but we use `.mul`
    {
        var m: Mat2x3 = .identity;
        m.mul(s);
        m.mul(r);
        m.mul(t);

        try expectVec2ApproxEql(Vec2{ .x = 1.0, .y = -3.0 }, m.timesPoint(.zero));
        try expectVec2ApproxEql(Vec2{ .x = 0.0, .y = 0.0 }, m.timesDir(.zero));

        try expectVec2ApproxEql(Vec2{ .x = 1.5, .y = -3.0 }, m.timesPoint(.y_pos));
        try expectVec2ApproxEql(Vec2{ .x = 0.5, .y = 0.0 }, m.timesDir(.y_pos));
    }

    // The same thing, but doing `times` in the correct order
    {
        var m: Mat2x3 = .identity;
        m = t.times(m);
        m = r.times(m);
        m = s.times(m);

        try expectVec2ApproxEql(Vec2{ .x = 1.0, .y = -3.0 }, m.timesPoint(.zero));
        try expectVec2ApproxEql(Vec2{ .x = 0.0, .y = 0.0 }, m.timesDir(.zero));

        try expectVec2ApproxEql(Vec2{ .x = 1.5, .y = -3.0 }, m.timesPoint(.y_pos));
        try expectVec2ApproxEql(Vec2{ .x = 0.5, .y = 0.0 }, m.timesDir(.y_pos));
    }

    // The same thing, but using apply
    {
        var m: Mat2x3 = .identity;
        m.apply(t);
        m.apply(r);
        m.apply(s);

        try expectVec2ApproxEql(Vec2{ .x = 1.0, .y = -3.0 }, m.timesPoint(.zero));
        try expectVec2ApproxEql(Vec2{ .x = 0.0, .y = 0.0 }, m.timesDir(.zero));

        try expectVec2ApproxEql(Vec2{ .x = 1.5, .y = -3.0 }, m.timesPoint(.y_pos));
        try expectVec2ApproxEql(Vec2{ .x = 0.5, .y = 0.0 }, m.timesDir(.y_pos));
    }

    // The same thing, but using applied
    {
        const m = t.applied(r).applied(s);

        try expectVec2ApproxEql(Vec2{ .x = 1.0, .y = -3.0 }, m.timesPoint(.zero));
        try expectVec2ApproxEql(Vec2{ .x = 0.0, .y = 0.0 }, m.timesDir(.zero));

        try expectVec2ApproxEql(Vec2{ .x = 1.5, .y = -3.0 }, m.timesPoint(.y_pos));
        try expectVec2ApproxEql(Vec2{ .x = 0.5, .y = 0.0 }, m.timesDir(.y_pos));
    }
}
