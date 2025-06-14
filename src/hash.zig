//! Mirrors of the hash and and hash based rand functions provided by GBMS, see GBMS for
//! documentation, origins, recommended usage, etc:
//!
//! https://github.com/Games-by-Mason/gbms/
//!
//! Definitely not cryptographically secure. Probably not good in hash maps either. Tuned for
//! graphics, prefer the Zig standard library for all other hash needs.

const std = @import("std");
const geom = @import("root.zig");

const Vec2 = geom.Vec2;
const Vec3 = geom.Vec3;
const Vec4 = geom.Vec4;

// Multiplying by the reciprocal produces exact results for all f32s that represent whole numbers
// that would fit in a u32.
const u32_max_recip = 1.0 / @as(f32, @floatFromInt(std.math.maxInt(u32)));

fn pcg(s: u32) u32 {
    const state: u32 = s *% 747796405 +% 2891336453;
    const word: u32 = ((state >> @intCast((state >> 28) +% 4)) ^ state) *% 277803737;
    return (word >> 22) ^ word;
}

test pcg {
    // Check single value
    try std.testing.expectEqual(129708002, pcg(0));

    // Run it a few times to check for overflow
    var result: u32 = 0;
    for (0..1000) |_| {
        result = pcg(result);
    }
}

fn pcg2d(s: @Vector(2, u32)) @Vector(2, u32) {
    var r = s;
    r = r *% @as(@Vector(2, u32), @splat(1664525)) +% @as(@Vector(2, u32), @splat(1013904223));
    r[0] +%= r[1] *% 1664525;
    r[1] +%= r[0] *% 1664525;
    r = r ^ (r >> @splat(16));
    r[0] +%= r[1] *% 1664525;
    r[1] +%= r[0] *% 1664525;
    r = r ^ (r >> @splat(16));
    return r;
}

test pcg2d {
    // Check single value
    try std.testing.expectEqual(
        .{ 2313183303, 4026777116 },
        pcg2d(.{ 0, 1 }),
    );

    // Run it a few times to check for overflow
    var result: @Vector(2, u32) = @splat(0);
    for (0..1000) |_| {
        result = pcg2d(result);
    }
}

fn pcg3d(s: @Vector(3, u32)) @Vector(3, u32) {
    var r = s;
    r = r *% @as(@Vector(3, u32), @splat(1664525)) +% @as(@Vector(3, u32), @splat(1013904223));
    r[0] +%= r[1] *% r[2];
    r[1] +%= r[2] *% r[0];
    r[2] +%= r[0] *% r[1];
    r ^= r >> @splat(16);
    r[0] +%= r[1] *% r[2];
    r[1] +%= r[2] *% r[0];
    r[2] +%= r[0] *% r[1];
    return r;
}

test pcg3d {
    // Check single value
    try std.testing.expectEqual(
        .{ 3409911753, 1806500465, 2000842263 },
        pcg3d(.{ 0, 1, 2 }),
    );

    // Run it a few times to check for overflow
    var result: @Vector(3, u32) = @splat(0);
    for (0..1000) |_| {
        result = pcg3d(result);
    }
}

fn pcg4d(s: @Vector(4, u32)) @Vector(4, u32) {
    var r = s;
    r = r *% @as(@Vector(4, u32), @splat(1664525)) +% @as(@Vector(4, u32), @splat(1013904223));
    r[0] +%= r[1] *% r[3];
    r[1] +%= r[2] *% r[0];
    r[2] +%= r[0] *% r[1];
    r[3] +%= r[1] *% r[2];
    r ^= r >> @splat(16);
    r[0] +%= r[1] *% r[3];
    r[1] +%= r[2] *% r[0];
    r[2] +%= r[0] *% r[1];
    r[3] +%= r[1] *% r[2];
    return r;
}

test pcg4d {
    // Check single value
    try std.testing.expectEqual(
        .{ 933639991, 2252496459, 1324331964, 1990701187 },
        pcg4d(.{ 0, 1, 2, 3 }),
    );

    // Run it a few times to check for overflow
    var result: @Vector(4, u32) = @splat(0);
    for (0..1000) |_| {
        result = pcg4d(result);
    }
}

fn default(s: u32) u32 {
    return pcg(s);
}

test default {
    // Make sure it compiles
    _ = default(0);
}

fn default2D(s: @Vector(2, u32)) @Vector(2, u32) {
    return pcg2d(s);
}

test default2D {
    // Make sure it compiles
    _ = default2D(.{ 0, 1 });
}

fn default3D(s: @Vector(3, u32)) @Vector(3, u32) {
    return pcg3d(s);
}

test default3D {
    // Make sure it compiles
    _ = default3D(.{ 0, 1, 2 });
}

fn default4D(s: @Vector(4, u32)) @Vector(4, u32) {
    return pcg4d(s);
}

test default4D {
    // Make sure it compiles
    _ = default4D(.{ 0, 1, 2, 3 });
}

fn rand(s: anytype) f32 {
    switch (@TypeOf(s)) {
        u32 => {
            const all: f32 = @floatFromInt(default(s));
            return all / std.math.maxInt(u32);
        },
        @Vector(2, u32) => {
            const all: @Vector(2, f32) = @floatFromInt(default2D(s));
            return all[0] / std.math.maxInt(u32);
        },
        @Vector(3, u32) => {
            const all: @Vector(3, f32) = @floatFromInt(default3D(s));
            return all[0] / std.math.maxInt(u32);
        },
        @Vector(4, u32) => {
            const all: @Vector(4, f32) = @floatFromInt(default4D(s));
            return all[0] / std.math.maxInt(u32);
        },
        f32 => return rand(@as(u32, @bitCast(s))),
        Vec2 => return rand(@Vector(2, u32){
            @bitCast(s.x),
            @bitCast(s.y),
        }),
        Vec3 => return rand(@Vector(3, u32){
            @bitCast(s.x),
            @bitCast(s.y),
            @bitCast(s.z),
        }),
        Vec4 => return rand(@Vector(4, u32){
            @bitCast(s.x),
            @bitCast(s.y),
            @bitCast(s.z),
            @bitCast(s.w),
        }),
        else => comptime unreachable,
    }
}

test rand {
    // Make sure it compiles for each type
    try std.testing.expectEqual(6.591631e-1, rand(@as(u32, 1)));
    try std.testing.expectEqual(1.0669651e-2, rand(@Vector(2, u32){ 1, 2 }));
    try std.testing.expectEqual(9.789959e-1, rand(@Vector(3, u32){ 1, 2, 3 }));
    try std.testing.expectEqual(2.1146852e-1, rand(@Vector(4, u32){ 1, 2, 3, 4 }));
    try std.testing.expectEqual(9.4426405e-1, rand(@as(f32, 1)));
    try std.testing.expectEqual(3.514351e-1, rand(Vec2{ .x = 1, .y = 2 }));
    try std.testing.expectEqual(6.142317e-1, rand(Vec3{ .x = 1, .y = 2, .z = 3 }));
    try std.testing.expectEqual(9.8791474e-1, rand(Vec4{ .x = 1, .y = 2, .z = 3, .w = 4 }));
}

fn rand2(s: anytype) Vec2 {
    switch (@TypeOf(s)) {
        u32 => {
            const all = default2D(.{ s, 1 });
            return (Vec2{
                .x = @floatFromInt(all[0]),
                .y = @floatFromInt(all[1]),
            }).scaled(u32_max_recip);
        },
        @Vector(2, u32) => {
            const all = default2D(s);
            return (Vec2{
                .x = @floatFromInt(all[0]),
                .y = @floatFromInt(all[1]),
            }).scaled(u32_max_recip);
        },
        @Vector(3, u32) => {
            const all = default3D(s);
            return (Vec2{
                .x = @floatFromInt(all[0]),
                .y = @floatFromInt(all[1]),
            }).scaled(u32_max_recip);
        },
        @Vector(4, u32) => {
            const all = default4D(s);
            return (Vec2{
                .x = @floatFromInt(all[0]),
                .y = @floatFromInt(all[1]),
            }).scaled(u32_max_recip);
        },
        f32 => return rand2(@as(u32, @bitCast(s))),
        Vec2 => return rand2(@Vector(2, u32){ @bitCast(s.x), @bitCast(s.y) }),
        Vec3 => return rand2(@Vector(3, u32){ @bitCast(s.x), @bitCast(s.y), @bitCast(s.z) }),
        Vec4 => return rand2(@Vector(4, u32){ @bitCast(s.x), @bitCast(s.y), @bitCast(s.z), @bitCast(s.w) }),
        else => comptime unreachable,
    }
}

test rand2 {
    // Make sure it compiles for each type
    try std.testing.expectEqual(
        Vec2{ .x = 3.076969e-1, .y = 9.435365e-1 },
        rand2(@as(u32, 1)),
    );
    try std.testing.expectEqual(
        Vec2{ .x = 1.0669651e-2, .y = 4.9842097e-2 },
        rand2(@Vector(2, u32){ 1, 2 }),
    );
    try std.testing.expectEqual(
        Vec2{ .x = 9.789959e-1, .y = 2.849572e-1 },
        rand2(@Vector(3, u32){ 1, 2, 3 }),
    );
    try std.testing.expectEqual(
        Vec2{ .x = 2.1146852e-1, .y = 9.417182e-1 },
        rand2(@Vector(4, u32){ 1, 2, 3, 4 }),
    );
    try std.testing.expectEqual(
        Vec2{ .x = 9.4483894e-1, .y = 6.1725557e-1 },
        rand2(@as(f32, 1)),
    );
    try std.testing.expectEqual(
        Vec2{ .x = 3.514351e-1, .y = 5.474391e-1 },
        rand2(Vec2{ .x = 1, .y = 2 }),
    );
    try std.testing.expectEqual(
        Vec2{ .x = 6.142317e-1, .y = 5.6874275e-1 },
        rand2(Vec3{ .x = 1, .y = 2, .z = 3 }),
    );
    try std.testing.expectEqual(
        Vec2{ .x = 9.8791474e-1, .y = 4.3170738e-1 },
        rand2(Vec4{ .x = 1, .y = 2, .z = 3, .w = 4 }),
    );
}

fn rand3(s: anytype) Vec3 {
    switch (@TypeOf(s)) {
        u32 => {
            const all = default3D(.{ s, 1, 1 });
            return (Vec3{
                .x = @floatFromInt(all[0]),
                .y = @floatFromInt(all[1]),
                .z = @floatFromInt(all[2]),
            }).scaled(u32_max_recip);
        },
        @Vector(2, u32) => {
            const all = default3D(.{ s[0], s[1], 1 });
            return (Vec3{
                .x = @floatFromInt(all[0]),
                .y = @floatFromInt(all[1]),
                .z = @floatFromInt(all[2]),
            }).scaled(u32_max_recip);
        },
        @Vector(3, u32) => {
            const all = default3D(s);
            return (Vec3{
                .x = @floatFromInt(all[0]),
                .y = @floatFromInt(all[1]),
                .z = @floatFromInt(all[2]),
            }).scaled(u32_max_recip);
        },
        @Vector(4, u32) => {
            const all = default4D(s);
            return (Vec3{
                .x = @floatFromInt(all[0]),
                .y = @floatFromInt(all[1]),
                .z = @floatFromInt(all[2]),
            }).scaled(u32_max_recip);
        },
        f32 => return rand3(@as(u32, @bitCast(s))),
        Vec2 => return rand3(@Vector(2, u32){
            @bitCast(s.x),
            @bitCast(s.y),
        }),
        Vec3 => return rand3(@Vector(3, u32){
            @bitCast(s.x),
            @bitCast(s.y),
            @bitCast(s.z),
        }),
        Vec4 => return rand3(@Vector(4, u32){
            @bitCast(s.x),
            @bitCast(s.y),
            @bitCast(s.z),
            @bitCast(s.w),
        }),
        else => comptime unreachable,
    }
}

test rand3 {
    // Make sure it compiles for each type
    try std.testing.expectEqual(
        Vec3{ .x = 8.722949e-1, .y = 5.462977e-1, .z = 3.7529972e-1 },
        rand3(@as(u32, 1)),
    );
    try std.testing.expectEqual(
        Vec3{ .x = 1.5867977e-1, .y = 4.5829082e-1, .z = 8.812844e-1 },
        rand3(@Vector(2, u32){ 1, 2 }),
    );
    try std.testing.expectEqual(
        Vec3{ .x = 9.789959e-1, .y = 2.849572e-1, .z = 3.4935537e-1 },
        rand3(@Vector(3, u32){ 1, 2, 3 }),
    );
    try std.testing.expectEqual(
        Vec3{ .x = 2.1146852e-1, .y = 9.417182e-1, .z = 8.791596e-1 },
        rand3(@Vector(4, u32){ 1, 2, 3, 4 }),
    );
    try std.testing.expectEqual(
        Vec3{ .x = 9.415978e-1, .y = 3.22427e-1, .z = 7.810834e-1 },
        rand3(@as(f32, 1)),
    );
    try std.testing.expectEqual(
        Vec3{ .x = 7.593601e-1, .y = 5.267169e-1, .z = 8.9228565e-1 },
        rand3(Vec2{ .x = 1, .y = 2 }),
    );
    try std.testing.expectEqual(
        Vec3{ .x = 6.142317e-1, .y = 5.6874275e-1, .z = 1.813631e-1 },
        rand3(Vec3{ .x = 1, .y = 2, .z = 3 }),
    );
    try std.testing.expectEqual(
        Vec3{ .x = 9.8791474e-1, .y = 4.3170738e-1, .z = 6.5100867e-1 },
        rand3(Vec4{ .x = 1, .y = 2, .z = 3, .w = 4 }),
    );
}

fn rand4(s: anytype) Vec4 {
    switch (@TypeOf(s)) {
        u32 => {
            const all = default4D(.{ s, 1, 1, 1 });
            return (Vec4{
                .x = @floatFromInt(all[0]),
                .y = @floatFromInt(all[1]),
                .z = @floatFromInt(all[2]),
                .w = @floatFromInt(all[3]),
            }).scaled(u32_max_recip);
        },
        @Vector(2, u32) => {
            const all = default4D(.{ s[0], s[1], 1, 1 });
            return (Vec4{
                .x = @floatFromInt(all[0]),
                .y = @floatFromInt(all[1]),
                .z = @floatFromInt(all[2]),
                .w = @floatFromInt(all[3]),
            }).scaled(u32_max_recip);
        },
        @Vector(3, u32) => {
            const all = default4D(.{ s[0], s[1], s[2], 1 });
            return (Vec4{
                .x = @floatFromInt(all[0]),
                .y = @floatFromInt(all[1]),
                .z = @floatFromInt(all[2]),
                .w = @floatFromInt(all[3]),
            }).scaled(u32_max_recip);
        },
        @Vector(4, u32) => {
            const all = default4D(s);
            return (Vec4{
                .x = @floatFromInt(all[0]),
                .y = @floatFromInt(all[1]),
                .z = @floatFromInt(all[2]),
                .w = @floatFromInt(all[3]),
            }).scaled(u32_max_recip);
        },
        f32 => return rand4(@as(u32, @bitCast(s))),
        Vec2 => return rand4(@Vector(2, u32){
            @bitCast(s.x),
            @bitCast(s.y),
        }),
        Vec3 => return rand4(@Vector(3, u32){
            @bitCast(s.x),
            @bitCast(s.y),
            @bitCast(s.z),
        }),
        Vec4 => return rand4(@Vector(4, u32){
            @bitCast(s.x),
            @bitCast(s.y),
            @bitCast(s.z),
            @bitCast(s.w),
        }),
        else => comptime unreachable,
    }
}

test rand4 {
    // Make sure it compiles for each type
    try std.testing.expectEqual(
        Vec4{ .x = 6.947346e-1, .y = 4.1038275e-1, .z = 9.989965e-1, .w = 1.7831983e-1 },
        rand4(@as(u32, 1)),
    );
    try std.testing.expectEqual(
        Vec4{ .x = 3.3835035e-2, .y = 2.1328963e-1, .z = 9.1972396e-2, .w = 4.4690752e-1 },
        rand4(@Vector(2, u32){ 1, 2 }),
    );
    try std.testing.expectEqual(
        Vec4{ .x = 2.0368083e-1, .y = 8.241063e-1, .z = 1.1822319e-1, .w = 1.2990429e-2 },
        rand4(@Vector(3, u32){ 1, 2, 3 }),
    );
    try std.testing.expectEqual(
        Vec4{ .x = 2.1146852e-1, .y = 9.417182e-1, .z = 8.791596e-1, .w = 1.0639917e-2 },
        rand4(@Vector(4, u32){ 1, 2, 3, 4 }),
    );
    try std.testing.expectEqual(
        Vec4{ .x = 2.6033977e-1, .y = 1.3925232e-1, .z = 2.4095826e-2, .w = 2.6369214e-2 },
        rand4(@as(f32, 1)),
    );
    try std.testing.expectEqual(
        Vec4{ .x = 5.175956e-1, .y = 4.7401184e-1, .z = 2.0530142e-1, .w = 9.6941704e-1 },
        rand4(Vec2{ .x = 1, .y = 2 }),
    );
    try std.testing.expectEqual(
        Vec4{ .x = 8.658684e-1, .y = 4.7979563e-1, .z = 1.226957e-1, .w = 6.556808e-1 },
        rand4(Vec3{ .x = 1, .y = 2, .z = 3 }),
    );
    try std.testing.expectEqual(
        Vec4{ .x = 9.8791474e-1, .y = 4.3170738e-1, .z = 6.5100867e-1, .w = 4.631154e-1 },
        rand4(Vec4{ .x = 1, .y = 2, .z = 3, .w = 4 }),
    );
}
