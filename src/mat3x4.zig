const std = @import("std");
const geom = @import("root.zig");

const Vec3 = geom.Vec3;
const Vec4 = geom.Vec4;
const Rotor3 = geom.Rotor3;
const Frustum3 = geom.Frustum3;
const Mat2x3 = geom.Mat2x3;
const Mat4 = geom.Mat4;

/// A row major affine transformation matrix for working in three dimensions.
pub const Mat3x4 = extern struct {
    /// Row 0, the x basis vector.
    r0: Vec4,
    /// Row 1, the y basis vector.
    r1: Vec4,
    /// Row 2, the z basis vector.
    r2: Vec4,

    /// The identity matrix. Has no effect.
    pub const identity: @This() = .{
        .r0 = .{ .x = 1, .y = 0, .z = 0, .w = 0 },
        .r1 = .{ .x = 0, .y = 1, .z = 0, .w = 0 },
        .r2 = .{ .x = 0, .y = 0, .z = 1, .w = 0 },
    };

    test identity {
        const p1: Vec3 = .{ .x = 2.0, .y = 3.0, .z = 4.0 };
        const p2: Vec3 = .{ .x = 5.0, .y = -2.0, .z = 6.0 };
        try std.testing.expectEqual(Mat3x4.identity, Mat3x4.identity.times(.identity));
        try std.testing.expectEqual(p1, Mat3x4.identity.timesPoint(p1));
        try std.testing.expectEqual(p2, Mat3x4.identity.timesPoint(p2));
    }

    /// Checks for equality.
    pub fn eql(self: Mat3x4, other: Mat3x4) bool {
        return std.meta.eql(self, other);
    }

    test eql {
        try std.testing.expect(Mat3x4.identity.eql(Mat3x4.identity));
        try std.testing.expect(!Mat3x4.identity.eql(Mat3x4.translation(.y_pos)));
    }

    /// Extends the matrix by appending the missing components from the identity matrix.
    pub fn fromMat2x3(m: Mat2x3) Mat3x4 {
        return .{
            .r0 = m.r0.withW(0),
            .r1 = m.r1.withW(0),
            .r2 = identity.r2,
        };
    }

    test fromMat2x3 {
        try std.testing.expectEqual(identity, fromMat2x3(.identity));
    }

    /// Truncates the matrix.
    pub fn fromMat4(m: Mat4) Mat3x4 {
        return .{
            .r0 = m.r0,
            .r1 = m.r1,
            .r2 = m.r2,
        };
    }

    test fromMat4 {
        try std.testing.expectEqual(identity, fromMat4(.identity));
    }

    /// Truncates the matrix.
    pub fn toMat2x3(self: Mat3x4) Mat2x3 {
        return .fromMat3x4(self);
    }

    test toMat2x3 {
        try std.testing.expectEqual(Mat2x3.identity, identity.toMat2x3());
    }

    /// Extends the matrix by appending the missing components from the identity matrix.
    pub fn toMat4(self: Mat3x4) Mat4 {
        return .fromMat3x4(self);
    }

    test toMat4 {
        try std.testing.expectEqual(Mat4.identity, identity.toMat4());
    }

    /// Returns an orthographic projection matrix that converts from view space to Vulkan/DX12 clip
    /// space. The far plane may be infinite.
    pub fn orthoFromFrustum(frustum: Frustum3) Mat3x4 {
        const width = frustum.right - frustum.left;
        const height = frustum.bottom - frustum.top;
        const depth = frustum.far - frustum.near;
        const x_scale = 2 / width;
        const y_scale = 2 / height;
        const z_scale = 1.0 / depth;
        const x_off = -(frustum.right + frustum.left) / width;
        const y_off = -(frustum.top + frustum.bottom) / height;
        const z_off = -frustum.near * z_scale;
        return .{
            .r0 = .{ .x = x_scale, .y = 0, .z = 0, .w = x_off },
            .r1 = .{ .x = 0, .y = y_scale, .z = 0, .w = y_off },
            .r2 = .{ .x = 0, .y = 0, .z = z_scale, .w = z_off },
        };
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
        };
    }

    test rotation {
        const m = Mat3x4.rotation(Rotor3.fromTo(.y_pos, .x_pos).nlerp(.identity, 0.5));
        try std.testing.expectEqual(Vec3.zero, m.getTranslation());

        try std.testing.expectApproxEqAbs(@cos(std.math.pi / 4.0), m.r0.x, 0.01);
        try std.testing.expectApproxEqAbs(@sin(std.math.pi / 4.0), m.r0.y, 0.01);
        try std.testing.expectApproxEqAbs(-@sin(std.math.pi / 4.0), m.r1.x, 0.01);
        try std.testing.expectApproxEqAbs(@cos(std.math.pi / 4.0), m.r1.y, 0.01);

        try expectVec3ApproxEql(
            .y_pos,
            Mat3x4.rotation(.fromTo(.x_pos, .y_pos)).timesPoint(.x_pos),
        );
        try expectVec3ApproxEql(
            .x_neg,
            Mat3x4.rotation(.fromTo(.x_pos, .y_pos)).timesPoint(.y_pos),
        );
        try expectVec3ApproxEql(
            .x_pos,
            Mat3x4.rotation(.fromTo(.x_neg, .x_pos)).timesPoint(.x_neg),
        );
        try expectVec3ApproxEql(
            .y_neg,
            Mat3x4.rotation(.fromTo(.x_neg, .x_pos)).timesPoint(.y_pos),
        );

        try expectVec3ApproxEql(
            .y_pos,
            Mat3x4.rotation(.fromTo(.x_pos, .y_pos)).timesDir(.x_pos),
        );
        try expectVec3ApproxEql(
            .x_neg,
            Mat3x4.rotation(.fromTo(.x_pos, .y_pos)).timesDir(.y_pos),
        );
        try expectVec3ApproxEql(
            .x_pos,
            Mat3x4.rotation(.fromTo(.x_neg, .x_pos)).timesDir(.x_neg),
        );
        try expectVec3ApproxEql(
            .y_neg,
            Mat3x4.rotation(.fromTo(.x_neg, .x_pos)).timesDir(.y_pos),
        );

        try expectVec3ApproxEql(
            .y_pos,
            Mat3x4.rotation(.fromTo(.z_pos, .y_pos)).timesPoint(.z_pos),
        );
        try expectVec3ApproxEql(
            .z_neg,
            Mat3x4.rotation(.fromTo(.z_pos, .y_pos)).timesPoint(.y_pos),
        );
        try expectVec3ApproxEql(
            .z_pos,
            Mat3x4.rotation(.fromTo(.z_neg, .z_pos)).timesPoint(.z_neg),
        );
        try expectVec3ApproxEql(
            .z_pos,
            Mat3x4.rotation(.fromTo(.y_pos, .y_neg)).timesPoint(.z_pos),
        );

        try expectVec3ApproxEql(
            .x_pos,
            Mat3x4.rotation(.fromTo(.z_pos, .x_pos)).timesPoint(.z_pos),
        );
        try expectVec3ApproxEql(
            .z_neg,
            Mat3x4.rotation(.fromTo(.z_pos, .x_pos)).timesPoint(.x_pos),
        );
        try expectVec3ApproxEql(
            .z_pos,
            Mat3x4.rotation(.fromTo(.x_pos, .x_neg)).timesPoint(.z_pos),
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
        };
    }

    test translation {
        try std.testing.expectEqual(Mat3x4{
            .r0 = .{ .x = 1, .y = 0, .z = 0, .w = 1 },
            .r1 = .{ .x = 0, .y = 1, .z = 0, .w = 2 },
            .r2 = .{ .x = 0, .y = 0, .z = 1, .w = 3 },
        }, Mat3x4.translation(.{ .x = 1, .y = 2, .z = 3 }));
        try std.testing.expectEqual(
            Vec3{ .x = 3, .y = 5, .z = 7 },
            Mat3x4.translation(.{ .x = 1, .y = 2, .z = 3 }).timesPoint(.{ .x = 2, .y = 3, .z = 4 }),
        );
        try std.testing.expectEqual(
            Vec3{ .x = 7, .y = 5, .z = 6 },
            Mat3x4.translation(.{ .x = -1, .y = 3, .z = 5 }).timesPoint(.{ .x = 8, .y = 2, .z = 1 }),
        );
        try std.testing.expectEqual(
            Vec3{ .x = 2, .y = 3, .z = -1 },
            Mat3x4.translation(.{ .x = 1, .y = 2, .z = 4 }).timesDir(.{ .x = 2, .y = 3, .z = -1 }),
        );
        try std.testing.expectEqual(
            Vec3{ .x = 8, .y = 2, .z = -1 },
            Mat3x4.translation(.{ .x = -1, .y = 3, .z = 4 }).timesDir(.{ .x = 8, .y = 2, .z = -1 }),
        );
    }

    pub fn translated(self: @This(), delta: Vec3) @This() {
        return translation(delta).times(self);
    }

    test translated {
        try std.testing.expectEqual(Mat3x4{
            .r0 = .{ .x = 1, .y = 0, .z = 0, .w = 1 },
            .r1 = .{ .x = 0, .y = 1, .z = 0, .w = 2 },
            .r2 = .{ .x = 0, .y = 0, .z = 1, .w = 3 },
        }, identity.translated(.{ .x = 1, .y = 2, .z = 3 }));
    }

    /// Create a scale matrix from a vector.
    pub fn scale(amount: Vec3) Mat3x4 {
        return .{
            .r0 = .{ .x = amount.x, .y = 0, .z = 0, .w = 0 },
            .r1 = .{ .x = 0, .y = amount.y, .z = 0, .w = 0 },
            .r2 = .{ .x = 0, .y = 0, .z = amount.z, .w = 0 },
        };
    }

    test scale {
        try std.testing.expectEqual(
            Mat3x4{
                .r0 = .{ .x = 0.5, .y = 0.0, .z = 0.0, .w = 0.0 },
                .r1 = .{ .x = 0.0, .y = 1.7, .z = 0.0, .w = 0.0 },
                .r2 = .{ .x = 0.0, .y = 0.0, .z = 1.1, .w = 0.0 },
            },
            Mat3x4.scale(.{ .x = 0.5, .y = 1.7, .z = 1.1 }),
        );
        try std.testing.expectEqual(
            Vec3{ .x = 0.5, .y = -6.0, .z = 50.0 },
            Mat3x4.scale(.{ .x = 0.5, .y = -2.0, .z = 10.0 })
                .timesPoint(.{ .x = 1.0, .y = 3.0, .z = 5.0 }),
        );
        try std.testing.expectEqual(
            Vec3{ .x = 0.5, .y = -6.0, .z = 10.0 },
            Mat3x4.scale(.{ .x = 0.5, .y = -2.0, .z = 5.0 })
                .timesDir(.{ .x = 1.0, .y = 3.0, .z = 2.0 }),
        );
        try std.testing.expectEqual(Vec3.zero, Mat3x4.scale(.{ .x = 0.5, .y = -2.0, .z = 1.5 }).getTranslation());
    }

    pub fn scaled(self: @This(), delta: Vec3) @This() {
        return scale(delta).times(self);
    }

    test scaled {
        try std.testing.expectEqual(
            Mat3x4{
                .r0 = .{ .x = 0.5, .y = 0.0, .z = 0.0, .w = 0.0 },
                .r1 = .{ .x = 0.0, .y = 1.7, .z = 0.0, .w = 0.0 },
                .r2 = .{ .x = 0.0, .y = 0.0, .z = 1.1, .w = 0.0 },
            },
            Mat3x4.scale(.{ .x = 0.5, .y = 1.7, .z = 1.1 }),
        );
        try std.testing.expectEqual(
            Vec3{ .x = 0.5, .y = -6.0, .z = 50.0 },
            Mat3x4.identity.scaled(.{ .x = 0.5, .y = -2.0, .z = 10.0 })
                .timesPoint(.{ .x = 1.0, .y = 3.0, .z = 5.0 }),
        );
        try std.testing.expectEqual(
            Vec3{ .x = 0.5, .y = -6.0, .z = 10.0 },
            Mat3x4.identity.scaled(.{ .x = 0.5, .y = -2.0, .z = 5.0 })
                .timesDir(.{ .x = 1.0, .y = 3.0, .z = 2.0 }),
        );
        try std.testing.expectEqual(Vec3.zero, Mat3x4.scale(.{ .x = 0.5, .y = -2.0, .z = 1.5 }).getTranslation());
    }

    test "rotatedTranslatedScaled" {
        var m = Mat3x4.identity;
        m = m.translated(.y_pos);
        m = m.rotated(.fromPlaneAngle(.yx_pos, std.math.pi));
        m = m.scaled(.splat(0.5));
        m = m.translated(.{ .x = 0.0, .y = 0.5, .z = 0.0 });
        try expectVec3ApproxEql(.{ .x = 0.0, .y = 0.0, .z = 0.0 }, m.timesPoint(.zero));
    }

    pub fn times(lhs: Mat3x4, rhs: Mat3x4) Mat3x4 {
        const V4 = @Vector(4, f32);

        const f: V4 = .{ rhs.r2.x, rhs.r2.y, rhs.r2.z, rhs.r2.w };
        const d: V4 = .{ rhs.r1.x, rhs.r1.y, rhs.r1.z, rhs.r1.w };
        const b: V4 = .{ rhs.r0.x, rhs.r0.y, rhs.r0.z, rhs.r0.w };
        const r0 = b: {
            const e: V4 = @splat(lhs.r0.z);
            const g: V4 = .{ 0, 0, 0, lhs.r0.w };
            const temp2 = @mulAdd(V4, e, f, g);

            const c: V4 = @splat(lhs.r0.y);
            const temp = @mulAdd(V4, c, d, temp2);

            const a: V4 = @splat(lhs.r0.x);
            break :b @mulAdd(V4, a, b, temp);
        };
        const r1 = b: {
            const e: V4 = @splat(lhs.r1.z);
            const g: V4 = .{ 0, 0, 0, lhs.r1.w };
            const temp2 = @mulAdd(V4, e, f, g);

            const c: V4 = @splat(lhs.r1.y);
            const temp = @mulAdd(V4, c, d, temp2);

            const a: V4 = @splat(lhs.r1.x);
            break :b @mulAdd(V4, a, b, temp);
        };
        const r2 = b: {
            const e: V4 = @splat(lhs.r2.z);
            const g: V4 = .{ 0, 0, 0, lhs.r2.w };
            const temp2 = @mulAdd(V4, e, f, g);

            const c: V4 = @splat(lhs.r2.y);
            const temp = @mulAdd(V4, c, d, temp2);

            const a: V4 = @splat(lhs.r2.x);
            break :b @mulAdd(V4, a, b, temp);
        };
        return .{
            .r0 = .{ .x = r0[0], .y = r0[1], .z = r0[2], .w = r0[3] },
            .r1 = .{ .x = r1[0], .y = r1[1], .z = r1[2], .w = r1[3] },
            .r2 = .{ .x = r2[0], .y = r2[1], .z = r2[2], .w = r2[3] },
        };
    }

    test times {
        const t: Mat3x4 = .translation(.{ .x = 1.0, .y = 2.0, .z = 3.0 });
        const r: Mat3x4 = .rotation(.fromTo(.y_pos, .x_pos));
        const s: Mat3x4 = .scale(.{ .x = 0.5, .y = 3.0, .z = 4.0 });

        {
            const a: Mat3x4 = .{
                .r0 = .{ .x = 1, .y = 2, .z = 3, .w = 4 },
                .r1 = .{ .x = 5, .y = 6, .z = 7, .w = 8 },
                .r2 = .{ .x = 9, .y = 10, .z = 11, .w = 12 },
            };
            const b: Mat3x4 = .{
                .r0 = .{ .x = 10, .y = 20, .z = 30, .w = 40 },
                .r1 = .{ .x = 50, .y = 60, .z = 70, .w = 80 },
                .r2 = .{ .x = 90, .y = 100, .z = 110, .w = 120 },
            };
            try std.testing.expectEqual(
                Mat3x4{
                    .r0 = .{ .x = 380, .y = 440, .z = 500, .w = 564 },
                    .r1 = .{ .x = 980, .y = 1160, .z = 1340, .w = 1528 },
                    .r2 = .{ .x = 1580, .y = 1880, .z = 2180, .w = 2492 },
                },
                a.times(b),
            );
        }

        {
            var m: Mat3x4 = .identity;
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
        const t: Mat3x4 = .translation(.{ .x = 1.0, .y = 2.0, .z = 3.0 });
        const r: Mat3x4 = .rotation(.fromTo(.y_pos, .x_pos));
        const s: Mat3x4 = .scale(.{ .x = 0.5, .y = 3.0, .z = 4.0 });

        var m: Mat3x4 = .identity;
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
        const t: Mat3x4 = .translation(.{ .x = 1.0, .y = 2.0, .z = 3.0 });
        const r: Mat3x4 = .rotation(.fromTo(.y_pos, .x_pos));
        const s: Mat3x4 = .scale(.{ .x = 0.5, .y = 3.0, .z = 4.0 });

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
        const t: Mat3x4 = .translation(.{ .x = 1.0, .y = 2.0, .z = 3.0 });
        const r: Mat3x4 = .rotation(.fromTo(.y_pos, .x_pos));
        const s: Mat3x4 = .scale(.{ .x = 0.5, .y = 3.0, .z = 4.0 });

        var m: Mat3x4 = .identity;
        m.apply(t);
        m.apply(r);
        m.apply(s);

        try expectVec3ApproxEql(Vec3{ .x = 1.0, .y = -3.0, .z = 12.0 }, m.timesPoint(.zero));
        try expectVec3ApproxEql(Vec3{ .x = 0.0, .y = 0.0, .z = 0.0 }, m.timesDir(.zero));

        try expectVec3ApproxEql(Vec3{ .x = 1.5, .y = -3.0, .z = 12.0 }, m.timesPoint(.y_pos));
        try expectVec3ApproxEql(Vec3{ .x = 0.5, .y = 0.0, .z = 0.0 }, m.timesDir(.y_pos));
    }

    /// Gets the translation of the matrix. Useful for human readable output, use for computation is
    /// discouraged.
    pub fn getTranslation(self: @This()) Vec3 {
        return .{ .x = self.r0.w, .y = self.r1.w, .z = self.r2.w };
    }

    test getTranslation {
        const r: Mat3x4 = .translation(.{ .x = 1, .y = 2, .z = 3 });
        try std.testing.expectEqual(Vec3{ .x = 1, .y = 2, .z = 3 }, r.getTranslation());
    }

    /// Returns a vector representing a point transformed by this matrix.
    pub fn timesPoint(self: @This(), v: Vec3) Vec3 {
        // This is as fast in the benchmarks than my attempt to inline and hand optimize it.
        // We skip the call to `toCartesian` and truncate with `xyz` isntead because we know that w
        // will always be `1`.
        return self.timesVec4(v.point()).xyz();
    }

    test timesPoint {
        const p1: Vec3 = .{ .x = 2.0, .y = 3.0, .z = 4.0 };
        try std.testing.expectEqual(p1, Mat3x4.identity.timesPoint(p1));
        try std.testing.expectEqual(
            Vec3{ .x = 3, .y = 5, .z = 7 },
            Mat3x4.translation(.{ .x = 1, .y = 2, .z = 3 }).timesPoint(p1),
        );
    }

    /// Returns a vector representing a direction transformed by this matrix.
    pub fn timesDir(self: @This(), v: Vec3) Vec3 {
        // The missing FMAs are intentional, adding them reduces benchmark performance slightly on
        // my AMD Ryzen 9 7950X.
        return .{
            .x = @mulAdd(f32, self.r0.z, v.z, self.r0.x * v.x) + self.r0.y * v.y,
            .y = @mulAdd(f32, self.r1.z, v.z, self.r1.x * v.x) + self.r1.y * v.y,
            .z = @mulAdd(f32, self.r2.z, v.z, self.r2.x * v.x) + self.r2.y * v.y,
        };
    }

    test timesDir {
        try expectVec3ApproxEql(
            Vec3.y_pos,
            Mat3x4.rotation(.fromTo(.x_pos, .y_pos)).timesDir(.x_pos),
        );
        const p1: Vec3 = .{ .x = 2.0, .y = 3.0, .z = 4.0 };
        try std.testing.expectEqual(p1, Mat3x4.translation(.{ .x = 1, .y = 2, .z = 3 }).timesDir(p1));
    }

    /// Multiplies the matrix by a homogeneous vec4.
    pub fn timesVec4(self: @This(), v: Vec4) Vec4 {
        return .{
            .x = self.r0.innerProd(v),
            .y = self.r1.innerProd(v),
            .z = self.r2.innerProd(v),
            .w = v.w,
        };
    }

    test timesVec4 {
        try expectVec4ApproxEql(
            Vec4.y_pos,
            Mat3x4.rotation(.fromTo(.x_pos, .y_pos)).timesVec4(.x_pos),
        );
    }
};

fn expectVec3ApproxEql(expected: Vec3, actual: Vec3) !void {
    try std.testing.expectApproxEqAbs(expected.x, actual.x, 0.01);
    try std.testing.expectApproxEqAbs(expected.y, actual.y, 0.01);
    try std.testing.expectApproxEqAbs(expected.z, actual.z, 0.01);
}

fn expectVec4ApproxEql(expected: Vec4, actual: Vec4) !void {
    try std.testing.expectApproxEqAbs(expected.x, actual.x, 0.01);
    try std.testing.expectApproxEqAbs(expected.y, actual.y, 0.01);
    try std.testing.expectApproxEqAbs(expected.z, actual.z, 0.01);
    try std.testing.expectApproxEqAbs(expected.w, actual.w, 0.01);
}
