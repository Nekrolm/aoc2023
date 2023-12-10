const input_data = @embedFile("../inputs/5.txt");

const std = @import("std");

const Mapping = struct {
    start_from: u64,
    start_to: u64,
    length: u64,
};

fn mappingLess(_: void, lhs: Mapping, rhs: Mapping) bool {
    return lhs.start_from < rhs.start_from;
}

const IntersectResult = struct { unchanged_left: Range, mapped: Range, unchanged_right: Range };

const Range = struct {
    begin: u64,
    length: u64,

    fn empty() Range {
        return .{ .begin = 0, .length = 0 };
    }

    fn print(self: Range) void {
        std.debug.print("begin={}, end={}\n", .{ self.begin, self.begin + self.length });
    }

    fn isEmpty(self: *const Range) bool {
        return self.length == 0;
    }

    fn intersect(input: Range, mapper: Range) IntersectResult {
        const intersection_begin = @max(input.begin, mapper.begin);
        const intersection_end = @min(input.begin + input.length, mapper.begin + mapper.length);

        if (intersection_begin >= intersection_end) {
            // no intersecion
            if (input.begin >= mapper.begin + mapper.length) {
                return .{ .unchanged_left = Range.empty(), .mapped = Range.empty(), .unchanged_right = input };
            } else {
                return .{
                    .unchanged_left = input,
                    .mapped = Range.empty(),
                    .unchanged_right = Range.empty(),
                };
            }
        }

        const unchanged_left = Range{ .begin = input.begin, .length = intersection_begin - input.begin };
        const mapped = Range{ .begin = intersection_begin, .length = intersection_end - intersection_begin };
        const unchanged_right = Range{ .begin = intersection_end, .length = input.begin + input.length - intersection_end };

        return .{ .unchanged_left = unchanged_left, .mapped = mapped, .unchanged_right = unchanged_right };
    }
};

fn rangeLessThan(_: void, lhs: Range, rhs: Range) bool {
    return lhs.begin < rhs.begin;
}

fn mergeRanges(ranges: *std.ArrayList(Range)) void {
    std.sort.pdq(Range, ranges.items, {}, rangeLessThan);
    var last_idx: usize = 0;
    for (ranges.items) |cur_range| {
        const last_range = ranges.items[last_idx];
        if (cur_range.begin <= last_range.begin + last_range.length) {
            const new_end = cur_range.begin + cur_range.length;
            ranges.items[last_idx].length = new_end - last_range.begin;
        } else {
            last_idx += 1;
            ranges.items[last_idx] = cur_range;
        }
    }
    const new_size = @min(last_idx + 1, ranges.items.len);
    ranges.resize(new_size) catch {};
}

const Map = struct {
    storage: std.ArrayList(Mapping),

    fn init(alloc: std.mem.Allocator) !Map {
        return .{ .storage = try std.ArrayList(Mapping).initCapacity(alloc, 300) };
    }

    fn deinit(self: Map) void {
        self.storage.deinit();
    }

    fn insert(self: *Map, mapping: Mapping) !void {
        try self.storage.append(mapping);
    }

    fn prepareMappings(self: *Map) void {
        std.sort.pdq(Mapping, self.storage.items, {}, mappingLess);
    }

    fn map(self: *const Map, value: u64) u64 {
        const items = self.storage.items;
        var left: u64 = 0;
        var right = items.len;
        var match: ?*const Mapping = null;
        while (left < right) {
            const mid = left + (right - left) / 2;
            const val = &items[mid];
            if (val.start_from <= value) {
                match = val;
                left = mid + 1;
            } else {
                right = mid;
            }
        }
        if (match) |matched_value| {
            const end = matched_value.start_from + matched_value.length;
            if (value < end) {
                return matched_value.start_to + (value - matched_value.start_from);
            } else {
                return value;
            }
        } else {
            return value;
        }
    }

    fn mapRange(self: *const Map, range: Range, output: *std.ArrayList(Range)) !void {
        if (range.length == 0) {
            return;
        }

        const items = self.storage.items;
        var match_begin: ?u64 = null;
        {
            var left: u64 = 0;
            var right = items.len;
            while (left < right) {
                const mid = left + (right - left) / 2;
                const val = &items[mid];
                if (val.start_from <= range.begin) {
                    match_begin = mid;
                    left = mid + 1;
                } else {
                    right = mid;
                }
            }
        }
        var match_end: ?usize = null;
        {
            var left: u64 = 0;
            var right = items.len;
            while (left < right) {
                const mid = left + (right - left) / 2;
                const val = &items[mid];
                if (val.start_from < range.begin + range.length) {
                    match_end = mid;
                    left = mid + 1;
                } else {
                    right = mid;
                }
            }
        }

        var input_range = range;

        const match_begin_idx = match_begin orelse (match_end orelse items.len);
        const match_end_idx = if (match_end) |end|
            end + 1
        else
            items.len;

        for (match_begin_idx..match_end_idx) |idx| {
            const cur_range = Range{ .begin = items[idx].start_from, .length = items[idx].length };
            const intersect_result = input_range.intersect(cur_range);
            if (!intersect_result.unchanged_left.isEmpty()) {
                try output.append(intersect_result.unchanged_left);
            }
            if (!intersect_result.mapped.isEmpty()) {
                const mapped_val = items[idx].start_to + (intersect_result.mapped.begin - items[idx].start_from);
                try output.append(.{ .begin = mapped_val, .length = intersect_result.mapped.length });
            }
            input_range = intersect_result.unchanged_right;
            if (intersect_result.unchanged_right.isEmpty()) {
                break;
            }
        }
        if (!input_range.isEmpty()) {
            try output.append(input_range);
        }
    }
};

const ParsingError = error{ParsingError};

fn parseMapTable(iter: *std.mem.SplitIterator(u8, std.mem.DelimiterType.sequence), alloc: std.mem.Allocator) !Map {
    _ = iter.next();
    var map = try Map.init(alloc);
    errdefer map.deinit();
    var parsed_map_line = try std.ArrayList(u64).initCapacity(alloc, 3);
    defer parsed_map_line.deinit();
    while (iter.next()) |line| {
        if (line.len == 0) {
            break;
        }
        parsed_map_line.clearRetainingCapacity();
        try processNumbersList(u64, line, &parsed_map_line, std.ArrayList(u64).append);
        const parsed_items = parsed_map_line.items;
        if (parsed_items.len != 3) {
            return ParsingError.ParsingError;
        }
        try map.insert(.{ .length = parsed_items[2], .start_from = parsed_items[1], .start_to = parsed_items[0] });
    }
    map.prepareMappings();
    return map;
}

fn processNumbersList(comptime T: type, list: []const u8, context: anytype, callback: fn (@TypeOf(context), T) anyerror!void) !void {
    var iter = std.mem.split(u8, list, " ");
    while (iter.next()) |num_str| {
        if (num_str.len == 0) continue;
        const val = try std.fmt.parseInt(T, num_str, 10);
        try callback(context, val);
    }
}

pub fn solve1() !void {
    var lines = std.mem.split(u8, input_data, "\n");

    const input_seeds = lines.first();
    _ = lines.next();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const seed_to_soil = try parseMapTable(&lines, alloc);
    defer seed_to_soil.deinit();
    const soil_to_fertilizer = try parseMapTable(&lines, alloc);
    defer soil_to_fertilizer.deinit();
    const fertilizer_to_water = try parseMapTable(&lines, alloc);
    defer fertilizer_to_water.deinit();
    const water_to_light = try parseMapTable(&lines, alloc);
    defer water_to_light.deinit();
    const light_to_temperature = try parseMapTable(&lines, alloc);
    defer light_to_temperature.deinit();

    const temperature_to_humidity = try parseMapTable(&lines, alloc);
    defer temperature_to_humidity.deinit();
    const humidity_to_location = try parseMapTable(&lines, alloc);
    defer humidity_to_location.deinit();

    const SeedProcessor = struct {
        mappers: []*const Map,
        min_answer: ?u64,

        const Self = @This();
        fn processSeed(self: *Self, val: u64) !void {
            var mapped_val = val;
            for (self.mappers) |mapper| {
                mapped_val = mapper.map(mapped_val);
            }
            self.min_answer = @min(self.min_answer orelse mapped_val, mapped_val);
        }
    };

    var mappers = [_]*const Map{ &seed_to_soil, &soil_to_fertilizer, &fertilizer_to_water, &water_to_light, &light_to_temperature, &temperature_to_humidity, &humidity_to_location };
    const mappers_slice = mappers[0..mappers.len];
    var processor = SeedProcessor{ .mappers = mappers_slice, .min_answer = null };

    try processNumbersList(u64, input_seeds[7..input_seeds.len], &processor, SeedProcessor.processSeed);

    if (processor.min_answer) |answer| {
        std.debug.print("{}\n", .{answer});
    }
}

fn printRanges(ranges: []const Range) void {
    std.debug.print("RANGE: \n", .{});
    for (ranges) |range| {
        std.debug.print("begin {}, end {}\n", .{ range.begin, range.begin + range.length });
    }
}

fn processRanges(mappers: []*const Map, input: *std.ArrayList(Range), buffer: *std.ArrayList(Range)) !*std.ArrayList(Range) {
    // printRanges(input.items);
    var input_arr = input;
    var output_arr = buffer;
    for (mappers) |mapper| {
        output_arr.clearRetainingCapacity();
        for (input_arr.items) |range| {
            try mapper.mapRange(range, output_arr);
        }
        mergeRanges(output_arr);
        // printRanges(output_arr.items);
        const temp = input_arr;
        input_arr = output_arr;
        output_arr = temp;
    }
    return input_arr;
}

pub fn solve() !void {
    var lines = std.mem.split(u8, input_data, "\n");

    const input_seeds = lines.first();
    _ = lines.next();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const seed_to_soil = try parseMapTable(&lines, alloc);
    defer seed_to_soil.deinit();
    const soil_to_fertilizer = try parseMapTable(&lines, alloc);
    defer soil_to_fertilizer.deinit();
    const fertilizer_to_water = try parseMapTable(&lines, alloc);
    defer fertilizer_to_water.deinit();
    const water_to_light = try parseMapTable(&lines, alloc);
    defer water_to_light.deinit();
    const light_to_temperature = try parseMapTable(&lines, alloc);
    defer light_to_temperature.deinit();

    const temperature_to_humidity = try parseMapTable(&lines, alloc);
    defer temperature_to_humidity.deinit();
    const humidity_to_location = try parseMapTable(&lines, alloc);
    defer humidity_to_location.deinit();

    var mappers = [_]*const Map{ &seed_to_soil, &soil_to_fertilizer, &fertilizer_to_water, &water_to_light, &light_to_temperature, &temperature_to_humidity, &humidity_to_location };
    const mappers_slice = mappers[0..mappers.len];

    var input = std.ArrayList(u64).init(alloc);
    defer input.deinit();
    try processNumbersList(u64, input_seeds[7..input_seeds.len], &input, std.ArrayList(u64).append);

    var initial_ranges = try std.ArrayList(Range).initCapacity(alloc, input.items.len);
    defer initial_ranges.deinit();

    for (0..(input.items.len / 2)) |idx| {
        try initial_ranges.append(.{ .begin = input.items[idx * 2], .length = input.items[idx * 2 + 1] });
    }

    var buffer = try std.ArrayList(Range).initCapacity(alloc, 1000);
    defer buffer.deinit();

    const result = try processRanges(mappers_slice, &initial_ranges, &buffer);

    std.debug.print("{}\n", .{result.items[0].begin});
}
