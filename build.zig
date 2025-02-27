const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const test_filters = b.option(
        []const []const u8,
        "test-filter",
        "Skip tests that do not match the specified filters.",
    ) orelse &.{};

    const geom = b.addModule("geom", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const tween = b.dependency("tween", .{
        .target = target,
        .optimize = optimize,
    });
    geom.addImport("tween", tween.module("tween"));

    const lib_unit_tests = b.addTest(.{
        .root_module = geom,
        .filters = test_filters,
    });
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);

    const bench = b.addExecutable(.{
        .name = "bench",
        .root_source_file = b.path("bench/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    bench.root_module.addImport("geom", geom);
    const run_bench = b.addRunArtifact(bench);
    const bench_step = b.step("bench", "Run benchmarks");
    bench_step.dependOn(&run_bench.step);
}
