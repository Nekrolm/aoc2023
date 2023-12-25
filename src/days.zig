// zig fmt: off
pub const days = [_]*const fn () anyerror!void{
    @import("days/day1.zig").solve,
    @import("days/day2.zig").solve,
    @import("days/day3.zig").solve,
    @import("days/day4.zig").solve,
    @import("days/day5.zig").solve,
    day6,
    @import("days/day7.zig").solve,
    @import("days/day8.zig").solve,
    @import("days/day9.zig").solve,
    @import("days/day10.zig").solve,
    @import("days/day11.zig").solve,
    @import("days/day12.zig").solve,
    @import("days/day13.zig").solve,
    @import("days/day14.zig").solve,
    @import("days/day15.zig").solve,
};
// zig fmt: on

const std = @import("std");

fn day6() !void {
    std.debug.print("Solve this task with pen and paper!\n", .{});
}
