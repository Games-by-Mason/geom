//! Geometry for game dev.

const std = @import("std");

pub const Vec2 = @import("vec2.zig").Vec2;
pub const Bivec2 = @import("bivec2.zig").Bivec2;
pub const Rotor2 = @import("rotor2.zig").Rotor2;
pub const Mat2x3 = @import("mat2x3.zig").Mat2x3;

test {
    std.testing.refAllDecls(@This());
}
