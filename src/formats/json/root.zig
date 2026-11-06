const tokenizer = @import("lexer.zig");

pub const tokenize = tokenizer.tokenize;
pub const Token = tokenizer.Token;
pub const TokenizerError = tokenizer.TokenizerError;
