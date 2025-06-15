//! Mirrors of hash based noise functions provided by GBMS, see GBMS for documentation, origins,
//! recommended usage, etc:
//!
//! https://github.com/Games-by-Mason/gbms/
//!
//! These are unrolled because that matches the GLSL and makes it easier to keep the implementations
//! in sync.

const std = @import("std");
const tween = @import("tween");
const geom = @import("root.zig");

const rand = geom.hash.rand;
const lerp = tween.interp.lerp;
const smootherstep = tween.ease.smootherstep;
const f32_max_consec = geom.constants.f32_max_consec;

const Vec2 = geom.Vec2;
const Vec3 = geom.Vec3;
const Vec4 = geom.Vec4;

pub fn valuePeriodic(p: anytype, period: @TypeOf(p)) f32 {
    switch (@TypeOf(p)) {
        f32 => {
            // Get the t value
            const cell = @floor(p);
            const t = p - cell;

            // Get the sample coordinates
            const c0 = @mod(cell + 0.0, period);
            const c1 = @mod(cell + 1.0, period);

            // Get the sample values, integer seed for better hash since it's a whole number
            const s0 = rand(@as(u32, @intFromFloat(c0)));
            const s1 = rand(@as(u32, @intFromFloat(c1)));

            // Perform linear interpolation with a smootherstep factor
            return lerp(s0, s1, smootherstep(t));
        },
        Vec2 => {
            // Calculate the t value
            const cell = p.floored();
            const t = p.minus(cell);

            // Get the sample coordinates
            const c00 = cell.modded(period);
            const c10 = cell.plus(.{ .x = 1, .y = 0 }).modded(period);
            const c01 = cell.plus(.{ .x = 0, .y = 1 }).modded(period);
            const c11 = cell.plus(.{ .x = 1, .y = 1 }).modded(period);

            // Get the sample values, integer seed for better hash since it's a whole number
            const s00 = rand(@Vector(2, u32){ @intFromFloat(c00.x), @intFromFloat(c00.y) });
            const s10 = rand(@Vector(2, u32){ @intFromFloat(c10.x), @intFromFloat(c10.y) });
            const s01 = rand(@Vector(2, u32){ @intFromFloat(c01.x), @intFromFloat(c01.y) });
            const s11 = rand(@Vector(2, u32){ @intFromFloat(c11.x), @intFromFloat(c11.y) });

            // Perform bilinear interpolation with a smootherstep factor
            const tx = smootherstep(t.x);
            const ty = smootherstep(t.y);
            const l0 = lerp(s00, s01, ty);
            const l1 = lerp(s10, s11, ty);
            const l = lerp(l0, l1, tx);

            // Return the result
            return l;
        },
        Vec3 => {
            // Get the t value
            const cell = p.floored();
            const t = p.minus(cell);

            // Get the sample coordinates
            const c000 = cell.modded(period);
            const c100 = cell.plus(.{ .x = 1, .y = 0, .z = 0 }).modded(period);
            const c010 = cell.plus(.{ .x = 0, .y = 1, .z = 0 }).modded(period);
            const c110 = cell.plus(.{ .x = 1, .y = 1, .z = 0 }).modded(period);
            const c001 = cell.plus(.{ .x = 0, .y = 0, .z = 1 }).modded(period);
            const c101 = cell.plus(.{ .x = 1, .y = 0, .z = 1 }).modded(period);
            const c011 = cell.plus(.{ .x = 0, .y = 1, .z = 1 }).modded(period);
            const c111 = cell.plus(.{ .x = 1, .y = 1, .z = 1 }).modded(period);

            // Get the sample values, integer seed for better hash since it's a whole number
            const s000 = rand(@Vector(3, u32){
                @intFromFloat(c000.x),
                @intFromFloat(c000.y),
                @intFromFloat(c000.z),
            });
            const s100 = rand(@Vector(3, u32){
                @intFromFloat(c100.x),
                @intFromFloat(c100.y),
                @intFromFloat(c100.z),
            });
            const s010 = rand(@Vector(3, u32){
                @intFromFloat(c010.x),
                @intFromFloat(c010.y),
                @intFromFloat(c010.z),
            });
            const s110 = rand(@Vector(3, u32){
                @intFromFloat(c110.x),
                @intFromFloat(c110.y),
                @intFromFloat(c110.z),
            });
            const s001 = rand(@Vector(3, u32){
                @intFromFloat(c001.x),
                @intFromFloat(c001.y),
                @intFromFloat(c001.z),
            });
            const s101 = rand(@Vector(3, u32){
                @intFromFloat(c101.x),
                @intFromFloat(c101.y),
                @intFromFloat(c101.z),
            });
            const s011 = rand(@Vector(3, u32){
                @intFromFloat(c011.x),
                @intFromFloat(c011.y),
                @intFromFloat(c011.z),
            });
            const s111 = rand(@Vector(3, u32){
                @intFromFloat(c111.x),
                @intFromFloat(c111.y),
                @intFromFloat(c111.z),
            });

            // Perform trilinear interpolation with a smootherstep factor
            const tx = smootherstep(t.x);
            const ty = smootherstep(t.y);
            const tz = smootherstep(t.z);

            const l00 = lerp(s000, s001, tz);
            const l01 = lerp(s010, s011, tz);
            const l10 = lerp(s100, s101, tz);
            const l11 = lerp(s110, s111, tz);

            const l0 = lerp(l00, l01, ty);
            const l1 = lerp(l10, l11, ty);

            const l = lerp(l0, l1, tx);

            // Return the result
            return l;
        },
        Vec4 => {
            // Get the t value
            const cell = p.floored();
            const t = p.minus(cell);

            // Get the sample coordinates
            const c0000 = cell.modded(period);
            const c1000 = cell.plus(.{ .x = 1, .y = 0, .z = 0, .w = 0 }).modded(period);
            const c0100 = cell.plus(.{ .x = 0, .y = 1, .z = 0, .w = 0 }).modded(period);
            const c1100 = cell.plus(.{ .x = 1, .y = 1, .z = 0, .w = 0 }).modded(period);
            const c0010 = cell.plus(.{ .x = 0, .y = 0, .z = 1, .w = 0 }).modded(period);
            const c1010 = cell.plus(.{ .x = 1, .y = 0, .z = 1, .w = 0 }).modded(period);
            const c0110 = cell.plus(.{ .x = 0, .y = 1, .z = 1, .w = 0 }).modded(period);
            const c1110 = cell.plus(.{ .x = 1, .y = 1, .z = 1, .w = 0 }).modded(period);
            const c0001 = cell.plus(.{ .x = 0, .y = 0, .z = 0, .w = 1 }).modded(period);
            const c1001 = cell.plus(.{ .x = 1, .y = 0, .z = 0, .w = 1 }).modded(period);
            const c0101 = cell.plus(.{ .x = 0, .y = 1, .z = 0, .w = 1 }).modded(period);
            const c1101 = cell.plus(.{ .x = 1, .y = 1, .z = 0, .w = 1 }).modded(period);
            const c0011 = cell.plus(.{ .x = 0, .y = 0, .z = 1, .w = 1 }).modded(period);
            const c1011 = cell.plus(.{ .x = 1, .y = 0, .z = 1, .w = 1 }).modded(period);
            const c0111 = cell.plus(.{ .x = 0, .y = 1, .z = 1, .w = 1 }).modded(period);
            const c1111 = cell.plus(.{ .x = 1, .y = 1, .z = 1, .w = 1 }).modded(period);

            // Get the sample values, integer seed for better hash since it's a whole number
            const s0000 = rand(@Vector(4, u32){
                @intFromFloat(c0000.x),
                @intFromFloat(c0000.y),
                @intFromFloat(c0000.z),
                @intFromFloat(c0000.w),
            });
            const s1000 = rand(@Vector(4, u32){
                @intFromFloat(c1000.x),
                @intFromFloat(c1000.y),
                @intFromFloat(c1000.z),
                @intFromFloat(c1000.w),
            });
            const s0100 = rand(@Vector(4, u32){
                @intFromFloat(c0100.x),
                @intFromFloat(c0100.y),
                @intFromFloat(c0100.z),
                @intFromFloat(c0100.w),
            });
            const s1100 = rand(@Vector(4, u32){
                @intFromFloat(c1100.x),
                @intFromFloat(c1100.y),
                @intFromFloat(c1100.z),
                @intFromFloat(c1100.w),
            });
            const s0010 = rand(@Vector(4, u32){
                @intFromFloat(c0010.x),
                @intFromFloat(c0010.y),
                @intFromFloat(c0010.z),
                @intFromFloat(c0010.w),
            });
            const s1010 = rand(@Vector(4, u32){
                @intFromFloat(c1010.x),
                @intFromFloat(c1010.y),
                @intFromFloat(c1010.z),
                @intFromFloat(c1010.w),
            });
            const s0110 = rand(@Vector(4, u32){
                @intFromFloat(c0110.x),
                @intFromFloat(c0110.y),
                @intFromFloat(c0110.z),
                @intFromFloat(c0110.w),
            });
            const s1110 = rand(@Vector(4, u32){
                @intFromFloat(c1110.x),
                @intFromFloat(c1110.y),
                @intFromFloat(c1110.z),
                @intFromFloat(c1110.w),
            });
            const s0001 = rand(@Vector(4, u32){
                @intFromFloat(c0001.x),
                @intFromFloat(c0001.y),
                @intFromFloat(c0001.z),
                @intFromFloat(c0001.w),
            });
            const s1001 = rand(@Vector(4, u32){
                @intFromFloat(c1001.x),
                @intFromFloat(c1001.y),
                @intFromFloat(c1001.z),
                @intFromFloat(c1001.w),
            });
            const s0101 = rand(@Vector(4, u32){
                @intFromFloat(c0101.x),
                @intFromFloat(c0101.y),
                @intFromFloat(c0101.z),
                @intFromFloat(c0101.w),
            });
            const s1101 = rand(@Vector(4, u32){
                @intFromFloat(c1101.x),
                @intFromFloat(c1101.y),
                @intFromFloat(c1101.z),
                @intFromFloat(c1101.w),
            });
            const s0011 = rand(@Vector(4, u32){
                @intFromFloat(c0011.x),
                @intFromFloat(c0011.y),
                @intFromFloat(c0011.z),
                @intFromFloat(c0011.w),
            });
            const s1011 = rand(@Vector(4, u32){
                @intFromFloat(c1011.x),
                @intFromFloat(c1011.y),
                @intFromFloat(c1011.z),
                @intFromFloat(c1011.w),
            });
            const s0111 = rand(@Vector(4, u32){
                @intFromFloat(c0111.x),
                @intFromFloat(c0111.y),
                @intFromFloat(c0111.z),
                @intFromFloat(c0111.w),
            });
            const s1111 = rand(@Vector(4, u32){
                @intFromFloat(c1111.x),
                @intFromFloat(c1111.y),
                @intFromFloat(c1111.z),
                @intFromFloat(c1111.w),
            });

            // Perform quadlinear interpolation with a smootherstep factor
            const tx = smootherstep(t.x);
            const ty = smootherstep(t.y);
            const tz = smootherstep(t.z);
            const tw = smootherstep(t.w);

            const l000 = lerp(s0000, s0001, tw);
            const l100 = lerp(s1000, s1001, tw);
            const l010 = lerp(s0100, s0101, tw);
            const l110 = lerp(s1100, s1101, tw);
            const l001 = lerp(s0010, s0011, tw);
            const l101 = lerp(s1010, s1011, tw);
            const l011 = lerp(s0110, s0111, tw);
            const l111 = lerp(s1110, s1111, tw);

            const l00 = lerp(l000, l001, tz);
            const l10 = lerp(l100, l101, tz);
            const l01 = lerp(l010, l011, tz);
            const l11 = lerp(l110, l111, tz);

            const l0 = lerp(l00, l01, ty);
            const l1 = lerp(l10, l11, ty);

            const l = lerp(l0, l1, tx);

            // Return the result
            return l;
        },
        else => comptime unreachable,
    }
}

pub fn value(p: anytype) f32 {
    switch (@TypeOf(p)) {
        f32 => return valuePeriodic(p, f32_max_consec),
        else => return valuePeriodic(p, .splat(f32_max_consec)),
    }
}

test value {
    // Make sure it compiles for each type. These results also were visually verified to match the
    // results from the GLSL code at the time of writing.
    try std.testing.expectEqual(3.0199997e-2, value(@as(f32, 0.0)));
    try std.testing.expectEqual(9.723196e-2, value(Vec2{ .x = 0.0, .y = 0.0 }));
    try std.testing.expectEqual(6.081519e-1, value(Vec3{ .x = 0.0, .y = 0.0, .z = 0.0 }));
    try std.testing.expectEqual(5.863906e-2, value(Vec4{ .x = 0.0, .y = 0.0, .z = 0.0, .w = 0.0 }));
}
