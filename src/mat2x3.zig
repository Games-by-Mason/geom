const std = @import("std");
const geom = @import("root.zig");

const Vec2 = geom.Vec2;
const Rotor2 = geom.Rotor2;

/// A two dimensional row major transform matrix with the redundant components shaved off to save
/// space.
pub const Mat2x3 = packed struct {
    /// The x basis vector.
    x: Row,
    /// The y basis vector.
    y: Row,

    /// `x` and `y` affect rotation, `a` affects translation.
    pub const Row = packed struct {
        x: f32,
        y: f32,
        a: f32,
    };

    /// The identity matrix. Has no effect.
    pub const identity: @This() = .{
        .x = .{ .x = 1, .y = 0, .a = 0 },
        .y = .{ .x = 0, .y = 1, .a = 0 },
    };

    /// Create a matrix from two basis vectors.
    pub fn fromBasis(x: Vec2, y: Vec2) Mat2x3 {
        return .{
            .x = .{ .x = x.x, .y = x.y, .a = 0.0 },
            .y = .{ .x = y.x, .y = y.y, .a = 0.0 },
        };
    }

    /// Create a rotation matrix from a rotor.
    pub fn rotation(rotor: Rotor2) @This() {
        const inverse = rotor.inverse();
        const x = inverse.timesVec2(.x_pos);
        const y = inverse.timesVec2(.y_pos);
        return .fromBasis(x, y);
    }

    /// Create a translation matrix from a vector.
    pub fn translation(delta: Vec2) @This() {
        return .{
            .x = .{ .x = 1, .y = 0, .a = delta.x },
            .y = .{ .x = 0, .y = 1, .a = delta.y },
        };
    }

    /// Create a scale matrix from a vector.
    pub fn scale(amount: Vec2) @This() {
        return .{
            .x = .{ .x = amount.x, .y = 0, .a = 0.0 },
            .y = .{ .x = 0, .y = amount.y, .a = 0.0 },
        };
    }

    /// Returns `lhs` multiplied by `rhs`.
    pub fn times(lhs: @This(), rhs: @This()) @This() {
        return .{
            .x = .{
                .x = lhs.x.x * rhs.x.x + lhs.x.y * rhs.y.x,
                .y = lhs.x.x * rhs.x.y + lhs.x.y * rhs.y.y,
                .a = lhs.x.x * rhs.x.a + lhs.x.y * rhs.y.a + lhs.x.a,
            },
            .y = .{
                .x = lhs.y.x * rhs.x.x + lhs.y.y * rhs.y.x,
                .y = lhs.y.x * rhs.x.y + lhs.y.y * rhs.y.y,
                .a = lhs.y.x * rhs.x.a + lhs.y.y * rhs.y.a + lhs.y.a,
            },
        };
    }

    /// Multiplies the vector by `other`.
    pub fn mul(self: *@This(), other: @This()) @This() {
        self.* = self.times(other);
    }

    /// Gets the rotation of the matrix in radians. Useful for human readable output, use for
    /// computation is discouraged.
    pub fn getRotation(self: @This()) f32 {
        const cos = self.x.x;
        const sin = self.x.y;
        return std.math.atan2(sin, cos);
    }

    /// Gets the translation of the matrix. Useful for human readable output, use for computation is
    /// discouraged.
    pub fn getTranslation(self: @This()) Vec2 {
        return .{ .x = self.x.a, .y = self.y.a };
    }

    /// Returns a vector representing a point transformed by this matrix.
    pub fn timesPoint(self: @This(), point: Vec2) Vec2 {
        return .{
            .x = self.x.x * point.x + self.x.y * point.y + self.x.a,
            .y = self.y.x * point.x + self.y.y * point.y + self.y.a,
        };
    }

    /// Returns a vector representing a direction transformed by this matrix.
    pub fn timesDir(self: @This(), point: Vec2) Vec2 {
        return .{
            .x = self.x.x * point.x + self.x.y * point.y,
            .y = self.y.x * point.x + self.y.y * point.y,
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
        .x = .{ .x = 1, .y = 2, .a = 3 },
        .y = .{ .x = 4, .y = 5, .a = 6 },
    };
    const b: Mat2x3 = .{
        .x = .{ .x = 10, .y = 20, .a = 30 },
        .y = .{ .x = 40, .y = 50, .a = 60 },
    };
    try std.testing.expectEqual(
        Mat2x3{
            .x = .{ .x = 90, .y = 120, .a = 153 },
            .y = .{ .x = 240, .y = 330, .a = 426 },
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
        .x = .{ .x = 1, .y = 0, .a = 1 },
        .y = .{ .x = 0, .y = 1, .a = 2 },
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

        try std.testing.expectApproxEqAbs(@cos(std.math.pi / 4.0), m.x.x, 0.01);
        try std.testing.expectApproxEqAbs(@sin(std.math.pi / 4.0), m.x.y, 0.01);
        try std.testing.expectApproxEqAbs(-@sin(std.math.pi / 4.0), m.y.x, 0.01);
        try std.testing.expectApproxEqAbs(@cos(std.math.pi / 4.0), m.y.y, 0.01);
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
            .x = .{ .x = 0.5, .y = 0.0, .a = 0 },
            .y = .{ .x = 0.0, .y = 1.7, .a = 0 },
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

    // Combine rotate/translate/scale
    const t: Mat2x3 = .translation(.{ .x = 1.0, .y = 2.0 });
    const r: Mat2x3 = .rotation(.fromTo(.y_pos, .x_pos));
    const s: Mat2x3 = .scale(.{ .x = 0.5, .y = 3.0 });
    const m = s.times(r).times(t);
    try expectVec2ApproxEql(Vec2{ .x = 1.0, .y = -3.0 }, m.timesPoint(.zero));
    try expectVec2ApproxEql(Vec2{ .x = 0.0, .y = 0.0 }, m.timesDir(.zero));

    try expectVec2ApproxEql(Vec2{ .x = 1.5, .y = -3.0 }, m.timesPoint(.y_pos));
    try expectVec2ApproxEql(Vec2{ .x = 0.5, .y = 0.0 }, m.timesDir(.y_pos));
}
