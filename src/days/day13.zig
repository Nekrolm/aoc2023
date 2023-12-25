const std = @import("std");

const input_data = @embedFile("../inputs/13.txt");

const ParseError = error{ParseError};

const Reflection = struct {
    pos: usize,
    len: usize,
};

fn hemmingDistance(lhs: []const u8, rhs: []const u8) usize {
    var ans: usize = 0;
    for (lhs, rhs) |x, y| {
        if (x != y) ans += 1;
    }
    return ans;
}

fn solveHorizontalMirror(matrix: []const []const u8) Reflection {
    var max_reflection_len: usize = 0;
    var pos: usize = 0;
    for (1..matrix.len) |split_before| {
        const first_len = split_before;
        const second_len = matrix.len - split_before;
        const length_to_check = @min(first_len, second_len);

        // const is_mirror = for (0..length_to_check) |ofs| {
        //     const lhs = matrix[split_before - ofs - 1];
        //     const rhs = matrix[split_before + ofs];
        //     if (!std.mem.eql(u8, lhs, rhs)) {
        //         break false;
        //     }
        // } else true;

        var diffs: usize = 0;
        for (0..length_to_check) |ofs| {
            const lhs = matrix[split_before - ofs - 1];
            const rhs = matrix[split_before + ofs];
            diffs += hemmingDistance(lhs, rhs);
        }
        const is_mirror = diffs == 1;
        if (is_mirror) {
            std.debug.print("mirror: len={}, pos={}\n", .{ length_to_check, split_before });
            if (length_to_check > max_reflection_len) {
                max_reflection_len = length_to_check;
                pos = split_before;
            }
        }
    }
    return .{ .pos = pos, .len = max_reflection_len };
}

fn solveMatrix(alloc: std.mem.Allocator, matrix: []const []const u8) !usize {
    const horizontal = solveHorizontalMirror(matrix);

    var transposed = try std.ArrayList(u8).initCapacity(alloc, matrix.len * matrix[0].len);
    defer transposed.deinit();

    for (0..matrix[0].len) |col|
        for (0..matrix.len) |row| {
            try transposed.append(matrix[row][col]);
        };

    var transposed_view = try std.ArrayList([]const u8).initCapacity(alloc, matrix[0].len);
    defer transposed_view.deinit();

    for (0..matrix[0].len) |row| {
        const start = row * matrix.len;
        const end = start + matrix.len;
        try transposed_view.append(transposed.items[start..end]);
    }

    const vertical = solveHorizontalMirror(transposed_view.items);

    const answer = horizontal.pos * 100 + vertical.pos;
    return answer;
}

pub fn solve() !void {
    var lines = std.mem.split(u8, input_data, "\n");
    var answer: u64 = 0;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    var buf = try std.ArrayList([]const u8).initCapacity(alloc, 10);
    defer buf.deinit();
    while (lines.next()) |line| {
        if (line.len == 0) {
            answer += try solveMatrix(alloc, buf.items);
            buf.clearRetainingCapacity();
        } else {
            try buf.append(line);
        }
    }
    std.debug.print("{}\n", .{answer});
}
