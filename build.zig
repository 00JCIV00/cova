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

    // Modules
    // - Lib Module
    const cova_mod = b.addModule("cova", .{
        .root_source_file = .{ .path = "src/cova.zig" },
    });
    // - Generator Module
    const cova_gen_exe = b.addExecutable(.{
        .name = "cova_generator",
        .root_source_file = .{ .path = "src/generator.zig" },
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(cova_gen_exe);
    //_ = b.addModule("cova_generator", .{
    //    .root_source_file = .{ .path = "src/generator.zig" },
    //});

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

    // Build Options for Gen Docs
    //build_options.addOption(bool, "no_manpages", 
    //    b.option(bool, "no-manpages", "Don't generate manpages (only applies to 'gen-doc' builds)") orelse false
    //);
    //const TabCompletionKind = enum {
    //    bash,
    //    zsh,
    //    ps1,
    //    json,
    //    kdl,
    //    all,
    //    none,
    //};
    //build_options.addOption(TabCompletionKind, "tab_completion_kind", 
    //    b.option(TabCompletionKind, "tab-completion-kind", "Generate tab completion scripts of the given kind (only applies to exe builds)") orelse .bash
    //);
    //build_options.addOption([]const u8, "cmd_type_field_name",
    //    b.option([]const u8, "cmd-type-field-name", "The name of the Command Type field being used to generate the Gen Docs (default: \"CommandT\")") 
    //    orelse "CommandT"
    //);
    //build_options.addOption([]const u8, "setup_cmd_field_name",
    //    b.option([]const u8, "setup-cmd-field-name", "The name of the command field being used to generate the Gen Docs (default: \"setup_cmd\")") 
    //    orelse "setup_cmd"
    //);

    //// Cova Demo Gen Docs
    //const cova_demo_aux = b.addExecutable(.{
    //    .name = "covademo-aux",
    //    .root_source_file = .{ .path = "generator.zig" },
    //    .target = target,
    //    .optimize = optimize,
    //});
    //cova_demo_aux.root_module.addImport("cova", cova_mod);
    //const cova_demo_mod = b.addModule("covademo", .{
    //    .root_source_file = .{ .path = "examples/covademo.zig" },
    //});
    //cova_demo_mod.import_table.put(b.allocator, "cova", cova_mod) catch @panic("OOM");
    //cova_demo_aux.root_module.addImport("program", cova_demo_mod);
    //// - Add Build Options
    //cova_demo_aux.root_module.addOptions("gen_opts", build_options);
    //// - Run Exe and Build Gen Docs
    //const build_cova_demo_aux = b.addRunArtifact(cova_demo_aux);
    //const build_cova_demo_aux_step = b.step("cova-demo-aux-docs", "Build the Manpages and Tab Completion scripts for the 'covademo' example");
    //build_cova_demo_aux_step.dependOn(&build_cova_demo_aux.step);

    //// Basic App Gen Docs
    //const basic_app_aux = b.addExecutable(.{
    //    .name = "basic-app-aux",
    //    .root_source_file = .{ .path = "generator.zig" },
    //    .target = target,
    //    .optimize = optimize,
    //});
    //basic_app_aux.root_module.addImport("cova", cova_mod);
    //const basic_app_mod = b.addModule("basic-app", .{
    //    .root_source_file = .{ .path = "examples/basic_app.zig" },
    //});
    //basic_app_mod.import_table.put(b.allocator, "cova", cova_mod) catch @panic("OOM");
    //basic_app_aux.root_module.addImport("program", basic_app_mod);
    //// - Add Build Options
    //basic_app_aux.root_module.addOptions("gen_opts", build_options);
    //// - Run Exe and Build Gen Docs
    //const build_basic_app_aux = b.addRunArtifact(basic_app_aux);
    //const build_basic_app_aux_step = b.step("basic-app-aux-docs", "Build the Manpages and Tab Completion scripts for the 'basic-app' example");
    //build_basic_app_aux_step.dependOn(&build_basic_app_aux.step);
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
    const cova_gen_exe = cova_dep.artifact("cova_generator");
    cova_gen_exe.root_module.addImport("cova", cova_dep.module("cova"));
    cova_gen_exe.root_module.addImport("program", program_mod);

    const md_conf_opts = b.addOptions();
    var sub_conf_map = std.StringHashMap(?*std.Build.Step.Options).init(b.allocator);
    sub_conf_map.put("manpages_config", null) catch @panic("OOM");
    sub_conf_map.put("tab_complete_config", null) catch @panic("OOM");

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
