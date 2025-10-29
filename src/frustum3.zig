//! A 3 dimensional frustum.
pub const Frustum3 = extern struct {
    left: f32,
    right: f32,
    bottom: f32,
    top: f32,
    near: f32,
    far: f32,
};
