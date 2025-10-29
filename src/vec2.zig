const std = @import("std");
const geom = @import("root.zig");

const math = std.math;

const Vec3 = geom.Vec3;
const Bivec2 = geom.Bivec2;
const Rotor2 = geom.Rotor2;

/// A two dimensional vector.
pub const Vec2 = extern struct {
    x: f32,
    y: f32,

    /// The zero vector.
    pub const zero: Vec2 = .{ .x = 0, .y = 0 };
    /// The positive x axis.
    pub const x_pos: Vec2 = .{ .x = 1, .y = 0 };
    /// The negative x axis.
    pub const x_neg: Vec2 = .{ .x = -1, .y = 0 };
    /// The positive y axis.
    pub const y_pos: Vec2 = .{ .x = 0, .y = 1 };
    /// The negative y axis.
    pub const y_neg: Vec2 = .{ .x = 0, .y = -1 };

    pub fn splat(f: f32) @This() {
        return .{ .x = f, .y = f };
    }

    test splat {
        try std.testing.expect(Vec2.splat(1.0).eql(.{ .x = 1.0, .y = 1.0 }));
        try std.testing.expect(Vec2.splat(3.0).eql(.{ .x = 3.0, .y = 3.0 }));
    }

    /// Checks for equality.
    pub fn eql(self: Vec2, other: Vec2) bool {
        return std.meta.eql(self, other);
    }

    test eql {
        try std.testing.expect(Vec2.y_pos.eql(Vec2.y_pos));
        try std.testing.expect(!Vec2.y_pos.eql(Vec2.x_pos));
    }

    /// Returns the unit vector in the given direction.
    pub fn unit(rad: f32) Vec2 {
        return .{
            .x = @cos(rad),
            .y = @sin(rad),
        };
    }

    test unit {
        // "Why `expectApproxEqAbs`? Surely the author of this library is misunderstanding how the
        // transcendental functions are implemented, they can't vary from one line to the next on
        // the same CPU. ...Right?"
        //
        // Try it. ;)
        const u: Vec2 = .unit(std.math.pi);
        try std.testing.expectApproxEqAbs(@as(f32, @cos(std.math.pi)), u.x, 0.01);
        try std.testing.expectApproxEqAbs(@as(f32, @sin(std.math.pi)), u.y, 0.01);
    }

    /// Returns the vector scaled by `factor`.
    pub fn scaled(self: Vec2, factor: f32) Vec2 {
        return .{
            .x = self.x * factor,
            .y = self.y * factor,
        };
    }

    test scaled {
        var v: Vec2 = .{ .x = 1.0, .y = 2.0 };
        v = v.scaled(2.0);
        try std.testing.expectEqual(Vec2{ .x = 2.0, .y = 4.0 }, v);
    }

    /// Scales the vector by `factor`.
    pub fn scale(self: *Vec2, factor: f32) void {
        self.* = self.scaled(factor);
    }

    test scale {
        var v: Vec2 = .{ .x = 1.0, .y = 2.0 };
        v.scale(2.0);
        try std.testing.expectEqual(Vec2{ .x = 2.0, .y = 4.0 }, v);
    }

    /// Returns the vector added to `other`.
    pub fn plus(self: Vec2, other: Vec2) Vec2 {
        return .{
            .x = self.x + other.x,
            .y = self.y + other.y,
        };
    }

    test plus {
        var v: Vec2 = .{ .x = 1.0, .y = 2.0 };
        v = v.plus(.{ .x = 2.0, .y = 3.0 });
        try std.testing.expectEqual(Vec2{ .x = 3.0, .y = 5.0 }, v);
    }

    /// Adds `other` to the vector.
    pub fn add(self: *Vec2, other: Vec2) void {
        self.* = self.plus(other);
    }

    test add {
        var v: Vec2 = .{ .x = 1.0, .y = 2.0 };
        v.add(.{ .x = 2.0, .y = 3.0 });
        try std.testing.expectEqual(Vec2{ .x = 3.0, .y = 5.0 }, v);
    }

    /// Returns the vector added to `other` scaled by `factor`
    pub fn plusScaled(self: Vec2, other: Vec2, factor: f32) Vec2 {
        return .{
            .x = @mulAdd(f32, other.x, factor, self.x),
            .y = @mulAdd(f32, other.y, factor, self.y),
        };
    }

    test plusScaled {
        var v: Vec2 = .{ .x = 1.0, .y = 2.0 };
        v = v.plusScaled(.{ .x = 2.0, .y = 3.0 }, 2.0);
        try std.testing.expectEqual(Vec2{ .x = 5.0, .y = 8.0 }, v);
    }

    /// Adds `other` scaled by `factor` to the vector.
    pub fn addScaled(self: *Vec2, other: Vec2, factor: f32) void {
        self.* = self.plusScaled(other, factor);
    }

    test addScaled {
        var v: Vec2 = .{ .x = 1.0, .y = 2.0 };
        v.addScaled(.{ .x = 2.0, .y = 3.0 }, 2.0);
        try std.testing.expectEqual(Vec2{ .x = 5.0, .y = 8.0 }, v);
    }

    /// Returns `other` subtracted from the vector.
    pub fn minus(self: Vec2, other: Vec2) Vec2 {
        return .{
            .x = self.x - other.x,
            .y = self.y - other.y,
        };
    }

    test minus {
        var v: Vec2 = .{ .x = 1.0, .y = 2.0 };
        v = v.minus(.{ .x = 2.0, .y = 4.0 });
        try std.testing.expectEqual(Vec2{ .x = -1.0, .y = -2.0 }, v);
    }

    /// Subtracts `other` from the vector.
    pub fn sub(self: *Vec2, other: Vec2) void {
        self.* = self.minus(other);
    }

    test sub {
        var v: Vec2 = .{ .x = 1.0, .y = 2.0 };
        v.sub(.{ .x = 2.0, .y = 4.0 });
        try std.testing.expectEqual(Vec2{ .x = -1.0, .y = -2.0 }, v);
    }

    /// Returns the vector with its components floored.
    pub fn floored(self: Vec2) Vec2 {
        return .{
            .x = @floor(self.x),
            .y = @floor(self.y),
        };
    }

    test floored {
        var v: Vec2 = .{ .x = 1.5, .y = 2.1 };
        v = v.floored();
        try std.testing.expectEqual(Vec2{ .x = 1.0, .y = 2.0 }, v);
    }

    /// Floors all components of the vector.
    pub fn floor(self: *Vec2) void {
        self.* = self.floored();
    }

    test floor {
        var v: Vec2 = .{ .x = 1.5, .y = 2.1 };
        v.floor();
        try std.testing.expectEqual(Vec2{ .x = 1.0, .y = 2.0 }, v);
    }

    // Takes the modulo of all components of `self` with `base`.
    pub fn mod(self: *Vec2, base: Vec2) void {
        self.* = self.modded(base);
    }

    test mod {
        var a: Vec2 = .{ .x = 11, .y = 15 };
        a.mod(.{ .x = 10, .y = 13 });
        try std.testing.expectEqual(Vec2{ .x = 1, .y = 2 }, a);
    }

    /// Returns the modulo of all components of `self` with `base`.
    pub fn modded(self: Vec2, base: Vec2) Vec2 {
        return .{
            .x = @mod(self.x, base.x),
            .y = @mod(self.y, base.y),
        };
    }

    test modded {
        try std.testing.expectEqual(
            Vec2{ .x = 1, .y = 2 },
            (Vec2{ .x = 11, .y = 15 }).modded(.{ .x = 10, .y = 13 }),
        );
    }

    /// Assigns each component to `std.math.sign` of itself.
    pub fn sign(self: *Vec2) void {
        self.* = self.signOf();
    }

    test sign {
        var a: Vec2 = .{ .x = -10, .y = 0 };
        a.sign();
        try std.testing.expectEqual(Vec2{ .x = -1, .y = 0 }, a);
    }

    /// Returns `std.math.sign` of each component.
    pub fn signOf(self: Vec2) Vec2 {
        return .{
            .x = std.math.sign(self.x),
            .y = std.math.sign(self.y),
        };
    }

    test signOf {
        try std.testing.expectEqual(Vec2{ .x = 1, .y = -1 }, (Vec2{ .x = 10, .y = -20 }).signOf());
    }

    /// Returns vector negated.
    pub fn negated(self: Vec2) Vec2 {
        return self.scaled(-1);
    }

    test negated {
        var v: Vec2 = .{ .x = 1.5, .y = 2.1 };
        v = v.negated();
        try std.testing.expectEqual(Vec2{ .x = -1.5, .y = -2.1 }, v);
    }

    /// Negates the vector.
    pub fn negate(self: *Vec2) void {
        self.* = self.negated();
    }

    test negate {
        var v: Vec2 = .{ .x = 1.5, .y = 2.1 };
        v.negate();
        try std.testing.expectEqual(Vec2{ .x = -1.5, .y = -2.1 }, v);
    }

    /// Returns the squared magnitude.
    pub fn magSq(self: Vec2) f32 {
        return self.innerProd(self);
    }

    test magSq {
        var v: Vec2 = .{ .x = 2, .y = 3 };
        try std.testing.expectEqual(13, v.magSq());
    }

    /// Returns the magnitude.
    pub fn mag(self: Vec2) f32 {
        return @sqrt(self.magSq());
    }

    test mag {
        var v: Vec2 = .{ .x = 2, .y = 3 };
        try std.testing.expectEqual(@sqrt(13.0), v.mag());
    }

    /// Returns the squared distance between two vectors.
    pub fn distSq(self: Vec2, other: Vec2) f32 {
        return self.minus(other).magSq();
    }

    test distSq {
        const a: Vec2 = .{ .x = 2, .y = 3 };
        const b: Vec2 = .{ .x = 3, .y = 5 };
        try std.testing.expectEqual(5.0, a.distSq(b));
    }

    /// Returns the distance between two vectors.
    pub fn dist(self: Vec2, other: Vec2) f32 {
        return @sqrt(self.distSq(other));
    }

    test dist {
        const a: Vec2 = .{ .x = 2, .y = 3 };
        const b: Vec2 = .{ .x = 3, .y = 5 };
        try std.testing.expectEqual(@sqrt(5.0), a.dist(b));
    }

    /// Returns the vector renormalized. Assumes the input is already near normal.
    pub fn renormalized(self: Vec2) Vec2 {
        const mag_sq = self.magSq();
        if (mag_sq == 0) return self;
        return self.scaled(geom.invSqrtNearOne(mag_sq));
    }

    test renormalized {
        var v: Vec2 = .{ .x = 1.05, .y = 0.0 };
        v = v.renormalized();
        try std.testing.expectApproxEqAbs(v.x, 1.0, 0.01);
        try std.testing.expectEqual(v.y, 0.0);
    }

    /// Renormalizes the vector. See `renormalized`.
    pub fn renormalize(self: *Vec2) void {
        self.* = self.renormalized();
    }

    test renormalize {
        var v: Vec2 = .{ .x = 1.05, .y = 0.0 };
        v.renormalize();
        try std.testing.expectApproxEqAbs(v.x, 1.0, 0.01);
        try std.testing.expectEqual(v.y, 0.0);
    }

    /// Returns the vector normalized. If the vector is `.zero`, it is returned unchanged. If your
    /// input is nearly normal already, consider using `renormalize` instead.
    pub fn normalized(self: Vec2) Vec2 {
        const mag_sq = self.magSq();
        if (mag_sq == 0) return self;
        return self.scaled(geom.invSqrt(mag_sq));
    }

    test normalized {
        var v: Vec2 = .{ .x = 10.0, .y = 0.0 };
        v = v.normalized();
        try std.testing.expectEqual(Vec2{ .x = 1.0, .y = 0.0 }, v);
        try std.testing.expectEqual(Vec2.zero, Vec2.normalized(.zero));
    }

    /// Normalizes the vector. See `normalized`.
    pub fn normalize(self: *Vec2) void {
        self.* = self.normalized();
    }

    test normalize {
        var v: Vec2 = .{ .x = 10.0, .y = 0.0 };
        v.normalize();
        try std.testing.expectEqual(Vec2{ .x = 1.0, .y = 0.0 }, v);
        v = .zero;
        v.normalize();
        try std.testing.expectEqual(Vec2.zero, v);
    }

    /// Returns the component wise product of two vectors.
    pub fn compProd(self: Vec2, other: Vec2) Vec2 {
        return .{
            .x = self.x * other.x,
            .y = self.y * other.y,
        };
    }

    test compProd {
        const a: Vec2 = .{ .x = 2, .y = 3 };
        const b: Vec2 = .{ .x = 4, .y = 5 };
        try std.testing.expectEqual(Vec2{ .x = 8, .y = 15 }, a.compProd(b));
    }

    /// Returns the component wise division of two vectors.
    pub fn compDiv(self: Vec2, other: Vec2) Vec2 {
        return .{
            .x = self.x / other.x,
            .y = self.y / other.y,
        };
    }

    test compDiv {
        const a: Vec2 = .{ .x = 2, .y = 3 };
        const b: Vec2 = .{ .x = 4, .y = 5 };
        try std.testing.expectEqual(Vec2{ .x = 0.5, .y = 0.6 }, a.compDiv(b));
    }

    /// Returns the inner product of two vectors. Equivalent to the dot product.
    pub fn innerProd(self: Vec2, other: Vec2) f32 {
        return @mulAdd(f32, self.x, other.x, self.y * other.y);
    }

    test innerProd {
        const a: Vec2 = .{ .x = 2, .y = 3 };
        const b: Vec2 = .{ .x = 4, .y = 5 };
        try std.testing.expectEqual(23, a.innerProd(b));
    }

    /// Returns the outer product of two vectors. Generalized form of the cross product, result is
    /// an oriented area.
    pub fn outerProd(lhs: Vec2, rhs: Vec2) Bivec2 {
        return .{
            .xy = @mulAdd(f32, lhs.x, rhs.y, -rhs.x * lhs.y),
        };
    }

    test outerProd {
        const a: Vec2 = .x_pos;
        const b: Vec2 = .y_pos;
        try std.testing.expectEqual(Bivec2{ .xy = 1.0 }, a.outerProd(b));
    }

    /// Returns the geometric product of two vectors. This is an intermediate step in creating a
    /// usable rotor, it's more likely that you want `Rotor2.fromTo`.
    pub fn geomProd(lhs: Vec2, rhs: Vec2) Rotor2 {
        return .{
            .xy = lhs.outerProd(rhs).xy,
            .a = lhs.innerProd(rhs) + 1.0,
        };
    }

    test geomProd {
        const a: Vec2 = .x_pos;
        const b: Vec2 = .y_pos;
        try std.testing.expectEqual(Rotor2{ .xy = 1.0, .a = 1.0 }, a.geomProd(b));
    }

    /// Returns the normal to the vector CW from the input. Assumes the vector is already
    /// normalized. If the vector is `.zero`, it is returned unchanged.
    pub fn normal(self: Vec2) Vec2 {
        return .{
            .x = self.y,
            .y = -self.x,
        };
    }

    test normal {
        var a: Vec2 = .{ .x = 1, .y = 2 };
        a = a.normal();
        try std.testing.expectEqual(Vec2{ .x = 2, .y = -1 }, a);
        try std.testing.expectEqual(Vec2.zero, Vec2.normal(.zero));
    }

    /// Returns the equivalent homogeneous point.
    pub fn point(self: Vec2) Vec3 {
        return .{ .x = self.x, .y = self.y, .z = 1.0 };
    }

    test point {
        var v: Vec2 = .{ .x = 1, .y = 2 };
        try std.testing.expectEqual(Vec3{ .x = 1, .y = 2, .z = 1.0 }, v.point());
    }

    /// Returns the equivalent homogeneous direction.
    pub fn dir(self: Vec2) Vec3 {
        return .{ .x = self.x, .y = self.y, .z = 0.0 };
    }

    test dir {
        var v: Vec2 = .{ .x = 1, .y = 2 };
        try std.testing.expectEqual(Vec3{ .x = 1, .y = 2, .z = 0.0 }, v.dir());
    }

    pub fn clamped(self: Vec2, min: Vec2, max: Vec2) @This() {
        return .{
            .x = std.math.clamp(self.x, min.x, max.x),
            .y = std.math.clamp(self.y, min.y, max.y),
        };
    }

    test clamped {
        try std.testing.expectEqual(
            Vec2{ .x = 10, .y = 4 },
            (Vec2{ .x = 100, .y = 0 }).clamped(
                .{ .x = 2, .y = 4 },
                .{ .x = 10, .y = 20 },
            ),
        );

        try std.testing.expectEqual(
            Vec2{ .x = 2, .y = 20 },
            (Vec2{ .x = 0, .y = 100 }).clamped(
                .{ .x = 2, .y = 4 },
                .{ .x = 10, .y = 20 },
            ),
        );

        try std.testing.expectEqual(
            Vec2{ .x = 3, .y = 10 },
            (Vec2{ .x = 3, .y = 10 }).clamped(
                .{ .x = 2, .y = 4 },
                .{ .x = 10, .y = 20 },
            ),
        );
    }

    pub fn clamp(self: *Vec2, min: Vec2, max: Vec2) void {
        self.* = self.clamped(min, max);
    }

    test clamp {
        {
            var v: Vec2 = .{ .x = 100, .y = 0 };
            v.clamp(.{ .x = 2, .y = 4 }, .{ .x = 10, .y = 20 });
            try std.testing.expectEqual(Vec2{ .x = 10, .y = 4 }, v);
        }
        {
            var v: Vec2 = .{ .x = 0, .y = 100 };
            v.clamp(.{ .x = 2, .y = 4 }, .{ .x = 10, .y = 20 });
            try std.testing.expectEqual(Vec2{ .x = 2, .y = 20 }, v);
        }
        {
            var v: Vec2 = .{ .x = 3, .y = 10 };
            v.clamp(.{ .x = 2, .y = 4 }, .{ .x = 10, .y = 20 });
            try std.testing.expectEqual(Vec2{ .x = 3, .y = 10 }, v);
        }
    }
};
