const std = @import("std");

const input_data = @embedFile("../inputs/12.txt");

const ParseError = error{ParseError};

fn processList(comptime T: type, list: []const u8, context: anytype, callback: fn (@TypeOf(context), T) anyerror!void) !void {
    var iter = std.mem.split(u8, list, ",");
    while (iter.next()) |num_str| {
        if (num_str.len == 0) continue;
        const val = try std.fmt.parseInt(T, num_str, 10);
        try callback(context, val);
    }
}

fn solveLine(alloc: std.mem.Allocator, line: []const u8, buf: *std.ArrayList(u8)) !usize {
    var parts = std.mem.split(u8, line, " ");
    const mask = parts.first();
    const config = parts.next() orelse return ParseError.ParseError;
    buf.clearRetainingCapacity();
    try processList(u8, config, buf, std.ArrayList(u8).append);

    var config_list = try std.ArrayList(u8).initCapacity(alloc, buf.items.len);
    defer config_list.deinit();
    for (0..5) |_|
        for (buf.items) |val| {
            try config_list.append(val);
        };

    var string = try std.ArrayList(u8).initCapacity(alloc, mask.len * 5 + 5);
    defer string.deinit();
    for (0..5) |_| {
        try string.appendSlice(mask);
        try string.append('?');
    }
    _ = string.pop();

    const mask_trimmed = std.mem.trim(u8, string.items, ".");
    var dp = try Lookup.init(alloc, mask_trimmed.len, config_list.items.len);
    defer dp.deinit();
    return solveMask(&dp, mask_trimmed, config_list.items);
}

const Lookup = struct {
    table: std.ArrayList(?usize),
    string_len: usize,

    fn init(alloc: std.mem.Allocator, string_len: usize, config_len: usize) !Lookup {
        var table = std.ArrayList(?usize).init(alloc);
        errdefer table.deinit();
        try table.resize((string_len + 1) * (config_len + 1));
        @memset(table.items, null);
        return .{ .table = table, .string_len = string_len + 1 };
    }

    fn deinit(self: *Lookup) void {
        self.table.deinit();
    }

    fn get(self: Lookup, skip_prefix: usize, skip_config: usize) ?usize {
        return self.table.items[skip_config * self.string_len + skip_prefix];
    }

    fn set(self: *Lookup, skip_prefix: usize, skip_config: usize, val: usize) void {
        self.table.items[skip_config * self.string_len + skip_prefix] = val;
    }
};

fn solveMaskDP(dp: *Lookup, mask_raw: []const u8, skip_prefix: usize, config_raw: []const u8, skip_config: usize) usize {
    if (dp.get(skip_prefix, skip_config)) |res| {
        return res;
    }

    var mask = mask_raw[skip_prefix..mask_raw.len];
    const config = config_raw[skip_config..config_raw.len];

    var max_hits: usize = 0;
    for (config) |c| max_hits += c;

    const hits = std.mem.count(u8, mask, "#");

    if (hits > max_hits) {
        return 0;
    }

    if (config.len == 0) {
        return 1; // we know that hits == 0 here
    }

    const required_min_len = max_hits + config.len - 1;

    if (mask.len < required_min_len) {
        return 0;
    }

    const block = config[0];

    var need_skip: usize = 0;
    while (mask.len >= block and std.mem.count(u8, mask[0..block], ".") > 0) {
        need_skip += 1;
        if (mask[0] == '#') {
            return 0;
        }
        mask = mask[1..mask.len];
    }

    if (mask.len < required_min_len) {
        return 0;
    }

    if (block == mask.len) {
        if (std.mem.count(u8, mask, ".") > 0) {
            return 0;
        }
        return 1;
    }

    if (mask[0] == '#') {
        if (mask[block] == '#') {
            return 0;
        }
        const ret = solveMaskDP(dp, mask_raw, skip_prefix + need_skip + block + 1, config_raw, skip_config + 1);
        dp.set(skip_prefix, skip_config, ret);
        return ret;
    }

    if (mask[block] == '#') {
        // don't set! it is the only option
        const ret = solveMaskDP(dp, mask_raw, skip_prefix + need_skip + 1, config_raw, skip_config);
        dp.set(skip_prefix, skip_config, ret);
        return ret;
    }

    // '?' here
    const try_set = solveMaskDP(dp, mask_raw, skip_prefix + need_skip + block + 1, config_raw, skip_config + 1);
    const try_not_set = solveMaskDP(dp, mask_raw, skip_prefix + need_skip + 1, config_raw, skip_config);
    dp.set(skip_prefix, skip_config, try_set + try_not_set);
    return try_set + try_not_set;
}

fn solveMask(dp: *Lookup, mask: []const u8, config: []const u8) usize {
    @memset(dp.table.items, null);
    return solveMaskDP(dp, mask, 0, config, 0);
}

pub fn solve() !void {
    var lines = std.mem.split(u8, input_data, "\n");
    var answer: u64 = 0;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    var buf = try std.ArrayList(u8).initCapacity(alloc, 10);
    var counter: usize = 1;
    while (lines.next()) |line| {
        if (line.len == 0) {
            break;
        }
        const val = try solveLine(alloc, line, &buf);
        answer += val;
        std.debug.print("processed: {} --- {}\n", .{ counter, val });
        counter += 1;
    }
    std.debug.print("{}\n", .{answer});
}
