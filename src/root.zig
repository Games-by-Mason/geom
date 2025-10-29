//! Geometry for game dev.

const std = @import("std");
const builtin = @import("builtin");

pub const Vec2 = @import("vec2.zig").Vec2;
pub const Vec3 = @import("vec3.zig").Vec3;
pub const Vec4 = @import("vec4.zig").Vec4;
pub const Bivec2 = @import("bivec2.zig").Bivec2;
pub const Bivec3 = @import("bivec3.zig").Bivec3;
pub const Rotor2 = @import("rotor2.zig").Rotor2;
pub const Rotor3 = @import("rotor3.zig").Rotor3;
pub const Mat2x3 = @import("mat2x3.zig").Mat2x3;
pub const Mat3x4 = @import("mat3x4.zig").Mat3x4;
pub const Frustum2 = @import("frustum2.zig").Frustum2;
pub const Frustum3 = @import("frustum3.zig").Frustum3;

pub const constants = @import("constants.zig");
pub const hash = @import("hash.zig");
pub const noise = @import("noise.zig");

pub const tween = @import("tween");

/// Very fast approximate inverse square root that only produces usable results when `f` is near 1.
///
/// Will eventually converge for values in the range `(0, 0.5 * (sqrt(17) - 1))`, or
/// `(0, ~1.5615528128088303)`.
///
/// Explanation: https://gamesbymason.com/devlog/2025/#Fast-Quaternion-Normalization
/// Proof: https://gamesbymason.com/devlog/2025/#Fast-Quaternion-Normalization-Proof
pub fn invSqrtNearOne(f: anytype) @TypeOf(f) {
    return @mulAdd(@TypeOf(f), f, -0.5, 1.5);
}

/// Fast approximate inverse square root using a dedicated hardware instruction when available.
///
/// Explanation: https://gamesbymason.com/devlog/2025/#Fast-Quaternion-Normalization
pub fn invSqrt(f: anytype) @TypeOf(f) {
    // If we're positive infinity, just return infinity
    if (std.math.isPositiveInf(f)) return f;

    // If we're NaN or negative infinity, return NaN
    if (std.math.isNan(f) or
        std.math.isNegativeInf(f) or
        f == 0.0)
    {
        return std.math.nan(f32);
    }

    // Now that we've ruled out values that would cause issues in optimized float mode, enable it
    // and calculate the inverse square root. This generates a hardware instruction approximating
    // the inverse square root on platforms that have one, and is therefore significantly faster.
    //
    // Note that this may also generate a refine step that we may or may not need, to avoid this
    // we'd need to give up portability by implementing this per architecture.
    {
        @setFloatMode(.optimized);
        return 1.0 / @sqrt(f);
    }
}

test {
    std.testing.refAllDecls(@This());
}
