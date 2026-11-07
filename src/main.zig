const std = @import("std");
const parser = @import("formats/json/parser.zig");
const lexer = @import("formats/json/lexer.zig");
pub fn main() !void {
    const example_json =
        \\{ "name": "John Doe","age": 30,"is_student": false,"courses": ["Math", "Science", "History"],"address": {"street": "123 Main St","city": "Anytown","zip": "12345"}}
    ;
    const tokens = try lexer.tokenize(example_json, std.heap.page_allocator);

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const a = arena.allocator();

    const root = try parser.parse(a, tokens.items);
    const name = root.object.get("name").?.string;
    const city = root.object.get("address").?.object.get("city").?.string;
    const street = root.object.get("address").?.object.get("street").?.string;
    std.debug.print("{s} lives in {s} on {s}\n", .{ name, city, street });
}
