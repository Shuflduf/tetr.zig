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

const das_time: f64 = 0.168;
const arr_time: f64 = 0.033;
const sdf_time: f64 = 0.100;
const gravity_time: f64 = 0.5;

const start_pos: [2]i8 = .{ 3, 0 };

var inputs: struct { left_held: bool, right_held: bool, down_held: bool, moving: enum { NONE, LEFT, RIGHT } } = .{
    .left_held = false,
    .right_held = false,
    .down_held = false,
    .moving = .NONE,
};

var das_timer: f64 = 0.0;
var sdf_timer: f64 = 0.0;
var gravity_timer: f64 = 0.0;

pub var current: Piece = undefined;
pub var ghost_offset: i8 = 0;

fn updateGhost() void {
    ghost_offset = 100;

    for (root.srs.pieces[current.idx][current.rot]) |offset| {
        var current_offset: i8 = 0;
        while (board.safePos(.{ current.pos[0] + offset[0], current.pos[1] + offset[1] + current_offset })) {
            current_offset += 1;
        }

        if (current_offset < ghost_offset) {
            ghost_offset = current_offset;
        }
    }

    ghost_offset -= 1;
    std.log.debug("g: {}", .{ghost_offset});
}

fn tryMove(dir: [2]i8) bool {
    for (root.srs.pieces[current.idx][current.rot]) |pos| {
        const tile = .{ current.pos[0] + pos[0] + dir[0], current.pos[1] + pos[1] + dir[1] };
        if (!board.safePos(tile)) return false;
    }

    current.pos[0] += dir[0];
    current.pos[1] += dir[1];

    updateGhost();
    return true;
}

fn tryRotate(new_rot: usize) void {
    for (root.srs.pieces[current.idx][new_rot]) |pos| {
        const tile = .{ current.pos[0] + pos[0], current.pos[1] + pos[1] };
        if (!board.safePos(tile)) return;
    }

    current.rot = new_rot;
    updateGhost();
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
    updateGhost();
}

pub fn init() void {
    nextPiece();
}

pub fn tick() void {
    const delta = sapp.frameDurationUnfiltered();
    gravity_timer += delta;
    if (gravity_timer > gravity_time) {
        gravity_timer = 0.0;
        const valid = tryMove(.{ 0, 1 });
        if (!valid) placePiece();
    }
    if (inputs.left_held or inputs.right_held) {
        das_timer += delta;

        if (das_timer > das_time) {
            switch (inputs.moving) {
                .LEFT => _ = tryMove(.{ -1, 0 }),
                .RIGHT => _ = tryMove(.{ 1, 0 }),
                else => {},
            }
            das_timer -= arr_time;
        }
    }
    if (inputs.down_held) {
        sdf_timer += delta;
        if (sdf_timer > sdf_time) {
            sdf_timer = 0.0;
            gravity_timer = 0.0;
            const valid = tryMove(.{ 0, 1 });
            if (!valid) placePiece();
        }
    }
}

pub fn event(ev: [*c]const sapp.Event) void {
    const e = ev.*;
    if (e.key_repeat == true) return;
    if (e.type == .KEY_DOWN) {
        _ = switch (e.key_code) {
            .A => {
                inputs.left_held = true;
                inputs.moving = .LEFT;
                _ = tryMove(.{ -1, 0 });
                das_timer = 0.0;
            },
            .D => {
                inputs.right_held = true;
                inputs.moving = .RIGHT;
                _ = tryMove(.{ 1, 0 });
                das_timer = 0.0;
            },
            .W => {
                const valid = tryMove(.{ 0, 1 });
                if (!valid) placePiece();

                gravity_timer = 0.0;
                inputs.down_held = true;
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
                    updateGhost();
                }
            },
            else => {},
        };
    } else if (e.type == .KEY_UP) {
        _ = switch (e.key_code) {
            .A => {
                inputs.left_held = false;
                if (inputs.right_held) {
                    inputs.moving = .RIGHT;
                    _ = tryMove(.{ 1, 0 });
                } else {
                    inputs.moving = .NONE;
                }
            },
            .D => {
                inputs.right_held = false;
                if (inputs.left_held) {
                    inputs.moving = .LEFT;
                    _ = tryMove(.{ -1, 0 });
                } else {
                    inputs.moving = .NONE;
                }
            },
            .W => {
                inputs.down_held = false;
            },
            else => {},
        };
    }
}
