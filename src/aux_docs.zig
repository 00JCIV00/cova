//! Functions to generate Manpages and Tab Completion scripts

// Standard
const std = @import("std");
const fmt = std.fmt;
const fs = std.fs;
const mem = std.mem;

/// A Config for creating manpages with `createManpage`.
/// Leaving any field blank will remove it from the created manpage.
pub const ManpageConfig = struct{
    /// Manpage Local Filepath
    /// This is the local path the file will be placed in. The file name will be "`name`.`section`".
    local_filepath: []const u8 = "bin",

    // Manpage Info
    /// Section of the Linux Man Pages.
    /// Treat this as a character (ex: `'1'`)
    /// Valid values can be found [here](https://en.wikipedia.org/wiki/Man_page#Manual_sections).
    section: u8 = '1',
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
    const mp_name = mp_config.name orelse cmd.name;
    const mp_description = mp_config.description orelse cmd.description;
    const title = fmt.comptimePrint(
        \\.TH {s}({c})
        \\
        , .{ mp_name, mp_config.section }
    );
    const name = fmt.comptimePrint(
        \\.SH NAME
        \\.B {s}
        \\
        , .{ mp_name }
    );
    const synopsis = 
        if (mp_config.synopsis) |synopsis|
            fmt.comptimePrint(
                \\.SH SYNOPSIS
                \\.B {s}
                \\
                , .{ synopsis }
            )
        else "";
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
                    opt.val.valType(),
                    opt.description,
                });
        }
        if (cmd.vals) |vals| {
            try mp_writer.print(".SS VALUES\n", .{});
            for (vals) |val| 
                try mp_writer.print(mp_config.vals_fmt, .{ 
                    val.name(), 
                    val.valType(),
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
}
