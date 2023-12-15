const input_data = @embedFile("../inputs/9.txt");

const std = @import("std");

fn processList(comptime T: type, list: []const u8, context: anytype, callback: fn (@TypeOf(context), T) anyerror!void) !void {
    var iter = std.mem.split(u8, list, " ");
    while (iter.next()) |num_str| {
        if (num_str.len == 0) continue;
        const val = try std.fmt.parseInt(T, num_str, 10);
        try callback(context, val);
    }
}

fn allZeros(items: []const i64) bool {
    return for (items) |x| {
        if (x != 0) break false;
    } else true;
}

fn solveForLine(alloc: std.mem.Allocator, line: []const u8) !i64 {
    var sequence = try std.ArrayList(i64).initCapacity(alloc, 3000);
    defer sequence.deinit();
    try processList(i64, line, &sequence, std.ArrayList(i64).append);

    // uncomment to solve part 2
    // std.mem.reverse(i64, sequence.items);

    var answer: i64 = 0;
    while (!allZeros(sequence.items) and sequence.items.len > 0) {
        for (0..sequence.items.len - 1) |idx| {
            const diff = sequence.items[idx + 1] - sequence.items[idx];
            sequence.items[idx] = diff;
        }
        answer += sequence.pop();
    }
    return answer;
}

pub fn solve() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    var lines = std.mem.split(u8, input_data, "\n");
    var answer: i64 = 0;
    while (lines.next()) |line| {
        if (line.len == 0) break;
        answer += try solveForLine(alloc, line);
    }
    std.debug.print("{}\n", .{answer});
}
