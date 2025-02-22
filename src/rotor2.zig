const std = @import("std");
const geom = @import("root.zig");

const math = std.math;

const Vec2 = geom.Vec2;
const Bivec2 = geom.Bivec2;
const Mat2x3 = geom.Mat2x3;

/// A two dimensional rotor. Rotors are a generalized form of quaternions which are used for
/// rotation. Unlike quaternions, rotors generalize to all dimensions. Rotors can represent up to
/// two full rotations, at which point they wrap back around.
pub const Rotor2 = extern struct {
    /// The component that rotates from x to y along the xy plane.
    ///
    /// Equivalent to the negative sine of half the rotation.
    xy: f32,
    /// The scalar component.
    ///
    /// Equivalent to the cosine of half the rotation.
    a: f32,

    /// The identity rotor. Has no effect.
    pub const identity: Rotor2 = .{ .xy = 0.0, .a = 1.0 };

    /// Checks for equality.
    pub fn eql(self: Rotor2, other: Rotor2) bool {
        return std.meta.eql(self, other);
    }

    /// Creates a rotor that rotates along the shortest path from `from` to `to`. `from` and `to`
    /// must be normalized.
    ///
    /// If `from` and to are parallel in opposite directions, the tie is broken arbitrarily.
    pub fn fromTo(from: Vec2, to: Vec2) Rotor2 {
        const result = from.geomProd(to);
        const res_mag = result.mag();
        if (res_mag == 0.0) {
            return .{ .xy = -1, .a = 0.0 };
        } else {
            return result.scaledComps(1.0 / res_mag);
        }
    }

    /// Creates a rotor that rotates from the positive y axis to the given direction. Assumes `dir`
    /// is normalized.
    pub fn look(dir: Vec2) Rotor2 {
        return .fromTo(.y_pos, dir);
    }

    /// Returns the rotor with all components scaled by the given factor. This does not scale the
    /// rotation.
    pub fn scaledComps(self: Rotor2, factor: f32) Rotor2 {
        return .{
            .xy = self.xy * factor,
            .a = self.a * factor,
        };
    }

    /// Scales the rotor's components by the given factor. This does not scale the rotation.
    pub fn scaleComps(self: *Rotor2, factor: f32) void {
        self.* = self.scaledComps(factor);
    }

    /// Creates a rotor that from the given angle. Prefer `fromTo` when not operating on human
    /// input.
    ///
    /// Angles greater than 2PI wrap.
    pub fn fromAngle(rad: f32) Rotor2 {
        return .{
            .xy = -@sin(rad / 2.0),
            .a = @cos(rad / 2.0),
        };
    }

    /// Returns the angle of rotation. Useful for human readable output, use for logic is
    /// discouraged. Angles greater than 2PI wrap.
    pub fn toAngle(self: Rotor2) f32 {
        return 2.0 * std.math.atan2(-self.xy, self.a);
    }

    /// Returns the squared magnitude of the rotor.
    pub fn magSq(self: Rotor2) f32 {
        return @mulAdd(f32, self.xy, self.xy, self.a * self.a);
    }

    /// Returns the magnitude of the rotor.
    pub fn mag(self: Rotor2) f32 {
        return @sqrt(self.magSq());
    }

    /// Returns the inverse rotation. Not to be confused with `negate`.
    pub fn inverse(self: Rotor2) Rotor2 {
        return .{
            .xy = -self.xy,
            .a = self.a,
        };
    }

    /// Inverts the rotation.
    pub fn invert(self: *Rotor2) void {
        self.* = self.inverse();
    }

    /// Not to be confused with `inverse`. Adds a full rotation to the given rotor, flipping its
    /// neighborhood. Agnostic to normalization.
    pub fn negated(self: Rotor2) Rotor2 {
        return .{
            .xy = -self.xy,
            .a = -self.a,
        };
    }

    /// Negates the rotor, see `negated`.
    pub fn negate(self: *Rotor2) void {
        self.* = self.negated();
    }

    /// Returns the cosine of the half angle between the two given normalized rotors. If the result
    /// is negative, they are more than a full rotation apart. If it is positive they are not.
    pub fn neighborhood(self: Rotor2, other: Rotor2) f32 {
        return @mulAdd(f32, self.xy, other.xy, self.a * self.a);
    }

    /// Returns a normalized rotor. If the magnitude is 0 the result will be a rotor filled with
    /// NaNs.
    pub fn normalized(self: Rotor2) Rotor2 {
        return self.scaledComps(1.0 / self.mag());
    }

    /// Normalizes the rotor. See `normalized`.
    pub fn normalize(self: *Rotor2) void {
        self.* = self.normalized();
    }

    /// Applies the rotor to a vector.
    pub fn timesVec2(self: Rotor2, point: Vec2) Vec2 {
        // temp = -rotor * point
        const x = @mulAdd(f32, self.a, point.x, -self.xy * point.y);
        const y = @mulAdd(f32, self.a, point.y, self.xy * point.x);

        // temp * rotor
        return .{
            .x = @mulAdd(f32, x, self.a, -y * self.xy),
            .y = @mulAdd(f32, x, self.xy, y * self.a),
        };
    }

    /// Returns the rotor multiplied by other. This lets you compose rotations. Order matters.
    pub fn times(self: Rotor2, other: Rotor2) Rotor2 {
        return .{
            .a = @mulAdd(f32, -self.xy, other.xy, self.a * other.a),
            .xy = @mulAdd(f32, self.xy, other.a, self.a * other.xy),
        };
    }

    /// Multiplies self by other. See `times`.
    pub fn mul(self: *Rotor2, other: Rotor2) void {
        self.* = self.times(other);
    }

    /// Takes the natural log of the given rotor, resulting in a bivector representing the plane the
    /// rotation occurs on with a magnitude of half the angle of rotation in radians. The rotor must
    /// be normalized.
    pub fn ln(self: Rotor2) Bivec2 {
        return .{ .xy = std.math.atan2(-self.xy, self.a) };
    }

    /// Spherically linearly interpolates between two rotors. See also `nlerp`.
    ///
    /// Interpolates a constant velocity, but is computationally heavy and is not commutative. Not
    /// exact at the beginning/end of ranges. If `t` is outside of the [0, 1] range, the rotation
    /// will continue past the start or end.
    pub fn slerp(start: Rotor2, end: Rotor2, t: f32) Rotor2 {
        return start.times(start.inverse().times(end).ln().scaled(t).exp());
    }

    /// Linearly interpolates between the two rotors, then normalizes the result. Prefer this over
    /// `slerp`.
    ///
    /// Interpolation speed is not entirely constant, but it is computationally cheap and
    /// commutative. Behaves well in the [0, 1] range for t, and the velocity remains close to
    /// constant within the 0 to PI/2 range, it gets worse the closer the angle is to 2PI.
    pub fn nlerp(start: Rotor2, end: Rotor2, t: f32) Rotor2 {
        var result: Rotor2 = .{
            .xy = std.math.lerp(start.xy, end.xy, t),
            .a = std.math.lerp(start.a, end.a, t),
        };

        const res_mag = result.mag();
        if (res_mag == 0.0) {
            return start;
        } else {
            return result.scaledComps(1.0 / res_mag);
        }
    }
};

fn expectRotor2ApproxEql(expected: Rotor2, actual: Rotor2) !void {
    try std.testing.expectApproxEqAbs(expected.xy, actual.xy, 0.01);
    try std.testing.expectApproxEqAbs(expected.a, actual.a, 0.01);
}

fn expectVec2ApproxEql(expected: Vec2, actual: Vec2) !void {
    try std.testing.expectApproxEqAbs(expected.x, actual.x, 0.01);
    try std.testing.expectApproxEqAbs(expected.y, actual.y, 0.01);
}

test "fields" {
    try expectRotor2ApproxEql(
        Rotor2{ .a = 0.924, .xy = -0.383 },
        .fromAngle(std.math.pi / 4.0),
    );

    try expectRotor2ApproxEql(
        Rotor2{ .xy = 0.0, .a = 1.0 },
        .fromAngle(0.0),
    );

    try expectRotor2ApproxEql(
        Rotor2{ .xy = -@sin(0.5 / 2.0), .a = @cos(0.5 / 2.0) },
        .fromAngle(0.5),
    );
}

test "fromTo" {
    // Test unit rotations
    try std.testing.expectEqual(0, Rotor2.fromTo(.x_pos, .x_pos).toAngle());
    try std.testing.expectEqual(0, Rotor2.fromTo(.x_neg, .x_neg).toAngle());
    try std.testing.expectEqual(0, Rotor2.fromTo(.y_pos, .y_pos).toAngle());
    try std.testing.expectEqual(0, Rotor2.fromTo(.y_neg, .y_neg).toAngle());

    try std.testing.expectEqual(Rotor2.identity, Rotor2.fromTo(.x_pos, .x_pos));
    try std.testing.expectEqual(Rotor2.identity, Rotor2.fromTo(.x_neg, .x_neg));
    try std.testing.expectEqual(Rotor2.identity, Rotor2.fromTo(.y_pos, .y_pos));
    try std.testing.expectEqual(Rotor2.identity, Rotor2.fromTo(.y_neg, .y_neg));

    try std.testing.expectEqual(Vec2.x_pos, Rotor2.fromTo(.x_pos, .x_pos).timesVec2(.x_pos));
    try std.testing.expectEqual(Vec2.y_pos, Rotor2.fromTo(.y_pos, .y_pos).timesVec2(.y_pos));

    try std.testing.expectEqual(Vec2.y_pos, Rotor2.fromTo(.x_pos, .x_pos).timesVec2(.y_pos));
    try std.testing.expectEqual(Vec2.x_pos, Rotor2.fromTo(.y_pos, .y_pos).timesVec2(.x_pos));

    // Test 90 degree rotations
    try std.testing.expectEqual(math.pi / 2.0, Rotor2.fromTo(.y_pos, .x_pos).toAngle());
    try std.testing.expectEqual(math.pi / 2.0, Rotor2.fromTo(.x_pos, .y_neg).toAngle());
    try std.testing.expectEqual(math.pi / 2.0, Rotor2.fromTo(.y_neg, .x_neg).toAngle());
    try std.testing.expectEqual(math.pi / 2.0, Rotor2.fromTo(.x_neg, .y_pos).toAngle());

    try std.testing.expectEqual(-math.pi / 2.0, Rotor2.fromTo(.x_pos, .y_pos).toAngle());
    try std.testing.expectEqual(-math.pi / 2.0, Rotor2.fromTo(.y_pos, .x_neg).toAngle());
    try std.testing.expectEqual(-math.pi / 2.0, Rotor2.fromTo(.x_neg, .y_neg).toAngle());
    try std.testing.expectEqual(-math.pi / 2.0, Rotor2.fromTo(.y_neg, .x_pos).toAngle());

    try expectVec2ApproxEql(Vec2.y_pos, Rotor2.fromTo(.x_pos, .y_pos).timesVec2(.x_pos));
    try expectVec2ApproxEql(Vec2.y_neg, Rotor2.fromTo(.y_pos, .x_pos).timesVec2(.x_pos));

    try expectVec2ApproxEql(Vec2.x_neg, Rotor2.fromTo(.x_pos, .y_pos).timesVec2(.y_pos));
    try expectVec2ApproxEql(Vec2.x_pos, Rotor2.fromTo(.y_pos, .x_pos).timesVec2(.y_pos));

    // Test 180 degree rotations
    try std.testing.expectEqual(math.pi, Rotor2.fromTo(.x_pos, .x_neg).toAngle());
    try std.testing.expectEqual(math.pi, Rotor2.fromTo(.x_neg, .x_pos).toAngle());
    try std.testing.expectEqual(math.pi, Rotor2.fromTo(.y_pos, .y_neg).toAngle());
    try std.testing.expectEqual(math.pi, Rotor2.fromTo(.y_neg, .y_pos).toAngle());

    try std.testing.expectEqual(Vec2.x_neg, Rotor2.fromTo(.x_pos, .x_neg).timesVec2(.x_pos));
    try std.testing.expectEqual(Vec2.x_pos, Rotor2.fromTo(.x_pos, .x_neg).timesVec2(.x_neg));
    try std.testing.expectEqual(Vec2.x_neg, Rotor2.fromTo(.x_neg, .x_pos).timesVec2(.x_pos));
    try std.testing.expectEqual(Vec2.x_pos, Rotor2.fromTo(.x_neg, .x_pos).timesVec2(.x_neg));

    try std.testing.expectEqual(Vec2.y_neg, Rotor2.fromTo(.x_pos, .x_neg).timesVec2(.y_pos));
    try std.testing.expectEqual(Vec2.y_pos, Rotor2.fromTo(.x_pos, .x_neg).timesVec2(.y_neg));
    try std.testing.expectEqual(Vec2.y_neg, Rotor2.fromTo(.x_neg, .x_pos).timesVec2(.y_pos));
    try std.testing.expectEqual(Vec2.y_pos, Rotor2.fromTo(.x_neg, .x_pos).timesVec2(.y_neg));

    try std.testing.expectEqual(Vec2.y_neg, Rotor2.fromTo(.y_pos, .y_neg).timesVec2(.y_pos));
    try std.testing.expectEqual(Vec2.y_pos, Rotor2.fromTo(.y_pos, .y_neg).timesVec2(.y_neg));
    try std.testing.expectEqual(Vec2.y_neg, Rotor2.fromTo(.y_neg, .y_pos).timesVec2(.y_pos));
    try std.testing.expectEqual(Vec2.y_pos, Rotor2.fromTo(.y_neg, .y_pos).timesVec2(.y_neg));

    try std.testing.expectEqual(Vec2.x_neg, Rotor2.fromTo(.y_pos, .y_neg).timesVec2(.x_pos));
    try std.testing.expectEqual(Vec2.x_pos, Rotor2.fromTo(.y_pos, .y_neg).timesVec2(.x_neg));
    try std.testing.expectEqual(Vec2.x_neg, Rotor2.fromTo(.y_neg, .y_pos).timesVec2(.x_pos));
    try std.testing.expectEqual(Vec2.x_pos, Rotor2.fromTo(.y_neg, .y_pos).timesVec2(.x_neg));
}

test "fromAngle" {
    const pi = std.math.pi;

    // Test rotating 0 degrees
    try std.testing.expectEqual(Vec2.x_pos, Rotor2.fromAngle(0).timesVec2(.x_pos));
    try std.testing.expectEqual(Vec2.x_neg, Rotor2.fromAngle(0).timesVec2(.x_neg));
    try std.testing.expectEqual(Vec2.y_pos, Rotor2.fromAngle(0).timesVec2(.y_pos));
    try std.testing.expectEqual(Vec2.y_neg, Rotor2.fromAngle(0).timesVec2(.y_neg));

    // Test rotating 90 degrees
    try expectVec2ApproxEql(Vec2.y_neg, Rotor2.fromAngle(pi / 2.0).timesVec2(.x_pos));
    try expectVec2ApproxEql(Vec2.y_pos, Rotor2.fromAngle(-pi / 2.0).timesVec2(.x_pos));
    try expectVec2ApproxEql(Vec2.x_pos, Rotor2.fromAngle(pi / 2.0).timesVec2(.y_pos));
    try expectVec2ApproxEql(Vec2.x_neg, Rotor2.fromAngle(-pi / 2.0).timesVec2(.y_pos));

    // Test rotating 180 degrees
    try expectVec2ApproxEql(Vec2.x_neg, Rotor2.fromAngle(pi).timesVec2(.x_pos));
    try expectVec2ApproxEql(Vec2.y_neg, Rotor2.fromAngle(pi).timesVec2(.y_pos));
    try expectVec2ApproxEql(Vec2.x_pos, Rotor2.fromAngle(pi).timesVec2(.x_neg));
    try expectVec2ApproxEql(Vec2.y_pos, Rotor2.fromAngle(pi).timesVec2(.y_neg));

    // Test rotating 360 degrees
    try expectVec2ApproxEql(Vec2.x_pos, Rotor2.fromAngle(2.0 * pi).timesVec2(.x_pos));
    try expectVec2ApproxEql(Vec2.y_pos, Rotor2.fromAngle(2.0 * pi).timesVec2(.y_pos));
    try expectVec2ApproxEql(Vec2.x_neg, Rotor2.fromAngle(2.0 * pi).timesVec2(.x_neg));
    try expectVec2ApproxEql(Vec2.y_neg, Rotor2.fromAngle(2.0 * pi).timesVec2(.y_neg));
}

fn testExpVsAngle(plane: Bivec2, angle: f32) !void {
    const exp = plane.scaled(angle / 2.0).exp();
    const from_angle: Rotor2 = .fromAngle(if (plane.xy < 0.0) -angle else angle);
    try expectRotor2ApproxEql(exp, from_angle);
}

test "exp" {
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

fn testLnVsFromAngle(plane: Bivec2, angle: f32) !void {
    const actual: Bivec2 = Rotor2.fromAngle(if (plane.xy < 0.0) -angle else angle).ln();
    const expected: Bivec2 = plane.scaled(angle / 2.0);
    if (@abs(angle) == 2 * std.math.pi) {
        try std.testing.expectApproxEqAbs(std.math.pi, @abs(actual.xy), 0.01);
    } else {
        try std.testing.expectEqual(actual, expected);
    }
}

test "ln" {
    const pi = std.math.pi;
    const xy: Bivec2 = Vec2.x_pos.outerProd(.y_pos);
    const yx: Bivec2 = Vec2.y_pos.outerProd(.x_pos);

    // Test 0 degree rotations
    try testLnVsFromAngle(xy, 0.0);
    try testLnVsFromAngle(yx, 0.0);

    // Test 90 degree rotations
    try testLnVsFromAngle(xy, pi / 2.0);
    try testLnVsFromAngle(yx, pi / 2.0);
    try testLnVsFromAngle(xy, -pi / 2.0);
    try testLnVsFromAngle(yx, -pi / 2.0);

    // Test 180 degree rotations
    try testLnVsFromAngle(xy, pi);
    try testLnVsFromAngle(yx, pi);
    try testLnVsFromAngle(xy, -pi);
    try testLnVsFromAngle(yx, -pi);

    // Test 360 degree rotations
    try testLnVsFromAngle(xy, 2.0 * pi);
    try testLnVsFromAngle(yx, 2.0 * pi);
    try testLnVsFromAngle(xy, -2.0 * pi);
    try testLnVsFromAngle(yx, -2.0 * pi);

    // Test a rotor that wasn't exactly normalized correctly (this used to result in NaN)
    try std.testing.expectEqual(Bivec2{ .xy = 0.0 }, (Rotor2{ .xy = 0.0, .a = 1.0000001 }).ln());
}

test "mul" {
    const xy: Rotor2 = .fromTo(.x_pos, .y_pos);
    const yx: Rotor2 = .fromTo(.y_pos, .x_pos);
    const xy_half = xy.nlerp(.identity, 0.5);
    const yx_half = yx.nlerp(.identity, 0.5);

    // Canceling out
    try expectRotor2ApproxEql(Rotor2.identity, xy.times(yx));
    try expectRotor2ApproxEql(Rotor2.identity, yx.times(xy));
    try expectRotor2ApproxEql(Rotor2.identity, yx_half.times(xy_half));
    try expectRotor2ApproxEql(Rotor2.identity, xy_half.times(yx_half));

    // 180 degrees (the sign here is arbitrary for `fromTo` so we manually write out the result)
    try expectRotor2ApproxEql(Rotor2{ .xy = -1.0, .a = 0.0 }, yx.times(yx));
    try expectRotor2ApproxEql(Rotor2{ .xy = 1.0, .a = 0.0 }, xy.times(xy));

    // Increments of 45 degrees
    try expectRotor2ApproxEql(xy, xy_half.times(xy_half));
    try expectRotor2ApproxEql(yx, yx_half.times(yx_half));
}

fn testInterpolation(large_angles: bool, interp: *const fn (Rotor2, Rotor2, f32) Rotor2) !void {
    const pi = std.math.pi;
    const r_0: Rotor2 = .identity;
    const r_yx180: Rotor2 = .fromAngle(-pi);
    const r_xy90: Rotor2 = .fromAngle(pi / 4.0);
    const r_yx90: Rotor2 = .fromAngle(-pi / 4.0);
    const r_xy270: Rotor2 = .fromAngle(3.0 * pi / 4.0);
    const r_xy45: Rotor2 = .fromAngle(pi / 8.0);

    // Test interpolating between identical rotors
    try std.testing.expectEqual(r_0, interp(r_0, r_0, 0.0));
    try std.testing.expectEqual(r_0, interp(r_0, r_0, 0.5));
    try std.testing.expectEqual(r_0, interp(r_0, r_0, 1.0));
    try std.testing.expectEqual(r_0, interp(r_0, r_0, 2.0));
    try std.testing.expectEqual(r_0, interp(r_0, r_0, -1.0));

    try std.testing.expectEqual(r_xy90, interp(r_xy90, r_xy90, 0.0));
    try std.testing.expectEqual(r_xy90, interp(r_xy90, r_xy90, 0.5));
    try std.testing.expectEqual(r_xy90, interp(r_xy90, r_xy90, 1.0));
    if (large_angles) {
        // Slerp is not exact here
        try expectRotor2ApproxEql(r_xy90, interp(r_xy90, r_xy90, 2.0));
    } else {
        try std.testing.expectEqual(r_xy90, interp(r_xy90, r_xy90, 2.0));
    }
    try std.testing.expectEqual(r_xy90, interp(r_xy90, r_xy90, -1.0));

    // Test interpolating between r0 and perpendicular rotors
    try std.testing.expectEqual(r_0, interp(r_0, r_xy90, 0.0));
    try expectRotor2ApproxEql(r_xy45, interp(r_0, r_xy90, 0.5));
    try std.testing.expectEqual(r_xy90, interp(r_0, r_xy90, 1.0));
    if (large_angles) {
        try expectRotor2ApproxEql(r_xy270, interp(r_0, r_xy90, 3.0));
        try std.testing.expectEqual(r_yx90, interp(r_0, r_xy90, -1.0));
    }

    if (large_angles) {
        // Slerp is not exact here
        try expectRotor2ApproxEql(r_0, interp(r_xy90, r_0, 1.0));
    } else {
        try std.testing.expectEqual(r_0, interp(r_xy90, r_0, 1.0));
    }
    try expectRotor2ApproxEql(r_xy45, interp(r_xy90, r_0, 0.5));
    try std.testing.expectEqual(r_xy90, interp(r_xy90, r_0, 0.0));
    if (large_angles) {
        try std.testing.expectEqual(r_yx90, interp(r_xy90, r_0, 2.0));
        try expectRotor2ApproxEql(r_xy270, interp(r_xy90, r_0, -2.0));
    }

    // Test interpolating between the same rotor in two different neighborhoods
    {
        const start = r_0;
        const end = start.negated();
        try std.testing.expectEqual(start, interp(start, end, 0.0));
        if (large_angles) {
            // The direction is arbitrary in this case since there's no shortest path, but we do get
            // half of the full turn as expected!
            try std.testing.expectEqual(r_yx180, interp(start, end, 0.5));

            // Slerp is approximate here unlike nlerp
            try expectRotor2ApproxEql(end, interp(start, end, 1.0));
        } else {
            // Nlerp is exact here unlike slerp
            try std.testing.expectEqual(end, interp(start, end, 1.0));

            // This is geometrically incorrect, but the result we expect out of nlerp for this
            // angle.
            try std.testing.expectEqual(start, interp(start, end, 0.5));
        }
    }
}

test "interpolation" {
    try testInterpolation(true, Rotor2.slerp);
    try testInterpolation(false, Rotor2.nlerp);
}
