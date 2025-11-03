const std = @import("std");
const geom = @import("root.zig");

const remap = geom.tween.interp.remap;

const Vec2 = geom.Vec2;
const Mat3 = geom.Mat3;

/// A 2 dimensional frustum.
pub const Frustum2 = extern struct {
    left: f32,
    right: f32,
    bottom: f32,
    top: f32,

    /// Undoes the orthographic projection specified by the given frustum on the given normalized
    /// device coordinate to get back a point in view space. See also `inverseTs`.
    pub fn unprojectOrtho(f: Frustum2, ndc: Vec2) Vec2 {
        return .{
            .x = remap(-1, 1, f.left, f.right, ndc.x),
            .y = remap(-1, 1, f.top, f.bottom, ndc.y),
        };
    }

    test unprojectOrtho {
        const f: Frustum2 = .{
            .left = -2.5,
            .right = 0.3,
            .top = 4.1,
            .bottom = -2.2,
        };
        const proj = Mat3.orthoFromFrustum(f);
        const p_view: Vec2 = .{ .x = 1, .y = 2 };
        const p_ndc = proj.timesPoint(p_view);
        const un = f.unprojectOrtho(p_ndc);
        try expectVec2ApproxEql(p_view, un);
    }
};

fn expectVec2ApproxEql(expected: Vec2, actual: Vec2) !void {
    try std.testing.expectApproxEqAbs(expected.x, actual.x, 0.0001);
    try std.testing.expectApproxEqAbs(expected.y, actual.y, 0.0001);
}
