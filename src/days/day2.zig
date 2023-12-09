const std = @import("std");

const input_data = @embedFile("../inputs/2.txt");

const Error = error{ Unknown, ParseError };

const Configuration = struct {
    red: u64,
    green: u64,
    blue: u64,

    pub fn addEvent(self: *Configuration, event: []const u8) Error!void {
        const space_idx = std.mem.indexOfScalar(u8, event, ' ') orelse return Error.ParseError;
        const value_str = event[0..space_idx];
        const value = std.fmt.parseInt(u64, value_str, 10) catch return Error.ParseError;
        const event_type = event[(space_idx + 1)..];
        // zig fmt: off
        const storage = if (std.mem.startsWith(u8, event_type, "red")) &self.red 
                         else if (std.mem.startsWith(u8, event_type, "blue")) &self.blue 
                         else if (std.mem.startsWith(u8, event_type, "green")) &self.green 
                         else return Error.ParseError;
        // zig fmt: on
        storage.* = @max(storage.*, value);
    }

    pub fn power(self: *const Configuration) u64 {
        return self.blue * self.green * self.red;
    }

    pub fn isSubsetOf(self: *const Configuration, other: *const Configuration) bool {
        return self.red <= other.red and self.blue <= other.blue and self.green <= other.green;
    }
};

// 12 red cubes, 13 green cubes, and 14 blue cubes.
const bag_config = Configuration{ .blue = 14, .red = 12, .green = 13 };

// Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
// Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue

fn parseGame(line: []const u8) Error!struct { index: u64, line: []const u8 } {
    const skip_game = 5;
    const colon_pos = std.mem.indexOfScalarPos(u8, line, skip_game, ':') orelse return Error.ParseError;
    const game_index = line[skip_game..colon_pos];
    const game_conf = line[(colon_pos + 2)..];
    const index = std.fmt.parseInt(u64, game_index, 10) catch return Error.ParseError;

    return .{
        .index = index,
        .line = game_conf,
    };
}

fn isRoundPossible(round: []const u8, config: *const Configuration, round_acc: *Configuration) Error!bool {
    var seq = std.mem.split(u8, round, ", ");

    while (seq.next()) |event| {
        try round_acc.addEvent(event);
    }
    return round_acc.isSubsetOf(config);
}

fn isPossible(line: []const u8, config: *const Configuration) Error!bool {
    var round_iter = std.mem.split(u8, line, "; ");
    var game_config = Configuration{ .blue = 0, .green = 0, .red = 0 };
    while (round_iter.next()) |round| {
        if (!try isRoundPossible(round, config, &game_config)) {
            return false;
        }
    }
    return true;
}

fn power(line: []const u8, config: *const Configuration) Error!u64 {
    var round_iter = std.mem.split(u8, line, "; ");
    var game_config = Configuration{ .blue = 0, .green = 0, .red = 0 };
    while (round_iter.next()) |round| {
        _ = try isRoundPossible(round, config, &game_config);
    }
    return game_config.power();
}

pub fn solve() !void {
    std.debug.print("debug\n", .{});
    var games = std.mem.split(u8, input_data, "\n");
    var answer: u64 = 0;
    while (games.next()) |game_line| {
        if (game_line.len == 0) continue;
        // std.debug.print("line: {s}\n", .{game_line});
        const parsed = try parseGame(game_line);
        // const index = parsed.index;
        // if (try isPossible(parsed.line, &bag_config)) {
        //     answer += index;
        // }
        answer += try power(parsed.line, &bag_config);
    }
    std.debug.print("{}\n", .{answer});
}
