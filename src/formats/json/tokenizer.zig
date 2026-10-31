const std = @import("std");

pub const TokenizerError = error{
    UnexpectedCharacter, // invalid byte found
    UnterminatedString, // string missing closing "
    InvalidEscape, // bad \uXXXX or unknown escape
    InvalidNumber, // malformed number
    InvalidLiteral, // true/false/null spelled wrong
};

const Token = union(enum) {
    LeftBrace,
    RightBrace,
    LeftBracket,
    RightBracket,
    Colon,
    Comma,
    True,
    False,
    Null,
    String: []const u8,
    Number: []const u8,

    pub const true_token: []const u8 = "true";
    pub const false_token: []const u8 = "false";
    pub const null_token: []const u8 = "null";

    const Self = @This();

    pub fn len(self: *const Self) usize {
        return switch (self.*) {
            .LeftBrace, .RightBrace, .LeftBracket, .RightBracket, .Colon, .Comma => 1,
            .True => true_token.len,
            .False => false_token.len,
            .Null => null_token.len,
            .Number => |n| n.len,
            .String => |s| s.len + 2,
        };
    }
};

const Tokenizer = struct {
    inline fn tokenize_literal(
        value: []const u8,
        expected: []const u8,
        token: Token,
    ) TokenizerError!Token {
        if (value.len < expected.len) {
            return TokenizerError.InvalidLiteral;
        }

        if (!std.mem.eql(u8, value[0..expected.len], expected)) {
            return TokenizerError.InvalidLiteral;
        }

        return token;
    }

    inline fn tokenize_string(bytes: []const u8) TokenizerError!Token {
        const len = (std.mem.indexOfScalar(u8, bytes[1..], '"') orelse return TokenizerError.UnterminatedString);
        return Token{ .String = bytes[1..(1 + len)] };
    }

    inline fn tokenize_number(bytes: []const u8) TokenizerError!Token {
        // foward on negative symbol
        var idx: usize = if (bytes[0] == '-') 1 else 0;
        // foward on interger part
        while (idx < bytes.len and ('0' <= bytes[idx] and bytes[idx] <= '9')) : (idx += 1) {}
        if (bytes[idx] == '.') {
            // foward dot
            idx += 1;
            // foward on floating part
            while (idx < bytes.len and ('0' <= bytes[idx] and bytes[idx] <= '9')) : (idx += 1) {}
        }
        if (!('0' <= bytes[idx - 1] and bytes[idx - 1] <= '9')) return TokenizerError.InvalidNumber;
        if (!(bytes[idx] == ',' or bytes[idx] == '}')) return TokenizerError.InvalidNumber;
        return .{ .Number = bytes[0..idx] };
    }

    fn from(input: []const u8, gpa: std.mem.Allocator) !std.ArrayList(Token) {
        var array: std.ArrayList(Token) = .empty;
        var idx: usize = 0;
        while (idx < input.len) {
            while (idx < input.len and std.ascii.isWhitespace(input[idx])) : (idx += 1) {}
            const token = switch (input[idx]) {
                '{' => Token.LeftBrace,
                '}' => Token.RightBrace,
                '[' => Token.LeftBracket,
                ']' => Token.RightBracket,
                ':' => Token.Colon,
                ',' => Token.Comma,
                't' => try tokenize_literal(input[idx..], Token.true_token, Token.True),
                'f' => try tokenize_literal(input[idx..], Token.false_token, Token.False),
                'n' => try tokenize_literal(input[idx..], Token.null_token, Token.Null),
                '"' => try tokenize_string(input[idx..]),
                '0'...'9', '-' => try tokenize_number(input[idx..]),
                else => return TokenizerError.UnexpectedCharacter,
            };
            try array.append(gpa, token);
            idx += token.len();
        }
        return array;
    }
};

test "simple Json tokenize" {
    const allocator = std.testing.allocator;
    const input =
        \\{"name":"alice","age":30,"active":true}
    ;
    const expected = &[_]Token{ .LeftBrace, .{ .String = "name" }, .Colon, .{ .String = "alice" }, .Comma, .{ .String = "age" }, .Colon, .{ .Number = "30" }, .Comma, .{ .String = "active" }, .Colon, .True, .RightBrace };
    var actual = try Tokenizer.from(input, allocator);
    defer actual.deinit(allocator);
    try std.testing.expectEqualDeep(expected, actual.items);
}

test "simple Json tokenize with space" {
    const allocator = std.testing.allocator;
    const input =
        \\{"name"   : "alice", "age" :30.02410, "active": true}
    ;
    const expected = &[_]Token{ .LeftBrace, .{ .String = "name" }, .Colon, .{ .String = "alice" }, .Comma, .{ .String = "age" }, .Colon, .{ .Number = "30.02410" }, .Comma, .{ .String = "active" }, .Colon, .True, .RightBrace };
    var actual = try Tokenizer.from(input, allocator);
    defer actual.deinit(allocator);
    try std.testing.expectEqualDeep(expected, actual.items);
}
