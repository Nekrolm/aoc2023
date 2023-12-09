const std = @import("std");

const days = @import("days.zig").days;

pub fn main() !void {
    var args = std.process.args();
    _ = args.skip(); // skip argv[0] that should be a programm name
    const day = args.next() orelse {
        std.debug.print("day is not specified\n", .{});
        return;
    };
    const day_no = try std.fmt.parseInt(usize, day, 10);
    if (0 < day_no and day_no <= days.len) {
        try days[day_no - 1]();
    } else {
        std.debug.print("there is no code for day {} yet :(\n", .{day_no});
    }
}
