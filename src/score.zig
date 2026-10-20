const sokol = @import("sokol");
const std = @import("std");
const sdtx = sokol.debugtext;
const sapp = sokol.app;

const piece = @import("piece.zig");
const root = @import("root");

var score: u32 = 0;
var high_score: u32 = 0;

pub fn lines(count: usize) void {
    switch (piece.last_tspin) {
        .FULL => score += root.srs.scoring_tspin[count],
        .NONE => if (count > 0) {
            score += root.srs.scoring_lines[count - 1];
        },
        .MINI => {},
    }
    if (score > high_score) high_score = score;
}

pub fn init() void {
    score = 0;
}

pub fn draw() void {
    var score_buf: [256]u8 = undefined;
    var high_score_buf: [256]u8 = undefined;
    const score_txt: [:0]const u8 = std.fmt.bufPrintSentinel(&score_buf, "SCORE: {d}", .{score}, 0) catch unreachable;
    const high_score_txt: [:0]const u8 = std.fmt.bufPrintSentinel(&high_score_buf, "HIGH: {d}", .{high_score}, 0) catch unreachable;
    const offset: f32 = @floatFromInt(@max(score_txt.len, high_score_txt.len));

    sdtx.canvas(sapp.widthf() * 0.3, sapp.heightf() * 0.3);
    sdtx.origin(sapp.widthf() * 0.0375 - offset - 1.5, sapp.heightf() * 0.0375 - 2.5);
    sdtx.home();
    sdtx.color3b(0xFF, 0xFF, 0xFF);
    sdtx.puts(score_txt);
    sdtx.crlf();
    sdtx.puts(high_score_txt);
}
