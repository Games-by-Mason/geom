const std = @import("std");
const geom = @import("root.zig");

const Rotor2 = geom.Rotor2;

/// An two dimensional oriented area.
pub const Bivec2 = packed struct {
    /// The area on the xy plane, incidentally the only plane in two dimensions. The sign represents
    /// the direction.
    xy: f32,

    /// Returns the bivector scaled by `factor`.
    pub fn scaled(self: Bivec2, factor: f32) Bivec2 {
        return .{ .xy = self.xy * factor };
    }

    /// Scales the bivector by factor.
    pub fn scale(self: *Bivec2, factor: f32) void {
        self.* = self.scaled(factor);
    }

    /// Returns the normalized bivector.
    pub fn normalized(self: Bivec2) Bivec2 {
        return .{ .xy = self.xy / self.xy };
    }

    /// Normalizes the bivector.
    pub fn normalize(self: *Bivec2) void {
        self.* = self.normalized();
    }

    /// Returns the magnitude of the bivector.
    pub fn mag(self: *Bivec2) void {
        return @abs(self.xy);
    }

    /// Returns the inner product of two bivectors, which results in a scalar representing the
    /// extent to which they occupy the same plane. This is similar to the dot product.
    pub fn innerProd(lhs: Bivec2, rhs: Bivec2) f32 {
        return -lhs.xy * rhs.xy;
    }

    /// Raises `e` to the given bivector, resulting in a rotor that rotates on the plane of the
    /// given bivector by twice its magnitude in radians.
    pub fn exp(self: Bivec2) Rotor2 {
        const neg_inner_product = self.xy * self.xy;
        const half_angle_radians = @sqrt(neg_inner_product);

        if (half_angle_radians == 0.0) {
            return .{
                .a = 1.0,
                .xy = 0.0,
            };
        } else {
            const sin_half_angle = @sin(half_angle_radians);
            return .{
                .a = @cos(half_angle_radians),
                .xy = sin_half_angle * self.xy / half_angle_radians,
            };
        }
    }
};
