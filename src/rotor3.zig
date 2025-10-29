const std = @import("std");
const geom = @import("root.zig");
const tween = @import("tween");

const math = std.math;

const Vec3 = geom.Vec3;
const Bivec3 = geom.Bivec3;

const lerp = tween.interp.lerp;

/// A three dimensional rotor. Rotors are a generalized form of quaternions which are used for
/// rotation. Unlike quaternions, rotors generalize to all dimensions. Rotors can represent up to
/// two full rotations, at which point they wrap back around.
///
/// No method is provided for constructing a `Rotor3` from Euler angles, as this library has no
/// opinion on the "correct" order in which to compose the three rotations. You can implement this
/// function with your preferred order by multiplying calls to `fromPlaneAngle`, or you can simply
/// use `fromPlaneAngle` or `fromTo` instead of using Euler angles.
pub const Rotor3 = extern struct {
    /// The component that rotates from x to y along the yz plane.
    ///
    /// Equivalent to the sine of half the rotation along the yz plane.
    yz: f32,
    /// The component that rotates from x to y along the xz plane.
    ///
    /// Equivalent to the sine of half the rotation along the xz plane.
    xz: f32,
    /// The component that rotates from x to y along the yx plane.
    ///
    /// Equivalent to the sine of half the rotation along the yx plane.
    yx: f32,
    /// The scalar component.
    ///
    /// Equivalent to the cosine of half the rotation.
    a: f32,

    /// The identity rotor. Has no effect.
    pub const identity: Rotor3 = .{ .yz = 0.0, .xz = 0.0, .yx = 0.0, .a = 1.0 };

    /// Checks for equality.
    pub fn eql(self: Rotor3, other: Rotor3) bool {
        return std.meta.eql(self, other);
    }

    test eql {
        try std.testing.expect(Rotor3.identity.eql(Rotor3.identity));
        try std.testing.expect(!Rotor3.identity.eql(Rotor3.fromTo(.x_pos, .z_pos)));
    }

    /// Creates a rotor that rotates along the shortest path from `from` to `to`. `from` and `to`
    /// must be normalized.
    ///
    /// If `from` and to are parallel in opposite directions, the tie is broken arbitrarily.
    pub fn fromTo(from: Vec3, to: Vec3) Rotor3 {
        const result = from.geomProd(to);
        const res_mag_sq = result.magSq();
        if (res_mag_sq == 0.0) {
            const plane = b: {
                const plane = from.outerProd(.x_pos);
                if (plane.magSq() != 0) break :b plane;
                break :b from.outerProd(.y_pos);
            };
            return .fromPlaneAngle(plane, math.pi);
        } else {
            return result.scaledComps(geom.invSqrt(res_mag_sq));
        }
    }

    test fromTo {
        // Test unit rotations
        try std.testing.expectEqual(Rotor3.identity, Rotor3.fromTo(.x_pos, .x_pos));
        try std.testing.expectEqual(Rotor3.identity, Rotor3.fromTo(.x_neg, .x_neg));
        try std.testing.expectEqual(Rotor3.identity, Rotor3.fromTo(.y_pos, .y_pos));
        try std.testing.expectEqual(Rotor3.identity, Rotor3.fromTo(.y_neg, .y_neg));
        try std.testing.expectEqual(Rotor3.identity, Rotor3.fromTo(.z_pos, .z_pos));
        try std.testing.expectEqual(Rotor3.identity, Rotor3.fromTo(.z_neg, .z_neg));

        try std.testing.expectEqual(Vec3.x_pos, Rotor3.fromTo(.x_pos, .x_pos).timesVec3(.x_pos));
        try std.testing.expectEqual(Vec3.y_pos, Rotor3.fromTo(.y_pos, .y_pos).timesVec3(.y_pos));
        try std.testing.expectEqual(Vec3.z_pos, Rotor3.fromTo(.z_pos, .z_pos).timesVec3(.z_pos));

        try std.testing.expectEqual(Vec3.y_pos, Rotor3.fromTo(.x_pos, .x_pos).timesVec3(.y_pos));
        try std.testing.expectEqual(Vec3.x_pos, Rotor3.fromTo(.y_pos, .y_pos).timesVec3(.x_pos));
        try std.testing.expectEqual(Vec3.z_pos, Rotor3.fromTo(.y_pos, .y_pos).timesVec3(.z_pos));

        // Test 90 degree rotations
        try expectVec3ApproxEql(Vec3.y_pos, Rotor3.fromTo(.x_pos, .y_pos).timesVec3(.x_pos));
        try expectVec3ApproxEql(Vec3.y_neg, Rotor3.fromTo(.y_pos, .x_pos).timesVec3(.x_pos));
        try expectVec3ApproxEql(Vec3.z_pos, Rotor3.fromTo(.x_pos, .z_pos).timesVec3(.x_pos));
        try expectVec3ApproxEql(Vec3.z_neg, Rotor3.fromTo(.z_pos, .x_pos).timesVec3(.x_pos));

        try expectVec3ApproxEql(Vec3.x_neg, Rotor3.fromTo(.x_pos, .y_pos).timesVec3(.y_pos));
        try expectVec3ApproxEql(Vec3.x_pos, Rotor3.fromTo(.y_pos, .x_pos).timesVec3(.y_pos));
        try expectVec3ApproxEql(Vec3.z_pos, Rotor3.fromTo(.y_pos, .z_pos).timesVec3(.y_pos));
        try expectVec3ApproxEql(Vec3.z_neg, Rotor3.fromTo(.z_pos, .y_pos).timesVec3(.y_pos));

        try expectVec3ApproxEql(Vec3.y_pos, Rotor3.fromTo(.z_pos, .y_pos).timesVec3(.z_pos));
        try expectVec3ApproxEql(Vec3.y_neg, Rotor3.fromTo(.y_pos, .z_pos).timesVec3(.z_pos));
        try expectVec3ApproxEql(Vec3.x_pos, Rotor3.fromTo(.z_pos, .x_pos).timesVec3(.z_pos));
        try expectVec3ApproxEql(Vec3.x_neg, Rotor3.fromTo(.x_pos, .z_pos).timesVec3(.z_pos));

        // Test 180 degree rotations
        try expectVec3ApproxEql(Vec3.x_neg, Rotor3.fromTo(.x_pos, .x_neg).timesVec3(.x_pos));
        try expectVec3ApproxEql(Vec3.x_pos, Rotor3.fromTo(.x_pos, .x_neg).timesVec3(.x_neg));
        try expectVec3ApproxEql(Vec3.x_neg, Rotor3.fromTo(.x_neg, .x_pos).timesVec3(.x_pos));
        try expectVec3ApproxEql(Vec3.x_pos, Rotor3.fromTo(.x_neg, .x_pos).timesVec3(.x_neg));

        try expectVec3ApproxEql(Vec3.y_neg, Rotor3.fromTo(.x_pos, .x_neg).timesVec3(.y_pos));
        try expectVec3ApproxEql(Vec3.y_pos, Rotor3.fromTo(.x_pos, .x_neg).timesVec3(.y_neg));
        try expectVec3ApproxEql(Vec3.y_neg, Rotor3.fromTo(.x_neg, .x_pos).timesVec3(.y_pos));
        try expectVec3ApproxEql(Vec3.y_pos, Rotor3.fromTo(.x_neg, .x_pos).timesVec3(.y_neg));

        try expectVec3ApproxEql(Vec3.z_pos, Rotor3.fromTo(.x_pos, .x_neg).timesVec3(.z_pos));
        try expectVec3ApproxEql(Vec3.z_neg, Rotor3.fromTo(.x_pos, .x_neg).timesVec3(.z_neg));
        try expectVec3ApproxEql(Vec3.z_pos, Rotor3.fromTo(.x_neg, .x_pos).timesVec3(.z_pos));
        try expectVec3ApproxEql(Vec3.z_neg, Rotor3.fromTo(.x_neg, .x_pos).timesVec3(.z_neg));

        try expectVec3ApproxEql(Vec3.y_neg, Rotor3.fromTo(.y_pos, .y_neg).timesVec3(.y_pos));
        try expectVec3ApproxEql(Vec3.y_pos, Rotor3.fromTo(.y_pos, .y_neg).timesVec3(.y_neg));
        try expectVec3ApproxEql(Vec3.y_neg, Rotor3.fromTo(.y_neg, .y_pos).timesVec3(.y_pos));
        try expectVec3ApproxEql(Vec3.y_pos, Rotor3.fromTo(.y_neg, .y_pos).timesVec3(.y_neg));

        try expectVec3ApproxEql(Vec3.x_neg, Rotor3.fromTo(.y_pos, .y_neg).timesVec3(.x_pos));
        try expectVec3ApproxEql(Vec3.x_pos, Rotor3.fromTo(.y_pos, .y_neg).timesVec3(.x_neg));
        try expectVec3ApproxEql(Vec3.x_neg, Rotor3.fromTo(.y_neg, .y_pos).timesVec3(.x_pos));
        try expectVec3ApproxEql(Vec3.x_pos, Rotor3.fromTo(.y_neg, .y_pos).timesVec3(.x_neg));

        try expectVec3ApproxEql(Vec3.z_neg, Rotor3.fromTo(.z_pos, .z_neg).timesVec3(.z_pos));
        try expectVec3ApproxEql(Vec3.z_pos, Rotor3.fromTo(.z_pos, .z_neg).timesVec3(.z_neg));
        try expectVec3ApproxEql(Vec3.z_neg, Rotor3.fromTo(.z_neg, .z_pos).timesVec3(.z_pos));
        try expectVec3ApproxEql(Vec3.z_pos, Rotor3.fromTo(.z_neg, .z_pos).timesVec3(.z_neg));
    }

    /// Creates a rotor that rotates from the positive y axis to the given direction. Assumes `dir`
    /// is normalized. If `dir` is `.zero`, `.identity` is returned.
    pub fn look(dir: Vec3) Rotor3 {
        return .fromTo(.y_pos, dir);
    }

    test look {
        try std.testing.expectEqual(Rotor3.identity, Rotor3.look(.y_pos));
        try std.testing.expectEqual(Rotor3.fromTo(.y_pos, .z_pos), Rotor3.look(.z_pos));
        try std.testing.expectEqual(Rotor3.identity, Rotor3.look(.zero));
    }

    /// Returns the rotor with all components scaled by the given factor. This does not scale the
    /// rotation.
    pub fn scaledComps(self: Rotor3, factor: f32) Rotor3 {
        return .{
            .yz = self.yz * factor,
            .xz = self.xz * factor,
            .yx = self.yx * factor,
            .a = self.a * factor,
        };
    }

    test scaledComps {
        const r: Rotor3 = .identity;
        const r2 = r.scaledComps(2.0);
        try std.testing.expectEqual(Rotor3{
            .yz = 0.0,
            .xz = 0.0,
            .yx = 0.0,
            .a = 2.0,
        }, r2);
    }

    /// Scales the rotor's components by the given factor. This does not scale the rotation.
    pub fn scaleComps(self: *Rotor3, factor: f32) void {
        self.* = self.scaledComps(factor);
    }

    test scaleComps {
        var r: Rotor3 = .identity;
        r.scaleComps(2.0);
        try std.testing.expectEqual(Rotor3{
            .yz = 0.0,
            .xz = 0.0,
            .yx = 0.0,
            .a = 2.0,
        }, r);
    }

    /// Creates a rotor from the given plane and angle. Prefer `fromTo` when not operating on human
    /// input.
    pub fn fromPlaneAngle(plane: Bivec3, rad: f32) Rotor3 {
        const half = rad * 0.5;
        const sin = @sin(half);
        const cos = @cos(half);
        return .{
            .yz = sin * plane.yz,
            .xz = sin * plane.xz,
            .yx = sin * plane.yx,
            .a = cos,
        };
    }

    test fromPlaneAngle {
        // Test rotating 0 degrees
        try std.testing.expectEqual(Vec3.x_pos, Rotor3.fromPlaneAngle(.yx_pos, 0).timesVec3(.x_pos));
        try std.testing.expectEqual(Vec3.x_neg, Rotor3.fromPlaneAngle(.yx_neg, 0).timesVec3(.x_neg));
        try std.testing.expectEqual(Vec3.y_pos, Rotor3.fromPlaneAngle(.yz_pos, 0).timesVec3(.y_pos));
        try std.testing.expectEqual(Vec3.y_neg, Rotor3.fromPlaneAngle(.yz_neg, 0).timesVec3(.y_neg));
        try std.testing.expectEqual(Vec3.z_neg, Rotor3.fromPlaneAngle(.xz_pos, 0).timesVec3(.z_neg));
        try std.testing.expectEqual(Vec3.z_pos, Rotor3.fromPlaneAngle(.xz_neg, 0).timesVec3(.z_pos));

        // Test rotating 90 degrees
        try expectVec3ApproxEql(Vec3.y_neg, Rotor3.fromPlaneAngle(.yx_pos, math.pi / 2.0).timesVec3(.x_pos));
        try expectVec3ApproxEql(Vec3.y_pos, Rotor3.fromPlaneAngle(.yx_pos, -math.pi / 2.0).timesVec3(.x_pos));
        try expectVec3ApproxEql(Vec3.x_pos, Rotor3.fromPlaneAngle(.yx_pos, math.pi / 2.0).timesVec3(.y_pos));
        try expectVec3ApproxEql(Vec3.x_neg, Rotor3.fromPlaneAngle(.yx_pos, -math.pi / 2.0).timesVec3(.y_pos));
        try expectVec3ApproxEql(Vec3.z_pos, Rotor3.fromPlaneAngle(.yx_pos, math.pi / 2.0).timesVec3(.z_pos));
        try expectVec3ApproxEql(Vec3.z_pos, Rotor3.fromPlaneAngle(.yx_pos, -math.pi / 2.0).timesVec3(.z_pos));

        try expectVec3ApproxEql(Vec3.z_pos, Rotor3.fromPlaneAngle(.xz_neg, -math.pi / 2.0).timesVec3(.x_pos));
        try expectVec3ApproxEql(Vec3.z_neg, Rotor3.fromPlaneAngle(.xz_neg, math.pi / 2.0).timesVec3(.x_pos));
        try expectVec3ApproxEql(Vec3.y_pos, Rotor3.fromPlaneAngle(.xz_neg, -math.pi / 2.0).timesVec3(.y_pos));
        try expectVec3ApproxEql(Vec3.y_pos, Rotor3.fromPlaneAngle(.xz_neg, math.pi / 2.0).timesVec3(.y_pos));
        try expectVec3ApproxEql(Vec3.x_neg, Rotor3.fromPlaneAngle(.xz_neg, -math.pi / 2.0).timesVec3(.z_pos));
        try expectVec3ApproxEql(Vec3.x_pos, Rotor3.fromPlaneAngle(.xz_neg, math.pi / 2.0).timesVec3(.z_pos));

        try expectVec3ApproxEql(Vec3.x_pos, Rotor3.fromPlaneAngle(.yz_pos, math.pi / 2.0).timesVec3(.x_pos));
        try expectVec3ApproxEql(Vec3.x_pos, Rotor3.fromPlaneAngle(.yz_pos, -math.pi / 2.0).timesVec3(.x_pos));
        try expectVec3ApproxEql(Vec3.z_pos, Rotor3.fromPlaneAngle(.yz_pos, math.pi / 2.0).timesVec3(.y_pos));
        try expectVec3ApproxEql(Vec3.z_neg, Rotor3.fromPlaneAngle(.yz_pos, -math.pi / 2.0).timesVec3(.y_pos));
        try expectVec3ApproxEql(Vec3.y_neg, Rotor3.fromPlaneAngle(.yz_pos, math.pi / 2.0).timesVec3(.z_pos));
        try expectVec3ApproxEql(Vec3.y_pos, Rotor3.fromPlaneAngle(.yz_pos, -math.pi / 2.0).timesVec3(.z_pos));

        // Test rotating 180 degrees
        try expectVec3ApproxEql(Vec3.x_neg, Rotor3.fromPlaneAngle(.yx_pos, math.pi).timesVec3(.x_pos));
        try expectVec3ApproxEql(Vec3.y_neg, Rotor3.fromPlaneAngle(.yx_pos, math.pi).timesVec3(.y_pos));
        try expectVec3ApproxEql(Vec3.z_pos, Rotor3.fromPlaneAngle(.yx_pos, math.pi).timesVec3(.z_pos));
        try expectVec3ApproxEql(Vec3.x_pos, Rotor3.fromPlaneAngle(.yx_pos, math.pi).timesVec3(.x_neg));
        try expectVec3ApproxEql(Vec3.y_pos, Rotor3.fromPlaneAngle(.yx_pos, math.pi).timesVec3(.y_neg));
        try expectVec3ApproxEql(Vec3.z_pos, Rotor3.fromPlaneAngle(.yx_pos, math.pi).timesVec3(.z_pos));

        try expectVec3ApproxEql(Vec3.x_neg, Rotor3.fromPlaneAngle(.xz_pos, -math.pi).timesVec3(.x_pos));
        try expectVec3ApproxEql(Vec3.x_pos, Rotor3.fromPlaneAngle(.xz_pos, -math.pi).timesVec3(.x_neg));
        try expectVec3ApproxEql(Vec3.y_pos, Rotor3.fromPlaneAngle(.xz_pos, -math.pi).timesVec3(.y_pos));
        try expectVec3ApproxEql(Vec3.y_neg, Rotor3.fromPlaneAngle(.xz_pos, -math.pi).timesVec3(.y_neg));
        try expectVec3ApproxEql(Vec3.z_neg, Rotor3.fromPlaneAngle(.xz_pos, -math.pi).timesVec3(.z_pos));
        try expectVec3ApproxEql(Vec3.z_pos, Rotor3.fromPlaneAngle(.xz_pos, -math.pi).timesVec3(.z_neg));

        try expectVec3ApproxEql(Vec3.x_pos, Rotor3.fromPlaneAngle(.yz_pos, math.pi).timesVec3(.x_pos));
        try expectVec3ApproxEql(Vec3.x_neg, Rotor3.fromPlaneAngle(.yz_pos, math.pi).timesVec3(.x_neg));
        try expectVec3ApproxEql(Vec3.y_neg, Rotor3.fromPlaneAngle(.yz_pos, math.pi).timesVec3(.y_pos));
        try expectVec3ApproxEql(Vec3.y_pos, Rotor3.fromPlaneAngle(.yz_pos, math.pi).timesVec3(.y_neg));
        try expectVec3ApproxEql(Vec3.z_neg, Rotor3.fromPlaneAngle(.yz_pos, math.pi).timesVec3(.z_pos));
        try expectVec3ApproxEql(Vec3.z_pos, Rotor3.fromPlaneAngle(.yz_pos, math.pi).timesVec3(.z_neg));

        // Test rotating 360 degrees
        try expectVec3ApproxEql(Vec3.x_pos, Rotor3.fromPlaneAngle(.yx_pos, 2.0 * math.pi).timesVec3(.x_pos));
        try expectVec3ApproxEql(Vec3.y_pos, Rotor3.fromPlaneAngle(.yx_pos, 2.0 * math.pi).timesVec3(.y_pos));
        try expectVec3ApproxEql(Vec3.x_neg, Rotor3.fromPlaneAngle(.yx_pos, 2.0 * math.pi).timesVec3(.x_neg));
        try expectVec3ApproxEql(Vec3.y_neg, Rotor3.fromPlaneAngle(.yx_pos, 2.0 * math.pi).timesVec3(.y_neg));
        try expectVec3ApproxEql(Vec3.z_pos, Rotor3.fromPlaneAngle(.yx_pos, 2.0 * math.pi).timesVec3(.z_pos));
        try expectVec3ApproxEql(Vec3.z_neg, Rotor3.fromPlaneAngle(.yx_pos, 2.0 * math.pi).timesVec3(.z_neg));

        try expectVec3ApproxEql(Vec3.x_pos, Rotor3.fromPlaneAngle(.xz_neg, 2.0 * math.pi).timesVec3(.x_pos));
        try expectVec3ApproxEql(Vec3.y_pos, Rotor3.fromPlaneAngle(.xz_neg, 2.0 * math.pi).timesVec3(.y_pos));
        try expectVec3ApproxEql(Vec3.x_neg, Rotor3.fromPlaneAngle(.xz_neg, 2.0 * math.pi).timesVec3(.x_neg));
        try expectVec3ApproxEql(Vec3.y_neg, Rotor3.fromPlaneAngle(.xz_neg, 2.0 * math.pi).timesVec3(.y_neg));
        try expectVec3ApproxEql(Vec3.z_pos, Rotor3.fromPlaneAngle(.xz_neg, 2.0 * math.pi).timesVec3(.z_pos));
        try expectVec3ApproxEql(Vec3.z_neg, Rotor3.fromPlaneAngle(.xz_neg, 2.0 * math.pi).timesVec3(.z_neg));

        try expectVec3ApproxEql(Vec3.x_pos, Rotor3.fromPlaneAngle(.yz_pos, 2.0 * math.pi).timesVec3(.x_pos));
        try expectVec3ApproxEql(Vec3.y_pos, Rotor3.fromPlaneAngle(.yz_pos, 2.0 * math.pi).timesVec3(.y_pos));
        try expectVec3ApproxEql(Vec3.x_neg, Rotor3.fromPlaneAngle(.yz_pos, 2.0 * math.pi).timesVec3(.x_neg));
        try expectVec3ApproxEql(Vec3.y_neg, Rotor3.fromPlaneAngle(.yz_pos, 2.0 * math.pi).timesVec3(.y_neg));
        try expectVec3ApproxEql(Vec3.z_pos, Rotor3.fromPlaneAngle(.yz_pos, 2.0 * math.pi).timesVec3(.z_pos));
        try expectVec3ApproxEql(Vec3.z_neg, Rotor3.fromPlaneAngle(.yz_pos, 2.0 * math.pi).timesVec3(.z_neg));
    }

    /// Returns the squared magnitude of the rotor.
    pub fn magSq(self: Rotor3) f32 {
        return @mulAdd(f32, self.yz, self.yz, self.xz * self.xz) +
            @mulAdd(f32, self.yx, self.yx, self.a * self.a);
    }

    test magSq {
        const r: Rotor3 = .{ .yz = 1.0, .xz = 2.0, .yx = 3.0, .a = 4.0 };
        try std.testing.expectEqual(30.0, r.magSq());
    }

    /// Returns the magnitude of the rotor. Prefer `magSq` paired with `geom.invSqrt` or
    /// `geom.invSqrtNearOne` when possible.
    pub fn mag(self: Rotor3) f32 {
        return @sqrt(self.magSq());
    }

    test mag {
        const r: Rotor3 = .{ .yz = 2.0, .xz = 3.0, .yx = 4.0, .a = 5.0 };
        try std.testing.expectEqual(7.3484692283495345, r.mag());
    }

    /// Returns the inverse rotation. Not to be confused with `negate`.
    pub fn inverse(self: Rotor3) Rotor3 {
        return .{
            .yz = -self.yz,
            .xz = -self.xz,
            .yx = -self.yx,
            .a = self.a,
        };
    }

    test inverse {
        const r: Rotor3 = .{ .yz = 2.0, .xz = 3.0, .yx = 4.0, .a = 5.0 };
        const ri = r.inverse();
        try std.testing.expectEqual(Rotor3{
            .yz = -r.yz,
            .xz = -r.xz,
            .yx = -r.yx,
            .a = r.a,
        }, ri);
    }

    /// Inverts the rotation.
    pub fn invert(self: *Rotor3) void {
        self.* = self.inverse();
    }

    test invert {
        var r: Rotor3 = .{ .yz = 2.0, .xz = 3.0, .yx = 4.0, .a = 5.0 };
        r.invert();
        try std.testing.expectEqual(Rotor3{
            .yz = -2.0,
            .xz = -3.0,
            .yx = -4.0,
            .a = 5.0,
        }, r);
    }

    /// Not to be confused with `inverse`. Adds a full rotation to the given rotor, flipping its
    /// neighborhood. Agnostic to normalization.
    pub fn negated(self: Rotor3) Rotor3 {
        return .{
            .yz = -self.yz,
            .xz = -self.xz,
            .yx = -self.yx,
            .a = -self.a,
        };
    }

    test negated {
        try std.testing.expectEqual(Rotor3{
            .yz = 0,
            .xz = 0,
            .yx = 0,
            .a = -1.0,
        }, Rotor3.identity.negated());
    }

    /// Negates the rotor, see `negated`.
    pub fn negate(self: *Rotor3) void {
        self.* = self.negated();
    }

    test negate {
        var r: Rotor3 = .identity;
        r.negate();
        try std.testing.expectEqual(Rotor3{
            .yz = 0,
            .xz = 0,
            .yx = 0,
            .a = -1.0,
        }, r);
    }

    /// Returns the cosine of the half angle between the two given normalized rotors. If the result
    /// is negative, they are more than a full rotation apart. If it is positive they are not.
    pub fn neighborhood(self: Rotor3, other: Rotor3) f32 {
        return @mulAdd(
            f32,
            self.yz,
            other.yz,
            @mulAdd(
                f32,
                self.xz,
                self.xz,
                @mulAdd(
                    f32,
                    self.yx,
                    self.yx,
                    self.a * self.a,
                ),
            ),
        );
    }

    test neighborhood {
        try std.testing.expect(Rotor3.neighborhood(.identity, .identity) > 0.0);
    }

    /// Returns a renormalized rotor. Assumes the input is already near normal.
    pub fn renormalized(self: Rotor3) Rotor3 {
        return self.scaledComps(geom.invSqrtNearOne(self.magSq()));
    }

    test renormalized {
        var r: Rotor3 = .{ .yz = 0.0, .xz = 0.0, .yx = 0.0, .a = 1.05 };
        r = r.renormalized();
        try std.testing.expectEqual(0.0, r.yz);
        try std.testing.expectEqual(0.0, r.xz);
        try std.testing.expectEqual(0.0, r.yx);
        try std.testing.expectApproxEqAbs(1.0, r.a, 0.01);
    }

    /// Renormalizes a rotor. See `renormalized`.
    pub fn renormalize(self: *Rotor3) void {
        self.* = self.renormalized();
    }

    test renormalize {
        var r: Rotor3 = .{ .yz = 0.0, .xz = 0.0, .yx = 0.0, .a = 1.05 };
        r.renormalize();
        try std.testing.expectEqual(0.0, r.yz);
        try std.testing.expectEqual(0.0, r.xz);
        try std.testing.expectEqual(0.0, r.yx);
        try std.testing.expectApproxEqAbs(1.0, r.a, 0.01);
    }

    /// Returns a normalized rotor. If the magnitude is 0 the result will be a rotor filled with
    /// NaNs. If your input is nearly normal already, consider using `renormalize` instead.
    pub fn normalized(self: Rotor3) Rotor3 {
        return self.scaledComps(geom.invSqrt(self.magSq()));
    }

    test normalized {
        var r: Rotor3 = .{ .yz = 0.0, .xz = 0.0, .yx = 0.0, .a = 10.0 };
        r = r.normalized();
        try std.testing.expectEqual(0.0, r.yz);
        try std.testing.expectEqual(0.0, r.xz);
        try std.testing.expectEqual(0.0, r.yx);
        try std.testing.expectEqual(1.0, r.a);
    }

    /// Normalizes the rotor. See `normalized`.
    pub fn normalize(self: *Rotor3) void {
        self.* = self.normalized();
    }

    test normalize {
        var r: Rotor3 = .{ .yz = 0.0, .xz = 0.0, .yx = 0.0, .a = 10.0 };
        r.normalize();
        try std.testing.expectEqual(0.0, r.yz);
        try std.testing.expectEqual(0.0, r.xz);
        try std.testing.expectEqual(0.0, r.yx);
        try std.testing.expectEqual(1.0, r.a);
    }

    /// Applies the rotor to a vector.
    pub fn timesVec3(self: Rotor3, point: Vec3) Vec3 {
        const s = self;
        const p = point;

        // temp = -rotor * point (results in trivector, stored as locals)
        const x = @mulAdd(f32, -s.xz, p.z, @mulAdd(f32, s.yx, p.y, s.a * p.x));
        const y = @mulAdd(f32, -s.yz, p.z, @mulAdd(f32, -s.yx, p.x, s.a * p.y));
        const z = @mulAdd(f32, s.yz, p.y, @mulAdd(f32, s.xz, p.x, s.a * p.z));
        const xyz = @mulAdd(f32, -s.yz, p.x, @mulAdd(f32, s.xz, p.y, s.yx * p.z));

        // temp * rotor
        return .{
            .x = y * s.yx - z * s.xz - xyz * s.yz + x * s.a,
            .y = -x * s.yx - z * s.yz + xyz * s.xz + y * s.a,
            .z = x * s.xz + y * s.yz + xyz * s.yx + z * s.a,
        };
    }

    test timesVec3 {
        try std.testing.expectEqual(Vec3.x_pos, Rotor3.fromTo(.x_pos, .x_pos).timesVec3(.x_pos));
        try std.testing.expectEqual(Vec3.y_pos, Rotor3.fromTo(.y_pos, .y_pos).timesVec3(.y_pos));
        try std.testing.expectEqual(Vec3.z_pos, Rotor3.fromTo(.z_pos, .z_pos).timesVec3(.z_pos));
    }

    /// Returns the rotor multiplied by other. This lets you compose rotations. Order matters.
    pub fn times(self: Rotor3, other: Rotor3) Rotor3 {
        const result: Rotor3 = .{
            .yz = self.yz * other.a - self.xz * other.yx + self.yx * other.xz + self.a * other.yz,
            .xz = self.yz * other.yx + self.xz * other.a - self.yx * other.yz + self.a * other.xz,
            .yx = -self.yz * other.xz + self.xz * other.yz + self.yx * other.a + self.a * other.yx,
            .a = -self.yz * other.yz - self.xz * other.xz - self.yx * other.yx + self.a * other.a,
        };
        return result.renormalized();
    }

    test times {
        const xy: Rotor3 = .fromTo(.x_pos, .y_pos);
        const yx: Rotor3 = .fromTo(.y_pos, .x_pos);
        const xz: Rotor3 = .fromTo(.x_pos, .z_pos);
        const zx: Rotor3 = .fromTo(.z_pos, .x_pos);
        const yz: Rotor3 = .fromTo(.y_pos, .z_pos);
        const zy: Rotor3 = .fromTo(.z_pos, .y_pos);

        // Identity
        try expectRotor3ApproxEql(Rotor3.identity, xy.times(yx));
        try expectRotor3ApproxEql(Rotor3.identity, yx.times(xy));
        try expectRotor3ApproxEql(Rotor3.identity, xz.times(zx));
        try expectRotor3ApproxEql(Rotor3.identity, zx.times(xz));
        try expectRotor3ApproxEql(Rotor3.identity, yz.times(zy));
        try expectRotor3ApproxEql(Rotor3.identity, zy.times(yz));

        // Two rotations
        try expectVec3ApproxEql(Vec3.y_pos, xz.times(zy).timesVec3(.x_pos));
        try expectVec3ApproxEql(Vec3.z_pos, xy.times(yz).timesVec3(.x_pos));
    }

    /// Multiplies self by other. See `times`.
    pub fn mul(self: *Rotor3, other: Rotor3) void {
        self.* = self.times(other);
    }

    test mul {
        const xy: Rotor3 = .fromTo(.x_pos, .y_pos);
        const yx: Rotor3 = .fromTo(.y_pos, .x_pos);
        const xy_half = xy.nlerp(.identity, 0.5);
        const yx_half = yx.nlerp(.identity, 0.5);

        const xz: Rotor3 = .fromTo(.x_pos, .z_pos);
        const zx: Rotor3 = .fromTo(.z_pos, .x_pos);
        const xz_half = xz.nlerp(.identity, 0.5);
        const zx_half = zx.nlerp(.identity, 0.5);

        const yz: Rotor3 = .fromTo(.x_pos, .z_pos);
        const zy: Rotor3 = .fromTo(.z_pos, .x_pos);
        const yz_half = yz.nlerp(.identity, 0.5);
        const zy_half = zy.nlerp(.identity, 0.5);

        // Canceling out
        try expectRotor3ApproxEql(Rotor3.identity, xy.times(yx));
        try expectRotor3ApproxEql(Rotor3.identity, yx.times(xy));
        try expectRotor3ApproxEql(Rotor3.identity, yx_half.times(xy_half));
        try expectRotor3ApproxEql(Rotor3.identity, xy_half.times(yx_half));

        try expectRotor3ApproxEql(Rotor3.identity, xz.times(zx));
        try expectRotor3ApproxEql(Rotor3.identity, zx.times(xz));
        try expectRotor3ApproxEql(Rotor3.identity, zx_half.times(xz_half));
        try expectRotor3ApproxEql(Rotor3.identity, xz_half.times(zx_half));

        try expectRotor3ApproxEql(Rotor3.identity, yz.times(zy));
        try expectRotor3ApproxEql(Rotor3.identity, zy.times(yz));
        try expectRotor3ApproxEql(Rotor3.identity, zy_half.times(yz_half));
        try expectRotor3ApproxEql(Rotor3.identity, yz_half.times(zy_half));

        // 180 degrees (the sign here is arbitrary for `fromTo` so we manually write out the result)
        try expectRotor3ApproxEql(
            Rotor3{ .yz = 0.0, .xz = 0.0, .yx = 1.0, .a = 0.0 },
            yx.times(yx),
        );
        try expectRotor3ApproxEql(
            Rotor3{ .yz = 0.0, .xz = 0.0, .yx = -1.0, .a = 0.0 },
            xy.times(xy),
        );
        try expectRotor3ApproxEql(
            Rotor3{ .yz = 0.0, .xz = 1.0, .yx = 0.0, .a = 0.0 },
            xz.times(xz),
        );
        try expectRotor3ApproxEql(
            Rotor3{ .yz = 0.0, .xz = -1.0, .yx = 0.0, .a = 0.0 },
            zx.times(zx),
        );
        try expectRotor3ApproxEql(
            Rotor3{ .yz = 0.0, .xz = 1.0, .yx = 0.0, .a = 0.0 },
            yz.times(yz),
        );
        try expectRotor3ApproxEql(
            Rotor3{ .yz = 0.0, .xz = -1.0, .yx = 0.0, .a = 0.0 },
            zy.times(zy),
        );

        // Increments of 45 degrees
        try expectRotor3ApproxEql(xy, xy_half.times(xy_half));
        try expectRotor3ApproxEql(yx, yx_half.times(yx_half));

        try expectRotor3ApproxEql(xz, xz_half.times(xz_half));
        try expectRotor3ApproxEql(zx, zx_half.times(zx_half));

        try expectRotor3ApproxEql(yz, yz_half.times(yz_half));
        try expectRotor3ApproxEql(zy, zy_half.times(zy_half));
    }

    /// Takes the natural log of the given rotor, resulting in a bivector representing the plane the
    /// rotation occurs on with a magnitude of half the angle of rotation in radians. The rotor must
    /// be normalized.
    pub fn ln(self: Rotor3) Bivec3 {
        const bivec: Bivec3 = .{ .yz = self.yz, .xz = self.xz, .yx = self.yx };
        const cos = self.a;
        const sin_sq = bivec.magSq();

        // If sin is 0, cos must be either -1 or 1.
        if (sin_sq == 0.0) {
            if (cos > 0.0) {
                // Cos is ~1, it's a 0 degree rotation.
                return .{ .yz = 0.0, .xz = 0.0, .yx = 0.0 };
            } else {
                // Cos is ~-1, it's a 360 degree rotation around an arbitrary plane.
                return .{ .yz = 0.0, .xz = 0.0, .yx = math.pi };
            }
        }

        // Normalize the bivector by dividing by its current magnitude (sin) and then scale it by
        // the half angle.
        const sin = @sqrt(sin_sq);
        const half = std.math.atan2(sin, cos);
        return bivec.scaled(half / sin);
    }

    test ln {
        const xy: Bivec3 = Vec3.x_pos.outerProd(.y_pos);
        const yx: Bivec3 = Vec3.y_pos.outerProd(.x_pos);

        const xz: Bivec3 = Vec3.x_pos.outerProd(.z_pos);
        const zx: Bivec3 = Vec3.z_pos.outerProd(.x_pos);

        const yz: Bivec3 = Vec3.y_pos.outerProd(.z_pos);
        const zy: Bivec3 = Vec3.z_pos.outerProd(.y_pos);

        // Test 0 degree rotations
        try testLnVsFromPlaneAngle(xy, 0.0);
        try testLnVsFromPlaneAngle(yx, 0.0);

        try testLnVsFromPlaneAngle(xz, 0.0);
        try testLnVsFromPlaneAngle(zx, 0.0);

        try testLnVsFromPlaneAngle(yz, 0.0);
        try testLnVsFromPlaneAngle(zy, 0.0);

        // Test 90 degree rotations
        try testLnVsFromPlaneAngle(xy, math.pi / 2.0);
        try testLnVsFromPlaneAngle(yx, math.pi / 2.0);
        try testLnVsFromPlaneAngle(xy, -math.pi / 2.0);
        try testLnVsFromPlaneAngle(yx, -math.pi / 2.0);

        try testLnVsFromPlaneAngle(xz, math.pi / 2.0);
        try testLnVsFromPlaneAngle(zx, math.pi / 2.0);
        try testLnVsFromPlaneAngle(xz, -math.pi / 2.0);
        try testLnVsFromPlaneAngle(zx, -math.pi / 2.0);

        try testLnVsFromPlaneAngle(yz, math.pi / 2.0);
        try testLnVsFromPlaneAngle(zy, math.pi / 2.0);
        try testLnVsFromPlaneAngle(yz, -math.pi / 2.0);
        try testLnVsFromPlaneAngle(zy, -math.pi / 2.0);

        // Test 180 degree rotations
        try testLnVsFromPlaneAngle(xy, math.pi);
        try testLnVsFromPlaneAngle(yx, math.pi);
        try testLnVsFromPlaneAngle(xy, -math.pi);
        try testLnVsFromPlaneAngle(yx, -math.pi);

        try testLnVsFromPlaneAngle(xz, math.pi);
        try testLnVsFromPlaneAngle(zx, math.pi);
        try testLnVsFromPlaneAngle(xz, -math.pi);
        try testLnVsFromPlaneAngle(zx, -math.pi);

        try testLnVsFromPlaneAngle(yz, math.pi);
        try testLnVsFromPlaneAngle(zy, math.pi);
        try testLnVsFromPlaneAngle(yz, -math.pi);
        try testLnVsFromPlaneAngle(zy, -math.pi);

        // Test 360 degree rotations
        try testLnVsFromPlaneAngle(xy, 2.0 * math.pi);
        try testLnVsFromPlaneAngle(yx, 2.0 * math.pi);
        try testLnVsFromPlaneAngle(xy, -2.0 * math.pi);
        try testLnVsFromPlaneAngle(yx, -2.0 * math.pi);

        try testLnVsFromPlaneAngle(xz, 2.0 * math.pi);
        try testLnVsFromPlaneAngle(zx, 2.0 * math.pi);
        try testLnVsFromPlaneAngle(xz, -2.0 * math.pi);
        try testLnVsFromPlaneAngle(zx, -2.0 * math.pi);

        try testLnVsFromPlaneAngle(yz, 2.0 * math.pi);
        try testLnVsFromPlaneAngle(zy, 2.0 * math.pi);
        try testLnVsFromPlaneAngle(yz, -2.0 * math.pi);
        try testLnVsFromPlaneAngle(zy, -2.0 * math.pi);

        // Test a rotor that wasn't exactly normalized correctly (this used to result in NaN in 2D)
        try std.testing.expectEqual(
            Bivec3{ .yz = 0.0, .xz = 0, .yx = 0 },
            (Rotor3{ .yx = 0.0, .xz = 0, .yz = 0, .a = 1.0000001 }).ln(),
        );
    }

    /// Spherically linearly interpolates between two rotors. See also `nlerp`.
    ///
    /// Interpolates a constant velocity, but is computationally heavy and is not commutative. Not
    /// exact at the beginning/end of ranges. If `t` is outside of the [0, 1] range, the rotation
    /// will continue past the start or end.
    pub fn slerp(start: Rotor3, end: Rotor3, t: f32) Rotor3 {
        var result = start.times(start.inverse().times(end).ln().scaled(t).exp());
        return result.renormalized();
    }

    test slerp {
        try testInterpolation(true, Rotor3.slerp);
    }

    /// Linearly interpolates between the two rotors, then normalizes the result. Prefer this over
    /// `slerp`.
    ///
    /// Interpolation speed is not entirely constant, but it is computationally cheap and
    /// commutative. Behaves well in the [0, 1] range for t, and the velocity remains close to
    /// constant within the 0 to PI/2 range, it gets worse the closer the angle is to 2PI.
    pub fn nlerp(start: Rotor3, end: Rotor3, t: f32) Rotor3 {
        const result: Rotor3 = lerp(start, end, t);
        const res_mag_sq = result.magSq();
        if (res_mag_sq == 0.0) return start;
        // Lerp may push us much further from 1, so we use `invSqrt` instead of `invSqrtNearOne`.
        return result.scaledComps(geom.invSqrt(res_mag_sq));
    }

    test nlerp {
        try testInterpolation(false, Rotor3.nlerp);
    }
};

fn expectVec3ApproxEql(expected: Vec3, actual: Vec3) !void {
    try std.testing.expectApproxEqAbs(expected.x, actual.x, 0.01);
    try std.testing.expectApproxEqAbs(expected.y, actual.y, 0.01);
    try std.testing.expectApproxEqAbs(expected.z, actual.z, 0.01);
}

fn expectRotor3ApproxEql(expected: Rotor3, actual: Rotor3) !void {
    try std.testing.expectApproxEqAbs(expected.yz, actual.yz, 0.01);
    try std.testing.expectApproxEqAbs(expected.xz, actual.xz, 0.01);
    try std.testing.expectApproxEqAbs(expected.yx, actual.yx, 0.01);
    try std.testing.expectApproxEqAbs(expected.a, actual.a, 0.01);
}

fn testLnVsFromPlaneAngle(plane: Bivec3, rad: f32) !void {
    const actual: Bivec3 = Rotor3.fromPlaneAngle(plane, rad).ln();
    const expected: Bivec3 = plane.scaled(rad / 2.0);
    if (@abs(rad) == 2 * std.math.pi) {
        try std.testing.expectApproxEqAbs(std.math.pi, actual.mag(), 0.01);
        var normalized = actual.normalized();
        normalized.yz = @abs(normalized.yz);
        normalized.xz = @abs(normalized.xz);
        normalized.yx = @abs(normalized.yx);
        var plane_abs = plane;
        plane_abs.yz = @abs(plane_abs.yz);
        plane_abs.xz = @abs(plane_abs.xz);
        plane_abs.yx = @abs(plane_abs.yx);
        try std.testing.expectEqual(plane_abs, normalized);
    } else {
        try std.testing.expectEqual(actual, expected);
    }
}

fn testInterpolation(large_angles: bool, interp: *const fn (Rotor3, Rotor3, f32) Rotor3) !void {
    const pi = std.math.pi;

    const r_0: Rotor3 = .identity;
    const r_yx180: Rotor3 = .fromPlaneAngle(.yx_pos, pi);

    const r_xy90: Rotor3 = .fromPlaneAngle(.yx_pos, -pi / 4.0);
    const r_yx90: Rotor3 = .fromPlaneAngle(.yx_pos, pi / 4.0);
    const r_xy270: Rotor3 = .fromPlaneAngle(.yx_pos, -3.0 * pi / 4.0);
    const r_xy45: Rotor3 = .fromPlaneAngle(.yx_pos, -pi / 8.0);

    const r_zx90: Rotor3 = .fromPlaneAngle(.xz_pos, -pi / 4.0);
    const r_xz90: Rotor3 = .fromPlaneAngle(.xz_pos, pi / 4.0);
    const r_zx270: Rotor3 = .fromPlaneAngle(.xz_pos, -3.0 * pi / 4.0);
    const r_zx45: Rotor3 = .fromPlaneAngle(.xz_pos, -pi / 8.0);

    const r_zy90: Rotor3 = .fromPlaneAngle(.yz_pos, -pi / 4.0);
    const r_yz90: Rotor3 = .fromPlaneAngle(.yz_pos, pi / 4.0);
    const r_zy270: Rotor3 = .fromPlaneAngle(.yz_pos, -3.0 * pi / 4.0);
    const r_zy45: Rotor3 = .fromPlaneAngle(.yz_pos, -pi / 8.0);

    // Test interpolating between identical rotors
    try std.testing.expectEqual(r_0, interp(r_0, r_0, 0.0));
    try std.testing.expectEqual(r_0, interp(r_0, r_0, 0.5));
    try std.testing.expectEqual(r_0, interp(r_0, r_0, 1.0));
    try std.testing.expectEqual(r_0, interp(r_0, r_0, 2.0));
    try std.testing.expectEqual(r_0, interp(r_0, r_0, -1.0));

    try std.testing.expectEqual(r_xy90, interp(r_xy90, r_xy90, 0.0));
    try std.testing.expectEqual(r_xy90, interp(r_xy90, r_xy90, 0.5));
    try std.testing.expectEqual(r_xy90, interp(r_xy90, r_xy90, 1.0));

    try std.testing.expectEqual(r_zx90, interp(r_zx90, r_zx90, 0.0));
    try std.testing.expectEqual(r_zx90, interp(r_zx90, r_zx90, 0.5));
    try std.testing.expectEqual(r_zx90, interp(r_zx90, r_zx90, 1.0));

    try std.testing.expectEqual(r_yz90, interp(r_yz90, r_yz90, 0.0));
    try std.testing.expectEqual(r_yz90, interp(r_yz90, r_yz90, 0.5));
    try std.testing.expectEqual(r_yz90, interp(r_yz90, r_yz90, 1.0));

    if (large_angles) {
        // Slerp is not exact here
        try expectRotor3ApproxEql(r_xy90, interp(r_xy90, r_xy90, 2.0));
        try expectRotor3ApproxEql(r_zx90, interp(r_zx90, r_zx90, 2.0));
        try expectRotor3ApproxEql(r_yz90, interp(r_yz90, r_yz90, 2.0));
    } else {
        try std.testing.expectEqual(r_xy90, interp(r_xy90, r_xy90, 2.0));
        try std.testing.expectEqual(r_zx90, interp(r_zx90, r_zx90, 2.0));
        try std.testing.expectEqual(r_yz90, interp(r_yz90, r_yz90, 2.0));
    }
    try std.testing.expectEqual(r_xy90, interp(r_xy90, r_xy90, -1.0));
    try std.testing.expectEqual(r_zx90, interp(r_zx90, r_zx90, -1.0));
    try std.testing.expectEqual(r_yz90, interp(r_yz90, r_yz90, -1.0));

    // Test interpolating between r0 and perpendicular rotors
    try std.testing.expectEqual(r_0, interp(r_0, r_xy90, 0.0));
    try std.testing.expectEqual(r_0, interp(r_0, r_zx90, 0.0));
    try std.testing.expectEqual(r_0, interp(r_0, r_yz90, 0.0));

    try expectRotor3ApproxEql(r_xy45, interp(r_0, r_xy90, 0.5));
    try expectRotor3ApproxEql(r_zx45, interp(r_0, r_zx90, 0.5));
    try expectRotor3ApproxEql(r_zy45, interp(r_0, r_zy90, 0.5));

    try std.testing.expectEqual(r_xy90, interp(r_0, r_xy90, 1.0));
    try std.testing.expectEqual(r_zx90, interp(r_0, r_zx90, 1.0));
    try std.testing.expectEqual(r_zy90, interp(r_0, r_zy90, 1.0));

    if (large_angles) {
        try expectRotor3ApproxEql(r_xy270, interp(r_0, r_xy90, 3.0));
        try expectRotor3ApproxEql(r_zx270, interp(r_0, r_zx90, 3.0));
        try expectRotor3ApproxEql(r_zy270, interp(r_0, r_zy90, 3.0));

        try std.testing.expectEqual(r_yx90, interp(r_0, r_xy90, -1.0));
        try std.testing.expectEqual(r_xz90, interp(r_0, r_zx90, -1.0));
        try std.testing.expectEqual(r_yz90, interp(r_0, r_zy90, -1.0));
    }

    if (large_angles) {
        // Slerp is not exact here
        try expectRotor3ApproxEql(r_0, interp(r_xy90, r_0, 1.0));
        try expectRotor3ApproxEql(r_0, interp(r_xz90, r_0, 1.0));
        try expectRotor3ApproxEql(r_0, interp(r_zy90, r_0, 1.0));
    } else {
        try std.testing.expectEqual(r_0, interp(r_xy90, r_0, 1.0));
        try std.testing.expectEqual(r_0, interp(r_xz90, r_0, 1.0));
        try std.testing.expectEqual(r_0, interp(r_zy90, r_0, 1.0));
    }

    try expectRotor3ApproxEql(r_xy45, interp(r_xy90, r_0, 0.5));
    try expectRotor3ApproxEql(r_zx45, interp(r_zx90, r_0, 0.5));
    try expectRotor3ApproxEql(r_zy45, interp(r_zy90, r_0, 0.5));

    try std.testing.expectEqual(r_xy90, interp(r_xy90, r_0, 0.0));
    try std.testing.expectEqual(r_xz90, interp(r_xz90, r_0, 0.0));
    try std.testing.expectEqual(r_zy90, interp(r_zy90, r_0, 0.0));

    if (large_angles) {
        try expectRotor3ApproxEql(r_yx90, interp(r_xy90, r_0, 2.0));
        try expectRotor3ApproxEql(r_zx90, interp(r_xz90, r_0, 2.0));
        try expectRotor3ApproxEql(r_zy90, interp(r_yz90, r_0, 2.0));

        try expectRotor3ApproxEql(r_xy270, interp(r_xy90, r_0, -2.0));
        try expectRotor3ApproxEql(r_zx270, interp(r_zx90, r_0, -2.0));
        try expectRotor3ApproxEql(r_zy270, interp(r_zy90, r_0, -2.0));
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
            try expectRotor3ApproxEql(end, interp(start, end, 1.0));
        } else {
            // Nlerp is exact here unlike slerp
            try std.testing.expectEqual(end, interp(start, end, 1.0));

            // This is geometrically incorrect, but the result we expect out of nlerp for this
            // angle.
            try std.testing.expectEqual(start, interp(start, end, 0.5));
        }
    }
}
