const std = @import("std");
const lexer = @import("lexer.zig");

const Token = lexer.Token;
const Tag = std.meta.Tag(Token);

pub const Error = error{
    UnexpectedToken,
    UnexpectedEnd,
    InvalidNumber,
} || std.mem.Allocator.Error;

pub const Value = union(enum) {
    null,
    bool: bool,
    number: f64,
    string: []const u8,
    array: []Value,
    object: std.StringArrayHashMapUnmanaged(Value),
};

/// Parses a token stream into a `Value` tree.
/// All memory is allocated with `allocator`; an arena is recommended.
pub fn parse(allocator: std.mem.Allocator, tokens: []const Token) Error!Value {
    var parser: Parser = .{ .allocator = allocator, .tokens = tokens };
    const value = try parser.parseValue();
    if (!parser.isAtEnd()) return Error.UnexpectedToken;
    return value;
}

const Parser = struct {
    allocator: std.mem.Allocator,
    tokens: []const Token,
    position: usize = 0,

    // ── Grammar ─────────────────────────────────────────────

    fn parseValue(self: *Parser) Error!Value {
        return switch (try self.next()) {
            .Null => .null,
            .True => .{ .bool = true },
            .False => .{ .bool = false },
            .String => |s| .{ .string = s },
            .Number => |n| .{ .number = try parseNumber(n) },
            .LeftBracket => self.parseArray(),
            .LeftBrace => self.parseObject(),
            else => Error.UnexpectedToken,
        };
    }

    /// array = "[" "]" | "[" value ("," value)* "]"
    fn parseArray(self: *Parser) Error!Value {
        if (try self.match(.RightBracket)) return .{ .array = &.{} };

        var items: std.ArrayList(Value) = .empty;
        while (true) {
            const parsed_value = try self.parseValue();
            try items.append(self.allocator, parsed_value);
            if (!try self.match(.Comma)) break;
        }
        try self.expect(.RightBracket);

        return .{ .array = try items.toOwnedSlice(self.allocator) };
    }

    /// object = "{" "}" | "{" pair ("," pair)* "}"
    /// pair   = string ":" value
    fn parseObject(self: *Parser) Error!Value {
        if (try self.match(.RightBrace)) return .{ .object = .empty };

        var map: std.StringArrayHashMapUnmanaged(Value) = .empty;
        while (true) {
            const key = try self.expectString();
            try self.expect(.Colon);
            try map.put(self.allocator, key, try self.parseValue());
            if (!try self.match(.Comma)) break;
        }
        try self.expect(.RightBrace);

        return .{ .object = map };
    }

    fn isAtEnd(self: *const Parser) bool {
        return self.position >= self.tokens.len;
    }

    fn peek(self: *const Parser) Error!Tag {
        if (self.isAtEnd()) return Error.UnexpectedEnd;
        return std.meta.activeTag(self.tokens[self.position]);
    }

    fn next(self: *Parser) Error!Token {
        if (self.isAtEnd()) return Error.UnexpectedEnd;
        defer self.position += 1;
        return self.tokens[self.position];
    }

    /// Consumes the next token if it has `tag`. Returns whether it did.
    fn match(self: *Parser, tag: Tag) Error!bool {
        if (try self.peek() != tag) return false;
        self.position += 1;
        return true;
    }

    /// Consumes the next token, failing unless it has `tag`.
    fn expect(self: *Parser, tag: Tag) Error!void {
        if (!try self.match(tag)) return Error.UnexpectedToken;
    }

    /// Consumes a String token and returns its contents.
    fn expectString(self: *Parser) Error![]const u8 {
        return switch (try self.next()) {
            .String => |s| s,
            else => Error.UnexpectedToken,
        };
    }
};

fn parseNumber(text: []const u8) Error!f64 {
    return std.fmt.parseFloat(f64, text) catch Error.InvalidNumber;
}
