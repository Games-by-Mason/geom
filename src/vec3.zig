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

    pub fn splat(f: f32) @This() {
        return .{ .x = f, .y = f, .z = f };
    }

    test splat {
        try std.testing.expect(Vec3.splat(1.0).eql(.{ .x = 1.0, .y = 1.0, .z = 1.0 }));
        try std.testing.expect(Vec3.splat(3.0).eql(.{ .x = 3.0, .y = 3.0, .z = 3.0 }));
    }

    /// Checks for equality.
    pub fn eql(self: Vec3, other: Vec3) bool {
        return std.meta.eql(self, other);
    }

    test eql {
        try std.testing.expect(Vec3.y_pos.eql(Vec3.y_pos));
        try std.testing.expect(!Vec3.y_pos.eql(Vec3.x_pos));
    }

    /// Returns the vector scaled by `factor`.
    pub fn scaled(self: Vec3, factor: f32) Vec3 {
        return .{
            .x = self.x * factor,
            .y = self.y * factor,
            .z = self.z * factor,
        };
    }

    test scaled {
        var v: Vec3 = .{ .x = 1.0, .y = 2.0, .z = 3.0 };
        v = v.scaled(2.0);
        try std.testing.expectEqual(Vec3{ .x = 2.0, .y = 4.0, .z = 6.0 }, v);
    }

    /// Scales the vector by `factor`.
    pub fn scale(self: *Vec3, factor: f32) void {
        self.* = self.scaled(factor);
    }

    test scale {
        var v: Vec3 = .{ .x = 1.0, .y = 2.0, .z = 3.0 };
        v.scale(2.0);
        try std.testing.expectEqual(Vec3{ .x = 2.0, .y = 4.0, .z = 6.0 }, v);
    }

    /// Returns the vector added to `other`.
    pub fn plus(self: Vec3, other: Vec3) Vec3 {
        return .{
            .x = self.x + other.x,
            .y = self.y + other.y,
            .z = self.z + other.z,
        };
    }

    test plus {
        var v: Vec3 = .{ .x = 1.0, .y = 2.0, .z = 3.0 };
        v = v.plus(.{ .x = 2.0, .y = 3.0, .z = 0.5 });
        try std.testing.expectEqual(Vec3{ .x = 3.0, .y = 5.0, .z = 3.5 }, v);
    }

    /// Adds `other` to the vector.
    pub fn add(self: *Vec3, other: Vec3) void {
        self.* = self.plus(other);
    }

    test add {
        var v: Vec3 = .{ .x = 1.0, .y = 2.0, .z = 3.0 };
        v.add(.{ .x = 2.0, .y = 3.0, .z = 0.5 });
        try std.testing.expectEqual(Vec3{ .x = 3.0, .y = 5.0, .z = 3.5 }, v);
    }

    /// Returns the vector added to `other` scaled by `factor`
    pub fn plusScaled(self: Vec3, other: Vec3, factor: f32) Vec3 {
        return .{
            .x = @mulAdd(f32, other.x, factor, self.x),
            .y = @mulAdd(f32, other.y, factor, self.y),
            .z = @mulAdd(f32, other.z, factor, self.z),
        };
    }

    test plusScaled {
        var v: Vec3 = .{ .x = 1.0, .y = 2.0, .z = 3.0 };
        v = v.plusScaled(.{ .x = 2.0, .y = 3.0, .z = 4.0 }, 2.0);
        try std.testing.expectEqual(Vec3{ .x = 5.0, .y = 8.0, .z = 11.0 }, v);
    }

    /// Adds `other` scaled by `factor` to the vector.
    pub fn addScaled(self: *Vec3, other: Vec3, factor: f32) void {
        self.* = self.plusScaled(other, factor);
    }

    test addScaled {
        var v: Vec3 = .{ .x = 1.0, .y = 2.0, .z = 3.0 };
        v.addScaled(.{ .x = 2.0, .y = 3.0, .z = 4.0 }, 2.0);
        try std.testing.expectEqual(Vec3{ .x = 5.0, .y = 8.0, .z = 11.0 }, v);
    }

    /// Returns `other` subtracted from the vector.
    pub fn minus(self: Vec3, other: Vec3) Vec3 {
        return .{
            .x = self.x - other.x,
            .y = self.y - other.y,
            .z = self.z - other.z,
        };
    }

    test minus {
        var v: Vec3 = .{ .x = 1.0, .y = 2.0, .z = 3.0 };
        v = v.minus(.{ .x = 2.0, .y = 4.0, .z = 6.0 });
        try std.testing.expectEqual(Vec3{ .x = -1.0, .y = -2.0, .z = -3.0 }, v);
    }

    /// Subtracts `other` from the vector.
    pub fn sub(self: *Vec3, other: Vec3) void {
        self.* = self.minus(other);
    }

    test sub {
        var v: Vec3 = .{ .x = 1.0, .y = 2.0, .z = 3.0 };
        v.sub(.{ .x = 2.0, .y = 4.0, .z = 6.0 });
        try std.testing.expectEqual(Vec3{ .x = -1.0, .y = -2.0, .z = -3.0 }, v);
    }

    /// Returns the vector with its components floored.
    pub fn floored(self: Vec3) Vec3 {
        return .{
            .x = @floor(self.x),
            .y = @floor(self.y),
            .z = @floor(self.z),
        };
    }

    test floored {
        var v: Vec3 = .{ .x = 1.5, .y = 2.1, .z = 3.9 };
        v = v.floored();
        try std.testing.expectEqual(Vec3{ .x = 1.0, .y = 2.0, .z = 3.0 }, v);
    }

    /// Floors all components of the vector.
    pub fn floor(self: *Vec3) void {
        self.* = self.floored();
    }

    test floor {
        var v: Vec3 = .{ .x = 1.5, .y = 2.1, .z = 3.9 };
        v.floor();
        try std.testing.expectEqual(Vec3{ .x = 1.0, .y = 2.0, .z = 3.0 }, v);
    }

    // Takes the modulo of all components of `self` with `base`.
    pub fn mod(self: *Vec3, base: Vec3) void {
        self.* = self.modded(base);
    }

    test mod {
        var a: Vec3 = .{ .x = 11, .y = 15, .z = 17 };
        a.mod(.{ .x = 10, .y = 13, .z = 10 });
        try std.testing.expectEqual(Vec3{ .x = 1, .y = 2, .z = 7 }, a);
    }

    /// Returns the modulo of all components of `self` with `base`.
    pub fn modded(self: Vec3, base: Vec3) Vec3 {
        return .{
            .x = @mod(self.x, base.x),
            .y = @mod(self.y, base.y),
            .z = @mod(self.z, base.z),
        };
    }

    test modded {
        try std.testing.expectEqual(
            Vec3{ .x = 1, .y = 2, .z = 7 },
            (Vec3{ .x = 11, .y = 15, .z = 17 }).modded(.{ .x = 10, .y = 13, .z = 10 }),
        );
    }

    /// Assigns each component to `std.math.sign` of itself.
    pub fn sign(self: *Vec3) void {
        self.* = self.signOf();
    }

    test sign {
        var a: Vec3 = .{ .x = -10, .y = 0, .z = 20 };
        a.sign();
        try std.testing.expectEqual(Vec3{ .x = -1, .y = 0, .z = 1 }, a);
    }

    /// Returns `std.math.sign` of each component.
    pub fn signOf(self: Vec3) Vec3 {
        return .{
            .x = std.math.sign(self.x),
            .y = std.math.sign(self.y),
            .z = std.math.sign(self.z),
        };
    }

    test signOf {
        try std.testing.expectEqual(
            Vec3{ .x = 1, .y = -1, .z = 0 },
            (Vec3{ .x = 10, .y = -20, .z = 0 }).signOf(),
        );
    }

    /// Returns vector negated.
    pub fn negated(self: Vec3) Vec3 {
        return self.scaled(-1);
    }

    test negated {
        var v: Vec3 = .{ .x = 1.5, .y = 2.1, .z = -3.1 };
        v = v.negated();
        try std.testing.expectEqual(Vec3{ .x = -1.5, .y = -2.1, .z = 3.1 }, v);
    }

    /// Negates the vector.
    pub fn negate(self: *Vec3) void {
        self.* = self.negated();
    }

    test negate {
        var v: Vec3 = .{ .x = 1.5, .y = 2.1, .z = -3.1 };
        v.negate();
        try std.testing.expectEqual(Vec3{ .x = -1.5, .y = -2.1, .z = 3.1 }, v);
    }

    /// Returns the squared magnitude.
    pub fn magSq(self: Vec3) f32 {
        return self.innerProd(self);
    }

    test magSq {
        var v: Vec3 = .{ .x = 2, .y = 3, .z = 4 };
        try std.testing.expectEqual(29, v.magSq());
    }

    /// Returns the magnitude.
    pub fn mag(self: Vec3) f32 {
        return @sqrt(self.magSq());
    }

    test mag {
        var v: Vec3 = .{ .x = 2, .y = 3, .z = 4 };
        try std.testing.expectEqual(@sqrt(29.0), v.mag());
    }

    /// Returns the squared distance between two vectors.
    pub fn distSq(self: Vec3, other: Vec3) f32 {
        return self.minus(other).magSq();
    }

    test distSq {
        const a: Vec3 = .{ .x = 2, .y = 3, .z = 4 };
        const b: Vec3 = .{ .x = 3, .y = 5, .z = 7 };
        try std.testing.expectEqual(14.0, a.distSq(b));
    }

    /// Returns the distance between two vectors.
    pub fn dist(self: Vec3, other: Vec3) f32 {
        return @sqrt(self.distSq(other));
    }

    test dist {
        const a: Vec3 = .{ .x = 2, .y = 3, .z = 4 };
        const b: Vec3 = .{ .x = 3, .y = 5, .z = 7 };
        try std.testing.expectEqual(@sqrt(14.0), a.dist(b));
    }

    /// Returns the vector renormalized. Assumes the input is already near normal.
    pub fn renormalized(self: Vec3) Vec3 {
        const len = self.mag();
        if (len == 0) return self;
        return self.scaled(1.0 / len);
    }

    test renormalized {
        var v: Vec3 = .{ .x = 1.05, .y = 0.0, .z = 0.0 };
        v = v.renormalized();
        try std.testing.expectApproxEqAbs(v.x, 1.0, 0.01);
        try std.testing.expectEqual(v.y, 0.0);
        try std.testing.expectEqual(v.z, 0.0);
    }

    /// Renormalizes the vector. See `renormalized`.
    pub fn renormalize(self: *Vec3) void {
        self.* = self.normalized();
    }

    test renormalize {
        var v: Vec3 = .{ .x = 1.05, .y = 0.0, .z = 0.0 };
        v.renormalize();
        try std.testing.expectApproxEqAbs(v.x, 1.0, 0.01);
        try std.testing.expectEqual(v.y, 0.0);
        try std.testing.expectEqual(v.z, 0.0);
    }

    /// Returns the vector normalized. If the vector is `.zero`, returns it unchanged. If your
    /// input is nearly normal already, consider using `renormalize` instead.
    pub fn normalized(self: Vec3) Vec3 {
        const len = self.mag();
        if (len == 0) return self;
        return self.scaled(1.0 / len);
    }

    test normalized {
        var v: Vec3 = .{ .x = 10.0, .y = 0.0, .z = 0.0 };
        v = v.normalized();
        try std.testing.expectEqual(Vec3{ .x = 1.0, .y = 0.0, .z = 0.0 }, v);
        try std.testing.expectEqual(Vec3.zero, Vec3.normalized(.zero));
    }

    /// Normalizes the vector. See `normalized`.
    pub fn normalize(self: *Vec3) void {
        self.* = self.normalized();
    }

    test normalize {
        var v: Vec3 = .{ .x = 10.0, .y = 0.0, .z = 0.0 };
        v.normalize();
        try std.testing.expectEqual(Vec3{ .x = 1.0, .y = 0.0, .z = 0.0 }, v);
        v = .zero;
        v.normalize();
        try std.testing.expectEqual(Vec3.zero, v);
    }

    /// Returns the component wise product of two vectors.
    pub fn compProd(self: Vec3, other: Vec3) Vec3 {
        return .{
            .x = self.x * other.x,
            .y = self.y * other.y,
            .z = self.z * other.z,
        };
    }

    test compProd {
        const a: Vec3 = .{ .x = 2, .y = 3, .z = 4 };
        const b: Vec3 = .{ .x = 4, .y = 5, .z = 6 };
        try std.testing.expectEqual(Vec3{ .x = 8, .y = 15, .z = 24 }, a.compProd(b));
    }

    /// Returns the inner product of two vectors. Equivalent to the dot product.
    pub fn innerProd(self: Vec3, other: Vec3) f32 {
        const pxy = @mulAdd(f32, self.x, other.x, self.y * other.y);
        const pxyz = @mulAdd(f32, self.z, other.z, pxy);
        return pxyz;
    }

    test innerProd {
        const a: Vec3 = .{ .x = 2, .y = 3, .z = 4 };
        const b: Vec3 = .{ .x = 4, .y = 5, .z = 6 };
        try std.testing.expectEqual(47, a.innerProd(b));
    }

    /// Returns the x and y components.
    pub fn xy(self: Vec3) Vec2 {
        return .{ .x = self.x, .y = self.y };
    }

    test xy {
        const a: Vec3 = .{ .x = 2, .y = 3, .z = 4 };
        try std.testing.expectEqual(Vec2{ .x = 2, .y = 3 }, a.xy());
    }
};
