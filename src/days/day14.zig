const std = @import("std");

const input_data = @embedFile("../inputs/14.txt");

const World = struct {
    tiles: []u8,
    rows: usize,
    cols: usize,

    fn evolveUp(self: *World) void {
        for (0..self.cols) |col| {
            self.evolveColumnUp(col);
        }
    }

    fn evolveDown(self: *World) void {
        for (0..self.cols) |col| {
            self.evolveColumnDown(col);
        }
    }

    fn evolveLeft(self: *World) void {
        for (0..self.rows) |row| {
            self.evolveRowLeft(row);
        }
    }

    fn evolveRight(self: *World) void {
        for (0..self.rows) |row| {
            self.evolveRowRight(row);
        }
    }

    fn evolve(self: *World) void {
        self.evolveUp();
        self.evolveLeft();
        self.evolveDown();
        self.evolveRight();
    }

    fn evolveColumnUp(self: *World, col: usize) void {
        var pos: usize = 0;
        for (0..self.rows) |row| {
            while (pos < row and self.tiles[pos * self.cols + col] != '.') {
                pos += 1;
            }
            const cur = &self.tiles[row * self.cols + col];
            if (cur.* == 'O') {
                cur.* = '.';
                self.tiles[pos * self.cols + col] = 'O';
                pos += 1;
            } else if (cur.* == '#') {
                pos = row + 1;
            }
        }
    }

    fn evolveColumnDown(self: *World, col: usize) void {
        var pos: usize = self.rows - 1;
        for (0..self.rows) |row_idx| {
            const row = self.rows - 1 - row_idx;
            while (pos > row and self.tiles[pos * self.cols + col] != '.') {
                pos -= 1;
            }
            const cur = &self.tiles[row * self.cols + col];
            if (cur.* == 'O') {
                cur.* = '.';
                self.tiles[pos * self.cols + col] = 'O';
                pos -|= 1;
            } else if (cur.* == '#') {
                pos = row -| 1;
            }
        }
    }

    fn evolveRowLeft(self: *World, row: usize) void {
        var pos: usize = 0;
        for (0..self.cols) |col| {
            while (pos < col and self.tiles[row * self.cols + pos] != '.') {
                pos += 1;
            }
            const cur = &self.tiles[row * self.cols + col];
            if (cur.* == 'O') {
                cur.* = '.';
                self.tiles[row * self.cols + pos] = 'O';
                pos += 1;
            } else if (cur.* == '#') {
                pos = col + 1;
            }
        }
    }

    fn evolveRowRight(self: *World, row: usize) void {
        var pos: usize = self.cols - 1;
        for (0..self.cols) |col_idx| {
            const col = self.cols - 1 - col_idx;
            while (pos > col and self.tiles[row * self.cols + pos] != '.') {
                pos -= 1;
            }
            const cur = &self.tiles[row * self.cols + col];
            if (cur.* == 'O') {
                cur.* = '.';
                self.tiles[row * self.cols + pos] = 'O';
                pos -|= 1;
            } else if (cur.* == '#') {
                pos = col -| 1;
            }
        }
    }

    fn display(self: World) void {
        for (0..self.rows) |row| {
            const row_s = self.tiles[row * self.cols .. (row + 1) * self.cols];
            std.debug.print("{s}\n", .{row_s});
        }
    }

    fn estimate(self: World) usize {
        var answer: usize = 0;
        for (0..self.rows) |row| {
            const row_s = self.tiles[row * self.cols .. (row + 1) * self.cols];
            answer += std.mem.count(u8, row_s, "O") * (self.rows - row);
        }
        return answer;
    }
};

fn findPeriod(seq: []const usize) usize {
    for (4..seq.len / 3) |period| {
        const last = seq[seq.len - period .. seq.len];
        const over_period = seq[seq.len - 2 * period .. seq.len - period];
        const over_2_periods = seq[seq.len - 3 * period .. seq.len - 2 * period];
        if (std.mem.eql(usize, last, over_period) and std.mem.eql(usize, last, over_2_periods)) {
            return period;
        }
    }
    return 0;
}

pub fn solve() !void {
    var lines = std.mem.split(u8, input_data, "\n");
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    var buf = std.ArrayList(u8).init(alloc);
    defer buf.deinit();
    var cols: usize = 0;
    while (lines.next()) |line| {
        if (line.len == 0) {
            break;
        } else {
            try buf.appendSlice(line);
            cols = line.len;
        }
    }
    const rows = buf.items.len / cols;

    var world = World{ .tiles = buf.items, .cols = cols, .rows = rows };

    var sequence = std.ArrayList(usize).init(alloc);
    defer sequence.deinit();

    for (0..10000) |_| {
        world.evolve();
        // world.display();
        const val = world.estimate();
        std.debug.print("{}\n", .{val});
        try sequence.append(val);
    }

    const p = findPeriod(sequence.items);
    std.debug.print("PERIDOD: {}\n", .{p});

    const unique = sequence.items[sequence.items.len - p .. sequence.items.len];
    const extra = (1000000000 - 10000 - 1) % p;
    std.debug.print("answer: {}\n", .{unique[extra]});
}
