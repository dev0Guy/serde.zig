const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const json = b.createModule(.{
        .root_source_file = b.path("src/formats/json/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const json_tests_module = b.createModule(.{
        .root_source_file = b.path("tests/formats/json/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "json", .module = json },
        },
    });

    const json_tests = b.addTest(.{
        .root_module = json_tests_module,
    });

    const run_json_tests = b.addRunArtifact(json_tests);

    const test_json_step = b.step("test-json", "Run JSON tests");
    test_json_step.dependOn(&run_json_tests.step);

    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&run_json_tests.step);
}
