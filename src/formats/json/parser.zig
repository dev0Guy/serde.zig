const std = @import("std");
const tokenizer = @import("tokenizer.zig");

pub const ParserError = error{
    UnexpectedToken,
    UnexpectedEndOfInput,
    InvalidNumber,
    InvalidLiteral,
    UnterminatedString,
};

pub const ObjectEntry = struct {
    key: []const u8,
    value: Value,
};

pub const Value = union(enum) {
    Null: void,
    Bool: bool,
    Number: f64,
    String: []const u8,
    Array: []Value,
    Object: []ObjectEntry,
};

pub const Parser = struct {
    allocator: std.mem.Allocator,
    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .allocator = allocator,
        };
    }

    pub fn parse(self: *Self, tokens: []const tokenizer.Token) !Value {
        switch (tokens[0]) {
            .LeftBrace => return self.parse_object(tokens),
            .LeftBracket => return self.parse_array(tokens),
            else => return ParserError.UnexpectedToken,
        }
        // Implement the parsing logic here
        return Value{ .Null = {} }; // Placeholder return value
    }

	fn parseArray(self: *Self, tokens: []const tokenizer.Token) !Value{
		for(tokens)|token|{
			switch (token) {
				.Value => 
			}
		}
		// 	switch (token) {
		// 		.Comma => 

		// 	}
		// }
	}

    // fn parseObject(self: *Self, tokens: []const tokenizer.Token) !Value {
    //     if (tokens[0] != .LeftBrace) return ParserError.UnexpectedToken;
    //     if (tokens.len < 2 || (tokens[tokens.len] != .RightBrace)) return ParserError.UnexpectedEndOfInput;
	// 	// while

    //     // for(tokens, 1..tokens.len) |token, i, |{

    //     // }

    // }
};
