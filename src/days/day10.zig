const input_data = @embedFile("../inputs/10.txt");

const std = @import("std");

const Pos = struct {
    row: isize,
    col: isize,

    fn eql(self: Pos, other: Pos) bool {
        return self.row == other.row and self.col == other.col;
    }
};

fn adjacentTiles(cur: u8, next: u8, dx: isize, dy: isize) bool {

    // up
    if ((cur == 'L' or cur == 'J' or cur == '|') and dy == -1) {
        return next == '|' or next == '7' or next == 'F';
    }

    // down
    if ((cur == '7' or cur == 'F' or cur == '|') and dy == 1) {
        return next == '|' or next == 'L' or next == 'J';
    }

    // left
    if ((cur == '7' or cur == 'J' or cur == '-') and dx == -1) {
        return next == '-' or next == 'L' or next == 'F';
    }

    // right
    if ((cur == 'L' or cur == 'F' or cur == '-') and dx == 1) {
        return next == '-' or next == 'J' or next == '7';
    }

    return false;
}

const Maze = struct {
    tiles: std.ArrayList([]const u8),
    start_as: u8,
    rows: usize,
    cols: usize,

    fn new(tiles: std.ArrayList([]const u8), start_as: u8) Maze {
        return .{
            .tiles = tiles,
            .start_as = start_as,
            .rows = tiles.items.len,
            .cols = tiles.items[0].len,
        };
    }

    fn isValid(self: Maze, pos: Pos) bool {
        return pos.row < self.rows and pos.col < self.cols and pos.row >= 0 and pos.col >= 0;
    }

    fn areAdjacent(self: Maze, cur: Pos, next: Pos) bool {
        const dx = next.col - cur.col;
        const dy = next.row - cur.row;
        const dist = @abs(dx) + @abs(dy);
        if (dist != 1) {
            return false;
        }
        const cur_tile = self.get(cur);
        const next_tile = self.get(next);
        return adjacentTiles(cur_tile, next_tile, dx, dy);
    }

    fn get(self: Maze, pos: Pos) u8 {
        if (self.isValid(pos)) {
            const v = self.tiles.items[@intCast(pos.row)][@intCast(pos.col)];
            return if (v == 'S') self.start_as else v;
        }
        return '.';
    }

    fn getStart(self: Maze) ?Pos {
        for (0..self.rows) |row|
            for (0..self.cols) |col|
                if (self.tiles.items[row][col] == 'S') return Pos{ .col = @intCast(col), .row = @intCast(row) };
        return null;
    }

    fn getNext(self: Maze, cur: Pos, prev: Pos) ?Pos {
        const Delta = std.meta.Tuple(&.{ isize, isize });
        const offsets = comptime [_]Delta{ .{ 0, 1 }, .{ 1, 0 }, .{ 0, -1 }, .{ -1, 0 } };
        for (offsets) |ofs| {
            const dcol = ofs[1];
            const drow = ofs[0];
            const next = Pos{
                .col = cur.col + dcol,
                .row = cur.row + drow,
            };
            // std.debug.print("test next: {},{}\n", .{ next.col, next.row });
            if (next.eql(prev)) continue;
            if (self.areAdjacent(cur, next)) {
                return next;
            }
        }
        return null;
    }
};

const ConfigError = error{NoStart};

const LoopMask = struct {
    mask: []bool,
    cols: usize,

    fn mark(self: *LoopMask, pos: Pos) void {
        const row: usize = @intCast(pos.row);
        const col: usize = @intCast(pos.col);
        const idx = row * self.cols + col;
        self.mask[idx] = true;
    }

    fn isLoop(self: LoopMask, pos: Pos) bool {
        const row: usize = @intCast(pos.row);
        const col: usize = @intCast(pos.col);
        const idx = row * self.cols + col;
        return self.mask[idx];
    }

    fn clear(self: *LoopMask) void {
        @memset(self.mask, false);
    }
};

fn traceLoop(maze: Maze, start: Pos, mask: *LoopMask) ?usize {
    var cur = start;
    var prev = start;
    var steps: usize = 0;
    // std.debug.print("start\n", .{});
    while (true) {
        mask.mark(cur);
        const next = maze.getNext(cur, prev);
        if (next) |next_pos| {
            // std.debug.print("cur={},{}, next={},{}\n", .{ cur.col, cur.row, next_pos.col, next_pos.row });
            steps += 1;
            prev = cur;
            cur = next_pos;
            if (next_pos.eql(start)) {
                // loop found
                return steps;
            }
        } else {
            break;
        }
    }
    return null;
}

fn isOposite(a: u8, b: u8) bool {
    if (a == 'L' and b == '7') return true;
    if (a == 'F' and b == 'J') return true;
    return false;
}

fn countEnclosed(maze: Maze, mask: LoopMask) usize {
    var enclosed: usize = 0;
    for (0..maze.rows) |row| {
        var prev: u8 = '|';
        var intersections: usize = 0;
        for (0..maze.cols) |col| {
            const pos = Pos{ .row = @intCast(row), .col = @intCast(col) };
            const tile = maze.get(pos);
            if (mask.isLoop(pos)) {
                if (std.mem.indexOfScalar(u8, "|FL7J", tile) == null) {
                    continue;
                }
                if (!isOposite(prev, tile)) {
                    intersections += 1;
                    prev = tile;
                } else {
                    prev = '|';
                }
            } else {
                enclosed += intersections % 2;
            }
        }
    }
    return enclosed;
}

pub fn solve() !void {
    var lines = std.mem.split(u8, input_data, "\n");

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    var maze = std.ArrayList([]const u8).init(alloc);
    defer maze.deinit();

    while (lines.next()) |line| {
        if (line.len == 0) break;
        try maze.append(line);
    }

    const start = Maze.new(maze, 'S').getStart() orelse return ConfigError.NoStart;
    var mask_array = std.ArrayList(bool).init(alloc);
    defer mask_array.deinit();
    try mask_array.resize(maze.items.len * maze.items[0].len);
    var mask = LoopMask{ .cols = maze.items[0].len, .mask = mask_array.items };
    var answer: usize = 0;
    for ("FLJ7|-") |start_t| {
        mask.clear();
        const maze_t = Maze.new(maze, start_t);
        const len = traceLoop(maze_t, start, &mask) orelse 0;
        if (len > 0) {
            const enclosed = countEnclosed(maze_t, mask);
            std.debug.print("enclosed={}\n", .{enclosed});
        }
        answer = @max(answer, len);
    }
    std.debug.print("{}\n", .{answer / 2});
}
