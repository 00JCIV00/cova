const std = @import("std");
pub const generate = @import("src/generate.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    //const build_options = b.addOptions();
    const bin_name = b.option([]const u8, "name", "A name for the binary being created.");
    b.exe_dir = "./bin";

    // Modules & Artifacts
    // - Lib Module
    const cova_mod = b.addModule("cova", .{
        .root_source_file = b.path("src/cova.zig"),
    });
    // - Generator Artifact
    _ = b.addModule("cova_gen", .{
        .root_source_file = b.path("src/generator.zig"),
    });

    // Static Lib (Used for Docs)
    const cova_lib = b.addStaticLibrary(.{
        .name = "cova",
        .root_source_file = b.path("src/cova.zig"),
        .target = target,
        .optimize = optimize,
    });
    //b.installArtifact(cova_lib);

    // Tests
    const cova_tests = b.addTest(.{
        .root_source_file = b.path("src/cova.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_cova_tests = b.addRunArtifact(cova_tests);
    const test_step = b.step("test", "Run the cova library tests");
    test_step.dependOn(&run_cova_tests.step);

    // Docs
    const cova_docs = cova_lib;
    //const cova_docs = cova_tests;
    const build_docs = b.addInstallDirectory(.{
        .source_dir = cova_docs.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "../docs",
    });
    const build_docs_step = b.step("docs", "Build the cova library docs");
    build_docs_step.dependOn(&build_docs.step);

    //==========================================
    // Examples
    //==========================================
    const examples = &.{ "cova-demo", "basic_app", "logger" };
    var ex_arena = std.heap.ArenaAllocator.init(b.allocator);
    defer ex_arena.deinit();
    const ex_alloc = ex_arena.allocator();
    inline for (examples) |example| {
        var ex_scored_buf = ex_alloc.dupe(u8, example) catch @panic("OOM");
        const ex_scored = std.mem.replaceOwned(u8, ex_alloc, ex_scored_buf[0..], "-", "_") catch @panic("OOM");
        const ex_name = exName: {
            if (std.mem.eql(u8, example, "cova-demo")) break :exName "covademo";
            break :exName example;
        };
        // - Exe
        const ex_exe = b.addExecutable(.{
            .name = bin_name orelse ex_name,
            .root_source_file = b.path(std.fmt.allocPrint(ex_alloc, "examples/{s}.zig", .{ex_name}) catch @panic("OOM")),
            .target = target,
            .optimize = optimize,
        });
        ex_exe.root_module.addImport("cova", cova_mod);
        const build_ex_demo = b.addInstallArtifact(ex_exe, .{});
        const build_ex_demo_step = b.step(example, "Build the '" ++ example ++ "' example (default: Debug)");
        build_ex_demo_step.dependOn(&build_ex_demo.step);
        // - Demo Meta Docs
        const ex_demo_gen = createDocGenStep(
            b,
            cova_mod,
            b.path("src/generator.zig"),
            ex_exe,
            .{
                .kinds = &.{.all},
                .version = "0.10.2",
                .ver_date = "23 OCT 2024",
                .author = "00JCIV00",
                .copyright = "MIT License",
                .help_docs_config = .{
                    .local_filepath = std.fmt.allocPrint(ex_alloc, "examples/{s}_meta/help_docs/", .{ex_scored}) catch @panic("OOM"),
                },
                .tab_complete_config = .{
                    .local_filepath = std.fmt.allocPrint(ex_alloc, "examples/{s}_meta/tab_completions/", .{ex_scored}) catch @panic("OOM"),
                    .include_opts = true,
                },
                .arg_template_config = .{
                    .local_filepath = std.fmt.allocPrint(ex_alloc, "examples/{s}_meta/arg_templates/", .{ex_scored}) catch @panic("OOM"),
                },
            },
        );
        const ex_demo_gen_step = b.step(example ++ "-gen", "Generate Meta Docs for the '" ++ example ++ "'");
        ex_demo_gen_step.dependOn(&ex_demo_gen.step);
    }
}

/// Add Cova's Meta Doc Generation Step to a project's `build.zig`.
/// Note, the `program_step` must have the same Target as the host machine.
/// Prefer to use `addCovaDocGenStepOrError` if the step will be used in cross-compilation CI pipeline.
pub fn addCovaDocGenStep(
    b: *std.Build,
    /// The Cova Dependency of the project's `build.zig`.
    cova_dep: *std.Build.Dependency,
    /// The Program Compile Step where the Command Type and Setup Command can be found.
    /// This is typically created with `const exe = b.addExecutable(.{...});` or similar
    program_step: *std.Build.Step.Compile,
    /// The Config for Meta Doc Generation.
    doc_gen_config: generate.MetaDocConfig,
) *std.Build.Step.Run {
    //const cova_dep = covaDep(b, .{});
    return createDocGenStep(
        b,
        cova_dep.module("cova"),
        cova_dep.path("src/generator.zig"),
        program_step,
        doc_gen_config,
    );
}

/// Add Cova's Meta Doc Generation Step to a project's `build.zig` or return an error if there's a Target mismatch.
/// A Target mismatch happens if the provided `program_step` doesn't have the same Target as the host machine.
/// This function is useful for cross-compilation in CI pipelines to ensure Target mismatches are handled properly.
pub fn addCovaDocGenStepOrError(
    b: *std.Build,
    /// The Cova Dependency of the project's `build.zig`.
    cova_dep: *std.Build.Dependency,
    /// The Program Compile Step where the Command Type and Setup Command can be found.
    /// This is typically created with `const exe = b.addExecutable(.{...});` or similar
    program_step: *std.Build.Step.Compile,
    /// The Config for Meta Doc Generation.
    doc_gen_config: generate.MetaDocConfig,
) !*std.Build.Step.Run {
    const host_triplets = b.graph.host.result.zigTriple(b.allocator) catch @panic("OOM");
    defer b.allocator.free(host_triplets);
    const program_triplets = program_step.rootModuleTarget().zigTriple(b.allocator) catch @panic("OOM");
    defer b.allocator.free(program_triplets);
    if (!std.mem.eql(u8, host_triplets, program_triplets)) return error.TargetMismatch;
    return createDocGenStep(
        b,
        cova_dep.module("cova"),
        cova_dep.path("src/generator.zig"),
        program_step,
        doc_gen_config,
    );
}

/// Create the Meta Doc Generation Step.
fn createDocGenStep(
    b: *std.Build,
    cova_mod: *std.Build.Module,
    cova_gen_path: std.Build.LazyPath,
    program_step: *std.Build.Step.Compile,
    doc_gen_config: generate.MetaDocConfig,
) *std.Build.Step.Run {
    const program_mod = program_step.root_module;
    const cova_gen_exe = b.addExecutable(.{
        .name = std.fmt.allocPrint(b.allocator, "cova_generator_{s}", .{program_step.name}) catch @panic("OOM"),
        .root_source_file = cova_gen_path,
        .target = b.graph.host,
        .optimize = .Debug,
    });
    b.installArtifact(cova_gen_exe);
    cova_gen_exe.root_module.addImport("cova", cova_mod);
    cova_gen_exe.root_module.addImport("program", program_mod);

    const md_conf_opts = b.addOptions();
    var sub_conf_map = std.StringHashMap(?*std.Build.Step.Options).init(b.allocator);
    sub_conf_map.put("help_docs_config", null) catch @panic("OOM");
    sub_conf_map.put("tab_complete_config", null) catch @panic("OOM");
    sub_conf_map.put("arg_template_config", null) catch @panic("OOM");

    inline for (@typeInfo(generate.MetaDocConfig).@"struct".fields) |field| {
        switch (@typeInfo(field.type)) {
            .@"struct", .@"enum" => continue,
            .optional => |optl| {
                switch (@typeInfo(optl.child)) {
                    .@"struct" => |struct_info| {
                        const maybe_conf = @field(doc_gen_config, field.name);
                        if (maybe_conf) |conf| {
                            const doc_conf_opts = b.addOptions();
                            inline for (struct_info.fields) |s_field| {
                                if (@typeInfo(s_field.type) == .@"enum") {
                                    doc_conf_opts.addOption(usize, s_field.name, @intFromEnum(@field(conf, s_field.name)));
                                    continue;
                                }
                                doc_conf_opts.addOption(s_field.type, s_field.name, @field(conf, s_field.name));
                            }
                            doc_conf_opts.addOption(bool, "provided", true);
                            sub_conf_map.put(field.name, doc_conf_opts) catch @panic("OOM");
                        }
                        continue;
                    },
                    else => {},
                }
            },
            .pointer => |ptr| {
                if (ptr.child == generate.MetaDocConfig.MetaDocKind) {
                    var kinds_list = std.ArrayList(usize).init(b.allocator);
                    for (@field(doc_gen_config, field.name)) |kind|
                        kinds_list.append(@intFromEnum(kind)) catch @panic("There was an issue with the Meta Doc Config.");
                    md_conf_opts.addOption(
                        []const usize,
                        field.name,
                        kinds_list.toOwnedSlice() catch @panic("There was an issue with the Meta Doc Config."),
                    );
                    continue;
                }
            },
            else => {},
        }
        md_conf_opts.addOption(
            field.type,
            field.name,
            @field(doc_gen_config, field.name),
        );
    }
    cova_gen_exe.root_module.addOptions("md_config_opts", md_conf_opts);
    var sub_conf_map_iter = sub_conf_map.iterator();
    while (sub_conf_map_iter.next()) |conf| {
        cova_gen_exe.root_module.addOptions(
            conf.key_ptr.*,
            if (conf.value_ptr.*) |conf_opts| conf_opts else confOpts: {
                const conf_opts = b.addOptions();
                conf_opts.addOption(bool, "provided", false);
                break :confOpts conf_opts;
            },
        );
    }

    return b.addRunArtifact(cova_gen_exe);
}

/// Return the Cova Dependency
/// Courtesy of @castholm
fn covaDep(b: *std.Build, args: anytype) *std.Build.Dependency {
    getDep: {
        const all_pkgs = @import("root").dependencies.packages;
        const pkg_hash =
            inline for (@typeInfo(all_pkgs).@"struct".decls) |decl| {
                const pkg = @field(all_pkgs, decl.name);
                if (@hasDecl(pkg, "build_zig") and pkg.build_zig == @This()) break decl.name;
            } else break :getDep;
        const dep_name =
            for (b.available_deps) |dep| {
                if (std.mem.eql(u8, dep[1], pkg_hash)) break dep[0];
            } else break :getDep;
        return b.dependency(dep_name, args);
    }
    std.debug.panic("'cova' is not a dependency of '{s}'", .{b.pathFromRoot("build.zig.zon")});
}
