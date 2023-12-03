const input_data = @embedFile("inputs/1.txt");

const std = @import("std");

fn evalLine(line: []const u8) !u64 {
    const n = line.len;

    const first: u64 = for (0..n) |idx| {
        const c = line[idx];
        if (std.ascii.isDigit(c)) {
            break c - '0';
        }
    } else 0;
    const last: u64 = for (1..(n + 1)) |idx| {
        const c = line[n - idx];
        if (std.ascii.isDigit(c)) {
            break c - '0';
        }
    } else 0;

    return first * 10 + last;
}

fn tryDigit(line: []const u8) ?u64 {
    const digit_repr = [_][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };
    if (std.ascii.isDigit(line[0])) {
        return line[0] - '0';
    }
    return for (digit_repr, 1..10) |repr, value| {
        if (std.mem.startsWith(u8, line, repr)) {
            break value;
        }
    } else null;
}

fn evalLine2(line: []const u8) !u64 {
    const n = line.len;

    const first: u64 = for (0..n) |idx| {
        const c = line[idx..n];
        const val = tryDigit(c) orelse {
            continue;
        };
        break val;
    } else 0;
    const last: u64 = for (1..(n + 1)) |idx| {
        const start = n - idx;
        const c = line[start..n];
        const val = tryDigit(c) orelse {
            continue;
        };
        break val;
    } else 0;

    return first * 10 + last;
}

pub fn solve() !void {
    var lines = std.mem.split(u8, input_data, "\n");
    var answer: u64 = 0;
    while (lines.next()) |line| {
        // std.debug.print("{s}\n", .{line});
        answer += try evalLine(line);
    }
    std.debug.print("{}\n", .{answer});
}
