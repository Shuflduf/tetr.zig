const sokol = @import("sokol");
const std = @import("std");
const sapp = sokol.app;

const root = @import("root");
const board = @import("board.zig");
const bag = @import("bag.zig");

pub const Piece = struct {
    pos: [2]i8,
    rot: usize,
    idx: usize,
};

const start_pos: [2]i8 = .{ 3, 0 };
const gravity_time: f64 = 0.5;

var gravity_timer: f64 = 0.0;
pub var current: Piece = undefined;

fn tryMove(dir: [2]i8) bool {
    for (root.srs.pieces[current.idx][current.rot]) |pos| {
        const tile = .{ current.pos[0] + pos[0] + dir[0], current.pos[1] + pos[1] + dir[1] };
        if (!board.safePos(tile)) return false;
    }

    current.pos[0] += dir[0];
    current.pos[1] += dir[1];

    return true;
}

fn tryRotate(new_rot: usize) void {
    for (root.srs.pieces[current.idx][new_rot]) |pos| {
        const tile = .{ current.pos[0] + pos[0], current.pos[1] + pos[1] };
        if (!board.safePos(tile)) return;
    }

    current.rot = new_rot;
}

fn placePiece() void {
    for (root.srs.pieces[current.idx][current.rot]) |pos| {
        const tile = .{ current.pos[0] + pos[0], current.pos[1] + pos[1] };
        board.tiles[@intCast(tile[0])][@intCast(tile[1])] = current.idx;
    }

    board.clearLines();
    bag.just_held = false;
    nextPiece();
}

fn nextPiece() void {
    current = .{ .idx = bag.nextPiece(), .pos = start_pos, .rot = 0 };
    gravity_timer = 0.0;
}

pub fn init() void {
    nextPiece();
}

pub fn tick() void {
    gravity_timer += sapp.frameDurationUnfiltered();
    if (gravity_timer > gravity_time) {
        gravity_timer = 0.0;
        const valid = tryMove(.{ 0, 1 });
        if (!valid) placePiece();
    }
}

pub fn event(ev: [*c]const sapp.Event) void {
    const e = ev.*;
    if (e.key_repeat == true) return;
    if (e.type == .KEY_DOWN) {
        _ = switch (e.key_code) {
            .A => tryMove(.{ -1, 0 }),
            .D => tryMove(.{ 1, 0 }),
            .W => {
                const valid = tryMove(.{ 0, 1 });
                if (!valid) placePiece();

                gravity_timer = 0.0;
            },
            .S => {
                while (tryMove(.{ 0, 1 })) {}
                placePiece();
            },
            .LEFT => tryRotate((current.rot + 3) % 4),
            .RIGHT => tryRotate((current.rot + 1) % 4),
            .LEFT_SHIFT => {
                if (!bag.just_held) {
                    var idx: usize = undefined;
                    if (bag.held != null) {
                        idx = bag.held.?;
                    } else {
                        idx = bag.nextPiece();
                    }

                    const last = current.idx;
                    current = .{ .idx = idx, .pos = start_pos, .rot = 0 };
                    gravity_timer = 0.0;
                    bag.held = last;
                    bag.just_held = true;
                }
            },
            else => {},
        };
    }
}
