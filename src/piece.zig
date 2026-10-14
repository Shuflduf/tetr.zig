const sokol = @import("sokol");
const sapp = sokol.app;

const root = @import("root");

pub const Piece = struct {
    pos: [2]i8,
    rot: usize,
    idx: usize,
};

const gravity_time: f64 = 0.5;

pub var current: Piece = .{ .idx = 1, .pos = .{ 3, 0 }, .rot = 0 };
var gravity_timer: f64 = 0.0;

fn tryMove(dir: [2]i8) void {
    for (root.srs.pieces[current.idx][current.rot]) |pos| {
        const tile = .{ current.pos[0] + pos[0] + dir[0], current.pos[1] + pos[1] + dir[1] };
        if (tile[0] < 0 or tile[0] > root.board_width - 1) return;
        if (tile[1] > root.board_height - 1) return;
    }

    current.pos[0] += dir[0];
    current.pos[1] += dir[1];
}

fn tryRotate(new_rot: usize) void {
    current.rot = new_rot;
}

pub fn tick() void {
    gravity_timer += sapp.frameDurationUnfiltered();
    if (gravity_timer > gravity_time) {
        gravity_timer = 0.0;
        tryMove(.{ 0, 1 });
        // current.pos[1] += 1;
    }
}

pub fn event(ev: [*c]const sapp.Event) void {
    const e = ev.*;
    if (e.type == .KEY_DOWN) {
        if (e.key_code == .A) tryMove(.{ -1, 0 });
        if (e.key_code == .D) tryMove(.{ 1, 0 });
        if (e.key_code == .LEFT) tryRotate((current.rot + 3) % 4);
        if (e.key_code == .RIGHT) tryRotate((current.rot + 1) % 4);
    }
}
