const std = @import("std");

const input_data = @embedFile("../inputs/3.txt");

const Diap = struct {
    begin: usize,
    end: usize,

    fn isEmpty(self: *const Diap) bool {
        return self.begin == self.end;
    }

    fn extend(self: *const Diap, limit: usize) Diap {
        var ret = self.*;
        if (ret.begin > 0) {
            ret.begin -= 1;
        }
        if (ret.end < limit) {
            ret.end += 1;
        }
        return ret;
    }
};

fn containsAnyNonDotSymbol(range: []const u8) bool {
    return for (range) |c| {
        if (c != '.') {
            break true;
        }
    } else false;
}

fn processDiap(diap: Diap, current: []const u8, prev: ?[]const u8, next: ?[]const u8) !u64 {
    if (diap.isEmpty()) {
        return 0;
    }

    const number = try std.fmt.parseInt(u64, current[diap.begin..diap.end], 10);
    if (diap.begin > 0 and current[diap.begin - 1] != '.') {
        return number;
    }
    if (diap.end < current.len and current[diap.end] != '.') {
        return number;
    }

    const extended = diap.extend(current.len);
    if (prev) |prev_line| {
        if (containsAnyNonDotSymbol(prev_line[extended.begin..extended.end])) {
            return number;
        }
    }

    if (next) |next_line| {
        if (containsAnyNonDotSymbol(next_line[extended.begin..extended.end])) {
            return number;
        }
    }

    return 0;
}

fn processLine(current: []const u8, prev: ?[]const u8, next: ?[]const u8) !u64 {
    // std.debug.print("{s}\n", .{current});
    var start_index: usize = 0;
    var answer: u64 = 0;
    while (start_index < current.len) {
        var end_index = start_index;
        while (end_index < current.len and std.ascii.isDigit(current[end_index])) {
            end_index += 1;
        }

        const cur_val = try processDiap(Diap{ .begin = start_index, .end = end_index }, current, prev, next);
        // if (cur_val != 0) {
        //     std.debug.print("{}\n", .{cur_val});
        // }
        answer += cur_val;
        start_index = end_index + 1;
    }
    return answer;
}

const StorageError = error{ OutOfCapacity, OutOfBounds };

const NumbersStorage = struct {
    storage: [6]?u64,

    fn new() NumbersStorage {
        return NumbersStorage{ .storage = [_]?u64{ null, null, null, null, null, null } };
    }

    fn size(self: *const NumbersStorage) usize {
        var cnt: usize = 0;
        for (self.storage) |val| {
            if (val != null) {
                cnt += 1;
            }
        }
        return cnt;
    }

    fn push(self: *NumbersStorage, val: u64) StorageError!void {
        for (0..6) |idx| {
            if (self.storage[idx] == null) {
                self.storage[idx] = val;
                return;
            }
        }
        return StorageError.OutOfCapacity;
    }

    fn get(self: *NumbersStorage, idx: usize) StorageError!u64 {
        if (idx >= 6) {
            return StorageError.OutOfBounds;
        }

        return self.storage[idx] orelse StorageError.OutOfBounds;
    }
};

fn processAroundIndexAdjacent(idx: usize, line: []const u8, storage: *NumbersStorage) !void {
    if (!std.ascii.isDigit(line[idx])) {
        return processLeftRightAroundIndex(idx, line, storage);
    }

    var left = idx;
    while (left > 0 and std.ascii.isDigit(line[left - 1])) {
        left -= 1;
    }

    var right = idx;
    while (right < line.len and std.ascii.isDigit(line[right])) {
        right += 1;
    }
    try storage.push(try std.fmt.parseInt(u64, line[left..right], 10));
}

fn processLeftRightAroundIndex(idx: usize, line: []const u8, storage: *NumbersStorage) !void {
    var left = idx;
    while (left > 0 and std.ascii.isDigit(line[left - 1])) {
        left -= 1;
    }

    if (left != idx) {
        try storage.push(try std.fmt.parseInt(u64, line[left..idx], 10));
    }

    var right = idx + 1;
    while (right < line.len and std.ascii.isDigit(line[right])) {
        right += 1;
    }

    if (right != idx + 1) {
        try storage.push(try std.fmt.parseInt(u64, line[idx + 1 .. right], 10));
    }
}

fn processAroundIndex(idx: usize, current: []const u8, prev: ?[]const u8, next: ?[]const u8) !u64 {
    var storage = NumbersStorage.new();

    try processLeftRightAroundIndex(idx, current, &storage);

    if (next) |line| {
        try processAroundIndexAdjacent(idx, line, &storage);
    }
    if (prev) |line| {
        try processAroundIndexAdjacent(idx, line, &storage);
    }

    if (storage.size() == 2) {
        const v1 = try storage.get(0);
        const v2 = try storage.get(1);
        return v1 * v2;
    }
    return 0;
}

fn processLine2(current: []const u8, prev: ?[]const u8, next: ?[]const u8) !u64 {
    var answer: u64 = 0;
    for (0..current.len, current) |idx, c| {
        if (c == '*') {
            answer += try processAroundIndex(idx, current, prev, next);
        }
    }
    return answer;
}

pub fn solve() !void {
    var lines = std.mem.split(u8, input_data, "\n");
    var answer: u64 = 0;
    var prev_line: ?[]const u8 = null;
    var cur_line: ?[]const u8 = null;
    var next_line: ?[]const u8 = null;
    while (lines.next()) |line| {
        next_line = if (line.len > 0) line else null;
        if (cur_line) |cur| {
            answer += try processLine2(cur, prev_line, next_line);
        }
        prev_line = cur_line;
        cur_line = next_line;
        next_line = null;
    }
    if (cur_line) |cur| {
        answer += try processLine2(cur, prev_line, next_line);
    }
    std.debug.print("{}\n", .{answer});
}
