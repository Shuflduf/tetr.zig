const srs_json = @embedFile("srs.json");
const std = @import("std");
const sokol = @import("sokol");
const slog = sokol.log;
const sg = sokol.gfx;
const sgl = sokol.gl;
const sapp = sokol.app;
const sglue = sokol.glue;
const print = std.debug.print;

const state = struct {};
pub const srs: struct {
    pieces: [7][4][4][2]i8,
    kicks: [8][4][2]i8,
    kicks_i: [8][4][2]i8,
    scoring_lines: [4]u32,
    scoring_tspin: [4]u32,
    scoring_mini: [3]u32,
} = @import("srs.zon");

export fn init() void {
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });
    sgl.setup(.{
        .depth_format = .NONE,
        .logger = .{ .func = slog.func },
    });
    print("Backend: {}\n", .{sg.queryBackend()});
    print("srs: {}\n", .{srs});
}

export fn frame() void {
    sgl.defaults();
    sgl.matrixModeProjection();
    sgl.ortho(0, sapp.widthf(), sapp.heightf(), 0, -1, 1);

    sgl.beginQuads();
    sgl.c3f(1.0, 0.2, 1.0);
    sgl.v2f(100, 100);
    sgl.v2f(200, 100);
    sgl.v2f(300, 300);
    sgl.v2f(100, 200);
    sgl.end();

    var action: sg.PassAction = .{};
    action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0, .g = 0, .b = 0, .a = 1 },
    };
    sg.beginPass(.{ .action = action, .swapchain = sglue.swapchain() });
    sgl.draw();
    sg.endPass();
    sg.commit();
}

export fn event(e: [*c]const sapp.Event) void {
    if (e.*.type == .CHAR) {
        print("{c}\n", .{@as(u8, @intCast(e.*.char_code))});
    }
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
