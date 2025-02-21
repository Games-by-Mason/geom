const std = @import("std");
const geom = @import("geom");
const Vec2 = geom.Vec2;
const Mat2x3 = geom.Mat2x3;

pub fn main() !void {
    var m: Mat2x3 = .rotation(.fromAngle(std.math.pi / 3.0));
    var p: Vec2 = .y_pos;
    var timer = try std.time.Timer.start();
    for (0..10_000_000) |_| {
        p = m.timesPoint(p);
    }
    std.debug.print("{}ms\n", .{timer.read() / 1000000});
    std.debug.print("{}\n", .{p});
}
