const std = @import("std");
const geom = @import("root.zig");

const assert = std.debug.assert;

const Vec3 = geom.Vec3;

/// Linear interpolation, exact results at `0` and `1`.
///
/// Supports floats, vectors of floats, and structs or arrays that only contain other supported
/// types.
pub fn lerp(start: anytype, end: anytype, t: anytype) @TypeOf(start, end) {
    comptime assert(@typeInfo(@TypeOf(t)) == .float or @typeInfo(@TypeOf(t)) == .comptime_float);
    const Type = @TypeOf(start, end);
    switch (@typeInfo(Type)) {
        .float, .comptime_float => return @mulAdd(Type, start, 1.0 - t, end * t),
        .vector => return @mulAdd(Type, start, @splat(1.0 - t), end * @as(Type, @splat(t))),
        .@"struct" => |info| {
            var result: Type = undefined;
            inline for (info.fields) |field| {
                @field(result, field.name) = lerp(
                    @field(start, field.name),
                    @field(end, field.name),
                    t,
                );
            }
            return result;
        },
        .array => {
            var result: Type = undefined;
            for (&result, start, end) |*dest, a, b| {
                dest.* = lerp(a, b, t);
            }
            return result;
        },
        else => comptime unreachable,
    }
}

test lerp {
    // Floats
    {
        try std.testing.expectEqual(100.0, lerp(100.0, 200.0, 0.0));
        try std.testing.expectEqual(200.0, lerp(100.0, 200.0, 1.0));
        try std.testing.expectEqual(150.0, lerp(100.0, 200.0, 0.5));
    }

    // Vectors
    {
        const a: @Vector(3, f32) = .{ 0.0, 50.0, 100.0 };
        const b: @Vector(3, f32) = .{ 100.0, 0.0, 200.0 };
        try std.testing.expectEqual(@Vector(3, f32){ 0.0, 50.0, 100.0 }, lerp(a, b, 0.0));
        try std.testing.expectEqual(@Vector(3, f32){ 50.0, 25.0, 150.0 }, lerp(a, b, 0.5));
        try std.testing.expectEqual(@Vector(3, f32){ 100.0, 0.0, 200.0 }, lerp(a, b, 1.0));
    }

    // Structs
    {
        const a: Vec3 = .{ .x = 0.0, .y = 50.0, .z = 100.0 };
        const b: Vec3 = .{ .x = 100.0, .y = 0.0, .z = 200.0 };
        try std.testing.expectEqual(Vec3{ .x = 0.0, .y = 50.0, .z = 100.0 }, lerp(a, b, 0.0));
        try std.testing.expectEqual(Vec3{ .x = 50.0, .y = 25.0, .z = 150.0 }, lerp(a, b, 0.5));
        try std.testing.expectEqual(Vec3{ .x = 100.0, .y = 0.0, .z = 200.0 }, lerp(a, b, 1.0));
    }

    // Array
    {
        const a: [3]f32 = .{ 0.0, 50.0, 100.0 };
        const b: [3]f32 = .{ 100.0, 0.0, 200.0 };
        try std.testing.expectEqual([3]f32{ 0.0, 50.0, 100.0 }, lerp(a, b, 0.0));
        try std.testing.expectEqual([3]f32{ 50.0, 25.0, 150.0 }, lerp(a, b, 0.5));
        try std.testing.expectEqual([3]f32{ 100.0, 0.0, 200.0 }, lerp(a, b, 1.0));
    }
}

/// Inverse linear interpolation, gives exact results at 0 and 1.
///
/// Only supports floats.
pub fn ilerp(start: anytype, end: anytype, val: anytype) @TypeOf(start, end, val) {
    const Type = @TypeOf(start, end, val);
    comptime assert(@typeInfo(Type) == .float or @typeInfo(Type) == .comptime_float);
    return (val - start) / (end - start);
}

test ilerp {
    try std.testing.expectEqual(0.0, ilerp(50.0, 100.0, 50.0));
    try std.testing.expectEqual(1.0, ilerp(50.0, 100.0, 100.0));
    try std.testing.expectEqual(0.5, ilerp(50.0, 100.0, 75.0));
}

/// Clamps a value between 0 and 1.
pub fn clamp01(val: anytype) @TypeOf(val) {
    return @max(0.0, @min(1.0, val));
}

test clamp01 {
    try std.testing.expectEqual(0.0, clamp01(-1.0));
    try std.testing.expectEqual(1.0, clamp01(10.0));
    try std.testing.expectEqual(0.5, clamp01(0.5));
}

/// Remaps a value from the start range into the end range.
///
/// Only supports floats.
pub fn remap(
    in_start: anytype,
    in_end: anytype,
    out_start: anytype,
    out_end: anytype,
    val: anytype,
) @TypeOf(in_start, in_end, out_start, out_end, val) {
    const t = ilerp(in_start, in_end, val);
    return lerp(out_start, out_end, t);
}

test remap {
    try std.testing.expectEqual(50.0, remap(10.0, 20.0, 50.0, 100.0, 10.0));
    try std.testing.expectEqual(100.0, remap(10.0, 20.0, 50.0, 100.0, 20.0));
    try std.testing.expectEqual(75.0, remap(10.0, 20.0, 50.0, 100.0, 15.0));
}
