//! Meta Doc Generation for Cova-based programs
//! This is meant to be built and run as a step in `build.zig`.

// Standard library
const std = @import("std");
const heap = std.heap;
const json = std.json;
const log = std.log;
const mem = std.mem;
const meta = std.meta;
const Build = std.Build;
// The Cova library is needed for the `generate` module.
const cova = @import("cova");
const generate = cova.generate;
const utils = cova.utils;

/// This is a reference module for the program being built. Typically this is the main `.zig` file
/// in a project that has both the `main()` function and `setup_cmd` Command. 
const program = @import("program");
/// This is a reference to the Build Options passed in from `build.zig`.
const md_config = @import("md_config_opts");
/// Manpages Config
const manpages_config = optsToConf(generate.ManpageConfig, @import("manpages_config"));
/// Tab Completion Config
const tab_complete_config = optsToConf(generate.TabCompletionConfig, @import("tab_complete_config"));
/// Argument Template Config
const arg_template_config = optsToConf(generate.ArgTemplateConfig, @import("arg_template_config"));

const meta_info: []const []const u8 = &.{
    "version",
    "ver_date",
    "name",
    "description",
    "author",
    "copyright",
};
/// Translate Build Options to Meta Doc Generation Configs.
///TODO Refactor this once Build Options support Types.
fn optsToConf(comptime ConfigT: type, comptime conf_opts: anytype) ?ConfigT {
    if (!conf_opts.provided) return null;
    var conf = ConfigT{};
    for (@typeInfo(ConfigT).Struct.fields) |field| {
        if (std.mem.eql(u8, field.name, "provided")) continue;
        @field(conf, field.name) = @field(conf_opts, field.name);
        if (
            (
                @typeInfo(@TypeOf(@field(conf, field.name))) == .Optional and 
                @field(conf, field.name) != null
            ) or
            utils.indexOfEql([]const u8, meta_info, field.name) == null
        ) continue;
        @field(conf, field.name) = @field(md_config, field.name);
    }
    return conf;
}

pub fn main() !void {
    const doc_kinds: []generate.MetaDocConfig.MetaDocKind = comptime docKinds: {
        var kinds: [md_config.kinds.len]generate.MetaDocConfig.MetaDocKind = undefined;
        for (md_config.kinds, kinds[0..]) |md_kind, *kind| kind.* = @enumFromInt(md_kind);
        if (kinds[0] != .all) break :docKinds kinds[0..];
        const mdk_info = @typeInfo(generate.MetaDocConfig.MetaDocKind);
        var kinds_list: [mdk_info.Enum.fields[1..].len]generate.MetaDocConfig.MetaDocKind = undefined;
        for (mdk_info.Enum.fields[1..], kinds_list[0..]) |field, *kind| kind.* = @enumFromInt(field.value);
        break :docKinds kinds_list[0..];
    };
    
    const cmd_type_name = @field(program, md_config.cmd_type_name);
    const setup_cmd_name = @field(program, md_config.setup_cmd_name);

    log.info("\nStarting Meta Doc Generation...", .{});
    inline for (doc_kinds[0..]) |kind| {
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
            .bash, .zsh, .ps1 => |shell| {
                if (tab_complete_config) |tc_config| {
                    try generate.createTabCompletion(
                        cmd_type_name,
                        setup_cmd_name,
                        tc_config,
                        meta.stringToEnum(generate.TabCompletionConfig.ShellKind, @tagName(shell)).?,
                    );
                }
                else {
                    log.warn("Missing Tab Completion Configuration! Skipping.", .{});
                    continue;
                }
            },
            .json, .kdl => |template| {
                if (arg_template_config) |at_config| {
                    try generate.createArgTemplate(
                        cmd_type_name,
                        setup_cmd_name,
                        at_config,
                        meta.stringToEnum(generate.ArgTemplateConfig.TemplateKind, @tagName(template)).?,
                    );
                }
                else {
                    log.warn("Missing Argument Template Configuration! Skipping.", .{});
                    continue;
                }
            },
            .all => {},
        }
    }
    log.info("Finished Meta Doc Generation!", .{});
}
