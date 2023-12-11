const input_data = @embedFile("../inputs/7.txt");

const std = @import("std");

// Five of a kind, where all five cards have the same label: AAAAA
// Four of a kind, where four cards have the same label and one card has a different label: AA8AA
// Full house, where three cards have the same label, and the remaining two cards share a different label: 23332
// Three of a kind, where three cards have the same label, and the remaining two cards are each different from any other card in the hand: TTT98
// Two pair, where two cards share one label, two other cards share a second label, and the remaining card has a third label: 23432
// One pair, where two cards share one label, and the other three cards have a different label from the pair and each other: A23A4
// High card, where all cards' labels are distinct: 23456

const HandType = enum(u64) {
    HighCard = 0,
    OnePair,
    TwoPairs,
    Three,
    FullHouse,
    Four,
    Five,
};

const Hand = [5]u8;

fn handType(hand: Hand) HandType {
    var hand_raw = hand;
    std.sort.insertion(u8, &hand_raw, {}, std.sort.asc(u8));

    if (hand_raw[0] == hand_raw[4]) {
        return .Five;
    }

    if (hand_raw[0] == hand_raw[3] or hand_raw[1] == hand_raw[4]) {
        return .Four;
    }

    if ((hand_raw[0] == hand_raw[2] and hand_raw[3] == hand_raw[4]) or (hand_raw[0] == hand_raw[1] and hand_raw[2] == hand_raw[4])) {
        return .FullHouse;
    }

    for (0..3) |start| {
        if (hand_raw[start] == hand_raw[start + 2]) {
            return .Three;
        }
    }

    var pairs: u8 = 0;
    for (0..4) |first| {
        if (hand_raw[first] == hand_raw[first + 1]) {
            pairs += 1;
        }
    }

    return switch (pairs) {
        1 => .OnePair,
        2 => .TwoPairs,
        else => .HighCard,
    };
}

fn handTypeJocker(hand: Hand) HandType {
    var hand_raw = hand;
    std.sort.insertion(u8, &hand_raw, {}, std.sort.asc(u8));
    if (hand_raw[0] != 0) {
        return handType(hand_raw);
    }

    var jocker: u8 = 1;
    for (1..5) |idx| {
        if (hand_raw[idx] == 0) {
            jocker += 1;
        } else {
            break;
        }
    }

    if (jocker >= 4) {
        return .Five;
    }

    if (jocker == 3) {
        return if (hand_raw[4] == hand_raw[3]) .Five else .Four;
    }

    if (jocker == 2) {
        if (hand_raw[4] == hand_raw[2]) {
            return .Five;
        }
        if (hand_raw[4] == hand_raw[3] or hand_raw[2] == hand_raw[3]) {
            return .Four;
        }
        return .Three;
    }

    // jocker == 1
    if (hand_raw[4] == hand_raw[1]) {
        return .Five;
    }

    if (hand_raw[4] == hand_raw[2] or hand_raw[1] == hand_raw[3]) {
        return .Four;
    }

    var pairs: u8 = 0;
    for (1..4) |idx| {
        if (hand_raw[idx] == hand_raw[idx + 1]) {
            pairs += 1;
        }
    }

    return switch (pairs) {
        2 => .FullHouse,
        1 => .Three,
        else => .OnePair,
    };
}

const HandBid = struct { hand_type: HandType, hand: Hand, bid: u64 };

fn handToOrder(hand: *Hand) void {
    for (hand) |*val| {
        const c = val.*;
        val.* = switch (c) {
            '1'...'9' => c - '1' + 1,
            'T' => 10,
            'J' => 11,
            'Q' => 12,
            'K' => 13,
            'A' => 14,
            else => 0,
        };
    }
}

fn handToOrderJocker(hand: *Hand) void {
    for (hand) |*val| {
        const c = val.*;
        val.* = switch (c) {
            '1'...'9' => c - '1' + 1,
            'T' => 10,
            'J' => 0,
            'Q' => 12,
            'K' => 13,
            'A' => 14,
            else => 0,
        };
    }
}

fn handBidLess(_: void, lhs: HandBid, rhs: HandBid) bool {
    if (lhs.hand_type != rhs.hand_type) {
        return @intFromEnum(lhs.hand_type) < @intFromEnum(rhs.hand_type);
    }
    return std.mem.lessThan(u8, &lhs.hand, &rhs.hand);
}

const ParseError = error{
    UnexpectedEOL,
    HandSizeError,
} || std.fmt.ParseIntError;

fn parseCard(line: []const u8, comptime order: fn (*Hand) void, comptime hand_t: fn (Hand) HandType) ParseError!HandBid {
    var tokens = std.mem.split(u8, line, " ");
    const hand_str = tokens.next() orelse return ParseError.UnexpectedEOL;
    const bid_str = tokens.next() orelse return ParseError.UnexpectedEOL;

    if (hand_str.len != 5) {
        return ParseError.HandSizeError;
    }

    var hand: Hand = hand_str[0..5].*;
    order(&hand);
    const bid = try std.fmt.parseInt(u64, bid_str, 10);

    return .{ .hand = hand, .hand_type = hand_t(hand), .bid = bid };
}

pub fn solve() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    var cards_array = try std.ArrayList(HandBid).initCapacity(alloc, 1000);

    var iter = std.mem.split(u8, input_data, "\n");
    while (iter.next()) |line| {
        if (line.len == 0) break;
        // const hand = try parseCard(line, handToOrder, handType);
        const hand = try parseCard(line, handToOrderJocker, handTypeJocker);
        try cards_array.append(hand);
    }

    std.mem.sort(HandBid, cards_array.items, {}, handBidLess);

    var answer: u64 = 0;
    for (cards_array.items, 0..) |card, rank| {
        answer += (rank + 1) * card.bid;
    }
    std.debug.print("{}\n", .{answer});
}
