const sokol = @import("sokol");
const std = @import("std");
const slog = sokol.log;
const sg = sokol.gfx;
const sgl = sokol.gl;
const sapp = sokol.app;
const sglue = sokol.glue;

const root = @import("root");
const piece = @import("piece.zig");
const bag = @import("bag.zig");
// const print = std.debug.print;

const Colour = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8 = 255,
};

pub const colours: [7]Colour = .{
    parseHex("#ff3030"),
    parseHex("#ff8330"),
    parseHex("#ffd130"),
    parseHex("#60ec3f"),
    parseHex("#3fd2ec"),
    parseHex("#3f53ec"),
    parseHex("#ff4fe0"),
};

const next_offset: [2]i8 = .{ 12, 1 };
const hold_offset: [2]i8 = .{ -6, 1 };
const board_colour: Colour = parseHex("#262626");

pub var tiles: [root.board_width][root.board_height]?usize = undefined;

fn parseHex(comptime hex: []const u8) Colour {
    if (hex.len != 7 and hex.len != 9 or hex[0] != '#') {
        @compileError("Invalid hex colour format");
    }
    return .{
        .r = std.fmt.parseInt(u8, hex[1..3], 16) catch @compileError("Invalid red value"),
        .g = std.fmt.parseInt(u8, hex[3..5], 16) catch @compileError("Invalid green value"),
        .b = std.fmt.parseInt(u8, hex[5..7], 16) catch @compileError("Invalid blue value"),
        .a = if (hex.len == 9)
            std.fmt.parseInt(u8, hex[7..9], 16) catch @compileError("Invalid alpha value")
        else
            255,
    };
}

fn drawOutline(tile_size: f32, offset_x: f32, offset_y: f32) void {
    sgl.beginQuads();
    sgl.c3b(board_colour.r, board_colour.g, board_colour.b);
    sgl.v2f(offset_x - tile_size, offset_y);
    sgl.v2f(offset_x, offset_y);
    sgl.v2f(offset_x, offset_y + tile_size * (root.board_height + 1));
    sgl.v2f(offset_x - tile_size, offset_y + tile_size * (root.board_height + 1));
    sgl.end();

    sgl.beginQuads();
    sgl.c3b(board_colour.r, board_colour.g, board_colour.b);
    sgl.v2f(offset_x + tile_size * root.board_width, offset_y);
    sgl.v2f(offset_x + tile_size * (root.board_width + 1), offset_y);
    sgl.v2f(offset_x + tile_size * (root.board_width + 1), offset_y + tile_size * (root.board_height + 1));
    sgl.v2f(offset_x + tile_size * root.board_width, offset_y + tile_size * (root.board_height + 1));
    sgl.end();

    sgl.beginQuads();
    sgl.c3b(board_colour.r, board_colour.g, board_colour.b);
    sgl.v2f(offset_x, offset_y + (tile_size * root.board_height));
    sgl.v2f(offset_x + tile_size * (root.board_width), offset_y + (tile_size * (root.board_height)));
    sgl.v2f(offset_x + tile_size * (root.board_width), offset_y + (tile_size * (root.board_height + 1)));
    sgl.v2f(offset_x, offset_y + (tile_size * (root.board_height + 1)));
    sgl.end();
}

fn drawTiles(tile_size: f32, offset_x: f32, offset_y: f32) void {
    for (tiles, 0..) |column, x| {
        for (column, 0..) |idx, y| {
            if (idx == null) continue;

            const col = colours[idx.?];
            const tile: [2]f32 = .{ @floatFromInt(x), @floatFromInt(y) };

            sgl.beginQuads();
            sgl.c3b(col.r, col.g, col.b);
            sgl.v2f(offset_x + tile_size * tile[0], offset_y + tile_size * tile[1]);
            sgl.v2f(offset_x + tile_size * (tile[0] + 1), offset_y + tile_size * tile[1]);
            sgl.v2f(offset_x + tile_size * (tile[0] + 1), offset_y + tile_size * (tile[1] + 1));
            sgl.v2f(offset_x + tile_size * tile[0], offset_y + tile_size * (tile[1] + 1));
            sgl.end();
        }
    }
}

fn drawCurrentPiece(tile_size: f32, offset_x: f32, offset_y: f32) void {
    for (root.srs.pieces[piece.current.idx][piece.current.rot]) |pos| {
        const tile = .{ piece.current.pos[0] + pos[0], piece.current.pos[1] + pos[1] };
        const col = colours[piece.current.idx];

        sgl.beginQuads();
        sgl.c3b(col.r, col.g, col.b);
        sgl.v2f(offset_x + tile_size * tile[0], offset_y + tile_size * tile[1]);
        sgl.v2f(offset_x + tile_size * (tile[0] + 1), offset_y + tile_size * tile[1]);
        sgl.v2f(offset_x + tile_size * (tile[0] + 1), offset_y + tile_size * (tile[1] + 1));
        sgl.v2f(offset_x + tile_size * tile[0], offset_y + tile_size * (tile[1] + 1));
        sgl.end();
    }
}

fn drawNextPieces(tile_size: f32, offset_x: f32, offset_y: f32) void {
    for (bag.next, 0..) |idx, i| {
        for (root.srs.pieces[idx][0]) |pos| {
            const i_u8: i8 = @intCast(i);
            const dv: i8 = i_u8 * 3;
            const tile = .{ pos[0] + next_offset[0], pos[1] + dv + next_offset[1] };
            const col = colours[idx];

            sgl.beginQuads();
            sgl.c3b(col.r, col.g, col.b);
            sgl.v2f(offset_x + tile_size * tile[0], offset_y + tile_size * tile[1]);
            sgl.v2f(offset_x + tile_size * (tile[0] + 1), offset_y + tile_size * tile[1]);
            sgl.v2f(offset_x + tile_size * (tile[0] + 1), offset_y + tile_size * (tile[1] + 1));
            sgl.v2f(offset_x + tile_size * tile[0], offset_y + tile_size * (tile[1] + 1));
            sgl.end();
        }
    }
}

fn drawHoldPiece(tile_size: f32, offset_x: f32, offset_y: f32) void {
    if (bag.held == null) return;

    for (root.srs.pieces[bag.held.?][0]) |pos| {
        const tile = .{ pos[0] + hold_offset[0], pos[1] + hold_offset[1] };
        const col = colours[bag.held.?];

        sgl.beginQuads();
        sgl.c3b(col.r, col.g, col.b);
        sgl.v2f(offset_x + tile_size * tile[0], offset_y + tile_size * tile[1]);
        sgl.v2f(offset_x + tile_size * (tile[0] + 1), offset_y + tile_size * tile[1]);
        sgl.v2f(offset_x + tile_size * (tile[0] + 1), offset_y + tile_size * (tile[1] + 1));
        sgl.v2f(offset_x + tile_size * tile[0], offset_y + tile_size * (tile[1] + 1));
        sgl.end();
    }
}

pub fn safePos(tile: [2]i8) bool {
    if (tile[0] < 0 or tile[0] > root.board_width - 1) return false;
    if (tile[1] > root.board_height - 1) return false;
    if (tiles[@intCast(tile[0])][@intCast(tile[1])] != null) return false;

    return true;
}

pub fn clearLines() void {
    var full_rows: [root.board_height]bool = @splat(false);
    row: for (0..root.board_height) |y| {
        for (0..root.board_width) |x| {
            if (tiles[x][y] == null) continue :row;
        }
        full_rows[y] = true;
    }

    var dest: usize = root.board_height;
    var source: usize = root.board_height;
    while (source > 0) {
        source -= 1;
        if (full_rows[source]) continue;
        dest -= 1;
        if (dest != source) {
            for (0..root.board_width) |x| {
                tiles[x][dest] = tiles[x][source];
            }
        }
    }

    for (0..dest) |y| {
        for (0..root.board_width) |x| {
            tiles[x][y] = null;
        }
    }
}

pub fn init() void {
    tiles = @splat(@splat(null));
}

pub fn draw() void {
    const tile_size: f32 = @min(sapp.heightf() / (root.board_height + 1), sapp.widthf() / (root.board_width + 2));
    const offset_x = @divTrunc((sapp.widthf() - tile_size * root.board_width), 2);
    const offset_y = @divTrunc((sapp.heightf() - tile_size * (root.board_height + 1)), 2);

    drawOutline(tile_size, offset_x, offset_y);
    drawTiles(tile_size, offset_x, offset_y);
    drawCurrentPiece(tile_size, offset_x, offset_y);
    drawNextPieces(tile_size, offset_x, offset_y);
    drawHoldPiece(tile_size, offset_x, offset_y);
}
