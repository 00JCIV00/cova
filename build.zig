const std = @import("std");
pub const generate = @import("src/generate.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    //const build_options = b.addOptions();
    const bin_name = b.option([]const u8, "name", "A name for the binary being created.");
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

    // Docs
    const cova_docs = cova_tests;
    const build_docs = b.addInstallDirectory(.{
        .source_dir = cova_docs.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "../docs",
    });
    const build_docs_step = b.step("docs", "Build the cova library docs");
    build_docs_step.dependOn(&build_docs.step);

    // Modules & Artifacts
    // - Lib Module
    const cova_mod = b.addModule("cova", .{
        .root_source_file = .{ .path = "src/cova.zig" },
    });
    // - Generator Artifact
    const cova_gen_exe = b.addExecutable(.{
        .name = "cova_generator",
        .root_source_file = .{ .path = "src/generator.zig" },
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(cova_gen_exe);

    // Examples
    // - Cova Demo Exe
    const cova_demo = b.addExecutable(.{
        .name = bin_name orelse "covademo",
        .root_source_file = .{ .path = "examples/covademo.zig" },
        .target = target,
        .optimize = optimize,
    });
    cova_demo.root_module.addImport("cova", cova_mod);
    const build_cova_demo = b.addInstallArtifact(cova_demo, .{});
    const build_cova_demo_step = b.step("cova-demo", "Build the 'covademo' example (default: Debug)");
    build_cova_demo_step.dependOn(&build_cova_demo.step);
    // - Cova Demo Meta Docs
    const cova_demo_gen = createDocGenStep(
        b,
        cova_gen_exe,
        cova_mod,
        &cova_demo.root_module,
        .{
            .kinds = &.{ .manpages, .bash },
            .manpages_config = .{
                .local_filepath = "meta/manpages",
                .version = "0.10.0",
                .ver_date = "05 FEB 2024",
                .man_name = "User's Manual",
                .author = "00JCIV00",
                .copyright = "Copyright info here",
            },
            .tab_complete_config = .{
                .local_filepath = "meta",
                .include_opts = true,
            },
        },
    );
    const cova_demo_gen_step = b.step("cova-demo-gen", "Generate Meta Docs for the 'covademo'");
    cova_demo_gen_step.dependOn(&cova_demo_gen.step);

    // - Basic App Exe
    const basic_app = b.addExecutable(.{
        .name = bin_name orelse "basic-app",
        .root_source_file = .{ .path = "examples/basic_app.zig" },
        .target = target,
        .optimize = optimize,
    });
    basic_app.root_module.addImport("cova", cova_mod);
    const build_basic_app = b.addInstallArtifact(basic_app, .{});
    const build_basic_app_step = b.step("basic-app", "Build the 'basic-app' example (default: Debug)");
    build_basic_app_step.dependOn(&build_basic_app.step);
    // - Basic App Meta Docs
    const basic_app_gen = createDocGenStep(
        b,
        cova_gen_exe,
        cova_mod,
        &basic_app.root_module,
        .{
            .kinds = &.{ .manpages, .json },
            .version = "0.10.0",
            .ver_date = "10 FEB 2024",
            .author = "00JCIV00",
            .copyright = "Copyright info here",
            .manpages_config = .{
                .local_filepath = "meta/manpages",
                .man_name = "User's Manual",
            },
            .tab_complete_config = .{
                .local_filepath = "meta",
                .include_opts = true,
            },
            .arg_template_config = .{
                .local_filepath = "meta/arg_templates",
                .include_opts = true
            },
        },
    );
    const basic_app_gen_step = b.step("basic-app-gen", "Generate Meta Docs for the 'basic-app'");
    basic_app_gen_step.dependOn(&basic_app_gen.step);
}


/// Add Cova's Meta Doc Generation Step to a project's `build.zig`.
pub fn addCovaDocGenStep(
    b: *std.Build,
    /// The Cova Dependency of the project's `build.zig`.
    cova_dep: *std.Build.Dependency,
    /// The Program Module where the Command Type and Setup Command can be found.
    program_mod: *std.Build.Module,
    /// The Config for Meta Doc Generation.
    doc_gen_config: generate.MetaDocConfig,
) *std.Build.Step.Run {
    return createDocGenStep(
        b,
        cova_dep.artifact("cova_generator"),
        cova_dep.module("cova"),
        program_mod,
        doc_gen_config,
    );
}

/// Create the Meta Doc Generation Step.
fn createDocGenStep(
    b: *std.Build,
    cova_gen_exe: *std.Build.Step.Compile,
    cova_mod: *std.Build.Module,
    program_mod: *std.Build.Module,
    doc_gen_config: generate.MetaDocConfig,
) *std.Build.Step.Run {
    //const cova_gen_exe = cova_dep.artifact("cova_generator");
    //cova_gen_exe.root_module.addImport("cova", cova_dep.module("cova"));
    cova_gen_exe.root_module.addImport("cova", cova_mod);
    cova_gen_exe.root_module.addImport("program", program_mod);

    const md_conf_opts = b.addOptions();
    var sub_conf_map = std.StringHashMap(?*std.Build.Step.Options).init(b.allocator);
    sub_conf_map.put("manpages_config", null) catch @panic("OOM");
    sub_conf_map.put("tab_complete_config", null) catch @panic("OOM");
    sub_conf_map.put("arg_template_config", null) catch @panic("OOM");

    inline for (@typeInfo(generate.MetaDocConfig).Struct.fields) |field| {
        switch(@typeInfo(field.type)) {
            .Struct, .Enum => continue,
            .Optional => |optl| {
                switch (@typeInfo(optl.child)) {
                    .Struct => |struct_info| {
                        const maybe_conf = @field(doc_gen_config, field.name);
                        if (maybe_conf) |conf| {
                            const doc_conf_opts = b.addOptions();
                            inline for (struct_info.fields) |s_field| {
                                if (@typeInfo(s_field.type) == .Enum) {
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
            .Pointer => |ptr| {
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
            if (conf.value_ptr.*) |conf_opts| conf_opts
            else confOpts: {
                const conf_opts = b.addOptions();
                conf_opts.addOption(bool, "provided", false);
                break :confOpts conf_opts;
            }
        );
    }

    return b.addRunArtifact(cova_gen_exe);
}
