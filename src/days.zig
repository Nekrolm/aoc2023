pub const days = [_]*const fn () anyerror!void{
    @import("days/day1.zig").solve,
    @import("days/day2.zig").solve,
    @import("days/day3.zig").solve,
};
