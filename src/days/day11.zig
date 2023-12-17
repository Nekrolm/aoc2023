const input_data = @embedFile("../inputs/11.txt");

const std = @import("std");

const Pos = struct {
    row: isize,
    col: isize,
};

const ExpandedGalaxy = struct {
    const GALAXY_WIDTH: comptime_int = 200;

    row_has_galaxy: [GALAXY_WIDTH]i32,
    col_has_galaxy: [GALAXY_WIDTH]i32,

    galaxies: std.ArrayList(Pos),

    fn init(alloc: std.mem.Allocator) ExpandedGalaxy {
        const galaxies = std.ArrayList(Pos).init(alloc);
        return ExpandedGalaxy{
            .galaxies = galaxies,
            .row_has_galaxy = [_]i32{0} ** GALAXY_WIDTH,
            .col_has_galaxy = [_]i32{0} ** GALAXY_WIDTH,
        };
    }
    fn deinit(self: *ExpandedGalaxy) void {
        self.galaxies.deinit();
    }

    fn recordGalaxy(self: *ExpandedGalaxy, pos: Pos) !void {
        try self.galaxies.append(pos);
        const row: usize = @intCast(pos.row);
        const col: usize = @intCast(pos.col);
        self.row_has_galaxy[row + 1] = 1;
        self.col_has_galaxy[col + 1] = 1;
    }

    fn recordRow(self: *ExpandedGalaxy, row: []const u8, row_no: usize) !void {
        for (row, 0..) |x, col_no| {
            if (x == '#') {
                try self.recordGalaxy(.{ .row = @intCast(row_no), .col = @intCast(col_no) });
            }
        }
    }

    fn integrateGalaxy(self: *ExpandedGalaxy) void {
        for (1..GALAXY_WIDTH) |idx| {
            self.col_has_galaxy[idx] += self.col_has_galaxy[idx - 1];
            self.row_has_galaxy[idx] += self.row_has_galaxy[idx - 1];
        }
    }

    fn distance(self: ExpandedGalaxy, lhs: Pos, rhs: Pos) usize {
        const dx_direct = @abs(lhs.col - rhs.col);
        const dx_non_expanded = @abs(self.col_has_galaxy[@intCast(rhs.col)] - self.col_has_galaxy[@intCast(lhs.col)]);

        const dy_direct = @abs(lhs.row - rhs.row);
        const dy_non_expanded = @abs(self.row_has_galaxy[@intCast(rhs.row)] - self.row_has_galaxy[@intCast(lhs.row)]);

        const expanded = dy_direct - dy_non_expanded + dx_direct - dx_non_expanded;

        return expanded * 1000000 + dy_non_expanded + dx_non_expanded;
    }
};

pub fn solve() !void {
    var lines = std.mem.split(u8, input_data, "\n");

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    var galaxy = ExpandedGalaxy.init(alloc);
    defer galaxy.deinit();

    var row: usize = 0;
    while (lines.next()) |line| {
        if (line.len == 0) break;
        try galaxy.recordRow(line, row);
        row += 1;
    }

    galaxy.integrateGalaxy();
    var answer: usize = 0;
    const galaxies = galaxy.galaxies.items;
    for (0..galaxies.len) |cur|
        for (cur + 1..galaxies.len) |next| {
            answer += galaxy.distance(galaxies[cur], galaxies[next]);
        };
    std.debug.print("{}\n", .{answer});
}
