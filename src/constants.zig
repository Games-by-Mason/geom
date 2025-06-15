//! Useful constants.

/// The max consecutive 32 bit floating point value.
pub const f32_max_consec: f32 = 16777216.0;

/// The max finite 32 bit floating point value.
pub const f32_max = 3.40282347E+38;

/// The reciprocal of the maximum u32 as a f32. Multiplying by this reciprocal provides exact
/// results for every whole floating point number also representable by as u32.
pub const u32_max_recip: f32 = 1.0 / @as(f32, @floatFromInt(0xffffffff));
