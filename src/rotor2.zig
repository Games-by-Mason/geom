const std = @import("std");
const geom = @import("root.zig");

const math = std.math;

const Vec2 = geom.Vec2;
const Bivec2 = geom.Bivec2;
const Mat2x3 = geom.Mat2x3;

/// A two dimensional rotor. Rotors are a generalized form of quaternions which are used for
/// rotation. Unlike quaternions, rotors generalize to all dimensions. Rotors can represent up to
/// two full rotations, at which point they wrap back around.
pub const Rotor2 = packed struct {
    /// The component that rotates from x to y along the xy plane.
    xy: f32,
    /// The scalar component.
    a: f32,

    /// The identity rotor. Has no effect.
    pub const identity: Rotor2 = .{ .xy = 0.0, .a = 1.0 };

    /// Creates a rotor that rotates from `from` to `to`, `from` and `to` must be normalized. If
    /// `from` and to are parallel in opposite directions, it rotates 180 degrees in an arbitrary
    /// direction.
    pub fn fromTo(from: Vec2, to: Vec2) Rotor2 {
        const result = from.geomProd(to);
        const res_mag = result.mag();
        if (res_mag == 0.0) {
            return .fromAngle(math.pi);
        } else {
            return result.scaled(1.0 / res_mag);
        }
    }

    /// Creates a rotor that rotates from the positive y axis to the given direction. Assumes `dir`
    /// is normalized.
    pub fn look(dir: Vec2) Rotor2 {
        return .fromTo(.y_pos, dir);
    }

    /// Returns the rotor scaled by the given factor.
    pub fn scaled(self: Rotor2, factor: f32) Rotor2 {
        return .{
            .xy = self.xy * factor,
            .a = self.a * factor,
        };
    }

    /// Scales the rotor by the given factor.
    pub fn scale(self: *Rotor2, factor: f32) void {
        self.* = self.scaled(factor);
    }

    /// Creates a rotor that from the given angle. Prefer `fromTo` when not operating on human
    /// input.
    pub fn fromAngle(rad: f32) Rotor2 {
        return .{
            .xy = -@sin(rad / 2.0),
            .a = @cos(rad / 2.0),
        };
    }

    /// Returns the angle of rotation. Useful for debugging, use for logic is discouraged.
    pub fn toAngle(self: Rotor2) f32 {
        return 2.0 * std.math.atan2(-self.xy, self.a);
    }

    /// Returns the squared magnitude of the rotor.
    pub fn magSq(self: Rotor2) f32 {
        return self.a * self.a + self.xy * self.xy;
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

    /// Adds a full rotation to the given rotor. Agnostic to normalization. Not to be confused with
    /// `inverse`.
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
        return self.a * other.a + self.xy * other.xy;
    }

    /// Returns a normalized rotor. If the magnitude is 0 the result will be a rotor filled with
    /// NaNs.
    pub fn normalized(self: Rotor2) Rotor2 {
        return self.scaled(1.0 / self.mag());
    }

    /// Normalizes the rotor. See `normalized`.
    pub fn normalize(self: *Rotor2) void {
        self.* = self.normalized();
    }

    /// Applies the rotor to a vector.
    pub fn timesPoint(self: Rotor2, point: Vec2) Vec2 {
        // temp = -rotor * point
        const x = self.a * point.x - self.xy * point.y;
        const y = self.a * point.y + self.xy * point.x;

        // temp * rotor
        return .{
            .x = x * self.a - y * self.xy,
            .y = x * self.xy + y * self.a,
        };
    }

    /// Returns the rotor multiplied by other. This lets you compose rotations. Order matters.
    pub fn times(self: Rotor2, other: Rotor2) Rotor2 {
        return .{
            .a = -self.xy * other.xy + self.a * other.a,
            .xy = self.xy * other.a + self.a * other.xy,
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
        const bivec: Bivec2 = .{ .xy = self.xy };
        const cos = self.a;
        const sin = bivec.mag();

        if (sin == 0.0) {
            // If sin is 0, cos must be either -1 or 1. We check with gt to avoid rounding errors.
            if (cos > 0.0) {
                // 0 degree rotation
                return .{ .xy = 0.0 };
            } else {
                // 360 degree rotation (around an arbitrary plane, but there's only one plane in 2D)
                return .{ .xy = std.math.pi };
            }
        } else {
            // Normalize the bivector by dividing by its current magnitude (sin) and then scale it by the
            // half angle.
            const half_angle = std.math.atan2(sin, cos);
            return bivec.scaled(half_angle / sin);
        }
    }

    /// Spherically linearly interpolates between two rotors. See also `nlerp`.
    ///
    /// Interpolates a constant velocity, but is computationally heavy and is not commutative. If
    /// `t` is outside of the [0, 1] range, the rotation will continue past the start or end.
    pub fn slerp(start: Rotor2, end: Rotor2, t: f32) Rotor2 {
        start.mul(start.inverse().mul(end).ln().scaled(t).exp());
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
            return result.scaled(1.0 / res_mag);
        }
    }
};
