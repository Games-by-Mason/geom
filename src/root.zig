//! Geometry for game dev.

const std = @import("std");
const builtin = @import("builtin");

pub const Vec2 = @import("vec2.zig").Vec2;
pub const Vec3 = @import("vec3.zig").Vec3;
pub const Bivec2 = @import("bivec2.zig").Bivec2;
pub const Rotor2 = @import("rotor2.zig").Rotor2;
pub const Mat2x3 = @import("mat2x3.zig").Mat2x3;

// Check for FMA support on common targets. Lack of FMA support is almost certainly a configuration
// error, we don't want to end up emulating it in software by mistake.
comptime {
    const assert = std.debug.assert;
    const cpu = builtin.cpu;

    if (cpu.arch.isX86()) {
        assert(std.Target.x86.featureSetHas(cpu.features, .fma));
    } else if (cpu.arch.isArm()) {
        assert(std.Target.arm.featureSetHasAny(cpu.features, .{ .neon, .vfp4 }));
    } else if (cpu.arch.isAARCH64()) {
        assert(std.Target.aarch64.featureSetHas(cpu.features, .neon));
    }
}

test {
    std.testing.refAllDecls(@This());
}
