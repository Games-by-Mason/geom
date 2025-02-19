const std = @import("std");
const geom = @import("root.zig");

const Vec2 = geom.Vec2;
const Rotor2 = geom.Rotor2;

/// A two dimensional column major transform matrix with the redundant components shaved off to save
/// space.
pub const Mat2x3 = packed struct {
    /// The x basis vector.
    x: Col,
    /// The y basis vector.
    y: Col,

    /// `x` and `y` affect rotation, `a` affects translation.
    const Col = packed struct {
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
        const x = inverse.timesPoint(.x_pos);
        const y = inverse.timesPoint(.y_pos);
        return .fromBasis(x, y);
    }

    /// Create a translation matrix from a vector.
    pub fn translation(delta: Vec2) @This() {
        return .{
            .x = .{ .x = 1, .y = 0, .a = delta.x },
            .y = .{ .x = 0, .y = 1, .a = delta.y },
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

    /// Gets the translation component of the matrix.
    pub fn getTranslation(self: @This()) Vec2 {
        return .{ .x = self.x.a, .y = self.y.a };
    }

    /// Gets the rotation component of the matrix in radians. May be removed in the future, present
    /// for compatibility with SDL APIs. Prefer using the matrix to transform points over attempting
    /// to extract the angle from it.
    pub fn getAngle(self: @This()) f32 {
        const cos = self.x.x;
        const sin = self.x.y;
        return std.math.atan2(sin, cos);
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
