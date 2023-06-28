const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    b.exe_dir = "./bin";

    // Static Lib (Unused)
    //const lib = b.addStaticLibrary(.{
    //    .name = "cova",
    //    .root_source_file = .{ .path = "src/cova.zig" },
    //    .target = target,
    //    .optimize = optimize,
    //});
    //b.installArtifact(lib);

    // Tests 
    const cova_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/cova.zig" },
        .target = target,
        .optimize = optimize,
    });
    const run_cova_tests = b.addRunArtifact(cova_tests);
    const test_step = b.step("test", "Run cova library tests");
    test_step.dependOn(&run_cova_tests.step);

    // Lib Module
    const cova_mod = b.addModule("cova", .{
        .source_file = std.Build.FileSource.relative("src/cova.zig"),
    });

    // Demo Exe
    const cova_demo = b.addExecutable(.{
        .name = "covademo",
        .root_source_file = .{ .path = "examples/covademo.zig" },
        .target = target,
        .optimize = optimize,
    });
    const build_cova_demo = b.addInstallArtifact(cova_demo);
    cova_demo.addModule("cova", cova_mod);
    const build_cova_demo_step = b.step("demo", "Build the 'covademo' example");
    build_cova_demo_step.dependOn(&build_cova_demo.step);

}
