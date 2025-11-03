const std = @import("std");
const geom = @import("root.zig");

const Vec2 = geom.Vec2;
const Vec3 = geom.Vec3;
const Rotor2 = geom.Rotor2;
const Frustum2 = geom.Frustum2;
const Mat2 = geom.Mat2;

/// A row major affine transformation matrix for working in two dimensions.
///
/// Elides `r2` as compared to `Mat3` to save on space/computation, it's implicitly considered to be
/// `Mat3.identity.r2`.
pub const Mat2x3 = extern struct {
    /// Row 0, the x basis vector.
    r0: Vec3,
    /// Row 1, the y basis vector.
    r1: Vec3,

    /// The identity matrix. Has no effect.
    pub const identity: @This() = .{
        .r0 = .{ .x = 1, .y = 0, .z = 0 },
        .r1 = .{ .x = 0, .y = 1, .z = 0 },
    };

    test identity {
        const p1: Vec2 = .{ .x = 2.0, .y = 3.0 };
        const p2: Vec2 = .{ .x = 4.0, .y = -2.0 };
        try std.testing.expectEqual(Mat2x3.identity, Mat2x3.identity.times(.identity));
        try std.testing.expectEqual(p1, Mat2x3.identity.timesPoint(p1));
        try std.testing.expectEqual(p2, Mat2x3.identity.timesPoint(p2));
    }

    /// Checks for equality.
    pub fn eql(self: Mat2x3, other: Mat2x3) bool {
        return std.meta.eql(self, other);
    }

    test eql {
        try std.testing.expect(Mat2x3.identity.eql(Mat2x3.identity));
        try std.testing.expect(!Mat2x3.identity.eql(Mat2x3.translation(.y_pos)));
    }

    /// Returns an orthographic projection matrix that converts from view space to Vulkan clip
    /// space.
    pub fn orthoFromFrustum(frustum: Frustum2) @This() {
        const width = frustum.right - frustum.left;
        const height = frustum.bottom - frustum.top;
        const x_scale = 2 / width;
        const y_scale = 2 / height;
        const x_off = -(frustum.right + frustum.left) / width;
        const y_off = -(frustum.top + frustum.bottom) / height;
        return .{
            .r0 = .{ .x = x_scale, .y = 0, .z = x_off },
            .r1 = .{ .x = 0, .y = y_scale, .z = y_off },
        };
    }

    test orthoFromFrustum {
        const f: Frustum2 = .{
            .left = -2.5,
            .right = 0.3,
            .top = 4.1,
            .bottom = -2.2,
        };
        const m = orthoFromFrustum(f);
        try expectVec2ApproxEql(
            .{ .x = -1, .y = -1 },
            m.timesPoint(.{ .x = f.left, .y = f.top }),
        );
        try expectVec2ApproxEql(
            .{ .x = 0, .y = 0 },
            m.timesPoint(.{ .x = (f.left + f.right) / 2, .y = (f.bottom + f.top) / 2 }),
        );
        try expectVec2ApproxEql(
            .{ .x = 1, .y = 1 },
            m.timesPoint(.{ .x = f.right, .y = f.bottom }),
        );
    }

    /// Create a rotation matrix from a rotor.
    pub fn rotation(rotor: Rotor2) @This() {
        const inverse = rotor.inverse();
        const x = inverse.timesVec2(.x_pos);
        const y = inverse.timesVec2(.y_pos);
        return .{
            .r0 = x.dir(),
            .r1 = y.dir(),
        };
    }

    test rotation {
        const m = Mat2x3.rotation(Rotor2.fromTo(.y_pos, .x_pos).nlerp(.identity, 0.5));
        try std.testing.expectApproxEqAbs(std.math.pi / 4.0, m.getRadians(), 0.01);
        try std.testing.expectEqual(Vec2.zero, m.getTranslation());

        try std.testing.expectApproxEqAbs(@cos(std.math.pi / 4.0), m.r0.x, 0.01);
        try std.testing.expectApproxEqAbs(@sin(std.math.pi / 4.0), m.r0.y, 0.01);
        try std.testing.expectApproxEqAbs(-@sin(std.math.pi / 4.0), m.r1.x, 0.01);
        try std.testing.expectApproxEqAbs(@cos(std.math.pi / 4.0), m.r1.y, 0.01);

        try expectVec2ApproxEql(
            .y_pos,
            Mat2x3.rotation(.fromTo(.x_pos, .y_pos)).timesPoint(.x_pos),
        );
        try expectVec2ApproxEql(
            .x_neg,
            Mat2x3.rotation(.fromTo(.x_pos, .y_pos)).timesPoint(.y_pos),
        );
        try expectVec2ApproxEql(
            .x_pos,
            Mat2x3.rotation(.fromTo(.x_neg, .x_pos)).timesPoint(.x_neg),
        );
        try expectVec2ApproxEql(
            .y_neg,
            Mat2x3.rotation(.fromTo(.x_neg, .x_pos)).timesPoint(.y_pos),
        );

        try expectVec2ApproxEql(
            .y_pos,
            Mat2x3.rotation(.fromTo(.x_pos, .y_pos)).timesDir(.x_pos),
        );
        try expectVec2ApproxEql(
            .x_neg,
            Mat2x3.rotation(.fromTo(.x_pos, .y_pos)).timesDir(.y_pos),
        );
        try expectVec2ApproxEql(
            .x_pos,
            Mat2x3.rotation(.fromTo(.x_neg, .x_pos)).timesDir(.x_neg),
        );
        try expectVec2ApproxEql(
            .y_neg,
            Mat2x3.rotation(.fromTo(.x_neg, .x_pos)).timesDir(.y_pos),
        );
    }

    pub fn rotated(self: @This(), rotor: Rotor2) @This() {
        return rotation(rotor).times(self);
    }

    test rotated {
        const r: Rotor2 = .fromTo(.x_pos, .y_pos);
        try std.testing.expectEqual(
            rotation(r).times(.identity),
            identity.rotated(r),
        );
    }

    /// Create a translation matrix from a vector.
    pub fn translation(delta: Vec2) @This() {
        return .{
            .r0 = .{ .x = 1, .y = 0, .z = delta.x },
            .r1 = .{ .x = 0, .y = 1, .z = delta.y },
        };
    }

    test translation {
        try std.testing.expectEqual(Mat2x3{
            .r0 = .{ .x = 1, .y = 0, .z = 1 },
            .r1 = .{ .x = 0, .y = 1, .z = 2 },
        }, Mat2x3.translation(.{ .x = 1, .y = 2 }));
        try std.testing.expectEqual(
            Vec2{ .x = 3, .y = 5 },
            Mat2x3.translation(.{ .x = 1, .y = 2 }).timesPoint(.{ .x = 2, .y = 3 }),
        );
        try std.testing.expectEqual(
            Vec2{ .x = 7, .y = 5 },
            Mat2x3.translation(.{ .x = -1, .y = 3 }).timesPoint(.{ .x = 8, .y = 2 }),
        );
        try std.testing.expectEqual(
            Vec2{ .x = 2, .y = 3 },
            Mat2x3.translation(.{ .x = 1, .y = 2 }).timesDir(.{ .x = 2, .y = 3 }),
        );
        try std.testing.expectEqual(
            Vec2{ .x = 8, .y = 2 },
            Mat2x3.translation(.{ .x = -1, .y = 3 }).timesDir(.{ .x = 8, .y = 2 }),
        );
        try std.testing.expectEqual(0, Mat2x3.translation(.{ .x = -1, .y = 3 }).getRadians());
    }

    pub fn translated(self: @This(), delta: Vec2) @This() {
        return translation(delta).times(self);
    }

    test translated {
        try std.testing.expectEqual(Mat2x3{
            .r0 = .{ .x = 1, .y = 0, .z = 1 },
            .r1 = .{ .x = 0, .y = 1, .z = 2 },
        }, identity.translated(.{ .x = 1, .y = 2 }));
    }

    /// Create a scale matrix from a vector.
    pub fn scale(amount: Vec2) @This() {
        return .{
            .r0 = .{ .x = amount.x, .y = 0, .z = 0.0 },
            .r1 = .{ .x = 0, .y = amount.y, .z = 0.0 },
        };
    }

    test scale {
        try std.testing.expectEqual(
            Mat2x3{
                .r0 = .{ .x = 0.5, .y = 0.0, .z = 0 },
                .r1 = .{ .x = 0.0, .y = 1.7, .z = 0 },
            },
            Mat2x3.scale(.{ .x = 0.5, .y = 1.7 }),
        );
        try std.testing.expectEqual(
            Vec2{ .x = 0.5, .y = -6.0 },
            Mat2x3.scale(.{ .x = 0.5, .y = -2.0 }).timesPoint(.{ .x = 1.0, .y = 3.0 }),
        );
        try std.testing.expectEqual(
            Vec2{ .x = 0.5, .y = -6.0 },
            Mat2x3.scale(.{ .x = 0.5, .y = -2.0 }).timesDir(.{ .x = 1.0, .y = 3.0 }),
        );
        try std.testing.expectEqual(0.0, Mat2x3.scale(.{ .x = 0.5, .y = -2.0 }).getRadians());
        try std.testing.expectEqual(Vec2.zero, Mat2x3.scale(.{ .x = 0.5, .y = -2.0 }).getTranslation());
    }

    pub fn scaled(self: @This(), delta: Vec2) @This() {
        return scale(delta).times(self);
    }

    test scaled {
        try std.testing.expectEqual(
            Mat2x3{
                .r0 = .{ .x = 0.5, .y = 0.0, .z = 0.0 },
                .r1 = .{ .x = 0.0, .y = 1.7, .z = 0.0 },
            },
            Mat2x3.scale(.{ .x = 0.5, .y = 1.7 }),
        );
        try std.testing.expectEqual(
            Vec2{ .x = 0.5, .y = -6.0 },
            Mat2x3.identity.scaled(.{ .x = 0.5, .y = -2.0 })
                .timesPoint(.{ .x = 1.0, .y = 3.0 }),
        );
        try std.testing.expectEqual(
            Vec2{ .x = 0.5, .y = -6.0 },
            Mat2x3.identity.scaled(.{ .x = 0.5, .y = -2.0 })
                .timesDir(.{ .x = 1.0, .y = 3.0 }),
        );
        try std.testing.expectEqual(Vec2.zero, Mat2x3.scale(.{ .x = 0.5, .y = -2.0 }).getTranslation());
    }

    test "rotatedTranslatedScaled" {
        var m = Mat2x3.identity;
        m = m.translated(.y_pos);
        m = m.rotated(.fromAngle(std.math.pi));
        m = m.scaled(.splat(0.5));
        m = m.translated(.{ .x = 0.0, .y = 0.5 });
        try expectVec2ApproxEql(Vec2{ .x = 0.0, .y = 0.0 }, m.timesPoint(.zero));
    }

    /// Returns `lhs` multiplied by `rhs`.
    pub fn times(lhs: Mat2x3, rhs: Mat2x3) Mat2x3 {
        return .{
            .r0 = .{
                .x = @mulAdd(f32, lhs.r0.x, rhs.r0.x, lhs.r0.y * rhs.r1.x),
                .y = @mulAdd(f32, lhs.r0.x, rhs.r0.y, lhs.r0.y * rhs.r1.y),
                .z = @mulAdd(f32, lhs.r0.x, rhs.r0.z, @mulAdd(f32, lhs.r0.y, rhs.r1.z, lhs.r0.z)),
            },
            .r1 = .{
                .x = @mulAdd(f32, lhs.r1.x, rhs.r0.x, lhs.r1.y * rhs.r1.x),
                .y = @mulAdd(f32, lhs.r1.x, rhs.r0.y, lhs.r1.y * rhs.r1.y),
                .z = @mulAdd(f32, lhs.r1.x, rhs.r0.z, @mulAdd(f32, lhs.r1.y, rhs.r1.z, lhs.r1.z)),
            },
        };
    }

    test times {
        const t: Mat2x3 = .translation(.{ .x = 1.0, .y = 2.0 });
        const r: Mat2x3 = .rotation(.fromTo(.y_pos, .x_pos));
        const s: Mat2x3 = .scale(.{ .x = 0.5, .y = 3.0 });

        {
            const a: Mat2x3 = .{
                .r0 = .{ .x = 1, .y = 2, .z = 3 },
                .r1 = .{ .x = 4, .y = 5, .z = 6 },
            };
            const b: Mat2x3 = .{
                .r0 = .{ .x = 10, .y = 20, .z = 30 },
                .r1 = .{ .x = 40, .y = 50, .z = 60 },
            };
            try std.testing.expectEqual(
                Mat2x3{
                    .r0 = .{ .x = 90, .y = 120, .z = 153 },
                    .r1 = .{ .x = 240, .y = 330, .z = 426 },
                },
                a.times(b),
            );
        }

        {
            var m: Mat2x3 = .identity;
            m = t.times(m);
            m = r.times(m);
            m = s.times(m);

            try expectVec2ApproxEql(Vec2{ .x = 1.0, .y = -3.0 }, m.timesPoint(.zero));
            try expectVec2ApproxEql(Vec2{ .x = 0.0, .y = 0.0 }, m.timesDir(.zero));

            try expectVec2ApproxEql(Vec2{ .x = 1.5, .y = -3.0 }, m.timesPoint(.y_pos));
            try expectVec2ApproxEql(Vec2{ .x = 0.5, .y = 0.0 }, m.timesDir(.y_pos));
        }

        {
            const m = s.times(r).times(t);

            try expectVec2ApproxEql(Vec2{ .x = 1.0, .y = -3.0 }, m.timesPoint(.zero));
            try expectVec2ApproxEql(Vec2{ .x = 0.0, .y = 0.0 }, m.timesDir(.zero));

            try expectVec2ApproxEql(Vec2{ .x = 1.5, .y = -3.0 }, m.timesPoint(.y_pos));
            try expectVec2ApproxEql(Vec2{ .x = 0.5, .y = 0.0 }, m.timesDir(.y_pos));
        }
    }

    /// Multiplies the matrix by `other`.
    pub fn mul(self: *@This(), other: @This()) void {
        self.* = self.times(other);
    }

    test mul {
        const t: Mat2x3 = .translation(.{ .x = 1.0, .y = 2.0 });
        const r: Mat2x3 = .rotation(.fromTo(.y_pos, .x_pos));
        const s: Mat2x3 = .scale(.{ .x = 0.5, .y = 3.0 });

        var m: Mat2x3 = .identity;
        m.mul(s);
        m.mul(r);
        m.mul(t);

        try expectVec2ApproxEql(Vec2{ .x = 1.0, .y = -3.0 }, m.timesPoint(.zero));
        try expectVec2ApproxEql(Vec2{ .x = 0.0, .y = 0.0 }, m.timesDir(.zero));

        try expectVec2ApproxEql(Vec2{ .x = 1.5, .y = -3.0 }, m.timesPoint(.y_pos));
        try expectVec2ApproxEql(Vec2{ .x = 0.5, .y = 0.0 }, m.timesDir(.y_pos));
    }

    /// The same as `times`, but the arguments are reversed. This is often more intuitive and less
    /// verbose.
    pub fn applied(self: @This(), other: @This()) @This() {
        return other.times(self);
    }

    test applied {
        const t: Mat2x3 = .translation(.{ .x = 1.0, .y = 2.0 });
        const r: Mat2x3 = .rotation(.fromTo(.y_pos, .x_pos));
        const s: Mat2x3 = .scale(.{ .x = 0.5, .y = 3.0 });

        const m = t.applied(r).applied(s);

        try expectVec2ApproxEql(Vec2{ .x = 1.0, .y = -3.0 }, m.timesPoint(.zero));
        try expectVec2ApproxEql(Vec2{ .x = 0.0, .y = 0.0 }, m.timesDir(.zero));

        try expectVec2ApproxEql(Vec2{ .x = 1.5, .y = -3.0 }, m.timesPoint(.y_pos));
        try expectVec2ApproxEql(Vec2{ .x = 0.5, .y = 0.0 }, m.timesDir(.y_pos));
    }

    /// The same as `mul`, but the arguments are reversed. This is often more intuitive and less
    /// verbose.
    pub fn apply(self: *@This(), other: @This()) void {
        self.* = self.applied(other);
    }

    test apply {
        const t: Mat2x3 = .translation(.{ .x = 1.0, .y = 2.0 });
        const r: Mat2x3 = .rotation(.fromTo(.y_pos, .x_pos));
        const s: Mat2x3 = .scale(.{ .x = 0.5, .y = 3.0 });

        var m: Mat2x3 = .identity;
        m.apply(t);
        m.apply(r);
        m.apply(s);

        try expectVec2ApproxEql(Vec2{ .x = 1.0, .y = -3.0 }, m.timesPoint(.zero));
        try expectVec2ApproxEql(Vec2{ .x = 0.0, .y = 0.0 }, m.timesDir(.zero));

        try expectVec2ApproxEql(Vec2{ .x = 1.5, .y = -3.0 }, m.timesPoint(.y_pos));
        try expectVec2ApproxEql(Vec2{ .x = 0.5, .y = 0.0 }, m.timesDir(.y_pos));
    }

    /// Gets the rotation of the matrix in radians. Useful for human readable output, use for
    /// computation is discouraged.
    pub fn getRadians(self: @This()) f32 {
        const cos = self.r0.x;
        const sin = self.r0.y;
        return std.math.atan2(sin, cos);
    }

    test getRadians {
        const r: Mat2x3 = .rotation(.fromTo(.y_pos, .x_pos));
        try std.testing.expectEqual(std.math.pi / 2.0, r.getRadians());
    }

    /// Extracts the rotation matrix.
    pub fn getRot(self: Mat2x3) Mat2 {
        return .{
            .r0 = .{ .x = self.r0.x, .y = self.r0.y },
            .r1 = .{ .x = self.r1.x, .y = self.r1.y },
        };
    }

    test getRot {
        const r: Rotor2 = .fromTo(.{ .x = 1, .y = 2 }, .{ .x = 3, .y = 4 });
        const a: Mat2x3 = .rotation(r);
        const b: Mat2 = .rotation(r);
        try std.testing.expectEqual(b, a.getRot());
    }

    /// Gets the translation of the matrix.
    pub fn getTranslation(self: @This()) Vec2 {
        return .{ .x = self.r0.z, .y = self.r1.z };
    }

    test getTranslation {
        const r: Mat2x3 = .translation(.{ .x = 1, .y = 2 });
        try std.testing.expectEqual(Vec2{ .x = 1, .y = 2 }, r.getTranslation());
    }

    /// Returns a vector representing a point transformed by this matrix.
    pub fn timesPoint(self: @This(), v: Vec2) Vec2 {
        // The missing FMAs are intentional, adding them reduces benchmark performance slightly on
        // my AMD Ryzen 9 7950X.
        // Note that we don't need to divide by the homogeneous coordinate because we know that it's
        // always 1.
        return .{
            .x = self.r0.y * v.y + @mulAdd(f32, self.r0.x, v.x, self.r0.z),
            .y = self.r1.y * v.y + @mulAdd(f32, self.r1.x, v.x, self.r1.z),
        };
    }

    test timesPoint {
        const p1: Vec2 = .{ .x = 2.0, .y = 3.0 };
        try std.testing.expectEqual(p1, Mat2x3.identity.timesPoint(p1));
        try std.testing.expectEqual(
            Vec2{ .x = 3, .y = 5 },
            Mat2x3.translation(.{ .x = 1, .y = 2 }).timesPoint(p1),
        );
    }

    /// Returns a vector representing a direction transformed by this matrix.
    pub fn timesDir(self: @This(), v: Vec2) Vec2 {
        return .{
            .x = @mulAdd(f32, self.r0.x, v.x, self.r0.y * v.y),
            .y = @mulAdd(f32, self.r1.x, v.x, self.r1.y * v.y),
        };
    }

    test timesDir {
        try expectVec2ApproxEql(
            Vec2.y_pos,
            Mat2x3.rotation(.fromTo(.x_pos, .y_pos)).timesDir(.x_pos),
        );
        const p1: Vec2 = .{ .x = 2.0, .y = 3.0 };
        try std.testing.expectEqual(p1, Mat2x3.translation(.{ .x = 1, .y = 2 }).timesDir(p1));
    }

    /// Multiplies the matrix by a homogeneous vec3.
    pub fn timesVec3(self: @This(), v: Vec3) Vec3 {
        return .{
            .x = self.r0.innerProd(v),
            .y = self.r1.innerProd(v),
            .z = v.z,
        };
    }

    test timesVec3 {
        try expectVec3ApproxEql(
            Vec3.y_pos,
            Mat2x3.rotation(.fromTo(.x_pos, .y_pos)).timesVec3(.x_pos),
        );
    }

    /// Returns the transpose of the matrix, assuming the missing row is `Mat3.identity.r2`. For
    /// pure rotation matrices, the transpose is equivalent to the inverse.
    pub fn transposed(self: @This()) Mat2x3 {
        return .{
            .r0 = .{ .x = self.r0.x, .y = self.r1.x, .z = 0 },
            .r1 = .{ .x = self.r0.y, .y = self.r1.y, .z = 0 },
        };
    }

    test transposed {
        const m: Mat2x3 = .{
            .r0 = .{ .x = 1, .y = 2, .z = 3 },
            .r1 = .{ .x = 4, .y = 5, .z = 6 },
        };
        const t: Mat2x3 = .{
            .r0 = .{ .x = 1, .y = 4, .z = 0 },
            .r1 = .{ .x = 2, .y = 5, .z = 0 },
        };
        try std.testing.expectEqual(t, m.transposed());

        const r = rotation(.fromTo(
            .{ .x = 1, .y = 2 },
            .{ .x = 3, .y = 4 },
        ));
        try expectMat2x3ApproxEq(identity, r.times(r.transposed()));
    }

    /// Transposes the matrix, assuming the missing row is `Mat3.identity.r3`. For pure rotation
    /// matrices, the transpose is equivalent to the inverse.
    pub fn transpose(self: *@This()) void {
        self.* = self.transposed();
    }

    test transpose {
        var m: Mat2x3 = .{
            .r0 = .{ .x = 1, .y = 2, .z = 3 },
            .r1 = .{ .x = 4, .y = 5, .z = 6 },
        };
        m.transpose();
        const t: Mat2x3 = .{
            .r0 = .{ .x = 1, .y = 4, .z = 0 },
            .r1 = .{ .x = 2, .y = 5, .z = 0 },
        };
        try std.testing.expectEqual(t, m);
    }

    /// Returns the inverse of a rotation translation matrix.
    pub fn inverseRt(self: Mat2x3) Mat2x3 {
        const inv_rot = self.getRot().transposed();
        const trans_neg = self.getTranslation().negated();
        const inv_trans = inv_rot.timesVec2(trans_neg);
        return .{
            .r0 = .{ .x = inv_rot.r0.x, .y = inv_rot.r0.y, .z = inv_trans.x },
            .r1 = .{ .x = inv_rot.r1.x, .y = inv_rot.r1.y, .z = inv_trans.y },
        };
    }

    test inverseRt {
        const m = translation(.{ .x = 1, .y = 2 })
            .times(rotation(.fromTo(.{ .x = 3, .y = 4 }, .{ .x = 5, .y = 6 })))
            .times(translation(.{ .x = 7, .y = 8 }))
            .times(rotation(.fromTo(.{ .x = -9, .y = 10 }, .{ .x = -11, .y = 12 })));
        const i = m.inverseRt();
        try expectMat2x3ApproxEq(identity, m.times(i));
    }

    /// Inverts a rotation translation matrix.
    pub fn invertRt(self: *Mat2x3) void {
        self.* = self.inverseRt();
    }

    test invertRt {
        const m = translation(.{ .x = 1, .y = 2 })
            .times(rotation(.fromTo(.{ .x = 3, .y = 4 }, .{ .x = 5, .y = 6 })))
            .times(translation(.{ .x = 7, .y = 8 }))
            .times(rotation(.fromTo(.{ .x = -9, .y = 10 }, .{ .x = -11, .y = 12 })));
        var i = m;
        i.invertRt();
        try expectMat2x3ApproxEq(identity, m.times(i));
    }
};

fn expectMat2x3ApproxEq(lhs: Mat2x3, rhs: Mat2x3) !void {
    try expectVec3ApproxEql(lhs.r0, rhs.r0);
    try expectVec3ApproxEql(lhs.r1, rhs.r1);
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
