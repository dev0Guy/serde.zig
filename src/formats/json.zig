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

    pub fn len(self: *const @This()) usize {
        return switch (self.*) {
            .LeftBrace, .RightBrace, .LeftBracket, .RightBracket, .Colon, .Comma => 1,
            .True => true_token.len,
            .False => false_token.len,
            .Null => null_token.len,
            .Number => |n| n.len,
            .String => |s| s.len + 2,
        };
    }

    pub fn printToken(token: Token) void {
        switch (token) {
            .LeftBrace => std.debug.print("{{", .{}),
            .RightBrace => std.debug.print("}}", .{}),
            .LeftBracket => std.debug.print("[", .{}),
            .RightBracket => std.debug.print("]", .{}),
            .Colon => std.debug.print(":", .{}),
            .Comma => std.debug.print(",", .{}),
            .True => std.debug.print("true", .{}),
            .False => std.debug.print("false", .{}),
            .Null => std.debug.print("null", .{}),
            .String => |s| std.debug.print("String(\"{s}\")", .{s}),
            .Number => |n| std.debug.print("Number({s})", .{n}),
        }
    }
};

const Tokenizer = struct {
    const TokenizeError = error{QuoteNotFound};

    inline fn tokenize_true(value: []const u8) !Token {
        const expected_len = Token.true_token.len;
        if (value.len < expected_len) return TokenizeError.QuoteNotFound;
        if (!std.mem.eql(u8, value[0..expected_len], Token.true_token)) return TokenizeError.QuoteNotFound;
        return Token.True;
    }

    inline fn tokenize_false(value: []const u8) TokenizeError!Token {
        const expected_len = Token.false_token.len;
        if (value.len < expected_len) return TokenizeError.QuoteNotFound;
        if (!std.mem.eql(u8, value[0..expected_len], Token.false_token)) return TokenizeError.QuoteNotFound;
        return Token.False;
    }

    inline fn tokenize_null(value: []const u8) TokenizeError!Token {
        const expected_len = Token.null_token.len;
        if (value.len < expected_len) return TokenizeError.QuoteNotFound;
        std.debug.print("got: {s}, expected: {s}\n", .{ value[0..expected_len], Token.null_token });
        if (!std.mem.eql(u8, value[0..expected_len], Token.null_token)) return TokenizeError.QuoteNotFound;
        return Token.Null;
    }

    inline fn tokenize_string(bytes: []const u8) TokenizeError!Token {
        const len = (std.mem.indexOfScalar(u8, bytes[1..], '"') orelse return TokenizeError.QuoteNotFound);
        return Token{ .String = bytes[1..(1 + len)] };
    }

    inline fn tokenize_number(bytes: []const u8) !Token {
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
        if (!('0' <= bytes[idx - 1] and bytes[idx - 1] <= '9')) return TokenizeError.QuoteNotFound;
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
                't' => try tokenize_true(input[idx..]),
                'f' => try tokenize_false(input[idx..]),
                'n' => try tokenize_null(input[idx..]),
                '"' => try tokenize_string(input[idx..]),
                '0'...'9', '-' => try tokenize_number(input[idx..]),
                else => return TokenizeError.QuoteNotFound,
            };
            try array.append(gpa, token);
            idx += token.len();
        }
        return array;
    }
};
const std = @import("std");

test "simple Json tokenize" {
    const allocator = std.testing.allocator;
    const input =
        \\{"name":"alice","age":30,"active":true}
    ;

    var tokens = try Tokenizer.from(input, allocator);

    defer tokens.deinit(allocator);

    for (tokens.items) |token| {
        token.printToken();
    }
}

test "simple Json tokenize with space" {
    const allocator = std.testing.allocator;
    const input =
        \\{"name"   : "alice", "age" :30.02410e,   "active": true}
    ;

    var tokens = try Tokenizer.from(input, allocator);

    defer tokens.deinit(allocator);

    for (tokens.items) |token| {
        token.printToken();
    }
}
