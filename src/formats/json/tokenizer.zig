const std = @import("std");

pub const TokenizerError = error{
    UnexpectedCharacter, // invalid byte found
    UnterminatedString, // string missing closing "
    InvalidEscape, // bad \uXXXX or unknown escape
    InvalidNumber, // malformed number
    InvalidLiteral, // true/false/null spelled wrong
};

pub const Token = union(enum) {
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

inline fn tokenize_literal(
    value: []const u8,
    expected: []const u8,
    token: Token,
) TokenizerError!Token {
    if (value.len < expected.len) return TokenizerError.InvalidLiteral;

    if (!std.mem.eql(u8, value[0..expected.len], expected)) return TokenizerError.InvalidLiteral;

    return token;
}

inline fn tokenize_string(bytes: []const u8) TokenizerError!Token {
    var idx: usize = 1;
    if (bytes.len < 2) return TokenizerError.UnterminatedString;
    while (idx < bytes.len) : (idx += if (bytes[idx] == '\\') 2 else 1) {
        if (bytes[idx] == '"') return .{ .String = bytes[1..idx] };
    }
    return TokenizerError.UnterminatedString;
}

inline fn tokenize_number(bytes: []const u8) TokenizerError!Token {
    // foward on negative symbol
    var idx: usize = if (bytes[0] == '-') 1 else 0;
    // foward on interger part
    while (idx < bytes.len and ('0' <= bytes[idx] and bytes[idx] <= '9')) : (idx += 1) {}
    if ((idx < bytes.len) and bytes[idx] == '.') {
        // foward dot
        idx += 1;
        // foward on floating part
        while (idx < bytes.len and ('0' <= bytes[idx] and bytes[idx] <= '9')) : (idx += 1) {}
    }
    if (!('0' <= bytes[idx - 1] and bytes[idx - 1] <= '9')) return TokenizerError.InvalidNumber;
    // if (idx < bytes.len and !(bytes[idx] == ',' or bytes[idx] == '}')) return TokenizerError.InvalidNumber;
    return .{ .Number = bytes[0..idx] };
}

inline fn tokenize_char(
    input: []const u8,
) TokenizerError!Token {
    return switch (input[0]) {
        '{' => .LeftBrace,
        '}' => .RightBrace,
        '[' => .LeftBracket,
        ']' => .RightBracket,
        ':' => .Colon,
        ',' => .Comma,
        't' => try tokenize_literal(input, Token.true_token, .True),
        'f' => try tokenize_literal(input, Token.false_token, .False),
        'n' => try tokenize_literal(input, Token.null_token, .Null),
        '"' => try tokenize_string(input),
        '0'...'9', '-' => try tokenize_number(input),
        else => return TokenizerError.UnexpectedCharacter,
    };
}

pub fn tokenize(input: []const u8, gpa: std.mem.Allocator) !std.ArrayList(Token) {
    var array: std.ArrayList(Token) = .empty;
    var idx: usize = 0;
    while (idx < input.len) {
        // skip white space
        while (idx < input.len and std.ascii.isWhitespace(input[idx])) : (idx += 1) {}
        if (idx == input.len) break;
        // tokenize
        const token = try tokenize_char(input[idx..]);
        try array.append(gpa, token);
        idx +|= token.len();
    }
    return array;
}
