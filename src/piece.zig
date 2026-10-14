pub const Piece = struct {
    pos: [2]i8,
    rot: usize,
    idx: usize,
};
pub var current: Piece = .{ .idx = 1, .pos = .{ 3, 0 }, .rot = 0 };
