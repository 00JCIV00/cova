//! Generate Tab Completion scripts for various shells based on Cova Commands.

// Standard
const std = @import("std");
const fmt = std.fmt;
const fs = std.fs;
const log = std.log;
const mem = std.mem;

// Cova
const utils = @import("../utils.zig");

/// A Config for creating tab completion scripts with `createTabCompletion()`.
pub const TabCompletionConfig = struct{
    /// Script Local Filepath
    /// This is the local path the file will be placed in. The file name will be "`name`-completion.`shell_type`".
    local_filepath: []const u8 = "meta",

    /// Script Header
    /// This is useful for setting the shebang of a shell and, optionally, header comments.
    /// If this is left null, a default shebang or value for the given Shell Kind will be used.
    script_header: ?[]const u8 = null,
    /// Name of the program.
    /// Note, if this is left null, the provided CommandT's name will be used.
    name: ?[]const u8 = null,

    /// Include Commands for Tab Completion.
    include_cmds: bool = true,
    /// Include Options for Tab Completion.
    include_opts: bool = false,
    /// Include Usage/Help for Tab Completion.
    include_usage_help: bool = true,
    /// Allow Cova Library message.
    /// By default the `createTabCompletion()` function will write a short message stating the script was generated by the Cova Library.
    allow_cova_lib_msg: bool = true,

    pub const ShellKind = enum{
        bash,
        zsh,
        ps1,
    };
};
/// Create a Tab Completion script for the provided CommandT (`cmd`) configured by the given TabCompletionConfig (`tc_config`).
pub fn createTabCompletion(comptime CommandT: type, comptime cmd: CommandT, comptime tc_config: TabCompletionConfig, comptime shell_kind: TabCompletionConfig.ShellKind) !void {
    //log.info("Generating '{s}' Tab Completion for '{s}'...", .{ @tagName(shell_kind), cmd.name });
    const tc_name = tc_config.name orelse cmd.name;
    const script_header = tc_config.script_header orelse switch (shell_kind) {
        .bash => "#! /usr/bin/env bash",
        .zsh => "",
        .ps1 => "",
    };

    const filepath = genFilepath: {
        comptime var path = if (tc_config.local_filepath.len >= 0) tc_config.local_filepath else ".";
        comptime { if (mem.indexOfScalar(u8, &.{ '/', '\\' }, path[path.len - 1]) == null) path = path ++ "/"; }
        try fs.cwd().makePath(path);
        break :genFilepath path ++ tc_name ++ "-completion." ++ @tagName(shell_kind);
    };
    var tab_completion = try fs.cwd().createFile(filepath, .{});
    var tc_writer = tab_completion.writer();
    defer tab_completion.close();


    // Tab Completion Script Header Write
    try tc_writer.print(
        \\{s}
        \\
        \\{s}
        \\
        \\
        \\
        , .{
            script_header,
            if (tc_config.allow_cova_lib_msg)
                \\# This Tab Completion script was generated by the Cova Library.
                \\# Details at https://github.com/00JCIV00/cova
            else "",
        }
    );
    const tc_ctx = TabCompletionContext{
        .name = tc_name,
        .include_cmds = tc_config.include_cmds,
        .include_opts = tc_config.include_opts,
        .include_usage_help = tc_config.include_usage_help,
    };
       
    switch (shell_kind) {
        .bash => try cmdTabCompletionBash(CommandT, cmd, tc_writer, tc_ctx),
        .zsh => {},
        .ps1 => {},
    }
    log.info("Generated '{s}' Tab Completion for '{s}' into '{s}'.", .{ @tagName(shell_kind), cmd.name, filepath });
}

/// Context used to track info through recursive calls of `cmdTabCompletion...()` functions.
const TabCompletionContext = struct{
    /// Parent Command Name
    parent_name: []const u8 = "",
    /// Command Name
    name: []const u8 = "",
    /// Argument Index
    idx: u8 = 1,
    /// Include Commands for Tab Completion.
    include_cmds: bool = true,
    /// Include Options for Tab Completion.
    include_opts: bool = false,
    /// Include Usage/Help for Tab Completion.
    include_usage_help: bool = true,
};
/// Writes a Tab Completion script snippet for the provided CommandT (`cmd`) to the given Writer (`tc_writer`).
/// This function passes the provided TabCompletionContext (`tc_ctx`) to track info through recursive calls.
fn cmdTabCompletionBash(comptime CommandT: type, comptime cmd: CommandT, tc_writer: anytype, comptime tc_ctx: TabCompletionContext) !void {
    // Get Sub Commands and Options
    const long_pf = CommandT.OptionT.long_prefix orelse "";
    const args_list: []const u8 = comptime genArgList: {
        var args: []const u8 = "";
        if (tc_ctx.include_cmds) {
            if (cmd.sub_cmds) |sub_cmds| {
                for (sub_cmds) |sub_cmd| args = args ++ sub_cmd.name ++ " ";
            }
            if (tc_ctx.include_usage_help) args = args ++ "help usage ";
        }
        if (tc_ctx.include_opts) {
            if (cmd.opts) |opts| {
                for (opts) |opt| {
                    if (opt.long_name) |long_name| args = args ++ long_pf ++ long_name ++ " ";
                }
            }
            if (tc_ctx.include_usage_help) args = args ++ long_pf ++ "help " ++ long_pf ++ "usage";
        }
        break :genArgList args;
    };
    if (args_list.len == 0) return;

    // Tab Completion Script Snippet Write
    try tc_writer.print(
        \\_{s}_completions() {{
        \\    local cur prev
        \\    COMPREPLY=()
        \\    cur="${{COMP_WORDS[COMP_CWORD]}}"
        \\    prev="${{COMP_WORDS[COMP_CWORD - 1]}}"
        \\
        \\    case "${{prev}}" in
        \\
        , .{
            if (tc_ctx.idx == 1) tc_ctx.name
            else tc_ctx.parent_name ++ "_" ++ tc_ctx.name,
        }
    );
    var args_iter = mem.splitScalar(u8, args_list, ' ');
    while (args_iter.next()) |arg| {
        if (
            utils.indexOfEql([]const u8, &.{ "usage", "help"}, arg) != null or
            mem.eql(u8, if(arg.len < long_pf.len) continue else arg[0..long_pf.len], long_pf)
        ) continue;
        try tc_writer.print(
            \\        "{s}")
            \\            _{s}_{s}_completions
            \\            ;;
            \\
            , .{
                arg,
                tc_ctx.parent_name ++ tc_ctx.name, arg,
            }
        );
    }
    try tc_writer.print(
        \\        "{s}")
        \\            COMPREPLY=($(compgen -W "{s}" -- ${{cur}}))
        \\            ;;
        \\        *)
        \\            COMPREPLY=($(compgen -f -- ${{cur}}))
        \\    esac
        \\}}
        \\
        \\
        , .{
            tc_ctx.name,
            args_list,
        }
    );

    // Iterate through sub-Commands
    if (cmd.sub_cmds) |sub_cmds| {
        comptime var next_ctx = tc_ctx;
        next_ctx.parent_name = (if (tc_ctx.parent_name.len == 0) "" else tc_ctx.parent_name ++ "_") ++ tc_ctx.name;
        next_ctx.idx += 1;
        inline for (sub_cmds) |sub_cmd| {
            next_ctx.name = sub_cmd.name;
            try cmdTabCompletionBash(CommandT, sub_cmd, tc_writer, next_ctx);
        }
    }

    if (tc_ctx.idx == 1) {
        try tc_writer.print("\ncomplete -F _{s}_completions {s}", .{
            tc_ctx.name,
            tc_ctx.name,
        });
    }
}