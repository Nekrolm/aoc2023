const input_data = @embedFile("../inputs/8.txt");

const std = @import("std");

const VertexId = []const u8;

const Adjacent = struct {
    left: VertexId,
    right: VertexId,
};

const Graph = struct {
    adjacent: std.StringHashMap(Adjacent),

    fn addNode(self: *Graph, node: VertexId, adj: Adjacent) !void {
        try self.adjacent.put(node, adj);
    }

    fn goLeft(self: Graph, cur: VertexId) ?VertexId {
        return if (self.adjacent.get(cur)) |adj|
            adj.left
        else
            null;
    }
    fn goRight(self: Graph, cur: VertexId) ?VertexId {
        return if (self.adjacent.get(cur)) |adj|
            adj.right
        else
            null;
    }

    fn init(alloc: std.mem.Allocator) Graph {
        return .{ .adjacent = std.StringHashMap(Adjacent).init(alloc) };
    }

    fn deinit(self: *Graph) void {
        self.adjacent.deinit();
    }
};

const CycleStringIterator = struct {
    pos: usize,
    string: []const u8,

    fn new(string: []const u8) CycleStringIterator {
        return .{ .string = string, .pos = 0 };
    }

    fn next(self: *CycleStringIterator) ?u8 {
        if (self.string.len == 0) {
            return null;
        }

        const val = self.string[self.pos];

        self.pos += 1;
        if (self.pos == self.string.len) {
            self.pos = 0;
        }

        return val;
    }
};

const GraphError = error{NotConnected};

fn followInstruction(graph: Graph, start: VertexId, stop: VertexId, instruction: []const u8) !u64 {
    var iter = CycleStringIterator.new(instruction);
    var steps: u64 = 0;
    var current = start;
    while (iter.next()) |command| {
        if (std.mem.eql(u8, current, stop)) {
            break;
        }
        steps += 1;
        current = (if (command == 'L') graph.goLeft(current) else graph.goRight(current)) orelse return GraphError.NotConnected;
    }
    return steps;
}

fn followInstruction2(alloc: std.mem.Allocator, graph: Graph, start: VertexId, instruction: []const u8, lengths: *std.ArrayList(u64)) !void {
    const Vertex = struct { instruction_id: usize, vertex: VertexId };

    const VertexContext = struct {
        const Self = @This();
        pub fn hash(_: Self, key: Vertex) u64 {
            const str_hash = std.hash_map.hashString(key.vertex);
            const seed = key.instruction_id;
            return str_hash + 0x9e3779b9 + (seed << 6) + (seed >> 2);
        }

        pub fn eql(_: Self, lhs: Vertex, rhs: Vertex) bool {
            return lhs.instruction_id == rhs.instruction_id and
                std.mem.eql(u8, lhs.vertex, rhs.vertex);
        }
    };

    const VisitedMap = std.HashMap(Vertex, void, VertexContext, 80);
    var visited = VisitedMap.init(alloc);
    defer visited.deinit();

    var instruction_pos: usize = 0;
    var steps: u64 = 0;
    var current = start;
    while (true) {
        const current_vertex = Vertex{ .instruction_id = instruction_pos, .vertex = current };
        const found_existing = (try visited.getOrPut(current_vertex)).found_existing;
        if (found_existing) {
            break;
        }
        const command = instruction[instruction_pos];
        current = (if (command == 'L') graph.goLeft(current) else graph.goRight(current)) orelse return GraphError.NotConnected;
        steps += 1;
        instruction_pos += 1;
        if (instruction_pos == instruction.len) {
            instruction_pos = 0;
        }
        if (current[2] == 'Z') {
            try lengths.append(steps);
        }
    }
}

const ParseError = error{LineTooShort};

fn parseLine(line: []const u8, node: *VertexId, adj: *Adjacent) !void {
    // TJF = (TXF, NGK)
    if (line.len < 15) {
        return ParseError.LineTooShort;
    }

    node.* = line[0..3];
    const left = line[7..10];
    const right = line[12..15];
    adj.* = .{ .left = left, .right = right };
}

pub fn solve1() !void {
    var input_iter = std.mem.split(u8, input_data, "\n");
    const instruction = input_iter.first();
    _ = input_iter.next();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    var graph = Graph.init(alloc);
    defer graph.deinit();
    while (input_iter.next()) |line| {
        if (line.len == 0) {
            break;
        }
        var node: VertexId = undefined;
        var adj: Adjacent = undefined;
        parseLine(line, &node, &adj) catch |err| {
            std.debug.print("{s}\n", .{line});
            return err;
        };
        try graph.addNode(node, adj);
    }

    const answer = try followInstruction(graph, "AAA", "ZZZ", instruction);
    std.debug.print("{}\n", .{answer});
}

fn lcm(a: u64, b: u64) u64 {
    const d = std.math.gcd(a, b);
    return (b / d) * a;
}

pub fn solve() !void {
    var input_iter = std.mem.split(u8, input_data, "\n");
    const instruction = input_iter.first();
    _ = input_iter.next();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    var graph = Graph.init(alloc);
    defer graph.deinit();

    var start_nodes = try std.ArrayList(VertexId).initCapacity(alloc, 3000);
    defer start_nodes.deinit();

    while (input_iter.next()) |line| {
        if (line.len == 0) {
            break;
        }
        var node: VertexId = undefined;
        var adj: Adjacent = undefined;
        parseLine(line, &node, &adj) catch |err| {
            std.debug.print("{s}\n", .{line});
            return err;
        };
        try graph.addNode(node, adj);
        if (node[2] == 'A') {
            try start_nodes.append(node);
        }
    }

    var lengths = try std.ArrayList(u64).initCapacity(alloc, 3000);
    for (start_nodes.items) |start| {
        try followInstruction2(alloc, graph, start, instruction, &lengths);
    }

    std.debug.print("lengths=\n", .{});
    var answer: u64 = 1;
    for (lengths.items) |len| {
        answer = lcm(answer, len);
        std.debug.print("{}\n", .{len});
    }

    std.debug.print("answer={}\n", .{answer});
}

test "testParsing" {
    const line = "TJF = (TXF, NGK)";
    var vertex: VertexId = undefined;
    var adj: Adjacent = undefined;
    try parseLine(line, &vertex, &adj);
    std.debug.print("{s} = ({s}, {s})\n", .{ vertex, adj.left, adj.right });
}
