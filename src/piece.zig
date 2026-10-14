const sokol = @import("sokol");
const std = @import("std");
const sapp = sokol.app;

const root = @import("root");

pub const Piece = struct {
    pos: [2]i8,
    rot: usize,
    idx: usize,
};

const base_bag: [7]usize = .{ 0, 1, 2, 3, 4, 5, 6 };
const start_pos: [2]i8 = .{ 3, 0 };
const gravity_time: f64 = 0.5;
const next_piece_count: usize = 2;

var prng: std.Random.DefaultPrng = undefined;

var bag: [7]usize = undefined;
var bag_counter: usize = 0;
var next: [next_piece_count]usize = undefined;

var gravity_timer: f64 = 0.0;
pub var current: Piece = undefined;

fn tryMove(dir: [2]i8) bool {
    for (root.srs.pieces[current.idx][current.rot]) |pos| {
        const tile = .{ current.pos[0] + pos[0] + dir[0], current.pos[1] + pos[1] + dir[1] };
        if (tile[0] < 0 or tile[0] > root.board_width - 1) return false;
        if (tile[1] > root.board_height - 1) return false;
    }

    current.pos[0] += dir[0];
    current.pos[1] += dir[1];

    return true;
}

fn tryRotate(new_rot: usize) void {
    for (root.srs.pieces[current.idx][new_rot]) |pos| {
        const tile = .{ current.pos[0] + pos[0], current.pos[1] + pos[1] };
        if (tile[0] < 0 or tile[0] > root.board_width - 1) return;
        if (tile[1] > root.board_height - 1) return;
    }

    current.rot = new_rot;
}

fn nextPiece() void {
    if (bag_counter >= bag.len) {
        shuffleBag();
        bag_counter = 0;
    }
    current = .{ .idx = next[0], .pos = start_pos, .rot = 0 };
    gravity_timer = 0.0;
    for (0..next_piece_count - 1) |i| {
        next[i] = next[i + 1];
    }
    next[next_piece_count - 1] = bag[bag_counter];
    bag_counter += 1;
}

fn initRng() void {
    std.debug.print("time: {}", .{sokol.time.now()});
    prng = std.Random.DefaultPrng.init(sokol.time.now());
}

fn shuffleBag() void {
    bag = base_bag;
    prng.random().shuffle(usize, &bag);
}

fn initNext() void {
    for (0..next_piece_count) |i| {
        next[i] = bag[i];
    }
    bag_counter = next_piece_count;
}

pub fn init() void {
    // bag = initBag();
    initRng();
    shuffleBag();
    initNext();
    nextPiece();
    // initBag();
}

pub fn tick() void {
    gravity_timer += sapp.frameDurationUnfiltered();
    if (gravity_timer > gravity_time) {
        gravity_timer = 0.0;
        const valid = tryMove(.{ 0, 1 });
        if (!valid) {
            current = .{ .idx = 0, .pos = start_pos, .rot = 0 };
            gravity_timer = 0.0;
        }
        // current.pos[1] += 1;
    }
}

pub fn event(ev: [*c]const sapp.Event) void {
    const e = ev.*;
    if (e.type == .KEY_DOWN) {
        _ = switch (e.key_code) {
            .A => tryMove(.{ -1, 0 }),
            .D => tryMove(.{ 1, 0 }),
            .W => {
                const valid = tryMove(.{ 0, 1 });
                if (!valid) {
                    nextPiece();
                }
                gravity_timer = 0.0;
            },
            .LEFT => tryRotate((current.rot + 3) % 4),
            .RIGHT => tryRotate((current.rot + 1) % 4),
            else => {},
        };
    }
}
