const std = @import("std");
const geom = @import("geom");
const Vec2 = geom.Vec2;
const Vec3 = geom.Vec3;
const Vec4 = geom.Vec4;
const Mat2x3 = geom.Mat2x3;
const Mat3x4 = geom.Mat3x4;
const Mat4 = geom.Mat4;
const Rotor2 = geom.Rotor2;
const Rotor3 = geom.Rotor3;

pub fn main() !void {
    {
        var r: Rotor2 = .fromAngle(std.math.pi / 3.0);
        std.debug.print("{} -> {}\n", .{ r, r.mag() });
        var timer = try std.time.Timer.start();
        for (0..100_000_000) |_| {
            r = r.times(r);
        }
        std.debug.print("r2 times: {}ms\n", .{timer.read() / 1000000});
        std.debug.print("{} -> {}\n", .{ r, r.mag() });
    }
    {
        var r: Rotor3 = .fromPlaneAngle(.yx_pos, std.math.pi / 3.0);
        std.debug.print("r3 times: {} -> {}\n", .{ r, r.mag() });
        var timer = try std.time.Timer.start();
        for (0..100_000_000) |_| {
            r = r.times(r);
        }
        std.debug.print("{}ms\n", .{timer.read() / 1000000});
        std.debug.print("{} -> {}\n", .{ r, r.mag() });
    }
    {
        var m: Mat2x3 = .rotation(.fromAngle(std.math.pi / 3.0));
        var p: Vec2 = .y_pos;
        var timer = try std.time.Timer.start();
        for (0..100_000_000) |_| {
            p = m.timesDir(p);
        }
        std.debug.print("m23 timesDir: {}ms\n", .{timer.read() / 1000000});
        std.debug.print("{}\n", .{p});
    }
    {
        var m: Mat2x3 = .rotation(.fromAngle(std.math.pi / 3.0));
        var p: Vec3 = .y_pos;
        var timer = try std.time.Timer.start();
        for (0..100_000_000) |_| {
            p = m.timesVec3(p);
        }
        std.debug.print("m23 timesVec3: {}ms\n", .{timer.read() / 1000000});
        std.debug.print("{}\n", .{p});
    }
    {
        var m: Mat2x3 = .identity;
        const m2: Mat2x3 = .rotation(.fromAngle(std.math.pi / 3.0));
        var timer = try std.time.Timer.start();
        for (0..100_000_000) |_| {
            m.apply(m2);
        }
        std.debug.print("m23 apply: {}ms\n", .{timer.read() / 1000000});
        std.debug.print("{}\n", .{m});
    }
    {
        var m: Mat2x3 = .rotation(.fromAngle(std.math.pi / 3.0));
        var p: Vec2 = .y_pos;
        var timer = try std.time.Timer.start();
        for (0..100_000_000) |_| {
            p = m.timesPoint(p);
        }
        std.debug.print("m23 timesPoint: {}ms\n", .{timer.read() / 1000000});
        std.debug.print("{}\n", .{p});
    }
    {
        var m: Mat3x4 = .rotation(.fromPlaneAngle(.yx_pos, std.math.pi / 3.0));
        var p: Vec3 = .y_pos;
        var timer = try std.time.Timer.start();
        for (0..100_000_000) |_| {
            p = m.timesDir(p);
        }
        std.debug.print("m34 timesDir: {}ms\n", .{timer.read() / 1000000});
        std.debug.print("{}\n", .{p});
    }
    {
        var m: Mat3x4 = .rotation(.fromPlaneAngle(.yx_pos, std.math.pi / 3.0));
        var p: Vec4 = .y_pos;
        var timer = try std.time.Timer.start();
        for (0..100_000_000) |_| {
            p = m.timesVec4(p);
        }
        std.debug.print("m34 timesVec4: {}ms\n", .{timer.read() / 1000000});
        std.debug.print("{}\n", .{p});
    }
    {
        var m: Mat3x4 = .identity;
        const m2: Mat3x4 = .rotation(.fromPlaneAngle(.yx_pos, std.math.pi / 3.0));
        var timer = try std.time.Timer.start();
        for (0..100_000_000) |_| {
            m.apply(m2);
        }
        std.debug.print("m34 apply: {}ms\n", .{timer.read() / 1000000});
        std.debug.print("{}\n", .{m});
    }
    {
        var m: Mat3x4 = .rotation(.fromPlaneAngle(.yx_pos, std.math.pi / 3.0));
        var p: Vec3 = .y_pos;
        var timer = try std.time.Timer.start();
        for (0..100_000_000) |_| {
            p = m.timesPoint(p);
        }
        std.debug.print("m34 timesPoint: {}ms\n", .{timer.read() / 1000000});
        std.debug.print("{}\n", .{p});
    }
    {
        var m: Mat4 = .rotation(.fromPlaneAngle(.yx_pos, std.math.pi / 3.0));
        var p: Vec3 = .y_pos;
        var timer = try std.time.Timer.start();
        for (0..100_000_000) |_| {
            p = m.timesDir(p);
        }
        std.debug.print("m4 timesDir: {}ms\n", .{timer.read() / 1000000});
        std.debug.print("{}\n", .{p});
    }
    {
        var m: Mat4 = .rotation(.fromPlaneAngle(.yx_pos, std.math.pi / 3.0));
        var p: Vec4 = .y_pos;
        var timer = try std.time.Timer.start();
        for (0..100_000_000) |_| {
            p = m.timesVec4(p);
        }
        std.debug.print("m4 timesVec4: {}ms\n", .{timer.read() / 1000000});
        std.debug.print("{}\n", .{p});
    }
    {
        var m: Mat4 = .identity;
        const m2: Mat4 = .rotation(.fromPlaneAngle(.yx_pos, std.math.pi / 3.0));
        var timer = try std.time.Timer.start();
        for (0..100_000_000) |_| {
            m.apply(m2);
        }
        std.debug.print("m4 apply: {}ms\n", .{timer.read() / 1000000});
        std.debug.print("{}\n", .{m});
    }
    {
        var m: Mat4 = .rotation(.fromPlaneAngle(.yx_pos, std.math.pi / 3.0));
        var p: Vec3 = .y_pos;
        var timer = try std.time.Timer.start();
        for (0..100_000_000) |_| {
            p = m.timesPoint(p);
        }
        std.debug.print("m4 timesPoint: {}ms\n", .{timer.read() / 1000000});
        std.debug.print("{}\n", .{p});
    }
    {
        var p: Vec2 = .{ .x = 0.2, .y = 0.3 };
        var timer = try std.time.Timer.start();
        for (0..100_000_000) |_| {
            p.addScaled(p, 1.5);
        }
        std.debug.print("v2: {}ms\n", .{timer.read() / 1000000});
        std.debug.print("{}\n", .{p});
    }
    {
        var p: Vec2 = .{ .x = 0.2, .y = 0.3 };
        var timer = try std.time.Timer.start();
        for (0..100_000_000) |_| {
            p.x = p.innerProd(p);
        }
        std.debug.print("v2: {}ms\n", .{timer.read() / 1000000});
        std.debug.print("{}\n", .{p});
    }
}
