//! Meta Doc Generation for Cova-based programs
//! This is meant to be built and run as a step in `build.zig`.

// Standard library
const std = @import("std");
const heap = std.heap;
const json = std.json;
const log = std.log;
const mem = std.mem;
const Build = std.Build;
// The Cova library is needed for the `generate` module.
const cova = @import("cova");
const generate = cova.generate;

/// This is a reference module for the program being built. Typically this is the main `.zig` file
/// in a project that has both the `main()` function and `setup_cmd` Command. 
const program = @import("program");
/// This is a reference to the Build Options passed in from `build.zig`.
const md_config = @import("md_config_opts");
/// Manpages Config
const manpages_config = optsToConf(generate.ManpageConfig, @import("manpages_config"));
/// Tab Completion Config
const tab_complete_config = optsToConf(generate.TabCompletionConfig, @import("tab_complete_config"));

/// Translate Build Options to Meta Doc Generation Configs.
///TODO Refactor this once Build Options support Types.
fn optsToConf(comptime ConfigT: type, comptime conf_opts: anytype) ?ConfigT {
    if (!conf_opts.provided) return null;
    var conf = ConfigT{};
    for (@typeInfo(ConfigT).Struct.fields) |field| {
        if (std.mem.eql(u8, field.name, "provided")) continue;
        @field(conf, field.name) = @field(conf_opts, field.name);
    }
    return conf;
}

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
    
    const cmd_type_name = @field(program, md_config.cmd_type_name);
    const setup_cmd_name = @field(program, md_config.setup_cmd_name);

    log.info("\nStarting Meta Doc Generation...", .{});
    for (doc_kinds[0..]) |kind| {
        switch (kind) {
            .manpages => {
                if (manpages_config) |mp_config| {
                    try generate.createManpage(
                        cmd_type_name,
                        setup_cmd_name,
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
                        cmd_type_name,
                        setup_cmd_name,
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
