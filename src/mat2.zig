const std = @import("std");
const geom = @import("root.zig");

const Rotor2 = geom.Rotor2;
const Vec2 = geom.Vec2;

/// A 2x2 row major transformation matrix.
pub const Mat2 = extern struct {
    /// Row 0, the x basis vector.
    r0: Vec2,
    /// Row 1, the y basis vector.
    r1: Vec2,

    /// The identity matrix. Has no effect.
    pub const identity: @This() = .{
        .r0 = .{ .x = 1, .y = 0 },
        .r1 = .{ .x = 0, .y = 1 },
    };

    test identity {
        const p1: Vec2 = .{ .x = 2.0, .y = 3.0 };
        const p2: Vec2 = .{ .x = 4.0, .y = -2.0 };
        try std.testing.expectEqual(identity, identity.times(.identity));
        try std.testing.expectEqual(p1, identity.timesVec2(p1));
        try std.testing.expectEqual(p2, identity.timesVec2(p2));
    }

    /// Checks for equality.
    pub fn eql(self: Mat2, other: Mat2) bool {
        return std.meta.eql(self, other);
    }

    test eql {
        try std.testing.expect(identity.eql(identity));
        try std.testing.expect(!identity.eql(rotation(.fromTo(.x_pos, .y_pos))));
    }

    /// Create a rotation matrix from a rotor.
    pub fn rotation(rotor: Rotor2) @This() {
        const inverse = rotor.inverse();
        return .{
            .r0 = inverse.timesVec2(.x_pos),
            .r1 = inverse.timesVec2(.y_pos),
        };
    }

    test rotation {
        const m = Mat2.rotation(Rotor2.fromTo(.y_pos, .x_pos).nlerp(.identity, 0.5));
        try std.testing.expectApproxEqAbs(std.math.pi / 4.0, m.getRotation(), 0.01);

        try std.testing.expectApproxEqAbs(@cos(std.math.pi / 4.0), m.r0.x, 0.01);
        try std.testing.expectApproxEqAbs(@sin(std.math.pi / 4.0), m.r0.y, 0.01);
        try std.testing.expectApproxEqAbs(-@sin(std.math.pi / 4.0), m.r1.x, 0.01);
        try std.testing.expectApproxEqAbs(@cos(std.math.pi / 4.0), m.r1.y, 0.01);

        try expectVec2ApproxEql(
            .y_pos,
            Mat2.rotation(.fromTo(.x_pos, .y_pos)).timesVec2(.x_pos),
        );
        try expectVec2ApproxEql(
            .x_neg,
            Mat2.rotation(.fromTo(.x_pos, .y_pos)).timesVec2(.y_pos),
        );
        try expectVec2ApproxEql(
            .x_pos,
            Mat2.rotation(.fromTo(.x_neg, .x_pos)).timesVec2(.x_neg),
        );
        try expectVec2ApproxEql(
            .y_neg,
            Mat2.rotation(.fromTo(.x_neg, .x_pos)).timesVec2(.y_pos),
        );
    }

    pub fn rotated(self: @This(), rotor: Rotor2) @This() {
        return rotation(rotor).times(self);
    }

    test rotated {
        const r: Rotor2 = .fromTo(.x_pos, .y_pos);
        try std.testing.expectEqual(
            rotation(r).times(.identity),
            identity.rotated(r),
        );
    }

    /// Create a scale matrix from a vector.
    pub fn scale(amount: Vec2) @This() {
        return .{
            .r0 = .{ .x = amount.x, .y = 0 },
            .r1 = .{ .x = 0, .y = amount.y },
        };
    }

    test scale {
        try std.testing.expectEqual(
            Mat2{
                .r0 = .{ .x = 0.5, .y = 0.0 },
                .r1 = .{ .x = 0.0, .y = 1.7 },
            },
            Mat2.scale(.{ .x = 0.5, .y = 1.7 }),
        );
        try std.testing.expectEqual(
            Vec2{ .x = 0.5, .y = -6.0 },
            Mat2.scale(.{ .x = 0.5, .y = -2.0 }).timesVec2(.{ .x = 1.0, .y = 3.0 }),
        );
        try std.testing.expectEqual(0.0, Mat2.scale(.{ .x = 0.5, .y = -2.0 }).getRotation());
    }

    pub fn scaled(self: @This(), delta: Vec2) @This() {
        return scale(delta).times(self);
    }

    test scaled {
        try std.testing.expectEqual(
            Mat2{
                .r0 = .{ .x = 0.5, .y = 0.0 },
                .r1 = .{ .x = 0.0, .y = 1.7 },
            },
            Mat2.scale(.{ .x = 0.5, .y = 1.7 }),
        );
        try std.testing.expectEqual(
            Vec2{ .x = 0.5, .y = -6.0 },
            Mat2.identity.scaled(.{ .x = 0.5, .y = -2.0 })
                .timesVec2(.{ .x = 1.0, .y = 3.0 }),
        );
    }

    test "rotatedScaled" {
        var m = Mat2.identity;
        m = m.rotated(.fromAngle(std.math.pi));
        m = m.scaled(.splat(0.5));
        try expectVec2ApproxEql(Vec2{ .x = -0.5, .y = 0.0 }, m.timesVec2(.x_pos));
    }

    /// Returns `lhs` multiplied by `rhs`.
    pub fn times(lhs: Mat2, rhs: Mat2) Mat2 {
        return .{
            .r0 = .{
                .x = @mulAdd(f32, lhs.r0.x, rhs.r0.x, lhs.r0.y * rhs.r1.x),
                .y = @mulAdd(f32, lhs.r0.x, rhs.r0.y, lhs.r0.y * rhs.r1.y),
            },
            .r1 = .{
                .x = @mulAdd(f32, lhs.r1.x, rhs.r0.x, lhs.r1.y * rhs.r1.x),
                .y = @mulAdd(f32, lhs.r1.x, rhs.r0.y, lhs.r1.y * rhs.r1.y),
            },
        };
    }

    test times {
        const a: Mat2 = .{
            .r0 = .{ .x = 1, .y = 2 },
            .r1 = .{ .x = 3, .y = 4 },
        };
        const b: Mat2 = .{
            .r0 = .{ .x = 10, .y = 20 },
            .r1 = .{ .x = 30, .y = 40 },
        };
        try std.testing.expectEqual(
            Mat2{
                .r0 = .{ .x = 70, .y = 100 },
                .r1 = .{ .x = 150, .y = 220 },
            },
            a.times(b),
        );
    }

    /// Multiplies the matrix by `other`.
    pub fn mul(self: *@This(), other: @This()) void {
        self.* = self.times(other);
    }

    test mul {
        const r: Mat2 = .rotation(.fromTo(.y_pos, .x_pos));
        const s: Mat2 = .scale(.{ .x = 0.5, .y = 3.0 });

        var m: Mat2 = .identity;
        m.mul(s);
        m.mul(r);

        try std.testing.expectEqual(m, s.times(r));
    }

    /// The same as `times`, but the arguments are reversed. This is often more intuitive and less
    /// verbose.
    pub fn applied(self: @This(), other: @This()) @This() {
        return other.times(self);
    }

    test applied {
        const r: Mat2 = .rotation(.fromTo(.y_pos, .x_pos));
        const s: Mat2 = .scale(.{ .x = 0.5, .y = 3.0 });

        const m = identity.applied(r).applied(s);

        try std.testing.expectEqual(m, s.times(r));
    }

    /// The same as `mul`, but the arguments are reversed. This is often more intuitive and less
    /// verbose.
    pub fn apply(self: *@This(), other: @This()) void {
        self.* = self.applied(other);
    }

    test apply {
        const r: Mat2 = .rotation(.fromTo(.y_pos, .x_pos));
        const s: Mat2 = .scale(.{ .x = 0.5, .y = 3.0 });

        var m: Mat2 = .identity;
        m.apply(r);
        m.apply(s);

        try std.testing.expectEqual(m, s.times(r));
    }

    /// Gets the rotation of the matrix in radians. Useful for human readable output, use for
    /// computation is discouraged.
    pub fn getRotation(self: @This()) f32 {
        const cos = self.r0.x;
        const sin = self.r0.y;
        return std.math.atan2(sin, cos);
    }

    test getRotation {
        const r: Mat2 = .rotation(.fromTo(.y_pos, .x_pos));
        try std.testing.expectEqual(std.math.pi / 2.0, r.getRotation());
    }

    /// Multiplies the matrix by a homogeneous vec3.
    pub fn timesVec2(self: @This(), v: Vec2) Vec2 {
        return .{
            .x = self.r0.innerProd(v),
            .y = self.r1.innerProd(v),
        };
    }

    test timesVec2 {
        try expectVec2ApproxEql(
            Vec2.y_pos,
            Mat2.rotation(.fromTo(.x_pos, .y_pos)).timesVec2(.x_pos),
        );
    }

    /// Returns the transpose of the matrix. For pure rotation matrices, the transpose is equivalent
    /// to the inverse.
    pub fn transposed(self: @This()) Mat2 {
        return .{
            .r0 = .{ .x = self.r0.x, .y = self.r1.x },
            .r1 = .{ .x = self.r0.y, .y = self.r1.y },
        };
    }

    test transposed {
        const m: Mat2 = .{
            .r0 = .{ .x = 1, .y = 2 },
            .r1 = .{ .x = 3, .y = 4 },
        };
        const t: Mat2 = .{
            .r0 = .{ .x = 1, .y = 3 },
            .r1 = .{ .x = 2, .y = 4 },
        };
        try std.testing.expectEqual(t, m.transposed());

        const r = rotation(.fromTo(
            .{ .x = 1, .y = 2 },
            .{ .x = 3, .y = 4 },
        ));
        try expectMat2ApproxEq(identity, r.times(r.transposed()));
    }

    /// Transposes the matrix. For pure rotation matrices, the transpose is equivalent to the
    /// inverse.
    pub fn transpose(self: *@This()) void {
        self.* = self.transposed();
    }

    test transpose {
        var m: Mat2 = .{
            .r0 = .{ .x = 1, .y = 2 },
            .r1 = .{ .x = 3, .y = 4 },
        };
        m.transpose();
        const t: Mat2 = .{
            .r0 = .{ .x = 1, .y = 3 },
            .r1 = .{ .x = 2, .y = 4 },
        };
        try std.testing.expectEqual(m, t);
    }
};

fn expectMat2ApproxEq(lhs: Mat2, rhs: Mat2) !void {
    try expectVec2ApproxEql(lhs.r0, rhs.r0);
    try expectVec2ApproxEql(lhs.r1, rhs.r1);
}

fn expectVec2ApproxEql(expected: Vec2, actual: Vec2) !void {
    try std.testing.expectApproxEqAbs(expected.x, actual.x, 0.0001);
    try std.testing.expectApproxEqAbs(expected.y, actual.y, 0.0001);
}
