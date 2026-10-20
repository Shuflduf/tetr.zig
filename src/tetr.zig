const srs_json = @embedFile("srs.json");
const std = @import("std");
const sokol = @import("sokol");
const slog = sokol.log;
const sg = sokol.gfx;
const sgl = sokol.gl;
const sapp = sokol.app;
const sglue = sokol.glue;
const stime = sokol.time;
const sdtx = sokol.debugtext;
const print = std.debug.print;

const board = @import("board.zig");
const piece = @import("piece.zig");
const bag = @import("bag.zig");
const ui = @import("ui.zig");

pub const board_width: i8 = 10;
pub const board_height: i8 = 20;
pub const srs: struct {
    pieces: [7][4][4][2]i8,
    kicks: [8][4][2]i8,
    kicks_i: [8][4][2]i8,
    scoring_lines: [4]u32,
    scoring_tspin: [4]u32,
    scoring_mini: [3]u32,
} = @import("srs.zon");

const state = struct {};

fn clear() void {
    var action: sg.PassAction = .{};
    action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0, .g = 0, .b = 0, .a = 1 },
    };
    sg.beginPass(.{ .action = action, .swapchain = sglue.swapchain() });
}

export fn init() void {
    stime.setup();
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });
    sgl.setup(.{
        .depth_format = .NONE,
        .logger = .{ .func = slog.func },
    });
    sdtx.setup(.{ .logger = .{ .func = slog.func }, .fonts = @splat(sdtx.fontKc853()) });
    bag.init();
    piece.init();
}

export fn frame() void {
    piece.tick();

    sgl.defaults();
    sgl.matrixModeProjection();
    sgl.ortho(0, sapp.widthf(), sapp.heightf(), 0, -1, 1);

    clear();
    board.draw();
    ui.draw();

    sgl.draw();
    sg.endPass();
    sg.commit();
}

export fn event(e: [*c]const sapp.Event) void {
    piece.event(e);
    // if (e.*.type == .CHAR) {
    //     print("{c}\n", .{@as(u8, @intCast(e.*.char_code))});
    // }
}

export fn cleanup() void {
    sgl.shutdown();
    sg.shutdown();
}

pub fn main() void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = event,
        .width = 640,
        .height = 480,
        .icon = .{ .sokol_default = true },
        .depth_format = .NONE,
        .window_title = "clear.zig",
        .logger = .{ .func = slog.func },
        .win32 = .{ .console_attach = true },
    });
}
