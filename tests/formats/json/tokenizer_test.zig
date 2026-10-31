const std = @import("std");
const testing = std.testing;
const Json = @import("json");

test "[tokenize] string - simple" {
    const allocator = testing.allocator;
    const input =
        \\"hello"
    ;
    var actual = try Json.tokenize(input, allocator);
    defer actual.deinit(allocator);

    const expected = &[_]Json.Token{
        .{ .String = "hello" },
    };

    try testing.expectEqualDeep(expected, actual.items);
}

test "[tokenize] string - empty" {
    const allocator = testing.allocator;
    const input =
        \\""
    ;
    var actual = try Json.tokenize(input, allocator);
    defer actual.deinit(allocator);

    const expected = &[_]Json.Token{
        .{ .String = "" },
    };

    try testing.expectEqualDeep(expected, actual.items);
}

test "[tokenize] string - escapedQuote" {
    const allocator = testing.allocator;
    const input =
        \\"hello \"world\""
    ;
    var actual = try Json.tokenize(input, allocator);
    defer actual.deinit(allocator);

    const expected = &[_]Json.Token{
        .{ .String = "hello \\\"world\\\"" },
    };

    try testing.expectEqualDeep(expected, actual.items);
}

test "[tokenize] number - integer" {
    const allocator = testing.allocator;
    const input = "123";
    var actual = try Json.tokenize(input, allocator);
    defer actual.deinit(allocator);

    const expected = &[_]Json.Token{
        .{ .Number = "123" },
    };

    try testing.expectEqualDeep(expected, actual.items);
}

test "[tokenize] number - negativeInteger" {
    const allocator = testing.allocator;
    const input = "-123";
    var actual = try Json.tokenize(input, allocator);
    defer actual.deinit(allocator);

    const expected = &[_]Json.Token{
        .{ .Number = "-123" },
    };

    try testing.expectEqualDeep(expected, actual.items);
}

test "[tokenize] number - decimal" {
    const allocator = testing.allocator;
    const input = "20.0340";
    var actual = try Json.tokenize(input, allocator);
    defer actual.deinit(allocator);

    const expected = &[_]Json.Token{
        .{ .Number = "20.0340" },
    };

    try testing.expectEqualDeep(expected, actual.items);
}

test "[tokenize] literal - false" {
    const allocator = testing.allocator;
    const input = "false";
    var actual = try Json.tokenize(input, allocator);
    defer actual.deinit(allocator);

    const expected = &[_]Json.Token{
        .False,
    };

    try testing.expectEqualDeep(expected, actual.items);
}

test "[tokenize] literal - true" {
    const allocator = testing.allocator;
    const input = "true";
    var actual = try Json.tokenize(input, allocator);
    defer actual.deinit(allocator);

    const expected = &[_]Json.Token{
        .True,
    };

    try testing.expectEqualDeep(expected, actual.items);
}

test "[tokenize] literal - null" {
    const allocator = testing.allocator;
    const input = "null";
    var actual = try Json.tokenize(input, allocator);
    defer actual.deinit(allocator);

    const expected = &[_]Json.Token{
        .Null,
    };

    try testing.expectEqualDeep(expected, actual.items);
}

test "[tokenize] array - empty" {
    const allocator = testing.allocator;
    const input = "[]";
    var actual = try Json.tokenize(input, allocator);
    defer actual.deinit(allocator);

    const expected = &[_]Json.Token{ .LeftBracket, .RightBracket };
    try testing.expectEqualDeep(expected, actual.items);
}

test "[tokenize] array - all literal" {
    const allocator = testing.allocator;
    const input = "[null, 23.323, -14, false, true, {5, 34}]";
    var actual = try Json.tokenize(input, allocator);
    defer actual.deinit(allocator);

    const expected = &[_]Json.Token{ .LeftBracket, .Null, .Comma, .{ .Number = "23.323" }, .Comma, .{ .Number = "-14" }, .Comma, .False, .Comma, .True, .Comma, .LeftBrace, .{ .Number = "5" }, .Comma, .{ .Number = "34" }, .RightBrace, .RightBracket };

    try testing.expectEqualDeep(expected, actual.items);
}

test "[tokenize] object" {
    const allocator = testing.allocator;
    const input =
        \\{"name": "Alice", "loveTo''": ["run","\"walk",] ,, "null": null, "true": true, "false": false, "age": {"number": 50}}
    ;
    // TODO add oute qute
    var actual = try Json.tokenize(input, allocator);
    defer actual.deinit(allocator);

    const expected = &[_]Json.Token{
        .LeftBrace,
        .{ .String = "name" },
        .Colon,
        .{ .String = "Alice" },
        .Comma,
        .{ .String = "loveTo''" },
        .Colon,
        .LeftBracket,
        .{ .String = "run" },
        .Comma,
        .{ .String = "\\\"walk" },
        .Comma,
        .RightBracket,
        .Comma,
        .Comma,
        .{ .String = "null" },
        .Colon,
        .Null,
        .Comma,
        .{ .String = "true" },
        .Colon,
        .True,
        .Comma,
        .{ .String = "false" },
        .Colon,
        .False,
        .Comma,
        .{ .String = "age" },
        .Colon,
        .LeftBrace,
        .{ .String = "number" },
        .Colon,
        .{ .Number = "50" },
        .RightBrace,
        .RightBrace,
    };
    try testing.expectEqualDeep(expected, actual.items);
}

test "[tokenize] error - unexpected character" {
    try testing.expectError(
        Json.TokenizerError.UnexpectedCharacter,
        Json.tokenize("@", testing.allocator),
    );
}

test "[tokenize] error - invalid literal" {
    try testing.expectError(
        Json.TokenizerError.InvalidLiteral,
        Json.tokenize("tru", testing.allocator),
    );
}

test "[tokenize] error - unterminated string" {
    try testing.expectError(
        Json.TokenizerError.UnterminatedString,
        Json.tokenize("\"hello", testing.allocator),
    );
}

test "[tokenize] error - invalid number" {
    try testing.expectError(
        Json.TokenizerError.InvalidNumber,
        Json.tokenize("-", testing.allocator),
    );
}

test "[tokenize] whitespace only" {
    var actual = try Json.tokenize("   \n\t", testing.allocator);
    defer actual.deinit(testing.allocator);

    try testing.expectEqual(@as(usize, 0), actual.items.len);
}
