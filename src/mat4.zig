const std = @import("std");
const geom = @import("root.zig");

const Vec2 = geom.Vec2;
const Vec3 = geom.Vec3;
const Vec4 = geom.Vec4;
const Rotor3 = geom.Rotor3;
const Frustum3 = geom.Frustum3;
const Mat3 = geom.Mat3;
const Mat3x4 = geom.Mat3x4;

/// A row major 4x4 matrix.
pub const Mat4 = extern struct {
    /// Row 0, the x basis vector.
    r0: Vec4,
    /// Row 1, the y basis vector.
    r1: Vec4,
    /// Row 2, the z basis vector.
    r2: Vec4,
    /// Row 3, the w basis vector.
    r3: Vec4,

    /// The identity matrix. Has no effect.
    pub const identity: @This() = .{
        .r0 = .{ .x = 1, .y = 0, .z = 0, .w = 0 },
        .r1 = .{ .x = 0, .y = 1, .z = 0, .w = 0 },
        .r2 = .{ .x = 0, .y = 0, .z = 1, .w = 0 },
        .r3 = .{ .x = 0, .y = 0, .z = 0, .w = 1 },
    };

    test identity {
        const p1: Vec3 = .{ .x = 2.0, .y = 3.0, .z = 4.0 };
        const p2: Vec3 = .{ .x = 5.0, .y = -2.0, .z = 6.0 };
        try std.testing.expectEqual(Mat4.identity, Mat4.identity.times(.identity));
        try std.testing.expectEqual(p1, Mat4.identity.timesPoint(p1));
        try std.testing.expectEqual(p2, Mat4.identity.timesPoint(p2));
    }

    /// Checks for equality.
    pub fn eql(self: Mat4, other: Mat4) bool {
        return std.meta.eql(self, other);
    }

    test eql {
        try std.testing.expect(Mat4.identity.eql(Mat4.identity));
        try std.testing.expect(!Mat4.identity.eql(Mat4.translation(.y_pos)));
    }

    /// Extends the affine matrix into a full matrix by appending the missing components from the
    /// identity matrix.
    pub fn fromAffine(m: Mat3x4) Mat4 {
        return .{
            .r0 = m.r0,
            .r1 = m.r1,
            .r2 = m.r2,
            .r3 = identity.r3,
        };
    }

    test fromAffine {
        try std.testing.expectEqual(identity, fromAffine(.identity));
    }

    /// Truncates the matrix into an affine matrix.
    pub fn toAffine(self: Mat4) Mat3x4 {
        return .{
            .r0 = self.r0,
            .r1 = self.r1,
            .r2 = self.r2,
        };
    }

    test toAffine {
        try std.testing.expectEqual(Mat3x4.identity, identity.toAffine());
    }

    /// Returns an orthographic projection matrix that converts from view space to Vulkan/DX12 clip
    /// space.
    pub fn orthoFromFrustum(frustum: Frustum3) Mat4 {
        return .fromAffine(.orthoFromFrustum(frustum));
    }

    test orthoFromFrustum {
        // Left handed ortho frustums
        {
            const f: Frustum3 = .{
                .left = -3.5,
                .right = 0.1,
                .top = 4.2,
                .bottom = -2.3,
                .near = 0.15,
                .far = 3.2,
            };
            const m = orthoFromFrustum(f);

            try expectVec3ApproxEql(
                .{ .x = -1.0, .y = -1.0, .z = 0.0 },
                m.timesPoint(.{ .x = f.left, .y = f.top, .z = f.near }),
            );
            try expectVec3ApproxEql(
                .{ .x = 0.0, .y = 0.0, .z = 0.5 },
                m.timesPoint(.{
                    .x = (f.left + f.right) / 2,
                    .y = (f.bottom + f.top) / 2,
                    .z = (f.near + f.far) / 2,
                }),
            );
            try expectVec3ApproxEql(
                .{ .x = 1.0, .y = 1.0, .z = 1.0 },
                m.timesPoint(.{ .x = f.right, .y = f.bottom, .z = f.far }),
            );
        }

        // Right handed ortho frustums
        {
            const f: Frustum3 = .{
                .left = -3.5,
                .right = 0.1,
                .top = 4.2,
                .bottom = -2.3,
                .near = -0.15,
                .far = -3.2,
            };
            const m = orthoFromFrustum(f);

            try expectVec3ApproxEql(
                .{ .x = -1.0, .y = -1.0, .z = 0.0 },
                m.timesPoint(.{ .x = f.left, .y = f.top, .z = f.near }),
            );
            try expectVec3ApproxEql(
                .{ .x = 0.0, .y = 0.0, .z = 0.5 },
                m.timesPoint(.{
                    .x = (f.left + f.right) / 2,
                    .y = (f.bottom + f.top) / 2,
                    .z = (f.near + f.far) / 2,
                }),
            );
            try expectVec3ApproxEql(
                .{ .x = 1.0, .y = 1.0, .z = 1.0 },
                m.timesPoint(.{ .x = f.right, .y = f.bottom, .z = f.far }),
            );
        }
    }

    /// Returns an perspective projection matrix that converts from view space to Vulkan/DX12 clip
    /// space.
    pub fn perspectiveFromFrustum(frustum: Frustum3) Mat4 {
        var p = orthoFromFrustum(frustum);
        p.r3.z = if (frustum.far > frustum.near) 1 else -1;
        p.r3.w = 0;
        return p;
    }

    test perspectiveFromFrustum {
        const f: Frustum3 = .{
            .left = -2.5,
            .right = 0.2,
            .top = 4.3,
            .bottom = -2.9,
            .near = -1.35,
            .far = 2.1,
        };
        const m = perspectiveFromFrustum(f);
        try expectVec4ApproxEql(
            .{ .x = -1, .y = -1, .z = 0, .w = f.near },
            m.timesVec4(.{ .x = f.left, .y = f.top, .z = f.near, .w = 1 }),
        );
        try expectVec4ApproxEql(
            .{ .x = 0, .y = 0, .z = 0.5, .w = (f.near + f.far) / 2 },
            m.timesVec4(.{
                .x = (f.left + f.right) / 2,
                .y = (f.bottom + f.top) / 2,
                .z = (f.near + f.far) / 2,
                .w = 1,
            }),
        );
        try expectVec4ApproxEql(
            .{ .x = 1, .y = 1, .z = 1, .w = f.far },
            m.timesVec4(.{ .x = f.right, .y = f.bottom, .z = f.far, .w = 1 }),
        );
        try expectVec3ApproxEql(
            .{ .x = 1 / f.far, .y = 1 / f.far, .z = 1 / f.far },
            m.timesPoint(.{ .x = f.right, .y = f.bottom, .z = f.far }),
        );
    }

    /// Create a rotation matrix from a rotor.
    pub fn rotation(rotor: Rotor3) @This() {
        const inverse = rotor.inverse();
        const x = inverse.timesVec3(.x_pos);
        const y = inverse.timesVec3(.y_pos);
        const z = inverse.timesVec3(.z_pos);
        return .{
            .r0 = x.dir(),
            .r1 = y.dir(),
            .r2 = z.dir(),
            .r3 = identity.r3,
        };
    }

    test rotation {
        const m = Mat4.rotation(Rotor3.fromTo(.y_pos, .x_pos).nlerp(.identity, 0.5));
        try std.testing.expectEqual(Vec3.zero, m.getTranslation());

        try std.testing.expectApproxEqAbs(@cos(std.math.pi / 4.0), m.r0.x, 0.01);
        try std.testing.expectApproxEqAbs(@sin(std.math.pi / 4.0), m.r0.y, 0.01);
        try std.testing.expectApproxEqAbs(-@sin(std.math.pi / 4.0), m.r1.x, 0.01);
        try std.testing.expectApproxEqAbs(@cos(std.math.pi / 4.0), m.r1.y, 0.01);

        try expectVec3ApproxEql(
            .y_pos,
            Mat4.rotation(.fromTo(.x_pos, .y_pos)).timesPoint(.x_pos),
        );
        try expectVec3ApproxEql(
            .x_neg,
            Mat4.rotation(.fromTo(.x_pos, .y_pos)).timesPoint(.y_pos),
        );
        try expectVec3ApproxEql(
            .x_pos,
            Mat4.rotation(.fromTo(.x_neg, .x_pos)).timesPoint(.x_neg),
        );
        try expectVec3ApproxEql(
            .y_neg,
            Mat4.rotation(.fromTo(.x_neg, .x_pos)).timesPoint(.y_pos),
        );

        try expectVec3ApproxEql(
            .y_pos,
            Mat4.rotation(.fromTo(.x_pos, .y_pos)).timesDir(.x_pos),
        );
        try expectVec3ApproxEql(
            .x_neg,
            Mat4.rotation(.fromTo(.x_pos, .y_pos)).timesDir(.y_pos),
        );
        try expectVec3ApproxEql(
            .x_pos,
            Mat4.rotation(.fromTo(.x_neg, .x_pos)).timesDir(.x_neg),
        );
        try expectVec3ApproxEql(
            .y_neg,
            Mat4.rotation(.fromTo(.x_neg, .x_pos)).timesDir(.y_pos),
        );

        try expectVec3ApproxEql(
            .y_pos,
            Mat4.rotation(.fromTo(.z_pos, .y_pos)).timesPoint(.z_pos),
        );
        try expectVec3ApproxEql(
            .z_neg,
            Mat4.rotation(.fromTo(.z_pos, .y_pos)).timesPoint(.y_pos),
        );
        try expectVec3ApproxEql(
            .z_pos,
            Mat4.rotation(.fromTo(.z_neg, .z_pos)).timesPoint(.z_neg),
        );
        try expectVec3ApproxEql(
            .z_pos,
            Mat4.rotation(.fromTo(.y_pos, .y_neg)).timesPoint(.z_pos),
        );

        try expectVec3ApproxEql(
            .x_pos,
            Mat4.rotation(.fromTo(.z_pos, .x_pos)).timesPoint(.z_pos),
        );
        try expectVec3ApproxEql(
            .z_neg,
            Mat4.rotation(.fromTo(.z_pos, .x_pos)).timesPoint(.x_pos),
        );
        try expectVec3ApproxEql(
            .z_pos,
            Mat4.rotation(.fromTo(.x_pos, .x_neg)).timesPoint(.z_pos),
        );
    }

    pub fn rotated(self: @This(), rotor: Rotor3) @This() {
        return rotation(rotor).times(self);
    }

    test rotated {
        const r: Rotor3 = .fromTo(.x_pos, .z_pos);
        try std.testing.expectEqual(
            rotation(r).times(.identity),
            identity.rotated(r),
        );
    }

    /// Create a translation matrix from a vector.
    pub fn translation(delta: Vec3) @This() {
        return .{
            .r0 = .{ .x = 1, .y = 0, .z = 0, .w = delta.x },
            .r1 = .{ .x = 0, .y = 1, .z = 0, .w = delta.y },
            .r2 = .{ .x = 0, .y = 0, .z = 1, .w = delta.z },
            .r3 = .{ .x = 0, .y = 0, .z = 0, .w = 1 },
        };
    }

    test translation {
        try std.testing.expectEqual(Mat4{
            .r0 = .{ .x = 1, .y = 0, .z = 0, .w = 1 },
            .r1 = .{ .x = 0, .y = 1, .z = 0, .w = 2 },
            .r2 = .{ .x = 0, .y = 0, .z = 1, .w = 3 },
            .r3 = .{ .x = 0, .y = 0, .z = 0, .w = 1 },
        }, Mat4.translation(.{ .x = 1, .y = 2, .z = 3 }));
        try std.testing.expectEqual(
            Vec3{ .x = 3, .y = 5, .z = 7 },
            Mat4.translation(.{ .x = 1, .y = 2, .z = 3 }).timesPoint(.{ .x = 2, .y = 3, .z = 4 }),
        );
        try std.testing.expectEqual(
            Vec3{ .x = 7, .y = 5, .z = 6 },
            Mat4.translation(.{ .x = -1, .y = 3, .z = 5 }).timesPoint(.{ .x = 8, .y = 2, .z = 1 }),
        );
        try std.testing.expectEqual(
            Vec3{ .x = 2, .y = 3, .z = -1 },
            Mat4.translation(.{ .x = 1, .y = 2, .z = 4 }).timesDir(.{ .x = 2, .y = 3, .z = -1 }),
        );
        try std.testing.expectEqual(
            Vec3{ .x = 8, .y = 2, .z = -1 },
            Mat4.translation(.{ .x = -1, .y = 3, .z = 4 }).timesDir(.{ .x = 8, .y = 2, .z = -1 }),
        );
    }

    pub fn translated(self: @This(), delta: Vec3) @This() {
        return translation(delta).times(self);
    }

    test translated {
        try std.testing.expectEqual(Mat4{
            .r0 = .{ .x = 1, .y = 0, .z = 0, .w = 1 },
            .r1 = .{ .x = 0, .y = 1, .z = 0, .w = 2 },
            .r2 = .{ .x = 0, .y = 0, .z = 1, .w = 3 },
            .r3 = .{ .x = 0, .y = 0, .z = 0, .w = 1 },
        }, identity.translated(.{ .x = 1, .y = 2, .z = 3 }));
    }

    /// Create a scale matrix from a vector.
    pub fn scale(amount: Vec3) Mat4 {
        return .{
            .r0 = .{ .x = amount.x, .y = 0, .z = 0, .w = 0 },
            .r1 = .{ .x = 0, .y = amount.y, .z = 0, .w = 0 },
            .r2 = .{ .x = 0, .y = 0, .z = amount.z, .w = 0 },
            .r3 = .{ .x = 0, .y = 0, .z = 0, .w = 1 },
        };
    }

    test scale {
        try std.testing.expectEqual(
            Mat4{
                .r0 = .{ .x = 0.5, .y = 0.0, .z = 0.0, .w = 0.0 },
                .r1 = .{ .x = 0.0, .y = 1.7, .z = 0.0, .w = 0.0 },
                .r2 = .{ .x = 0.0, .y = 0.0, .z = 1.1, .w = 0.0 },
                .r3 = .{ .x = 0.0, .y = 0.0, .z = 0.0, .w = 1.0 },
            },
            Mat4.scale(.{ .x = 0.5, .y = 1.7, .z = 1.1 }),
        );
        try std.testing.expectEqual(
            Vec3{ .x = 0.5, .y = -6.0, .z = 50.0 },
            Mat4.scale(.{ .x = 0.5, .y = -2.0, .z = 10.0 })
                .timesPoint(.{ .x = 1.0, .y = 3.0, .z = 5.0 }),
        );
        try std.testing.expectEqual(
            Vec3{ .x = 0.5, .y = -6.0, .z = 10.0 },
            Mat4.scale(.{ .x = 0.5, .y = -2.0, .z = 5.0 })
                .timesDir(.{ .x = 1.0, .y = 3.0, .z = 2.0 }),
        );
        try std.testing.expectEqual(Vec3.zero, Mat4.scale(.{ .x = 0.5, .y = -2.0, .z = 1.5 }).getTranslation());
    }

    pub fn scaled(self: @This(), delta: Vec3) @This() {
        return scale(delta).times(self);
    }

    test scaled {
        try std.testing.expectEqual(
            Mat4{
                .r0 = .{ .x = 0.5, .y = 0.0, .z = 0.0, .w = 0.0 },
                .r1 = .{ .x = 0.0, .y = 1.7, .z = 0.0, .w = 0.0 },
                .r2 = .{ .x = 0.0, .y = 0.0, .z = 1.1, .w = 0.0 },
                .r3 = .{ .x = 0.0, .y = 0.0, .z = 0.0, .w = 1.0 },
            },
            Mat4.scale(.{ .x = 0.5, .y = 1.7, .z = 1.1 }),
        );
        try std.testing.expectEqual(
            Vec3{ .x = 0.5, .y = -6.0, .z = 50.0 },
            Mat4.identity.scaled(.{ .x = 0.5, .y = -2.0, .z = 10.0 })
                .timesPoint(.{ .x = 1.0, .y = 3.0, .z = 5.0 }),
        );
        try std.testing.expectEqual(
            Vec3{ .x = 0.5, .y = -6.0, .z = 10.0 },
            Mat4.identity.scaled(.{ .x = 0.5, .y = -2.0, .z = 5.0 })
                .timesDir(.{ .x = 1.0, .y = 3.0, .z = 2.0 }),
        );
        try std.testing.expectEqual(Vec3.zero, Mat4.scale(.{ .x = 0.5, .y = -2.0, .z = 1.5 }).getTranslation());
    }

    test "rotatedTranslatedScaled" {
        var m = Mat4.identity;
        m = m.translated(.y_pos);
        m = m.rotated(.fromPlaneAngle(.yx_plane, std.math.pi));
        m = m.scaled(.splat(0.5));
        m = m.translated(.{ .x = 0.0, .y = 0.5, .z = 0.0 });
        try expectVec3ApproxEql(.{ .x = 0.0, .y = 0.0, .z = 0.0 }, m.timesPoint(.zero));
    }

    pub fn times(lhs: Mat4, rhs: Mat4) Mat4 {
        const V4 = @Vector(4, f32);

        const f: V4 = .{ rhs.r2.x, rhs.r2.y, rhs.r2.z, rhs.r2.w };
        const h: V4 = .{ rhs.r3.x, rhs.r3.y, rhs.r3.z, rhs.r3.w };
        const d: V4 = .{ rhs.r1.x, rhs.r1.y, rhs.r1.z, rhs.r1.w };
        const b: V4 = .{ rhs.r0.x, rhs.r0.y, rhs.r0.z, rhs.r0.w };
        const r0 = b: {
            const e: V4 = @splat(lhs.r0.z);
            const g: V4 = @splat(lhs.r0.w);
            const temp2 = @mulAdd(V4, e, f, g * h);

            const c: V4 = @splat(lhs.r0.y);
            const temp = @mulAdd(V4, c, d, temp2);

            const a: V4 = @splat(lhs.r0.x);
            break :b @mulAdd(V4, a, b, temp);
        };
        const r1 = b: {
            const e: V4 = @splat(lhs.r1.z);
            const g: V4 = @splat(lhs.r1.w);
            const temp2 = @mulAdd(V4, e, f, g * h);

            const c: V4 = @splat(lhs.r1.y);
            const temp = @mulAdd(V4, c, d, temp2);

            const a: V4 = @splat(lhs.r1.x);
            break :b @mulAdd(V4, a, b, temp);
        };
        const r2 = b: {
            const e: V4 = @splat(lhs.r2.z);
            const g: V4 = @splat(lhs.r2.w);
            const temp2 = @mulAdd(V4, e, f, g * h);

            const c: V4 = @splat(lhs.r2.y);
            const temp = @mulAdd(V4, c, d, temp2);

            const a: V4 = @splat(lhs.r2.x);
            break :b @mulAdd(V4, a, b, temp);
        };
        const r3 = b: {
            const e: V4 = @splat(lhs.r3.z);
            const g: V4 = @splat(lhs.r3.w);
            const temp2 = @mulAdd(V4, e, f, g * h);

            const c: V4 = @splat(lhs.r3.y);
            const temp = @mulAdd(V4, c, d, temp2);

            const a: V4 = @splat(lhs.r3.x);
            break :b @mulAdd(V4, a, b, temp);
        };
        return .{
            .r0 = .{ .x = r0[0], .y = r0[1], .z = r0[2], .w = r0[3] },
            .r1 = .{ .x = r1[0], .y = r1[1], .z = r1[2], .w = r1[3] },
            .r2 = .{ .x = r2[0], .y = r2[1], .z = r2[2], .w = r2[3] },
            .r3 = .{ .x = r3[0], .y = r3[1], .z = r3[2], .w = r3[3] },
        };
    }

    test times {
        const t: Mat4 = .translation(.{ .x = 1.0, .y = 2.0, .z = 3.0 });
        const r: Mat4 = .rotation(.fromTo(.y_pos, .x_pos));
        const s: Mat4 = .scale(.{ .x = 0.5, .y = 3.0, .z = 4.0 });

        {
            const a: Mat4 = .{
                .r0 = .{ .x = 1, .y = 2, .z = 3, .w = 4 },
                .r1 = .{ .x = 5, .y = 6, .z = 7, .w = 8 },
                .r2 = .{ .x = 9, .y = 10, .z = 11, .w = 12 },
                .r3 = .{ .x = 13, .y = 14, .z = 15, .w = 16 },
            };
            const b: Mat4 = .{
                .r0 = .{ .x = 10, .y = 20, .z = 30, .w = 40 },
                .r1 = .{ .x = 50, .y = 60, .z = 70, .w = 80 },
                .r2 = .{ .x = 90, .y = 100, .z = 110, .w = 120 },
                .r3 = .{ .x = 130, .y = 140, .z = 150, .w = 160 },
            };
            try std.testing.expectEqual(
                Mat4{
                    .r0 = .{ .x = 900, .y = 1000, .z = 1100, .w = 1200 },
                    .r1 = .{ .x = 2020, .y = 2280, .z = 2540, .w = 2800 },
                    .r2 = .{ .x = 3140, .y = 3560, .z = 3980, .w = 4400 },
                    .r3 = .{ .x = 4260, .y = 4840, .z = 5420, .w = 6000 },
                },
                a.times(b),
            );
        }

        {
            var m: Mat4 = .identity;
            m = t.times(m);
            m = r.times(m);
            m = s.times(m);

            try expectVec3ApproxEql(Vec3{ .x = 1.0, .y = -3.0, .z = 12.0 }, m.timesPoint(.zero));
            try expectVec3ApproxEql(Vec3{ .x = 0.0, .y = 0.0, .z = 0.0 }, m.timesDir(.zero));

            try expectVec3ApproxEql(Vec3{ .x = 1.5, .y = -3.0, .z = 12.0 }, m.timesPoint(.y_pos));
            try expectVec3ApproxEql(Vec3{ .x = 0.5, .y = 0.0, .z = 0.0 }, m.timesDir(.y_pos));
        }

        {
            const m = s.times(r).times(t);

            try expectVec3ApproxEql(Vec3{ .x = 1.0, .y = -3.0, .z = 12.0 }, m.timesPoint(.zero));
            try expectVec3ApproxEql(Vec3{ .x = 0.0, .y = 0.0, .z = 0 }, m.timesDir(.zero));

            try expectVec3ApproxEql(Vec3{ .x = 1.5, .y = -3.0, .z = 12.0 }, m.timesPoint(.y_pos));
            try expectVec3ApproxEql(Vec3{ .x = 0.5, .y = 0.0, .z = 0.0 }, m.timesDir(.y_pos));
        }
    }

    /// Multiplies the matrix by `other`.
    pub fn mul(self: *@This(), other: @This()) void {
        self.* = self.times(other);
    }

    test mul {
        const t: Mat4 = .translation(.{ .x = 1.0, .y = 2.0, .z = 3.0 });
        const r: Mat4 = .rotation(.fromTo(.y_pos, .x_pos));
        const s: Mat4 = .scale(.{ .x = 0.5, .y = 3.0, .z = 4.0 });

        var m: Mat4 = .identity;
        m.mul(s);
        m.mul(r);
        m.mul(t);

        try expectVec3ApproxEql(Vec3{ .x = 1.0, .y = -3.0, .z = 12.0 }, m.timesPoint(.zero));
        try expectVec3ApproxEql(Vec3{ .x = 0.0, .y = 0.0, .z = 0.0 }, m.timesDir(.zero));

        try expectVec3ApproxEql(Vec3{ .x = 1.5, .y = -3.0, .z = 12.0 }, m.timesPoint(.y_pos));
        try expectVec3ApproxEql(Vec3{ .x = 0.5, .y = 0.0, .z = 0.0 }, m.timesDir(.y_pos));
    }

    /// The same as `times`, but the arguments are reversed. This is often more intuitive and less
    /// verbose.
    pub fn applied(self: @This(), other: @This()) @This() {
        return other.times(self);
    }

    test applied {
        const t: Mat4 = .translation(.{ .x = 1.0, .y = 2.0, .z = 3.0 });
        const r: Mat4 = .rotation(.fromTo(.y_pos, .x_pos));
        const s: Mat4 = .scale(.{ .x = 0.5, .y = 3.0, .z = 4.0 });

        const m = t.applied(r).applied(s);

        try expectVec3ApproxEql(Vec3{ .x = 1.0, .y = -3.0, .z = 12.0 }, m.timesPoint(.zero));
        try expectVec3ApproxEql(Vec3{ .x = 0.0, .y = 0.0, .z = 0.0 }, m.timesDir(.zero));

        try expectVec3ApproxEql(Vec3{ .x = 1.5, .y = -3.0, .z = 12.0 }, m.timesPoint(.y_pos));
        try expectVec3ApproxEql(Vec3{ .x = 0.5, .y = 0.0, .z = 0.0 }, m.timesDir(.y_pos));
    }

    /// The same as `mul`, but the arguments are reversed. This is often more intuitive and less
    /// verbose.
    pub fn apply(self: *@This(), other: @This()) void {
        self.* = self.applied(other);
    }

    test apply {
        const t: Mat4 = .translation(.{ .x = 1.0, .y = 2.0, .z = 3.0 });
        const r: Mat4 = .rotation(.fromTo(.y_pos, .x_pos));
        const s: Mat4 = .scale(.{ .x = 0.5, .y = 3.0, .z = 4.0 });

        var m: Mat4 = .identity;
        m.apply(t);
        m.apply(r);
        m.apply(s);

        try expectVec3ApproxEql(Vec3{ .x = 1.0, .y = -3.0, .z = 12.0 }, m.timesPoint(.zero));
        try expectVec3ApproxEql(Vec3{ .x = 0.0, .y = 0.0, .z = 0.0 }, m.timesDir(.zero));

        try expectVec3ApproxEql(Vec3{ .x = 1.5, .y = -3.0, .z = 12.0 }, m.timesPoint(.y_pos));
        try expectVec3ApproxEql(Vec3{ .x = 0.5, .y = 0.0, .z = 0.0 }, m.timesDir(.y_pos));
    }

    /// Extracts the translation component of the matrix.
    pub fn getTranslation(self: @This()) Vec3 {
        return .{ .x = self.r0.w, .y = self.r1.w, .z = self.r2.w };
    }

    test getTranslation {
        const r: Mat4 = .translation(.{ .x = 1, .y = 2, .z = 3 });
        try std.testing.expectEqual(Vec3{ .x = 1, .y = 2, .z = 3 }, r.getTranslation());
    }

    /// Extracts the rotation matrix. Note that `Mat3` is typically used as a homogeneous 2d matrix,
    /// but this result treats it as just a 3d matrix.
    pub fn getRot(self: Mat4) Mat3 {
        return .{
            .r0 = .{ .x = self.r0.x, .y = self.r0.y, .z = self.r0.z },
            .r1 = .{ .x = self.r1.x, .y = self.r1.y, .z = self.r1.z },
            .r2 = .{ .x = self.r2.x, .y = self.r2.y, .z = self.r2.z },
        };
    }

    test getRot {
        const r: Rotor3 = .fromTo(.{ .x = 1, .y = 2, .z = 3 }, .{ .x = 3, .y = 4, .z = 5 });
        const a: Mat4 = .rotation(r);
        const p: Vec3 = .{ .x = 1, .y = 2, .z = 1 };
        try expectVec2ApproxEql(
            a.timesPoint(p).toCartesian(),
            a.getRot().timesVec3(p).toCartesian(),
        );
    }

    /// Gets the scale of the matrix.
    pub fn getScale(self: @This()) Vec3 {
        return .{ .x = self.r0.x, .y = self.r1.y, .z = self.r2.z };
    }

    test getScale {
        const s: Vec3 = .{ .x = 2, .y = 3, .z = 4 };
        try std.testing.expectEqual(s, scale(s).getScale());
    }

    /// Returns a vector representing a point transformed by this matrix.
    pub fn timesPoint(self: @This(), v: Vec3) Vec3 {
        // Inlining this to remove the multiplication by one doesn't improve benchmark performance.
        return self.timesVec4(v.point()).toCartesian();
    }

    test timesPoint {
        const p1: Vec3 = .{ .x = 2.0, .y = 3.0, .z = 4.0 };
        try std.testing.expectEqual(p1, Mat4.identity.timesPoint(p1));
        try std.testing.expectEqual(
            Vec3{ .x = 3, .y = 5, .z = 7 },
            Mat4.translation(.{ .x = 1, .y = 2, .z = 3 }).timesPoint(p1),
        );
    }

    /// Returns a vector representing a direction transformed by this matrix.
    pub fn timesDir(self: @This(), v: Vec3) Vec3 {
        // This is slightly faster in the benchmarks than my attempt to inline and hand optimize it.
        return self.timesVec4(v.dir()).xyz();
    }

    test timesDir {
        try expectVec3ApproxEql(
            Vec3.y_pos,
            Mat4.rotation(.fromTo(.x_pos, .y_pos)).timesDir(.x_pos),
        );
        const p1: Vec3 = .{ .x = 2.0, .y = 3.0, .z = 4.0 };
        try std.testing.expectEqual(p1, Mat4.translation(.{ .x = 1, .y = 2, .z = 3 }).timesDir(p1));
    }

    /// Multiplies the matrix by a homogeneous vec4.
    pub fn timesVec4(self: @This(), v: Vec4) Vec4 {
        return .{
            .x = self.r0.innerProd(v),
            .y = self.r1.innerProd(v),
            .z = self.r2.innerProd(v),
            .w = self.r3.innerProd(v),
        };
    }

    test timesVec4 {
        try expectVec4ApproxEql(
            Vec4.y_pos,
            Mat4.rotation(.fromTo(.x_pos, .y_pos)).timesVec4(.x_pos),
        );
    }

    /// Returns the transpose of the matrix. For pure rotation matrices, the transpose is equivalent
    /// to the inverse.
    pub fn transposed(self: @This()) Mat4 {
        return .{
            .r0 = .{ .x = self.r0.x, .y = self.r1.x, .z = self.r2.x, .w = self.r3.x },
            .r1 = .{ .x = self.r0.y, .y = self.r1.y, .z = self.r2.y, .w = self.r3.y },
            .r2 = .{ .x = self.r0.z, .y = self.r1.z, .z = self.r2.z, .w = self.r3.z },
            .r3 = .{ .x = self.r0.w, .y = self.r1.w, .z = self.r2.w, .w = self.r3.w },
        };
    }

    test transposed {
        const m: Mat4 = .{
            .r0 = .{ .x = 1, .y = 2, .z = 3, .w = 4 },
            .r1 = .{ .x = 5, .y = 6, .z = 7, .w = 8 },
            .r2 = .{ .x = 9, .y = 10, .z = 11, .w = 12 },
            .r3 = .{ .x = 13, .y = 14, .z = 15, .w = 16 },
        };
        const t: Mat4 = .{
            .r0 = .{ .x = 1, .y = 5, .z = 9, .w = 13 },
            .r1 = .{ .x = 2, .y = 6, .z = 10, .w = 14 },
            .r2 = .{ .x = 3, .y = 7, .z = 11, .w = 15 },
            .r3 = .{ .x = 4, .y = 8, .z = 12, .w = 16 },
        };
        try std.testing.expectEqual(t, m.transposed());

        const r = rotation(.fromTo(
            .{ .x = 1, .y = 2, .z = 3 },
            .{ .x = 4, .y = 5, .z = 6 },
        ));
        try expectMat4ApproxEq(identity, r.times(r.transposed()));
    }

    /// Transposes the matrix. For pure rotation matrices, the transpose is equivalent to the
    /// inverse.
    pub fn transpose(self: *@This()) void {
        self.* = self.transposed();
    }

    test transpose {
        var m: Mat4 = .{
            .r0 = .{ .x = 1, .y = 2, .z = 3, .w = 4 },
            .r1 = .{ .x = 5, .y = 6, .z = 7, .w = 8 },
            .r2 = .{ .x = 9, .y = 10, .z = 11, .w = 12 },
            .r3 = .{ .x = 13, .y = 14, .z = 15, .w = 16 },
        };
        m.transpose();
        const t: Mat4 = .{
            .r0 = .{ .x = 1, .y = 5, .z = 9, .w = 13 },
            .r1 = .{ .x = 2, .y = 6, .z = 10, .w = 14 },
            .r2 = .{ .x = 3, .y = 7, .z = 11, .w = 15 },
            .r3 = .{ .x = 4, .y = 8, .z = 12, .w = 16 },
        };
        try std.testing.expectEqual(m, t);
    }

    /// Returns the inverse of a rotation translation matrix.
    pub fn inverseRt(self: Mat4) Mat4 {
        return .fromAffine(self.toAffine().inverseRt());
    }

    test inverseRt {
        const m = translation(.{ .x = 1, .y = 2, .z = 3 })
            .times(rotation(.fromTo(.{ .x = 3, .y = 4, .z = 5 }, .{ .x = 5, .y = 6, .z = 7 })))
            .times(translation(.{ .x = 7, .y = 8, .z = 9 }))
            .times(rotation(.fromTo(.{ .x = -9, .y = 10, .z = 11 }, .{ .x = -11, .y = 12, .z = 13 })));
        const i = m.inverseRt();
        try expectMat4ApproxEq(identity, m.times(i));
    }

    /// Inverts a rotation translation matrix.
    pub fn invertRt(self: *Mat4) void {
        self.* = self.inverseRt();
    }

    test invertRt {
        const m = translation(.{ .x = 1, .y = 2, .z = 3 })
            .times(rotation(.fromTo(.{ .x = 3, .y = 4, .z = 5 }, .{ .x = 5, .y = 6, .z = 7 })))
            .times(translation(.{ .x = 7, .y = 8, .z = 9 }))
            .times(rotation(.fromTo(.{ .x = -9, .y = 10, .z = 11 }, .{ .x = -11, .y = 12, .z = 13 })));
        var i = m;
        i.invertRt();
        try expectMat4ApproxEq(identity, m.times(i));
    }

    /// Returns the inverse of a translate scale matrix. Useful for inverting orthographic
    /// projections.
    pub fn inverseTs(self: Mat4) Mat4 {
        return .fromAffine(self.toAffine().inverseTs());
    }

    test inverseTs {
        const m = orthoFromFrustum(.{
            .left = -2.5,
            .right = 0.3,
            .top = 4.1,
            .bottom = -2.2,
            .near = 0.15,
            .far = 3.2,
        });
        try expectMat4ApproxEq(identity, m.times(m.inverseTs()));
    }

    /// Inverts a translate scale matrix. Useful for inverting orthographic projections.
    pub fn invertTs(self: *Mat4) void {
        self.* = self.inverseTs();
    }

    test invertTs {
        const m = orthoFromFrustum(.{
            .left = -2.5,
            .right = 0.3,
            .top = 4.1,
            .bottom = -2.2,
            .near = 0.15,
            .far = 3.2,
        });
        var i = m;
        i.invertTs();
        try expectMat4ApproxEq(identity, m.times(i));
    }
};

fn expectMat4ApproxEq(lhs: Mat4, rhs: Mat4) !void {
    try expectVec4ApproxEql(lhs.r0, rhs.r0);
    try expectVec4ApproxEql(lhs.r1, rhs.r1);
    try expectVec4ApproxEql(lhs.r2, rhs.r2);
    try expectVec4ApproxEql(lhs.r3, rhs.r3);
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

fn expectVec4ApproxEql(expected: Vec4, actual: Vec4) !void {
    try std.testing.expectApproxEqAbs(expected.x, actual.x, 0.0001);
    try std.testing.expectApproxEqAbs(expected.y, actual.y, 0.0001);
    try std.testing.expectApproxEqAbs(expected.z, actual.z, 0.0001);
    try std.testing.expectApproxEqAbs(expected.w, actual.w, 0.0001);
}
