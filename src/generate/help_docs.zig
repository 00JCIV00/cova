//! Generate Help Docs based on Cova Commands.

// Standard
const std = @import("std");
const ascii = std.ascii;
const fmt = std.fmt;
const fs = std.fs;
const log = std.log;
const mem = std.mem;

// Cova
const utils = @import("../utils.zig");

/// A Config for creating Help Docs with `createHelpDoc()`.
/// Leaving any field `null` will remove it from the created Help Doc.
pub const HelpDocsConfig = struct{
    /// Help Doc Local Filepath
    /// This is the local path the file will be placed in. The file name will be "`name`.`section`".
    local_filepath: []const u8 = "meta/help_docs",
    /// Recursively generate Manpages for sub-Commands.
    /// Generated Help Docs for sub-Commands will be titled with `parent-child` syntax. (Ex: `git log` becomes `git-log`).
    recursive_gen: bool = true,
    /// Max-depth for recursive generation.
    recursive_max_depth: u8 = 3,
    /// Blocklist for recursive generation sub-Commands.
    /// This is useful to avoid generating Help Docs for Commands like `usage` and `help`.
    recursive_blocklist: []const []const u8 = &.{ "usage", "help" },

    // Help
    /// Version of the program
    /// This is shown in the Bottom Left.
    version: ?[]const u8 = null,
    /// Date of the program version.
    /// This is shown in the Bottom Center.
    ver_date: ?[]const u8 = null,
    /// Name of the program.
    /// Note, if this is left null, the provided CommandT's name will be used.
    name: ?[]const u8 = null,
    /// Description of the program.
    /// Note, if this is left null, the provided CommandT's description will be used.
    description: ?[]const u8 = null,
    /// Author of the program.
    author: ?[]const u8 = null,
    /// Copyright info.
    copyright: ?[]const u8 = null,
    /// More examples of the program.
    examples: ?[]const u8 = null,

    // Manpage Info
    /// Section of the Linux Manpages.
    /// Treat this as a character (ex: `'1'`)
    /// Valid values can be found [here](https://en.wikipedia.org/wiki/Man_page#Manual_sections).
    section: u8 = '1',
    /// Name of the manpage group.
    /// This is shown in the Upper Center.
    man_name: ?[]const u8 = null,
    /// A quick example of how the program is commonly used.
    synopsis: ?[]const u8 = null,

    // Manpage Structure
    /// Manpages Sub Commands Format.
    /// Must support the following format types in this order:
    /// 1. String (Command Name)
    /// 2. String (Command Description)
    mp_subcmds_fmt: []const u8 = ".B {s}:\n{s}\n\n",
    /// Manpages Options Format.
    /// Must support the following format types in this order:
    /// 1. Character (Option Short Prefix)
    /// 2. Optional Character "{?c}" (Option Short Name)
    /// 3. String (Option Long Prefix)
    /// 4. Optional String "{?s}" (Option Long Name)
    /// 5. String (Option Value Name)
    /// 6. String (Option Value Type)
    /// 7. String (Option Name)
    /// 8. String (Option Description)
    mp_opts_fmt: []const u8 = ".B {s}:\n[{c}{?c},{s}{?s} \"{s} ({s})\"]:\n  {s}\n\n",
    /// Manpages Values Format.
    /// Must support the following format types in this order:
    /// 1. String (Value Name)
    /// 2. String (Value Type)
    /// 3. String (Value Description)
    mp_vals_fmt: []const u8 = ".B {s}:\n({s}): {s}\n\n",
    /// Manpages Examples Format.
    /// Must support the following format types in this order:
    /// 1. String (Example)
    mp_examples_fmt: []const u8 = ".B {s}\n\n",

    // Markdown Structure
    /// Markdown Sub Commands Format.
    /// Must support the following format types in this order:
    /// 1. String (Command Name)
    /// 2. String (Command Description)
    md_subcmds_fmt: []const u8 = "- [__{s}__]({s}): {s}\n",
    /// Markdown Options Format.
    /// Must support the following format types in this order:
    /// 1. Character (Option Short Prefix)
    /// 2. Optional Character "{?c}" (Option Short Name)
    /// 3. String (Option Long Prefix)
    /// 4. Optional String "{?s}" (Option Long Name)
    /// 5. String (Option Aliases)
    /// 6. String (Option Value Name)
    /// 7. String (Option Value Type)
    /// 8. String (Option Name)
    /// 9. String (Option Description)
    md_opts_fmt: []const u8 =
        \\- __{s}__:
        \\    - `{c}{?c}, {s}{?s}{s} <{s} ({s})>`
        \\    - {s}
        \\
    ,
    /// Markdown Values Format.
    /// Must support the following format types in this order:
    /// 1. String (Value Name)
    /// 2. String (Value Type)
    /// 3. String (Value Description)
    md_vals_fmt: []const u8 = 
        \\- __{s}__ ({s})
        \\    - {s}
        \\
    ,
    /// Markdown Examples Format.
    /// Must support the following format types in this order:
    /// 1. String (Example)
    md_examples_fmt: []const u8 = "- `{s}`\n",

    /// Available Kinds of Help Docs.
    pub const DocKind = enum{
        manpages,
        markdown,
    };
};

/// Create a Help Doc for this program based on the provided `CommandT` (`cmd`) and HelpDocConfig (`hd_config`).
/// Note, Manpages are intended for use on Unix systems (where Manpages are typically found).
pub fn createHelpDoc(
    comptime CommandT: type, 
    comptime cmd: CommandT, 
    comptime hd_config: HelpDocsConfig,
    comptime doc_kind: HelpDocsConfig.DocKind,
) !void {
    switch (doc_kind) {
        .manpages => {
            try createManpageCtx(CommandT, cmd, hd_config, .{
                .name = hd_config.name orelse cmd.name,
                .cur_depth = 0,
            });
        },
        .markdown => {
            try createMarkdownCtx(CommandT, cmd, hd_config, .{
                .name = hd_config.name orelse cmd.name,
                .cur_depth = 0,
            });
        },
    }
}
/// Help Doc Context for recursive calls of `create[Doc]Ctx()`.
const HelpDocContext = struct {
    /// Name of the Help Doc.
    name: []const u8,
    /// Current recursion depth.
    cur_depth: u8 = 0,
    /// Names of Predecessor Commands.
    pre_names: ?[]const []const u8 = null,
    /// Filepaths of Predecessor Commands.
    pre_paths: []const []const u8 = &.{ "" },
};

/// Create a manpage with Context (`mp_ctx`).
fn createManpageCtx(
    comptime CommandT: type,
    comptime cmd: CommandT,
    comptime mp_config: HelpDocsConfig,
    comptime mp_ctx: HelpDocContext
) !void {
    //log.info("Generating Manpages for '{s}'...", .{ cmd.name });
    const mp_name = mp_ctx.name;
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
        else if (CommandT.include_examples) cmdExamples: {
            const examples = cmd.examples orelse break :cmdExamples "";
            comptime var example_str: []const u8 = ".SH Examples\n\n";
            inline for (examples) |example| 
                example_str = example_str ++ fmt.comptimePrint(mp_config.mp_examples_fmt, .{ example });
            example_str = example_str ++ "\n";
            const example_str_out = example_str;
            break :cmdExamples example_str_out;
        }
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
        path = path ++ "manpages/";
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
                try mp_writer.print(mp_config.mp_subcmds_fmt, .{ sub_cmd.name, sub_cmd.description });
        }
        if (cmd.opts) |opts| {
            try mp_writer.print(".SS OPTIONS\n", .{});
            for (opts) |opt|
                try mp_writer.print(mp_config.mp_opts_fmt, .{
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
                try mp_writer.print(mp_config.mp_vals_fmt, .{
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
    log.info("Generated Manpages for '{s}' into '{s}'.", .{ cmd.name, filepath });

    // Recursive sub-Command generation
    if (!mp_config.recursive_gen or (mp_ctx.cur_depth + 1 >= mp_config.recursive_max_depth)) return;
    inline for (cmd.sub_cmds orelse return) |sub_cmd| {
        comptime if (utils.indexOfEql([]const u8, mp_config.recursive_blocklist, sub_cmd.name) != null) continue;
        comptime var new_ctx = mp_ctx;
        new_ctx.cur_depth += 1;
        new_ctx.name = new_ctx.name ++ "-" ++ sub_cmd.name;
        try createManpageCtx(CommandT, sub_cmd, mp_config, new_ctx);
    }
}

/// Create a Markdown file with Context (`md_ctx`).
fn createMarkdownCtx(
    comptime CommandT: type,
    comptime cmd: CommandT,
    comptime md_config: HelpDocsConfig,
    comptime md_ctx: HelpDocContext
) !void {
    //log.info("Generating Manpages for '{s}'...", .{ cmd.name });
    const md_name = md_ctx.name;
    const md_description = md_config.description orelse cmd.description;
    const filepath = genFilepath: {
        comptime var path = if (md_config.local_filepath.len >= 0) md_config.local_filepath else ".";
        comptime { if (mem.indexOfScalar(u8, &.{ '/', '\\' }, path[path.len - 1]) == null) path = path ++ "/"; }
        path = path ++ "markdown/";
        try fs.cwd().makePath(path);
        break :genFilepath path ++ md_name ++ ".md";
    };
    const local_path = "./" ++ md_name ++ ".md";
    var markdown = try fs.cwd().createFile(filepath, .{});
    var md_writer = markdown.writer();
    defer markdown.close();

    // Header
    try md_writer.print("# {s}\n", .{ cmd.name });
    // - Predecessors
    if (md_ctx.pre_names) |pres| preLinks: {
        try md_writer.print("__[{s}]({s})__", .{ pres[0], md_ctx.pre_paths[0] });
        defer md_writer.print(" > __{s}__\n\n", .{ cmd.name }) catch {};
        if (pres.len == 1) { break :preLinks; }
        for (pres[1..], md_ctx.pre_paths[1..]) |pre_name, pre_path| 
            try md_writer.print(" > __[{s}]({s})__", .{ pre_name, pre_path });
    }
    // - Description
    try md_writer.print("{s}\n\n", .{ md_description });
    // - Meta Info
    if (md_ctx.cur_depth == 0) {
        if (md_config.version) |ver| try md_writer.print("__Version:__ {s}<br>\n", .{ ver });
        if (md_config.ver_date) |date| try md_writer.print("__Date:__ {s}<br>\n", .{ date });
        if (md_config.author) |author| try md_writer.print("__Author:__ {s}<br>\n", .{ author });
        if (md_config.copyright) |copyright| try md_writer.print("__Copyright:__ {s}<br>\n", .{ copyright });
    }
    try md_writer.print("___\n\n", .{});

    // Usage
    try md_writer.print("## Usage\n```shell\n", .{});
    try cmd.usage(md_writer);
    try md_writer.print("```\n\n", .{});

    // Aliases
    if (cmd.alias_names) |aliases| addAliases: {
        try md_writer.print("## Alias(es)\n", .{});
        try md_writer.print("- `{s}`", .{ aliases[0] });
        defer md_writer.print("\n\n", .{}) catch {};
        if (aliases.len == 1) { break :addAliases; }
        for (aliases[1..]) |alias| try md_writer.print("\n- `{s}`", .{ alias });
    }
    
    // Examples
    if (md_config.examples) |examples| try md_writer.print("## Examples\n\n{s]}\n", .{ examples })
    else if (CommandT.include_examples) cmdExamples: {
        const examples = cmd.examples orelse break :cmdExamples;
        try md_writer.print("## Examples\n\n", .{});
        for (examples) |example| try md_writer.print(md_config.md_examples_fmt, .{ example });
        try md_writer.print("\n", .{});
    }

    // Argument Writes
    // TODO Solve custom formats for these
    if (cmd.sub_cmds != null or cmd.opts != null or cmd.vals != null) {
        try md_writer.print("## Arguments\n", .{});
        if (cmd.sub_cmds) |sub_cmds| {
            try md_writer.print("### Commands\n", .{});
            inline for (sub_cmds) |sub_cmd|
                try md_writer.print(md_config.md_subcmds_fmt, .{
                    sub_cmd.name,
                    local_path[0..local_path.len - 3] ++ "-" ++ sub_cmd.name ++ ".md",
                    sub_cmd.description,
                });
        }
        if (cmd.opts) |opts| {
            try md_writer.print("### Options\n", .{});
            const opt_long_pf = CommandT.OptionT.long_prefix orelse "";
            inline for (opts) |opt|
                try md_writer.print(md_config.md_opts_fmt, .{
                    opt.name,
                    CommandT.OptionT.short_prefix orelse 0,
                    if (CommandT.OptionT.short_prefix != null) opt.short_name else 0,
                    opt_long_pf,
                    if (CommandT.OptionT.long_prefix != null) opt.long_name else "",
                    if (opt.alias_long_names) |opt_aliases| optAliases: {
                        comptime var alias_list: []const u8 = "";
                        inline for (opt_aliases) |opt_alias| alias_list = alias_list ++ ", " ++ opt_long_pf ++ opt_alias;
                        break :optAliases alias_list;
                    }
                    else "",
                    opt.val.name(),
                    opt.val.childType(),
                    opt.description,
                });
        }
        if (cmd.vals) |vals| {
            try md_writer.print("### Values\n", .{});
            for (vals) |val|
                try md_writer.print(md_config.md_vals_fmt , .{
                    val.name(),
                    val.childType(),
                    val.description(),
                });
        }
        try md_writer.print("\n", .{});
    }

    log.info("Generated Markdown for '{s}' into '{s}'.", .{ cmd.name, filepath });

    // Recursive sub-Command generation
    if (!md_config.recursive_gen or (md_ctx.cur_depth + 1 >= md_config.recursive_max_depth)) return;
    inline for (cmd.sub_cmds orelse return) |sub_cmd| {
        comptime if (utils.indexOfEql([]const u8, md_config.recursive_blocklist, sub_cmd.name) != null) continue;
        comptime var new_ctx = md_ctx;
        new_ctx.cur_depth += 1;
        new_ctx.name = new_ctx.name ++ "-" ++ sub_cmd.name;
        new_ctx.pre_names = 
            if (new_ctx.pre_names) |pre_names| pre_names ++ @as([]const []const u8, &.{ cmd.name })
            else &.{ cmd.name };
        new_ctx.pre_paths =
            if (new_ctx.pre_paths[0].len > 0) new_ctx.pre_paths ++ @as([]const []const u8, &.{ local_path })
            else &.{ local_path };
        try createMarkdownCtx(CommandT, sub_cmd, md_config, new_ctx);
    }
}
