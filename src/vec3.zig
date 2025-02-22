const std = @import("std");
const geom = @import("root.zig");

const math = std.math;

const Vec2 = geom.Vec2;
const Bivec2 = geom.Bivec2;
const Rotor2 = geom.Rotor2;

/// A two dimensional vector.
pub const Vec3 = extern struct {
    x: f32,
    y: f32,
    z: f32,

    /// The zero vector.
    pub const zero: Vec3 = .{ .x = 0, .y = 0, .z = 0.0 };
    /// The positive x axis.
    pub const x_pos: Vec3 = .{ .x = 1, .y = 0, .z = 0.0 };
    /// The negative x axis.
    pub const x_neg: Vec3 = .{ .x = -1, .y = 0, .z = 0.0 };
    /// The positive y axis.
    pub const y_pos: Vec3 = .{ .x = 0, .y = 1, .z = 0.0 };
    /// The negative y axis.
    pub const y_neg: Vec3 = .{ .x = 0, .y = -1, .z = 0.0 };
    /// The positive z axis.
    pub const z_pos: Vec3 = .{ .x = 0, .y = 0, .z = 1.0 };
    /// The negative z axis.
    pub const z_neg: Vec3 = .{ .x = 0, .y = 0, .z = -1.0 };

    /// Returns the vector scaled by `factor`.
    pub fn scaled(self: Vec3, factor: f32) Vec3 {
        return .{
            .x = self.x * factor,
            .y = self.y * factor,
            .z = self.z * factor,
        };
    }

    /// Scales the vector by `factor`.
    pub fn scale(self: *Vec3, factor: f32) Vec3 {
        self.* = self.scaled(factor);
    }

    /// Returns the vector added to `other`.
    pub fn plus(self: Vec3, other: Vec3) Vec3 {
        return .{
            .x = self.x + other.x,
            .y = self.y + other.y,
            .z = self.z + other.z,
        };
    }

    /// Adds `other` to the vector.
    pub fn add(self: *Vec3, other: Vec3) void {
        self.* = self.plus(other);
    }

    /// Returns the vector added to `other` scaled by `factor`
    pub fn plusScaled(self: Vec3, other: Vec3, factor: f32) Vec3 {
        return .{
            .x = @mulAdd(f32, other.x, factor, self.x),
            .y = @mulAdd(f32, other.y, factor, self.y),
            .z = @mulAdd(f32, other.z, factor, self.z),
        };
    }

    /// Adds `other` scaled by `factor` to the vector.
    pub fn addScaled(self: *Vec3, other: Vec3, factor: f32) void {
        self.* = self.plus(other, factor);
    }

    /// Returns `other` subtracted from the vector.
    pub fn minus(self: Vec3, other: Vec3) Vec3 {
        return .{
            .x = self.x - other.x,
            .y = self.y - other.y,
            .z = self.z - other.z,
        };
    }

    /// Subtracts `other` from the vector.
    pub fn sub(self: *Vec3, other: Vec3) void {
        self.* = self.minus(other);
    }

    /// Returns the vector with its components floored.
    pub fn floored(self: Vec3) Vec3 {
        return .{
            .x = @floor(self.x),
            .y = @floor(self.y),
            .z = @floor(self.z),
        };
    }

    /// Floors all components of the vector.
    pub fn floor(self: *Vec3) Vec3 {
        self.* = self.floored();
    }

    /// Returns vector negated.
    pub fn negated(self: Vec3) Vec3 {
        return self.scaled(-1);
    }

    /// Negates the vector.
    pub fn negate(self: *Vec3) void {
        self.* = self.negated();
    }

    /// Returns the squared magnitude.
    pub fn magSq(self: Vec3) f32 {
        return self.innerProd(self);
    }

    /// Returns the magnitude.
    pub fn mag(self: Vec3) f32 {
        return @sqrt(self.magSq());
    }

    /// Returns the squared distance between two vectors.
    pub fn distSq(self: Vec3, other: Vec3) f32 {
        return self.minus(other).magSq();
    }

    /// Returns the distance between two vectors.
    pub fn dist(self: Vec3, other: Vec3) f32 {
        return @sqrt(self.distSq(other));
    }

    /// Returns the vector normalized.
    pub fn normalized(self: Vec3) Vec3 {
        const len = self.mag();
        if (len == 0) return self;
        return self.scaled(1.0 / len);
    }

    /// Normalizes the vector.
    pub fn normalize(self: *Vec3) Vec3 {
        self.* = self.normalized();
    }

    /// Returns the component wise product of two vectors.
    pub fn compProd(self: Vec3, other: Vec3) Vec3 {
        return .{
            .x = self.x * other.x,
            .y = self.y * other.y,
            .z = self.z * other.z,
        };
    }

    /// Returns the inner product of two vectors. Equivalent to the dot product.
    pub fn innerProd(self: Vec3, other: Vec3) f32 {
        const yz = @mulAdd(f32, self.y, other.y, self.z * other.z);
        const xyz = @mulAdd(f32, self.x, other.x, yz);
        return xyz;
    }

    /// Returns the x and y components.
    pub fn xy(self: Vec3) Vec2 {
        return .{ .x = self.x, .y = self.y };
    }
};
