//! Meta Doc Generation for Cova-based programs
//! This is meant to be built and run as a step in `build.zig`.

/// Standard library
const std = @import("std");
const heap = std.heap;
const json = std.json;
const log = std.log;
const mem = std.mem;
const Build = std.Build;
/// The Cova library is needed for the `generate` module.
const cova = @import("cova");
const generate = cova.generate; //@import("generate");
/// This is a reference module for the program being built. Typically this is the main `.zig` file
/// in a project that has both the `main()` function and `setup_cmd` Command. 
const program = @import("program");
/// This is a reference to the Build Options passed in from `build.zig`.
const md_config = @import("md_config_opts");
/// Manpages Config
const manpages_config: ?generate.ManpageConfig = mpConfig: {
    const mp_conf_opts = @import("manpages_config");
    if (!mp_conf_opts.provided) break :mpConfig null;
    var mp_conf = generate.ManpageConfig{};
    for (@typeInfo(generate.ManpageConfig).Struct.fields) |field| {
        if (std.mem.eql(u8, field.name, "provided")) continue;
        @field(mp_conf, field.name) = @field(mp_conf_opts, field.name);
    }
    break :mpConfig mp_conf;
};
/// Tab Completion Config
const tab_complete_config: ?generate.TabCompletionConfig = tcConfig: {
    const tc_conf_opts = @import("tab_complete_config");
    if (!tc_conf_opts.provided) break :tcConfig null;
    var tc_conf = generate.TabCompletionConfig{};
    for (@typeInfo(generate.TabCompletionConfig).Struct.fields) |field| {
        if (std.mem.eql(u8, field.name, "provided")) continue;
        @field(tc_conf, field.name) = @field(tc_conf_opts, field.name);
    }
    break :tcConfig tc_conf;
};

//const config: generate.MetaDocConfig = configSetup: {
//    var fba_buf: [100_000]u8 = undefined;
//    var fba = heap.FixedBufferAllocator.init(fba_buf[0..]);
//    const alloc = fba.allocator();
//
//    const config_parsed = json.parseFromSliceLeaky(
//        generate.MetaDocConfig,
//        alloc,
//        md_config.config_json,
//        .{},
//    ) catch @panic("There was an issue with the Meta Doc Config");
//    //defer config_parsed.deinit();
//    //break :configSetup config_parsed.value;
//    break :configSetup config_parsed;
//};

pub fn main() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var arena = heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const alloc = arena.allocator();

    const doc_kinds: []generate.MetaDocConfig.MetaDocKind = docKinds: {
        var kinds: [md_config.kinds.len]generate.MetaDocConfig.MetaDocKind = undefined;
        for (md_config.kinds, kinds[0..]) |md_kind, *kind| kind.* = @enumFromInt(md_kind);
        if (kinds[0] != .all) break :docKinds alloc.dupe(generate.MetaDocConfig.MetaDocKind, kinds[0..]) catch @panic("OOM");
        const mdk_info = @typeInfo(generate.MetaDocConfig.MetaDocKind);
        var kinds_list = std.ArrayList(generate.MetaDocConfig.MetaDocKind).init(alloc);
        errdefer kinds_list.deinit();
        inline for (mdk_info.Enum.fields[1..]) |kind| kinds_list.append(@enumFromInt(kind.value)) catch @panic("OOM");
        break :docKinds kinds_list.toOwnedSlice() catch @panic("OOM");
    };
    log.info("\nStarting Meta Doc Generation...", .{});
    for (doc_kinds[0..]) |kind| {
        switch (kind) {
            .manpages => {
                if (manpages_config) |mp_config| {
                    try generate.createManpage(
                        @field(program, md_config.cmd_type_name),
                        @field(program, md_config.setup_cmd_name),
                        mp_config,
                    );
                }
                else {
                    log.warn("Missing Manpage Configuration! Skipping.", .{});
                    continue;
                }
            },
            .bash => {
                if (tab_complete_config) |tc_config| {
                try generate.createTabCompletion(
                    @field(program, md_config.cmd_type_name),
                    @field(program, md_config.setup_cmd_name),
                    tc_config,
                    .bash,
                );
                }
                else {
                    log.warn("Missing Tab Completion Configuration! Skipping.", .{});
                    continue;
                }
            },
            .zsh => {},
            .ps1 => {},
            .json => {},
            .kdl => {},
            .all => {},
        }
    }
    log.info("Finished Meta Doc Generation!", .{});
}

///// A Build Step for Generating Manpages, Tab Completion Scripts, and other Meta Documents.
//pub fn GeneratorStep(comptime CommandT: type, comptime setup_cmd: CommandT) type {
//    return struct{
//        md_config: MetaDocConfig = .{},
//        step: Build.Step,
//
//        pub fn init(b: *Build, md_config: MetaDocConfig) *@This() {
//            const self = b.allocator.create(@This()) catch @panic("OOM");
//            self.* = .{
//                .md_config = md_config,
//                .step = Build.Step.init(.{
//                    .id = .install_file,
//                    .name = "GenMetaDocs",
//                    .owner = b,
//                    .makeFn = make,
//                }),
//            };
//            return self;
//        }
//
//        fn make(step: *Build.Step, _: *std.Progress.Node) !void {
//            const b = step.owner;
//            const self = @fieldParentPtr(@This(), "step", step);
//
//            const project_main_mod = b.addModule("project_main_mod", .{
//                .root_source_file = .{ .path = self.md_config.project_main_source_file },
//            });
//            _ = project_main_mod;
//            
//            //const project_main = @import("project_main_mod");
//            //const CommandT = @field(project_main, self.md_config.cmd_type_name);
//            //const setup_cmd = @field(project_main, self.md_config.setup_cmd_name);
//            @panic("Command Type: " ++ @typeName(CommandT) ++ ", Setup Command: " ++ setup_cmd.name);
//        }
//    };
//}
