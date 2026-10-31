const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // zcov coverage options
    const coverage = b.option(
        bool,
        "coverage",
        "Enable code coverage",
    ) orelse false;

    const coverage_rt = b.option(
        []const u8,
        "coverage-rt",
        "Path to zig-cov-rt.o",
    );

    // JSON library module
    const json = b.createModule(.{
        .root_source_file = b.path("src/formats/json/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // JSON tests module
    const json_tests_module = b.createModule(.{
        .root_source_file = b.path("tests/formats/json/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "json", .module = json },
        },
    });

    // Test executable
    const json_tests = b.addTest(.{
        .root_module = json_tests_module,
    });

    // Enable zcov instrumentation
    if (coverage) {
        json_tests.use_llvm = true;
        json_tests.root_module.fuzz = true;
        json_tests.root_module.link_libc = true;

        if (coverage_rt) |path| {
            json_tests.root_module.addObjectFile(.{
                .cwd_relative = path,
            });
        }
    }

    // Run JSON tests
    const run_json_tests = b.addRunArtifact(json_tests);

    const test_json_step = b.step(
        "test-json",
        "Run JSON tests",
    );
    test_json_step.dependOn(&run_json_tests.step);

    // Run all tests
    const test_step = b.step(
        "test",
        "Run all tests",
    );
    test_step.dependOn(&run_json_tests.step);
}
