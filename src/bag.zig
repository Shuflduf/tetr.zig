const sokol = @import("sokol");
const std = @import("std");
const sapp = sokol.app;

const root = @import("root");
const board = @import("board.zig");

const next_piece_count: usize = 2;
const base_bag: [7]usize = .{ 0, 1, 2, 3, 4, 5, 6 };

var prng: std.Random.DefaultPrng = undefined;

var bag: [7]usize = undefined;
var bag_counter: usize = 0;
var next: [next_piece_count]usize = undefined;

fn initRng() void {
    prng = std.Random.DefaultPrng.init(sokol.time.now());
}

pub fn init() void {
    initRng();
    shuffleBag();
    initNext();
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

pub fn nextPiece() usize {
    if (bag_counter >= bag.len) {
        shuffleBag();
        bag_counter = 0;
    }
    const n = next[0];
    for (0..next_piece_count - 1) |i| {
        next[i] = next[i + 1];
    }
    next[next_piece_count - 1] = bag[bag_counter];
    bag_counter += 1;
    return n;
}
