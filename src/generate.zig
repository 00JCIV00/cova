//! Functions to generate Manpages and Tab Completion scripts

// Standard
const std = @import("std");
const fmt = std.fmt;
const fs = std.fs;
const log = std.log;
const mem = std.mem;

// Cova
const utils = @import("utils.zig");

/// A Config for setting up all Meta Docs
pub const MetaDocConfig = struct{
    /// Specify which kinds of Meta Docs should be generated.
    kinds: []const MetaDocKind = &.{ .manpages, .bash },
    /// Manpages Config
    manpages_config: ?ManpageConfig = null,
    /// Tab Completion Config
    tab_complete_config: ?TabCompletionConfig = null,
    /// Command Type Name.
    /// This is the name of the Command Type declaration in the main source file.
    cmd_type_name: []const u8 = "CommandT",
    /// Setup Command Name.
    /// This is the name of the comptime Setup Command in the main source file.
    setup_cmd_name: []const u8 = "setup_cmd",

    /// Different Kinds of Meta Documents (Manpages, Tab Completions, etc) available.
    pub const MetaDocKind = enum {
        /// This is the same as adding All of the MetaDocKinds.
        all,
        /// Generate Manpages.
        manpages,
        /// Generate a Bash Tab Completion Script.
        bash,
        /// Generate a Zsh Tab Completion Script. (WIP)
        zsh,
        /// Generate a PowerShell Tab Completion Script. (WIP)
        ps1,
        /// Generate a JSON Representation. (WIP)
        /// This is useful for parsing the main Command using external tools.
        json,
        /// Generate a KDL Representation for use with the [`usage`](https://sr.ht/~jdx/usage/) tool. (WIP)
        kdl,
    };
};

/// A Config for creating manpages with `createManpage`.
/// Leaving any field `null` will remove it from the created manpage.
pub const ManpageConfig = struct{
    /// Manpage Local Filepath
    /// This is the local path the file will be placed in. The file name will be "`name`.`section`".
    local_filepath: []const u8 = "meta",

    // Manpage Info
    /// Section of the Linux Man Pages.
    /// Treat this as a character (ex: `'1'`)
    /// Valid values can be found [here](https://en.wikipedia.org/wiki/Man_page#Manual_sections).
    section: u8 = '1',
    /// Version of the program
    /// This is shown in the Bottom Left.
    version: ?[]const u8 = null,
    /// Date of the program version.
    /// This is shown in the Bottm Center.
    ver_date: ?[]const u8 = null,
    /// Name of the manpage group.
    /// This is shown in the Upper Center.
    man_name: ?[]const u8 = null,
    /// Name of the program.
    /// Note, if this is left null, the provided CommandT's name will be used.
    name: ?[]const u8 = null,
    /// Description of the program.
    /// Note, if this is left null, the provided CommandT's description will be used.
    description: ?[]const u8 = null,
    /// Author of the program.
    author: ?[]const u8 = null,
    /// Copyright message.
    copyright: ?[]const u8 = null,
    /// A quick example of how the program is commonly used.
    synopsis: ?[]const u8 = null,
    /// More examples of the program.
    examples: ?[]const u8 = null,

    // Manpage Structure
    /// Sub Commands Format.
    /// Must support the following format types in this order:
    /// 1. String (Command Name)
    /// 2. String (Command Description)
    subcmds_fmt: []const u8 = ".B {s}:\n{s}\n\n",
    /// Options Format.
    /// Must support the following format types in this order:
    /// 1. Character (Option Short Prefix)
    /// 2. Optional Character "{?c}" (Option Short Name)
    /// 3. String (Option Long Prefix)
    /// 4. Optional String "{?s}" (Option Long Name)
    /// 5. String (Option Value Name)
    /// 6. String (Option Value Type)
    /// 7. String (Option Name)
    /// 8. String (Option Description)
    opts_fmt: []const u8 = ".B {s}:\n[{c}{?c},{s}{?s} \"{s} ({s})\"]:\n  {s}\n\n",
    /// Values Format.
    /// Must support the following format types in this order:
    /// 1. String (Value Name)
    /// 2. String (Value Type)
    /// 3. String (Value Description)
    vals_fmt: []const u8 = ".B {s}:\n({s}): {s}\n\n",
};

/// Create a manpage for this program based on the provided `CommandT` (`cmd`) and ManpageConfig (`mp_config`).
/// Note this is intended for use on Unix systems (where man pages are typically found).
pub fn createManpage(comptime CommandT: type, comptime cmd: CommandT, comptime mp_config: ManpageConfig) !void {
    log.info("Generating Manpages for '{s}'...", .{ cmd.name });
    const mp_name = mp_config.name orelse cmd.name;
    const mp_description = mp_config.description orelse cmd.description;
    const title = fmt.comptimePrint(
        \\.TH {s} {c} {s}{s}{s}
        \\
        , .{
            mp_name,
            mp_config.section,
            if (mp_config.ver_date) |date| "\"" ++ date ++ "\" " else "",
            if (mp_config.version) |ver| "\"" ++ ver ++ "\" " else "",
            if (mp_config.man_name) |man_name| "\"" ++ man_name ++ "\" " else "",
        }
    );
    const name = fmt.comptimePrint(
        \\.SH NAME
        \\.B {s}
        \\
        , .{ mp_name }
    );
    const synopsis = fmt.comptimePrint(
        \\.SH SYNOPSIS
        \\{s}
        \\
        , .{ if (mp_config.synopsis) |synopsis| synopsis else ".B " ++ mp_name ++ "\n.RB [COMMAND]\n.RB [OPTIONS]\n.RB [VALUES]" }
    );
    const description = fmt.comptimePrint(
        \\.SH DESCRIPTION
        \\.B {s}
        \\
        , .{ mp_description }
    );
    const examples =
        if (mp_config.examples) |examples|
            fmt.comptimePrint(
                \\.SH EXAMPLES
                \\.B {s}
                \\
                , .{ examples }
            )
        else "";
    const author =
        if (mp_config.author) |author|
            fmt.comptimePrint(
                \\.SH AUTHOR
                \\.B {s}
                \\
                , .{ author }
            )
        else "";
    const copyright =
        if (mp_config.copyright) |copyright|
            fmt.comptimePrint(
                \\.SH COPYRIGHT
                \\.B {s}
                \\
                , .{ copyright }
            )
        else "";

    const filepath = genFilepath: {
        comptime var path = if (mp_config.local_filepath.len >= 0) mp_config.local_filepath else ".";
        comptime { if (mem.indexOfScalar(u8, &.{ '/', '\\' }, path[path.len - 1]) == null) path = path ++ "/"; }
        try fs.cwd().makePath(path);
        break :genFilepath path ++ mp_name ++ "." ++ .{ mp_config.section };
    };
    var manpage = try fs.cwd().createFile(filepath, .{});
    var mp_writer = manpage.writer();
    defer manpage.close();
    // Pre-Argument Writes
    try mp_writer.print(
        \\{s}
        \\{s}
        \\{s}
        \\{s}
        , .{
            title,
            name,
            synopsis,
            description,
        }
    );
    // Argument Writes
    if (cmd.sub_cmds != null or cmd.opts != null or cmd.vals != null) {
        try mp_writer.print(".SH ARGUMENTS\n", .{});
        if (cmd.sub_cmds) |sub_cmds| {
            try mp_writer.print(".SS COMMANDS\n", .{});
            for (sub_cmds) |sub_cmd|
                try mp_writer.print(mp_config.subcmds_fmt, .{ sub_cmd.name, sub_cmd.description });
        }
        if (cmd.opts) |opts| {
            try mp_writer.print(".SS OPTIONS\n", .{});
            for (opts) |opt|
                try mp_writer.print(mp_config.opts_fmt, .{
                    opt.name,
                    CommandT.OptionT.short_prefix orelse 0,
                    if (CommandT.OptionT.short_prefix != null) opt.short_name else 0,
                    CommandT.OptionT.long_prefix orelse 0,
                    if (CommandT.OptionT.long_prefix != null) opt.long_name else "",
                    opt.val.name(),
                    opt.val.childType(),
                    opt.description,
                });
        }
        if (cmd.vals) |vals| {
            try mp_writer.print(".SS VALUES\n", .{});
            for (vals) |val|
                try mp_writer.print(mp_config.vals_fmt, .{
                    val.name(),
                    val.childType(),
                    val.description()
                });
        }
    }
    // Post-Argument Writes
    try mp_writer.print(
        \\{s}
        \\{s}
        \\{s}
        , .{
            examples,
            author,
            copyright,
        }
    );
    log.info("Generated Manpages for '{s}' into '{s}/'", .{ cmd.name, mp_config.local_filepath });
}

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
    log.info("Generating '{any}' Tab Completion for '{s}'...", .{ shell_kind, cmd.name });
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
    log.info("Generated '{any}' Tab Completion for '{s}' into '{s}/'", .{ shell_kind, cmd.name, tc_config.local_filepath });
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
