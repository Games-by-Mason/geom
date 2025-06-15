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
const hash = geom.hash.default;
const hash2D = geom.hash.default2D;
const hash3D = geom.hash.default3D;
const hash4D = geom.hash.default4D;
const lerp = tween.interp.lerp;
const smootherstep = tween.ease.smootherstep;
const f32_max_consec = geom.constants.f32_max_consec;
const u32_max_recip = geom.constants.u32_max_recip;

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

pub fn perlinPeriodic(p: anytype, period: @TypeOf(p)) f32 {
    switch (@TypeOf(p)) {
        f32 => {
            // Get the cell and t value
            const cell = @floor(p);
            const t = p - cell;

            // Get the sample offsets
            const o0: f32 = 0;
            const o1: f32 = 1;

            // Get the samples
            const s0 = perlinDotGrad1(
                @mod(cell + o0, period),
                @mod(t - o0, std.math.sign(0.5 - o0) * period),
            );
            const s1 = perlinDotGrad1(
                @mod(cell + o1, period),
                @mod(t - o1, std.math.sign(0.5 - o1) * period),
            );

            // Perform linear interpolation with a smootherstep factor
            return lerp(s0, s1, smootherstep(t));
        },
        Vec2 => {
            // Get the cell and t value
            const cell = p.floored();
            const t = p.minus(cell);

            // Get the sample offsets
            const o00: Vec2 = .{ .x = 0, .y = 0 };
            const o10: Vec2 = .{ .x = 1, .y = 0 };
            const o01: Vec2 = .{ .x = 0, .y = 1 };
            const o11: Vec2 = .{ .x = 1, .y = 1 };

            // Get the samples
            const s00 = perlinDotGrad2(
                cell.plus(o00).modded(period),
                t.minus(o00).modded(Vec2.splat(0.5).minus(o00).signOf().compProd(period)),
            );
            const s10 = perlinDotGrad2(
                cell.plus(o10).modded(period),
                t.minus(o10).modded(Vec2.splat(0.5).minus(o10).signOf().compProd(period)),
            );
            const s01 = perlinDotGrad2(
                cell.plus(o01).modded(period),
                t.minus(o01).modded(Vec2.splat(0.5).minus(o01).signOf().compProd(period)),
            );
            const s11 = perlinDotGrad2(
                cell.plus(o11).modded(period),
                t.minus(o11).modded(Vec2.splat(0.5).minus(o11).signOf().compProd(period)),
            );

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
            // Get the cell and t value
            const cell = p.floored();
            const t = p.minus(cell);

            // Get the sample offsets
            const o000: Vec3 = .{ .x = 0, .y = 0, .z = 0 };
            const o100: Vec3 = .{ .x = 1, .y = 0, .z = 0 };
            const o010: Vec3 = .{ .x = 0, .y = 1, .z = 0 };
            const o110: Vec3 = .{ .x = 1, .y = 1, .z = 0 };
            const o001: Vec3 = .{ .x = 0, .y = 0, .z = 1 };
            const o101: Vec3 = .{ .x = 1, .y = 0, .z = 1 };
            const o011: Vec3 = .{ .x = 0, .y = 1, .z = 1 };
            const o111: Vec3 = .{ .x = 1, .y = 1, .z = 1 };

            // Get the sample values
            const s000 = perlinDotGrad3(
                cell.plus(o000).modded(period),
                t.minus(o000).modded(Vec3.splat(0.5).minus(o000).signOf().compProd(period)),
            );
            const s100 = perlinDotGrad3(
                cell.plus(o100).modded(period),
                t.minus(o100).modded(Vec3.splat(0.5).minus(o100).signOf().compProd(period)),
            );
            const s010 = perlinDotGrad3(
                cell.plus(o010).modded(period),
                t.minus(o010).modded(Vec3.splat(0.5).minus(o010).signOf().compProd(period)),
            );
            const s110 = perlinDotGrad3(
                cell.plus(o110).modded(period),
                t.minus(o110).modded(Vec3.splat(0.5).minus(o110).signOf().compProd(period)),
            );
            const s001 = perlinDotGrad3(
                cell.plus(o001).modded(period),
                t.minus(o001).modded(Vec3.splat(0.5).minus(o001).signOf().compProd(period)),
            );
            const s101 = perlinDotGrad3(
                cell.plus(o101).modded(period),
                t.minus(o101).modded(Vec3.splat(0.5).minus(o101).signOf().compProd(period)),
            );
            const s011 = perlinDotGrad3(
                cell.plus(o011).modded(period),
                t.minus(o011).modded(Vec3.splat(0.5).minus(o011).signOf().compProd(period)),
            );
            const s111 = perlinDotGrad3(
                cell.plus(o111).modded(period),
                t.minus(o111).modded(Vec3.splat(0.5).minus(o111).signOf().compProd(period)),
            );

            // Perform trilinear interpolation with a smootherstep factor
            const tx = smootherstep(t.x);
            const ty = smootherstep(t.y);
            const tz = smootherstep(t.z);

            const l00 = lerp(s000, s001, tz);
            const l10 = lerp(s100, s101, tz);
            const l01 = lerp(s010, s011, tz);
            const l11 = lerp(s110, s111, tz);

            const l0 = lerp(l00, l01, ty);
            const l1 = lerp(l10, l11, ty);

            const l = lerp(l0, l1, tx);

            // Return the result
            return l;
        },
        Vec4 => {
            // Get the cell and t value
            const cell = p.floored();
            const t = p.minus(cell);

            // Get the sample offsets
            const o0000: Vec4 = .{ .x = 0, .y = 0, .z = 0, .w = 0 };
            const o1000: Vec4 = .{ .x = 1, .y = 0, .z = 0, .w = 0 };
            const o0100: Vec4 = .{ .x = 0, .y = 1, .z = 0, .w = 0 };
            const o1100: Vec4 = .{ .x = 1, .y = 1, .z = 0, .w = 0 };
            const o0010: Vec4 = .{ .x = 0, .y = 0, .z = 1, .w = 0 };
            const o1010: Vec4 = .{ .x = 1, .y = 0, .z = 1, .w = 0 };
            const o0110: Vec4 = .{ .x = 0, .y = 1, .z = 1, .w = 0 };
            const o1110: Vec4 = .{ .x = 1, .y = 1, .z = 1, .w = 0 };
            const o0001: Vec4 = .{ .x = 0, .y = 0, .z = 0, .w = 1 };
            const o1001: Vec4 = .{ .x = 1, .y = 0, .z = 0, .w = 1 };
            const o0101: Vec4 = .{ .x = 0, .y = 1, .z = 0, .w = 1 };
            const o1101: Vec4 = .{ .x = 1, .y = 1, .z = 0, .w = 1 };
            const o0011: Vec4 = .{ .x = 0, .y = 0, .z = 1, .w = 1 };
            const o1011: Vec4 = .{ .x = 1, .y = 0, .z = 1, .w = 1 };
            const o0111: Vec4 = .{ .x = 0, .y = 1, .z = 1, .w = 1 };
            const o1111: Vec4 = .{ .x = 1, .y = 1, .z = 1, .w = 1 };

            // Get the sample values
            const s0000 = perlinDotGrad4(
                cell.plus(o0000).modded(period),
                t.minus(o0000).modded(Vec4.splat(0.5).minus(o0000).signOf().compProd(period)),
            );
            const s1000 = perlinDotGrad4(
                cell.plus(o1000).modded(period),
                t.minus(o1000).modded(Vec4.splat(0.5).minus(o1000).signOf().compProd(period)),
            );
            const s0100 = perlinDotGrad4(
                cell.plus(o0100).modded(period),
                t.minus(o0100).modded(Vec4.splat(0.5).minus(o0100).signOf().compProd(period)),
            );
            const s1100 = perlinDotGrad4(
                cell.plus(o1100).modded(period),
                t.minus(o1100).modded(Vec4.splat(0.5).minus(o1100).signOf().compProd(period)),
            );
            const s0010 = perlinDotGrad4(
                cell.plus(o0010).modded(period),
                t.minus(o0010).modded(Vec4.splat(0.5).minus(o0010).signOf().compProd(period)),
            );
            const s1010 = perlinDotGrad4(
                cell.plus(o1010).modded(period),
                t.minus(o1010).modded(Vec4.splat(0.5).minus(o1010).signOf().compProd(period)),
            );
            const s0110 = perlinDotGrad4(
                cell.plus(o0110).modded(period),
                t.minus(o0110).modded(Vec4.splat(0.5).minus(o0110).signOf().compProd(period)),
            );
            const s1110 = perlinDotGrad4(
                cell.plus(o1110).modded(period),
                t.minus(o1110).modded(Vec4.splat(0.5).minus(o1110).signOf().compProd(period)),
            );
            const s0001 = perlinDotGrad4(
                cell.plus(o0001).modded(period),
                t.minus(o0001).modded(Vec4.splat(0.5).minus(o0001).signOf().compProd(period)),
            );
            const s1001 = perlinDotGrad4(
                cell.plus(o1001).modded(period),
                t.minus(o1001).modded(Vec4.splat(0.5).minus(o1001).signOf().compProd(period)),
            );
            const s0101 = perlinDotGrad4(
                cell.plus(o0101).modded(period),
                t.minus(o0101).modded(Vec4.splat(0.5).minus(o0101).signOf().compProd(period)),
            );
            const s1101 = perlinDotGrad4(
                cell.plus(o1101).modded(period),
                t.minus(o1101).modded(Vec4.splat(0.5).minus(o1101).signOf().compProd(period)),
            );
            const s0011 = perlinDotGrad4(
                cell.plus(o0011).modded(period),
                t.minus(o0011).modded(Vec4.splat(0.5).minus(o0011).signOf().compProd(period)),
            );
            const s1011 = perlinDotGrad4(
                cell.plus(o1011).modded(period),
                t.minus(o1011).modded(Vec4.splat(0.5).minus(o1011).signOf().compProd(period)),
            );
            const s0111 = perlinDotGrad4(
                cell.plus(o0111).modded(period),
                t.minus(o0111).modded(Vec4.splat(0.5).minus(o0111).signOf().compProd(period)),
            );
            const s1111 = perlinDotGrad4(
                cell.plus(o1111).modded(period),
                t.minus(o1111).modded(Vec4.splat(0.5).minus(o1111).signOf().compProd(period)),
            );

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

pub fn perlin(p: anytype) f32 {
    switch (@TypeOf(p)) {
        f32 => return perlinPeriodic(p, f32_max_consec),
        else => return perlinPeriodic(p, .splat(f32_max_consec)),
    }
}

test perlin {
    // Make sure it compiles for each type. These results also were visually verified to match the
    // results from the GLSL code at the time of writing.
    try std.testing.expectEqual(-3.1448156e-1, perlin(@as(f32, 0.5)));
    try std.testing.expectEqual(5e-1, perlin(Vec2{ .x = 0.5, .y = 0.5 }));
    try std.testing.expectEqual(-1.25e-1, perlin(Vec3{ .x = 0.5, .y = 0.5, .z = 0.5 }));
    try std.testing.expectEqual(0, perlin(Vec4{ .x = 0.5, .y = 0.5, .z = 0.5, .w = 0.5 }));
}

fn perlinDotGrad1(cell: f32, p: f32) f32 {
    // Mimics `perlinDotGrad*` API to show how the algorithm generalizes even though we don't
    // really need to pull this out into a function here.
    return lerp(-1, 1, rand(@as(u32, @bitCast(@as(i32, @intFromFloat(cell)))))) * p;
}

fn perlinDotGrad2(cell: Vec2, p: Vec2) f32 {
    // Take the dot product of the cell with a random diagonal vector:
    // - The vector is not supposed to be normalized since the max distance is in fact to a corner.
    // - We return the dot product instead of the gradient itself since the dot product of a vector
    //   with only ones and zeroes is easier to compute than that of one that could hold arbitrary
    //   values.
    // - We cast the cell to an integer before hashing to better utilize the input space, otherwise
    //   the modulo results in a bad hash. It must be signed since it may be negative.
    return switch (@as(u3, @intCast(hash2D(@Vector(2, u32){
        @bitCast(@as(i32, @intFromFloat(cell.x))),
        @bitCast(@as(i32, @intFromFloat(cell.y))),
    })[0] % 8))) {
        0 => -p.x + -p.y,
        1 => -p.x + 0,
        2 => -p.x + p.y,
        3 => 0 + -p.y,
        4 => 0 + p.y,
        5 => p.x + -p.y,
        6 => p.x + 0,
        7 => p.x + p.y,
    };
}

fn perlinDotGrad3(cell: Vec3, p: Vec3) f32 {
    // See `perlinDotGrad2` for an explanation.
    //
    // Duplicate cases make modulo an even multiple, they following a tetrahedron to avoid bias:
    // https://mrl.cs.nyu.edu/~perlin/paper445.pdf
    return switch (@as(u4, @intCast(hash3D(@Vector(3, u32){
        @bitCast(@as(i32, @intFromFloat(cell.x))),
        @bitCast(@as(i32, @intFromFloat(cell.y))),
        @bitCast(@as(i32, @intFromFloat(cell.z))),
    })[0] % 16))) {
        0 => -p.x + -p.y + 0,
        1 => -p.x + 0 + -p.z,
        2 => -p.x + 0 + p.z,
        3 => 0 + p.y + -p.z,
        4 => 0 + p.y + p.z,
        5 => p.x + -p.y + 0,
        6 => p.x + 0 + -p.z,
        7 => p.x + 0 + p.z,
        8, 9 => p.x + p.y + 0,
        10, 11 => -p.x + p.y + 0,
        12, 13 => 0 + -p.y + p.z,
        14, 15 => 0 + -p.y + -p.z,
    };
}

fn perlinDotGrad4(cell: Vec4, p: Vec4) f32 {
    // See `perlinDotGrad2` for an explanation.
    return switch (@as(u5, @intCast(hash4D(@Vector(4, u32){
        @bitCast(@as(i32, @intFromFloat(cell.x))),
        @bitCast(@as(i32, @intFromFloat(cell.y))),
        @bitCast(@as(i32, @intFromFloat(cell.z))),
        @bitCast(@as(i32, @intFromFloat(cell.w))),
    })[0] % 32))) {
        0 => -p.x + -p.y + -p.z + 0,
        1 => -p.x + -p.y + 0 + -p.w,
        2 => -p.x + -p.y + 0 + p.w,
        3 => -p.x + -p.y + p.z + 0,
        4 => -p.x + 0 + -p.z + -p.w,
        5 => -p.x + 0 + -p.z + p.w,
        6 => -p.x + 0 + p.z + -p.w,
        7 => -p.x + 0 + p.z + p.w,
        8 => -p.x + p.y + -p.z + 0,
        9 => -p.x + p.y + 0 + -p.w,
        10 => -p.x + p.y + 0 + p.w,
        11 => -p.x + p.y + p.z + 0,
        12 => 0 + -p.y + -p.z + -p.w,
        13 => 0 + -p.y + -p.z + p.w,
        14 => 0 + -p.y + p.z + -p.w,
        15 => 0 + -p.y + p.z + p.w,
        16 => 0 + p.y + -p.z + -p.w,
        17 => 0 + p.y + -p.z + p.w,
        18 => 0 + p.y + p.z + -p.w,
        19 => 0 + p.y + p.z + p.w,
        20 => p.x + -p.y + -p.z + 0,
        21 => p.x + -p.y + 0 + -p.w,
        22 => p.x + -p.y + 0 + p.w,
        23 => p.x + -p.y + p.z + 0,
        24 => p.x + 0 + -p.z + -p.w,
        25 => p.x + 0 + -p.z + p.w,
        26 => p.x + 0 + p.z + -p.w,
        27 => p.x + 0 + p.z + p.w,
        28 => p.x + p.y + -p.z + 0,
        29 => p.x + p.y + 0 + -p.w,
        30 => p.x + p.y + 0 + p.w,
        31 => p.x + p.y + p.z + 0,
    };
}

fn VoronoiImpl(T: type, features: u4) type {
    return switch (features) {
        1 => return struct {
            point: T,
            id: u32,
            dist2: f32,
        },
        2 => return struct {
            point: [2]T,
            id: [2]u32,
            dist2: [2]f32,
        },
        else => comptime unreachable,
    };
}

pub fn Voronoi(T: type) type {
    return VoronoiImpl(T, 1);
}

pub fn VoronoiF1F2(T: type) type {
    return VoronoiImpl(T, 2);
}

fn voronoiImpl(
    p: anytype,
    period: @TypeOf(p),
    comptime features: u4,
) VoronoiImpl(@TypeOf(p), features) {
    var result_point: [features]@TypeOf(p) = undefined;
    var result_id: [features]u32 = undefined;
    var result_dist2: [features]f32 = @splat(std.math.inf(f32));
    switch (@TypeOf(p)) {
        f32 => {
            const cell = @floor(p);
            const t = p - cell;
            for ([3]f32{ -1.0, 0.0, 1.0 }) |offset| {
                const hashed = hash(@intFromFloat(@mod(cell + offset, period)));
                const id = hashed;
                const point = @as(f32, @floatFromInt(hashed)) * u32_max_recip + offset;
                const dist2 = @abs(point - t);
                for (0..features) |i| {
                    if (dist2 < result_dist2[i]) {
                        if (features > 1 and i == 0) {
                            result_dist2[i + 1] = result_dist2[i];
                            result_point[i + 1] = result_point[i];
                            result_id[i + 1] = result_id[i];
                        }
                        result_dist2[i] = dist2;
                        result_point[i] = cell + point;
                        result_id[i] = id;
                        break;
                    }
                }
            }
        },
        Vec2 => {
            const cell = p.floored();
            const t = p.minus(cell);
            for ([3]f32{ -1.0, 0.0, 1.0 }) |x| {
                for ([3]f32{ -1.0, 0.0, 1.0 }) |y| {
                    const offset: Vec2 = .{ .x = x, .y = y };
                    const seed = cell.plus(offset).modded(period);
                    const hashed = hash2D(@Vector(2, u32){
                        @intFromFloat(seed.x),
                        @intFromFloat(seed.y),
                    });
                    const id = hashed[0];
                    const point = (Vec2{
                        .x = @floatFromInt(hashed[0]),
                        .y = @floatFromInt(hashed[1]),
                    }).scaled(u32_max_recip).plus(offset);
                    const dist2 = point.minus(t).magSq();
                    for (0..features) |i| {
                        if (dist2 < result_dist2[i]) {
                            if (features > 1 and i == 0) {
                                result_dist2[i + 1] = result_dist2[i];
                                result_point[i + 1] = result_point[i];
                                result_id[i + 1] = result_id[i];
                            }
                            result_dist2[i] = dist2;
                            result_point[i] = cell.plus(point);
                            result_id[i] = id;
                            break;
                        }
                    }
                }
            }
        },
        Vec3 => {
            const cell = p.floored();
            const t = p.minus(cell);
            for ([3]f32{ -1.0, 0.0, 1.0 }) |x| {
                for ([3]f32{ -1.0, 0.0, 1.0 }) |y| {
                    for ([3]f32{ -1.0, 0.0, 1.0 }) |z| {
                        const offset: Vec3 = .{ .x = x, .y = y, .z = z };
                        const seed = cell.plus(offset).modded(period);
                        const hashed = hash3D(@Vector(3, u32){
                            @intFromFloat(seed.x),
                            @intFromFloat(seed.y),
                            @intFromFloat(seed.z),
                        });
                        const id = hashed[0];
                        const point = (Vec3{
                            .x = @floatFromInt(hashed[0]),
                            .y = @floatFromInt(hashed[1]),
                            .z = @floatFromInt(hashed[2]),
                        }).scaled(u32_max_recip).plus(offset);
                        const dist2 = point.minus(t).magSq();
                        for (0..features) |i| {
                            if (dist2 < result_dist2[i]) {
                                if (features > 1 and i == 0) {
                                    result_dist2[i + 1] = result_dist2[i];
                                    result_point[i + 1] = result_point[i];
                                    result_id[i + 1] = result_id[i];
                                }
                                result_dist2[i] = dist2;
                                result_point[i] = cell.plus(point);
                                result_id[i] = id;
                                break;
                            }
                        }
                    }
                }
            }
        },
        Vec4 => {
            const cell = p.floored();
            const t = p.minus(cell);
            for ([3]f32{ -1.0, 0.0, 1.0 }) |x| {
                for ([3]f32{ -1.0, 0.0, 1.0 }) |y| {
                    for ([3]f32{ -1.0, 0.0, 1.0 }) |z| {
                        for ([3]f32{ -1.0, 0.0, 1.0 }) |w| {
                            const offset: Vec4 = .{ .x = x, .y = y, .z = z, .w = w };
                            const seed = cell.plus(offset).modded(period);
                            const hashed = hash4D(@Vector(4, u32){
                                @intFromFloat(seed.x),
                                @intFromFloat(seed.y),
                                @intFromFloat(seed.z),
                                @intFromFloat(seed.w),
                            });
                            const id = hashed[0];
                            const point = (Vec4{
                                .x = @floatFromInt(hashed[0]),
                                .y = @floatFromInt(hashed[1]),
                                .z = @floatFromInt(hashed[2]),
                                .w = @floatFromInt(hashed[3]),
                            }).scaled(u32_max_recip).plus(offset);
                            const dist2 = point.minus(t).magSq();
                            for (0..features) |i| {
                                if (dist2 < result_dist2[i]) {
                                    if (features > 1 and i == 0) {
                                        result_dist2[i + 1] = result_dist2[i];
                                        result_point[i + 1] = result_point[i];
                                        result_id[i + 1] = result_id[i];
                                    }
                                    result_dist2[i] = dist2;
                                    result_point[i] = cell.plus(point);
                                    result_id[i] = id;
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        },
        else => comptime unreachable,
    }
    return switch (features) {
        1 => .{
            .point = result_point[0],
            .id = result_id[0],
            .dist2 = result_dist2[0],
        },
        2 => .{
            .point = result_point,
            .id = result_id,
            .dist2 = result_dist2,
        },
        else => comptime unreachable,
    };
}

pub fn voronoiPeriodic(p: anytype, period: @TypeOf(p)) Voronoi(@TypeOf(p)) {
    return voronoiImpl(p, period, 1);
}

pub fn voronoi(p: anytype) Voronoi(@TypeOf(p)) {
    const period: @TypeOf(p) = switch (@TypeOf(p)) {
        f32 => f32_max_consec,
        else => .splat(f32_max_consec),
    };
    return voronoiImpl(p, period, 1);
}

pub fn voronoiPeriodicF1F2(p: anytype, period: @TypeOf(p)) VoronoiF1F2(@TypeOf(p)) {
    return voronoiImpl(p, period, 2);
}

pub fn voronoiF1F2(p: anytype) VoronoiF1F2(@TypeOf(p)) {
    const period: @TypeOf(p) = switch (@TypeOf(p)) {
        f32 => f32_max_consec,
        else => .splat(f32_max_consec),
    };
    return voronoiImpl(p, period, 2);
}

test voronoi {
    // Make sure it compiles for each type. These results also were visually verified to match the
    // results from the GLSL code at the time of writing.
    try std.testing.expectEqual(3.0199997e-2, voronoi(@as(f32, 0.0)).dist2);
    try std.testing.expectEqual(9.893582e-3, voronoi(Vec2{ .x = 0.0, .y = 0.0 }).dist2);
    try std.testing.expectEqual(4.204531e-1, voronoi(Vec3{ .x = 0.0, .y = 0.0, .z = 0.0 }).dist2);
    try std.testing.expectEqual(3.6259472e-1, voronoi(Vec4{ .x = 0.0, .y = 0.0, .z = 0.0, .w = 0.0 }).dist2);
}

test voronoiF1F2 {
    // Make sure it compiles for each type. These results also were visually verified to match the
    // results from the GLSL code at the time of writing.
    try std.testing.expectEqual(
        voronoi(@as(f32, 0.0)).dist2,
        voronoiF1F2(@as(f32, 0.0)).dist2[0],
    );
    try std.testing.expectEqual(
        voronoi(Vec2{ .x = 0.0, .y = 0.0 }).dist2,
        voronoiF1F2(Vec2{ .x = 0.0, .y = 0.0 }).dist2[0],
    );
    try std.testing.expectEqual(
        voronoi(Vec3{ .x = 0.0, .y = 0.0, .z = 0.0 }).dist2,
        voronoiF1F2(Vec3{ .x = 0.0, .y = 0.0, .z = 0.0 }).dist2[0],
    );
    try std.testing.expectEqual(
        voronoi(Vec4{ .x = 0.0, .y = 0.0, .z = 0.0, .w = 0.0 }).dist2,
        voronoiF1F2(Vec4{ .x = 0.0, .y = 0.0, .z = 0.0, .w = 0.0 }).dist2[0],
    );

    try std.testing.expectEqual(
        8.3925533e-1,
        voronoiF1F2(@as(f32, 0.0)).dist2[1],
    );
    try std.testing.expectEqual(
        1.0877938e-1,
        voronoiF1F2(Vec2{ .x = 0.0, .y = 0.0 }).dist2[1],
    );
    try std.testing.expectEqual(
        7.610585e-1,
        voronoiF1F2(Vec3{ .x = 0.0, .y = 0.0, .z = 0.0 }).dist2[1],
    );
    try std.testing.expectEqual(
        4.246807e-1,
        voronoiF1F2(Vec4{ .x = 0.0, .y = 0.0, .z = 0.0, .w = 0.0 }).dist2[1],
    );
}
