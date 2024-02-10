//! Generate Manpages based on Cova Commands.

// Standard
const std = @import("std");
const fmt = std.fmt;
const fs = std.fs;
const log = std.log;
const mem = std.mem;

// Cova
const utils = @import("../utils.zig");

/// A Config for creating manpages with `createManpage`.
/// Leaving any field `null` will remove it from the created manpage.
pub const ManpageConfig = struct{
    /// Manpage Local Filepath
    /// This is the local path the file will be placed in. The file name will be "`name`.`section`".
    local_filepath: []const u8 = "meta",
    /// Recursively generate Manpages for sub-Commands.
    /// Generated Manpages for sub-Commands will be titled with `parent-child` syntax. (Ex: `git log` becomes `git-log`).
    recursive_gen: bool = true,
    /// Max-depth for recursive generation.
    recursive_max_depth: u8 = 3,
    /// Blocklist for recursive generation sub-Commands.
    /// This is useful to avoid generating Manpages for Commands like `usage` and `help`.
    recursive_blocklist: []const []const u8 = &.{ "usage", "help" },

    // Manpage Info
    /// Section of the Linux Man Pages.
    /// Treat this as a character (ex: `'1'`)
    /// Valid values can be found [here](https://en.wikipedia.org/wiki/Man_page#Manual_sections).
    section: u8 = '1',
    /// Version of the program
    /// This is shown in the Bottom Left.
    version: ?[]const u8 = null,
    /// Date of the program version.
    /// This is shown in the Bottom Center.
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
    /// Copyright info.
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
    try createManpageCtx(CommandT, cmd, mp_config, .{
        .name = mp_config.name orelse cmd.name,
        .cur_depth = 0,
    });
}
/// Manpage Context for recursive calls of `createManpageCtx()`.
const ManpageContext = struct {
    /// Name of the Manpage. 
    name: []const u8,
    /// Current recursion depth.
    cur_depth: u8 = 0,
};
/// Create a manpage with Context (`mp_ctx`).
fn createManpageCtx(comptime CommandT: type, comptime cmd: CommandT, comptime mp_config: ManpageConfig, comptime mp_ctx: ManpageContext) !void {
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
