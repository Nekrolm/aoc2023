const std = @import("std");

// const trebuchet = @import("trebuchet.zig");
const cubes = @import("cubes.zig");

pub fn main() !void {
    try cubes.solve();
}
