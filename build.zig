const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const duck_dep = b.dependency("duckdb", .{});

    _ = b.addModule("duck", .{
        .source_file = .{ .path = "src/main.zig" },
    });

    _ = b.addModule("libduckdb.so", .{
        .source_file = .{ .path = duck_dep.builder.pathFromRoot(
            duck_dep.module("libduckdb.so").source_file.path,
        ) },
    });

    _ = b.installLibFile(duck_dep.builder.pathFromRoot(
        duck_dep.module("libduckdb.so").source_file.path,
    ), "libduckdb.so");

    const lib = b.addStaticLibrary(.{
        .name = "duck",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    lib.addLibraryPath(.{ .path = duck_dep.builder.pathFromRoot(
        duck_dep.module("libduckdb.lib").source_file.path,
    ) });
    lib.addIncludePath(.{ .path = duck_dep.builder.pathFromRoot(
        duck_dep.module("libduckdb.include").source_file.path,
    ) });
    lib.linkSystemLibraryName("duckdb");

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(lib);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/test.zig" },
        .target = target,
        .optimize = optimize,
    });
    unit_tests.step.dependOn(b.getInstallStep());
    unit_tests.linkLibC();
    unit_tests.addLibraryPath(.{ .path = duck_dep.builder.pathFromRoot(
        duck_dep.module("libduckdb.lib").source_file.path,
    ) });
    unit_tests.addIncludePath(.{ .path = duck_dep.builder.pathFromRoot(
        duck_dep.module("libduckdb.include").source_file.path,
    ) });
    unit_tests.linkSystemLibraryName("duckdb");

    const run_unit_tests = b.addRunArtifact(unit_tests);
    run_unit_tests.setEnvironmentVariable("LD_LIBRARY_PATH", "zig-out/lib");

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
