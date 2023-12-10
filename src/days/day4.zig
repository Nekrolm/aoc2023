const input_data = @embedFile("../inputs/4.txt");

const std = @import("std");

// pub fn solve() !void {
//     var lines = std.mem.split(u8, input_data, "\n");
//     var answer: u64 = 0;
//     while (lines.next()) |line| {
//         // std.debug.print("{s}\n", .{line});
//         if (line.len == 0) {
//             break;
//         }
//         answer += try evalCard(line);
//     }
//     std.debug.print("{}\n", .{answer});
// }

pub fn solve() !void {
    var lines = std.mem.split(u8, input_data, "\n");
    var cards_counter: [300]u64 = [_]u64{0} ** 300;
    while (lines.next()) |line| {
        // std.debug.print("{s}\n", .{line});
        if (line.len == 0) {
            break;
        }
        try evalCard2(line, &cards_counter);
    }
    var answer: u64 = 0;
    for (cards_counter) |counter| {
        answer += counter;
    }
    std.debug.print("{}\n", .{answer});
}

const EvalError = error{ ParseError, StorageError };

const Storage = struct {
    storage: [100]bool,

    fn init() Storage {
        return .{
            .storage = [_]bool{false} ** 100,
        };
    }

    fn insert(self: *Storage, val: u8) EvalError!void {
        if (val >= self.storage.len) {
            return EvalError.StorageError;
        }
        self.storage[val] = true;
    }

    fn contains(self: *const Storage, val: u8) bool {
        if (val >= self.storage.len) {
            return false;
        }
        return self.storage[val];
    }
};

fn process_list(comptime T: type, list: []const u8, context: anytype, callback: fn (@TypeOf(context), T) anyerror!void) !void {
    var iter = std.mem.split(u8, list, " ");
    while (iter.next()) |num_str| {
        if (num_str.len == 0) continue;
        const val = try std.fmt.parseInt(T, num_str, 10);
        try callback(context, val);
    }
}

fn evalCard(line: []const u8) !u64 {
    // Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
    const card_prefix_end = std.mem.indexOfScalarPos(u8, line, 0, ':') orelse return EvalError.ParseError;
    const card_separator = std.mem.indexOfScalarPos(u8, line, card_prefix_end, '|') orelse return EvalError.ParseError;

    const list_to_search = line[card_prefix_end + 1 .. card_separator - 1];
    const list_have = line[card_separator + 1 .. line.len];

    var numbers = Storage.init();
    try process_list(u8, list_have, &numbers, Storage.insert);

    const Context = struct {
        counter: u8,
        storage: *const Storage,

        const Self = @This();

        fn try_find(self: *Self, val: u8) !void {
            if (self.storage.contains(val)) {
                self.counter += 1;
            }
        }
    };

    var ctx = Context{ .counter = 0, .storage = &numbers };

    try process_list(u8, list_to_search, &ctx, Context.try_find);

    if (ctx.counter == 0) {
        return 0;
    } else {
        const power = ctx.counter - 1;
        const one: u64 = 1;
        const power_shift: u6 = @intCast(power & 0x3F);
        return one << power_shift;
    }
}

fn evalCard2(line: []const u8, cards_counter: []u64) !void {

    // Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
    const card_prefix_end = std.mem.indexOfScalarPos(u8, line, 0, ':') orelse return EvalError.ParseError;
    const card_separator = std.mem.indexOfScalarPos(u8, line, card_prefix_end, '|') orelse return EvalError.ParseError;

    const space_before_index_end = std.mem.lastIndexOf(u8, line[0..card_prefix_end], " ") orelse return EvalError.ParseError;

    const card_idx = try std.fmt.parseInt(usize, line[space_before_index_end + 1 .. card_prefix_end], 10);

    cards_counter[card_idx] += 1;

    const to_add_on_win = cards_counter[card_idx];

    const list_to_search = line[card_prefix_end + 1 .. card_separator - 1];
    const list_have = line[card_separator + 1 .. line.len];

    var numbers = Storage.init();
    try process_list(u8, list_have, &numbers, Storage.insert);

    const Context = struct {
        counter: u8,
        storage: *const Storage,

        const Self = @This();

        fn try_find(self: *Self, val: u8) !void {
            if (self.storage.contains(val)) {
                self.counter += 1;
            }
        }
    };

    var ctx = Context{ .counter = 0, .storage = &numbers };

    try process_list(u8, list_to_search, &ctx, Context.try_find);

    const next_card_idx = card_idx + 1;
    for (next_card_idx..(next_card_idx + ctx.counter)) |idx| {
        cards_counter[idx] += to_add_on_win;
    }
}
