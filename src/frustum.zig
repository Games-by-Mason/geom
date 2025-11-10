const std = @import("std");
const geom = @import("root.zig");

const remap = geom.tween.interp.remap;

const Vec2 = geom.Vec2;
const Vec3 = geom.Vec3;
const Vec4 = geom.Vec4;
const Mat3 = geom.Mat3;
const Mat4 = geom.Mat4;

/// A 2 dimensional orthographic frustum.
pub const Frustum2 = extern struct {
    left: f32,
    right: f32,
    bottom: f32,
    top: f32,

    /// Undoes the orthographic projection specified by the given frustum on the given normalized
    /// device coordinate to get back a point in view space. See also `inverseTs`.
    pub fn unproject(f: Frustum2, ndc: Vec2) Vec2 {
        return .{
            .x = remap(-1, 1, f.left, f.right, ndc.x),
            .y = remap(-1, 1, f.top, f.bottom, ndc.y),
        };
    }

    test unproject {
        const f: Frustum2 = .{
            .left = -2.5,
            .right = 0.3,
            .top = 4.1,
            .bottom = -2.2,
        };
        const proj: Mat3 = .ortho(f);
        const p_view: Vec2 = .{ .x = 1, .y = 2 };
        const p_ndc = proj.timesPoint(p_view);
        const un = f.unproject(p_ndc);
        try expectVec2ApproxEql(p_view, un);
    }
};

/// A 3 dimensional orthographic frustum.
pub const OrthoFrustum3 = extern struct {
    left: f32,
    right: f32,
    bottom: f32,
    top: f32,
    near: f32,
    far: f32,

    /// Undoes the orthographic projection specified by the given frustum on the given normalized
    /// device coordinate to get back a point in view space with Z elided. See also `inverseTs`.
    pub fn unproject(f: OrthoFrustum3, ndc: Vec2) Vec2 {
        return .{
            .x = remap(-1, 1, f.left, f.right, ndc.x),
            .y = remap(-1, 1, f.top, f.bottom, ndc.y),
        };
    }

    test unproject {
        const f: OrthoFrustum3 = .{
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
        const un = unproject(f, p_ndc.xy());
        try expectVec2ApproxEql(p_view.xy(), un);
    }
};

/// A 3 dimensional perspective frustum.
pub const PerspectiveFrustum3 = extern struct {
    /// The extent at distance `focal_length`.
    sensor: Frustum2,
    /// The near plane.
    near: f32,
    /// The far plane.
    far: f32,
    /// The focal length.
    focal_length: f32,

    pub const FromFovOptions = struct {
        /// The vertical field of view in radians.
        fovy: f32,
        /// The aspect ratio.
        aspect_ratio: f32,
        /// The near plane.
        near: f32,
        /// The far plane.
        far: f32,
        /// The focal length.
        focal_length: f32 = 1.0,
    };

    /// Creates a frustum using a field of view instead of sensor extents.
    pub fn fromFov(options: FromFovOptions) PerspectiveFrustum3 {
        const half_height = @tan(options.fovy * 0.5);
        const half_width = half_height * options.aspect_ratio;
        return .{
            .sensor = .{
                .left = -half_width,
                .right = half_width,
                .top = -half_height,
                .bottom = half_height,
            },
            .near = options.near,
            .far = options.far,
            .focal_length = options.focal_length,
        };
    }

    test fromFov {
        const options: FromFovOptions = .{
            .fovy = std.math.degreesToRadians(60),
            .aspect_ratio = 16.0 / 9.0,
            .near = 0.1,
            .far = 1000.0,
        };
        const m: Mat4 = .perspective(.fromFov(options));
        const g = 1.0 / @tan(options.fovy * 0.5);
        const k = options.far / (options.far - options.near);
        const expected: Mat4 = .{
            .r0 = .{ .x = g / options.aspect_ratio, .y = 0, .z = 0, .w = 0 },
            .r1 = .{ .x = 0.0, .y = g, .z = 0, .w = 0 },
            .r2 = .{ .x = 0.0, .y = 0, .z = k, .w = -options.near * k },
            .r3 = .{ .x = 0.0, .y = 0, .z = 1, .w = 0 },
        };
        try std.testing.expectEqual(expected, m);
    }

    /// Undoes the perspective projection specified by the given frustum on the given normalized
    /// device coordinate to get back a point in view space at the specified depth.
    pub fn unproject(self: PerspectiveFrustum3, ndc: Vec2, view_z: f32) Vec3 {
        const view_xy = ndc.scaled(view_z / self.focal_length);
        return .{
            .x = remap(-1, 1, self.sensor.left, self.sensor.right, view_xy.x),
            .y = remap(-1, 1, self.sensor.top, self.sensor.bottom, view_xy.y),
            .z = view_z,
        };
    }

    test unproject {

        // Focal length of 1
        {
            const f: PerspectiveFrustum3 = .{
                .sensor = .{
                    .left = -2.5,
                    .right = 0.3,
                    .top = 4.1,
                    .bottom = -2.2,
                },
                .near = 0.15,
                .far = 3.2,
                .focal_length = 1,
            };
            const proj: Mat4 = .perspective(f);
            const p_view: Vec3 = .{ .x = 1, .y = 2, .z = 3 };
            const p_ndc = proj.timesPoint(p_view);
            const un = unproject(f, p_ndc.xy(), p_view.z);
            try expectVec3ApproxEql(p_view, un);
        }

        // Focal length of 2
        {
            const f: PerspectiveFrustum3 = .{
                .sensor = .{
                    .left = -2.5,
                    .right = 0.3,
                    .top = 4.1,
                    .bottom = -2.2,
                },
                .near = 0.15,
                .far = 3.2,
                .focal_length = 2,
            };
            const proj = Mat4.perspective(f);
            const p_view: Vec3 = .{ .x = 1, .y = 2, .z = 3 };
            const p_ndc = proj.timesPoint(p_view);
            const un = unproject(f, p_ndc.xy(), p_view.z);
            try expectVec3ApproxEql(p_view, un);
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

fn expectVec4ApproxEql(expected: Vec4, actual: Vec4) !void {
    try std.testing.expectApproxEqAbs(expected.x, actual.x, 0.0001);
    try std.testing.expectApproxEqAbs(expected.y, actual.y, 0.0001);
    try std.testing.expectApproxEqAbs(expected.z, actual.z, 0.0001);
    try std.testing.expectApproxEqAbs(expected.w, actual.w, 0.0001);
}

fn expectMat4ApproxEql(expected: Mat4, actual: Mat4) !void {
    try std.testing.expectApproxEqAbs(expected.r0, actual.r0, 0.0001);
    try std.testing.expectApproxEqAbs(expected.r1, actual.r1, 0.0001);
    try std.testing.expectApproxEqAbs(expected.r2, actual.r2, 0.0001);
    try std.testing.expectApproxEqAbs(expected.r3, actual.r3, 0.0001);
}
