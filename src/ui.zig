const sokol = @import("sokol");
const std = @import("std");
const sapp = sokol.app;
const sdtx = sokol.debugtext;

const root = @import("root");
const score = @import("score.zig");

const controls: [7][:0]const u8 = .{
    "A - LEFT",
    "D - RIGHT",
    "LEFT - CCW",
    "RIGHT - CW",
    "S - HARD",
    "W - SOFT",
    "SHIFT - HOLD",
};

fn drawTitle() void {
    sdtx.canvas(sapp.widthf() * 0.2, sapp.heightf() * 0.2);
    sdtx.origin(0.0, 0.0);
    sdtx.home();

    sdtx.color3b(0xFF, 0xFF, 0xFF);
    sdtx.pos(0.5, 0.5);
    sdtx.puts("TETR.ZIG");
}

fn drawControls() void {
    sdtx.canvas(sapp.widthf() * 0.3, sapp.heightf() * 0.3);
    sdtx.origin(0.5, -0.5);
    sdtx.home();

    sdtx.color3b(0x4C, 0x4C, 0x4C);
    sdtx.pos(0, sapp.heightf() * 0.0375 - controls.len);
    for (controls) |line| {
        sdtx.puts(line);
        sdtx.crlf();
    }
}

pub fn draw() void {
    sdtx.font(0);

    drawTitle();
    drawControls();
    score.draw();

    sdtx.draw();
}
