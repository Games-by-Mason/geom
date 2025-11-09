const std = @import("std");
const geom = @import("root.zig");

const remap = geom.tween.interp.remap;

const Vec2 = geom.Vec2;
const Vec3 = geom.Vec3;
const Mat4 = geom.Mat4;
const Frustum3 = geom.Frustum3;

/// Undoes the perspective projection specified by the given frustum on the given normalized
/// device coordinate to get back a point in view space at the specified depth.
pub fn perspective(opt: Mat4.PerspectiveOptions, ndc: Vec2, view_z: f32) Vec3 {
    const view_xy = ndc.scaled(view_z / opt.focal_length);
    return .{
        .x = remap(-1, 1, opt.frustum.left, opt.frustum.right, view_xy.x),
        .y = remap(-1, 1, opt.frustum.top, opt.frustum.bottom, view_xy.y),
        .z = view_z,
    };
}

test perspective {
    const f: Frustum3 = .{
        .left = -2.5,
        .right = 0.3,
        .top = 4.1,
        .bottom = -2.2,
        .near = 0.15,
        .far = 3.2,
    };

    // Focal length of 1
    {
        const opt: Mat4.PerspectiveOptions = .{ .focal_length = 1.0, .frustum = f };
        const proj = Mat4.perspective(opt);
        const p_view: Vec3 = .{ .x = 1, .y = 2, .z = 3 };
        const p_ndc = proj.timesPoint(p_view);
        const un = perspective(opt, p_ndc.xy(), p_view.z);
        try expectVec3ApproxEql(p_view, un);
    }

    // Focal length of 2
    {
        const opt: Mat4.PerspectiveOptions = .{ .focal_length = 2.0, .frustum = f };
        const proj = Mat4.perspective(opt);
        const p_view: Vec3 = .{ .x = 1, .y = 2, .z = 3 };
        const p_ndc = proj.timesPoint(p_view);
        const un = perspective(opt, p_ndc.xy(), p_view.z);
        try expectVec3ApproxEql(p_view, un);
    }
}

/// Undoes the orthographic projection specified by the given frustum on the given normalized
/// device coordinate to get back a point in view space with Z elided. See also `inverseTs`.
pub fn ortho(f: Frustum3, ndc: Vec2) Vec2 {
    return .{
        .x = remap(-1, 1, f.left, f.right, ndc.x),
        .y = remap(-1, 1, f.top, f.bottom, ndc.y),
    };
}

test ortho {
    const f: Frustum3 = .{
        .left = -2.5,
        .right = 0.3,
        .top = 4.1,
        .bottom = -2.2,
        .near = 0.15,
        .far = 3.2,
    };
    const proj: Mat4 = .ortho(f);
    const p_view: Vec3 = .{ .x = 1, .y = 2, .z = 3 };
    const p_ndc = proj.timesPoint(p_view);
    const un = ortho(f, p_ndc.xy());
    try expectVec2ApproxEql(p_view.xy(), un);
}

fn expectVec2ApproxEql(expected: Vec2, actual: Vec2) !void {
    try std.testing.expectApproxEqAbs(expected.x, actual.x, 0.0001);
    try std.testing.expectApproxEqAbs(expected.y, actual.y, 0.0001);
}

fn expectVec3ApproxEql(expected: Vec3, actual: Vec3) !void {
    try std.testing.expectApproxEqAbs(expected.x, actual.x, 0.0001);
    try std.testing.expectApproxEqAbs(expected.y, actual.y, 0.0001);
    try std.testing.expectApproxEqAbs(expected.z, actual.z, 0.0001);
}
