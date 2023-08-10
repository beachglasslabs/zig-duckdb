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

    const duck_dep = b.dependency("duckdb", .{
        .target = target,
        .optimize = optimize,
    });

    var duck_module = b.createModule(.{
        .source_file = .{ .path = "src/main.zig" },
    });

    try b.modules.put(b.dupe("duck"), duck_module);

    const lib = b.addStaticLibrary(.{
        .name = "duck",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const path = try std.fmt.allocPrint(b.allocator, "{s}/lib", .{b.install_prefix});
    defer b.allocator.free(path);
    lib.addLibraryPath(.{ .path = path });
    //lib.linkSystemLibraryName("duckdb");
    lib.linkLibrary(duck_dep.artifact("duckdb"));

    lib.installLibraryHeaders(duck_dep.artifact("duckdb"));
    // b.installArtifact(duck_dep.artifact("duckdb"));

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(lib);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
