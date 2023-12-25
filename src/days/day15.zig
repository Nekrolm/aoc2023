const std = @import("std");

const input_data = @embedFile("../inputs/15.txt");

fn hashIt(str: []const u8) usize {
    var res: usize = 0;
    for (str) |x| {
        res += x;
        res *= 17;
        res %= 256;
    }
    return res;
}

const Lens = struct {
    label: []const u8,
    value: usize,
};

const Box = struct {
    storage: std.ArrayList(Lens),
    fn init(alloc: std.mem.Allocator) Box {
        return .{ .storage = std.ArrayList(Lens).init(alloc) };
    }

    fn deinit(self: Box) void {
        self.storage.deinit();
    }

    fn findLens(self: Box, id: []const u8) ?usize {
        for (self.storage.items, 0..) |lens, idx| {
            if (std.mem.eql(u8, id, lens.label)) {
                return idx;
            }
        }
        return null;
    }

    fn removeLense(self: *Box, id: []const u8) void {
        if (self.findLens(id)) |idx| {
            _ = self.storage.orderedRemove(idx);
        }
    }

    fn addLense(self: *Box, lens: Lens) !void {
        if (self.findLens(lens.label)) |idx| {
            self.storage.items[idx].value = lens.value;
        } else {
            try self.storage.append(lens);
        }
    }

    fn power(self: Box) usize {
        var res: usize = 0;
        for (self.storage.items, 0..) |item, idx| {
            res += item.value * (idx + 1);
        }
        return res;
    }
};

const System = struct {
    boxes: [256]Box,

    fn init(alloc: std.mem.Allocator) System {
        var boxes = [_]Box{undefined} ** 256;
        for (&boxes) |*box| {
            box.* = Box.init(alloc);
        }
        return .{ .boxes = boxes };
    }

    fn deinit(self: System) void {
        for (self.boxes) |box| {
            box.deinit();
        }
    }

    fn process(self: *System, cmd: []const u8) !void {
        if (cmd[cmd.len - 1] == '-') {
            const label = cmd[0 .. cmd.len - 1];
            const hash = hashIt(label);
            self.boxes[hash].removeLense(label);
        } else {
            const label = cmd[0 .. cmd.len - 2];
            const val = (cmd[cmd.len - 1] - '0');
            const hash = hashIt(label);
            try self.boxes[hash].addLense(.{ .label = label, .value = val });
        }
    }

    fn power(self: System) usize {
        var res: usize = 0;
        for (self.boxes, 0..) |box, idx| {
            res += box.power() * (idx + 1);
        }
        return res;
    }
};

pub fn solve() !void {
    var lines = std.mem.split(u8, input_data, "\n");
    // var answer: usize = 0;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    var system = System.init(alloc);
    defer system.deinit();

    while (lines.next()) |line| {
        var strs = std.mem.split(u8, line, ",");
        while (strs.next()) |str| {
            if (str.len > 0) {
                try system.process(str);
            }
        }
    }
    std.debug.print("{}\n", .{system.power()});
}
