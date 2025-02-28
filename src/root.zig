//! Geometry for game dev.

const std = @import("std");
const builtin = @import("builtin");

pub const Vec2 = @import("vec2.zig").Vec2;
pub const Vec3 = @import("vec3.zig").Vec3;
pub const Bivec2 = @import("bivec2.zig").Bivec2;
pub const Rotor2 = @import("rotor2.zig").Rotor2;
pub const Mat2x3 = @import("mat2x3.zig").Mat2x3;

pub const tween = @import("tween");

/// Very fast approximate inverse square root that only produces usable results when `f` is near 1.
pub fn invSqrtNearOne(f: anytype) @TypeOf(f) {
    return @mulAdd(@TypeOf(f), f, -0.5, 1.5);
}

/// Fast approximate inverse square root using a dedicated hardware instruction when available.
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
    {
        @setFloatMode(.optimized);
        return 1.0 / @sqrt(f);
    }
}

// Check for important features on common targets. If these aren't enabled, it's almost certainly a
// configuration mistake. We don't want to end up generating worse code or emulating FMA in software
// by mistake.
comptime {
    const assert = std.debug.assert;
    const cpu = builtin.cpu;

    if (cpu.arch.isX86()) {
        assert(std.Target.x86.featureSetHasAll(cpu.features, .{ .fma, .sse3 }));
    } else if (cpu.arch.isArm()) {
        assert(std.Target.arm.featureSetHasAny(cpu.features, .{ .neon, .vfp4 }));
    } else if (cpu.arch.isAARCH64()) {
        assert(std.Target.aarch64.featureSetHas(cpu.features, .neon));
    }
}

test {
    std.testing.refAllDecls(@This());
}
