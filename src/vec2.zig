const std = @import("std");
const geom = @import("root.zig");

const math = std.math;

const Bivec2 = geom.Bivec2;
const Rotor2 = geom.Rotor2;

/// A two dimensional vector.
pub const Vec2 = packed struct {
    x: f32,
    y: f32,

    /// The zero vector.
    pub const zero: Vec2 = .{ .x = 0, .y = 0 };
    /// The positive y axis.
    pub const y_pos: Vec2 = .{ .x = 0, .y = 1 };
    /// The negative y axis.
    pub const y_neg: Vec2 = .{ .x = 0, .y = -1 };
    /// The positive x axis.
    pub const x_pos: Vec2 = .{ .x = 1, .y = 0 };
    /// The negative x axis.
    pub const x_neg: Vec2 = .{ .x = -1, .y = 0 };

    /// Returns the unit vector in the given direction.
    pub fn unit(rad: f32) Vec2 {
        return .{
            .x = @cos(rad),
            .y = @sin(rad),
        };
    }

    /// Returns the vector scaled by `factor`.
    pub fn scaled(self: Vec2, factor: f32) Vec2 {
        return .{
            .x = self.x * factor,
            .y = self.y * factor,
        };
    }

    /// Scales the vector by `factor`.
    pub fn scale(self: *Vec2, factor: f32) Vec2 {
        self.* = self.scaled(factor);
    }

    /// Returns the vector added to `other`.
    pub fn plus(self: Vec2, other: Vec2) Vec2 {
        return .{
            .x = self.x + other.x,
            .y = self.y + other.y,
        };
    }

    /// Adds `other` to the vector.
    pub fn add(self: *Vec2, other: Vec2) void {
        self.* = self.plus(other);
    }

    /// Returns the vector added to `other` scaled by `factor`
    pub fn plusScaled(self: Vec2, other: Vec2, factor: f32) Vec2 {
        return .{
            .x = self.x + other.x * factor,
            .y = self.y + other.y * factor,
        };
    }

    /// Adds `other` scaled by `factor` to the vector.
    pub fn addScaled(self: *Vec2, other: Vec2, factor: f32) void {
        self.* = self.plus(other, factor);
    }

    /// Returns `other` subtracted from the vector.
    pub fn minus(self: Vec2, other: Vec2) Vec2 {
        return .{
            .x = self.x - other.x,
            .y = self.y - other.y,
        };
    }

    /// Subtracts `other` from the vector.
    pub fn sub(self: *Vec2, other: Vec2) void {
        self.* = self.minus(other);
    }

    /// Returns the vector with its components floored.
    pub fn floored(self: Vec2) Vec2 {
        return .{
            .x = @floor(self.x),
            .y = @floor(self.y),
        };
    }

    /// Floors all components of the vector.
    pub fn floor(self: *Vec2) Vec2 {
        self.* = self.floored();
    }

    /// Returns vector negated.
    pub fn negated(self: Vec2) Vec2 {
        return .{
            .x = -self.x,
            .y = -self.y,
        };
    }

    /// Negates the vector.
    pub fn negate(self: *Vec2) void {
        self.* = self.negated();
    }

    /// Returns the squared magnitude.
    pub fn magSq(self: Vec2) f32 {
        return self.x * self.x + self.y * self.y;
    }

    /// Returns the magnitude.
    pub fn mag(self: Vec2) f32 {
        return @sqrt(self.magSq());
    }

    /// Returns the squared distance between two vectors.
    pub fn distSq(self: Vec2, other: Vec2) f32 {
        return self.minus(other).magSq();
    }

    /// Returns the distance between two vectors.
    pub fn dist(self: Vec2, other: Vec2) f32 {
        return @sqrt(self.distSq(other));
    }

    /// Returns the vector normalized.
    pub fn normalized(self: Vec2) Vec2 {
        const len = self.mag();
        if (len == 0) return self;
        return self.scaled(1.0 / len);
    }

    /// Normalizes the vector.
    pub fn normalize(self: *Vec2) Vec2 {
        self.* = self.normalized();
    }

    /// Returns the component wise product of two vectors.
    pub fn compProd(self: Vec2, other: Vec2) Vec2 {
        return .{
            .x = self.x * other.x,
            .y = self.y * other.y,
        };
    }

    /// Returns the inner product of two vectors. Equivalent to the dot product.
    pub fn innerProd(self: Vec2, other: Vec2) f32 {
        return self.x * other.x + self.y * other.y;
    }

    /// Returns the outer product of two vectors. Generalized form of the cross product.
    pub fn outerProd(lhs: Vec2, rhs: Vec2) Bivec2 {
        return .{
            .xy = lhs.x * rhs.y - rhs.x * lhs.y,
        };
    }

    /// Returns the geometric product of two vectors.
    pub fn geomProd(lhs: Vec2, rhs: Vec2) Rotor2 {
        return .{
            .xy = lhs.outerProd(rhs).xy,
            .a = lhs.innerProd(rhs) + 1.0,
        };
    }

    /// Returns the normal to the vector. Assumes the vector is already normalized.
    pub fn normal(self: Vec2) Vec2 {
        return .{
            .x = -self.y,
            .y = self.x,
        };
    }
};
