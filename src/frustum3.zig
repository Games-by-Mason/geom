const std = @import("std");
const geom = @import("root.zig");

const remap = geom.tween.interp.remap;

const Vec2 = geom.Vec2;
const Vec3 = geom.Vec3;
const Vec4 = geom.Vec4;
const Mat4 = geom.Mat4;
const Trivec4 = geom.Trivec4;

/// A 3 dimensional frustum.
pub const Frustum3 = extern struct {
    left: f32,
    right: f32,
    bottom: f32,
    top: f32,
    near: f32,
    far: f32,

    /// Undoes the perspective projection specified by the given frustum on the given normalized
    /// device coordinate to get back a point in view space at the specified depth.
    pub fn unprojectPerspective(f: Frustum3, ndc: Vec2, view_z: f32) Vec3 {
        const view_xy = ndc.scaled(view_z);
        return .{
            .x = remap(-1, 1, f.left, f.right, view_xy.x),
            .y = remap(-1, 1, f.top, f.bottom, view_xy.y),
            .z = view_z,
        };
    }

    test unprojectPerspective {
        const f: Frustum3 = .{
            .left = -2.5,
            .right = 0.3,
            .top = 4.1,
            .bottom = -2.2,
            .near = 0.15,
            .far = 3.2,
        };
        const proj = Mat4.perspectiveFromFrustum(f);
        const p_view: Vec3 = .{ .x = 1, .y = 2, .z = 3 };
        const p_ndc = proj.timesPoint(p_view);
        const un = f.unprojectPerspective(p_ndc.xy(), p_view.z);
        try expectVec3ApproxEql(p_view, un);
    }

    /// Undoes the orthographic projection specified by the given frustum on the given normalized
    /// device coordinate to get back a point in view space with Z elided. See also `inverseTs`.
    pub fn unprojectOrtho(f: Frustum3, ndc: Vec2) Vec2 {
        return .{
            .x = remap(-1, 1, f.left, f.right, ndc.x),
            .y = remap(-1, 1, f.top, f.bottom, ndc.y),
        };
    }

    test unprojectOrtho {
        const f: Frustum3 = .{
            .left = -2.5,
            .right = 0.3,
            .top = 4.1,
            .bottom = -2.2,
            .near = 0.15,
            .far = 3.2,
        };
        const proj = Mat4.orthoFromFrustum(f);
        const p_view: Vec3 = .{ .x = 1, .y = 2, .z = 3 };
        const p_ndc = proj.timesPoint(p_view);
        const un = f.unprojectOrtho(p_ndc.xy());
        try expectVec2ApproxEql(p_view.xy(), un);
    }

    // XXX: do enough to get this working, and then get book for rest to fill in
    pub fn unprojectPerspectiveOntoPlane(f: Frustum3, ndc: Vec2, plane: Trivec4) ?Vec3 {
        // Unproject the cursor into a line
        const near_intersect = unprojectPerspective(f, ndc, f.near);
        const far_intersect = unprojectPerspective(f, ndc, f.far);
        const line = near_intersect.point().outerProd(far_intersect.point());

        // Get the intersection between that line and the given plane
        const plane_intersect = plane.meet(line).toCartesian();

        // If the intersection isn't between the near and far plane, return null
        const near_dist_sq = plane_intersect.minus(near_intersect).magSq();
        const far_dist_sq = plane_intersect.minus(far_intersect).magSq();
        const depth_sq = near_intersect.minus(far_intersect).magSq();

        if (near_dist_sq + far_dist_sq > depth_sq) {
            return null;
        }

        // XXX: why would this happen again?
        // If we got NaN for the intersection, return null
        if (plane_intersect.x != plane_intersect.x or
            plane_intersect.y != plane_intersect.y or
            plane_intersect.z != plane_intersect.z)
        {
            return null;
        }

        // Return the intersection
        return plane_intersect;
    }

    // XXX: ...
    // XXX: test exact equal in cases we care about?
    // XXX: test in game
    test unprojectPerspectiveOntoPlane {
        const f: Frustum3 = .{
            .left = -2.5,
            .right = 0.3,
            .top = 4.1,
            .bottom = -2.2,
            .near = 0.15,
            .far = 3.2,
        };
        const proj_from_view: Mat4 = .perspectiveFromFrustum(f);

        {
            const a: Vec3 = .{ .x = 0, .y = 0, .z = f.near };
            const b: Vec3 = .{ .x = 1, .y = 0, .z = f.near };
            const c: Vec3 = .{ .x = 0, .y = 1, .z = f.near };
            const plane = a.point().outerProd(b.point()).outerProd(c.point());
            const ndc = Vec2.zero;
            const unprojected = unprojectPerspectiveOntoPlane(f, ndc, plane).?;
            const projected = proj_from_view.timesPoint(unprojected);
            try expectVec2ApproxEql(projected.xy(), ndc);
        }

        {
            const a: Vec3 = .{ .x = 0, .y = 0, .z = 1 };
            const b: Vec3 = .{ .x = 1, .y = 0, .z = 1 };
            const c: Vec3 = .{ .x = 0, .y = 1, .z = 1 };
            const plane = a.point().outerProd(b.point()).outerProd(c.point());
            const ndc = Vec2.zero;
            const unprojected = unprojectPerspectiveOntoPlane(f, ndc, plane).?;
            const projected = proj_from_view.timesPoint(unprojected);
            try expectVec2ApproxEql(projected.xy(), ndc);
        }

        {
            const a: Vec3 = .{ .x = 0, .y = 0, .z = 1 };
            const b: Vec3 = .{ .x = 1, .y = 0, .z = 1 };
            const c: Vec3 = .{ .x = 0, .y = 1, .z = 1 };
            const plane = a.point().outerProd(b.point()).outerProd(c.point());
            const ndc: Vec2 = .{ .x = 1, .y = 1 };
            const unprojected = unprojectPerspectiveOntoPlane(f, ndc, plane).?;
            const projected = proj_from_view.timesPoint(unprojected);
            try expectVec2ApproxEql(projected.xy(), ndc);
        }

        {
            const a: Vec3 = .{ .x = 0, .y = 0, .z = f.far };
            const b: Vec3 = .{ .x = 1, .y = 0, .z = f.far };
            const c: Vec3 = .{ .x = 0, .y = 1, .z = f.far };
            const plane = a.point().outerProd(b.point()).outerProd(c.point());
            const ndc = Vec2.zero;
            const unprojected = unprojectPerspectiveOntoPlane(f, ndc, plane).?;
            const projected = proj_from_view.timesPoint(unprojected);
            try expectVec2ApproxEql(projected.xy(), ndc);
        }

        {
            const a: Vec3 = .{ .x = 0, .y = 0, .z = f.far };
            const b: Vec3 = .{ .x = 1, .y = 0, .z = f.far };
            const c: Vec3 = .{ .x = 0, .y = 1, .z = f.far };
            const plane = a.point().outerProd(b.point()).outerProd(c.point());
            const ndc: Vec2 = .{ .x = 1, .y = 1 };
            const unprojected = unprojectPerspectiveOntoPlane(f, ndc, plane).?;
            const projected = proj_from_view.timesPoint(unprojected);
            try expectVec2ApproxEql(projected.xy(), ndc);
        }
    }
};

fn expectVec2ApproxEql(expected: Vec2, actual: Vec2) !void {
    try std.testing.expectApproxEqAbs(expected.x, actual.x, 0.0001);
    try std.testing.expectApproxEqAbs(expected.y, actual.y, 0.0001);
}

fn expectVec3ApproxEql(expected: Vec3, actual: Vec3) !void {
    try std.testing.expectApproxEqAbs(expected.x, actual.x, 0.0001);
    try std.testing.expectApproxEqAbs(expected.y, actual.y, 0.0001);
    try std.testing.expectApproxEqAbs(expected.z, actual.z, 0.0001);
}
