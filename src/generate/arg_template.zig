//! Generate Argument Templates that can be easily parsed in external programs.

// Standard
const std = @import("std");
const fmt = std.fmt;
const fs = std.fs;
const json = std.json;
const log = std.log;
const mem = std.mem;

// Cova
const utils = @import("../utils.zig");

/// The Command Template Type, built from a Command Type.
pub fn CommandTemplate(CommandT: type) type {
    return struct {
        const CmdT: type = CommandT;
        const OptTemplateT: type = OptionTemplate(CommandT.OptionT);

        /// Command Name
        name: []const u8,
        /// Command Description
        description: []const u8,

        /// Sub-Commands
        sub_cmds: []const @This(),
        /// Options
        opts: []const OptionTemplate(CommandT.OptionT),


        /// Create a Template from a Command.
        pub fn from(comptime cmd: CommandT) @This() {
            return .{
                .name = cmd.name,
                .description = cmd.description,
                .sub_cmds = comptime subCmds: {
                    if (cmd.sub_cmds) |sub_cmds| {
                        var cmd_tmplts: [sub_cmds.len]@This() = undefined;
                        for (sub_cmds, cmd_tmplts[0..]) |sub_cmd, *tmplt| tmplt.* = from(sub_cmd);
                        break :subCmds cmd_tmplts[0..];
                    }
                    else break :subCmds &.{};
                },
                .opts = comptime setOpts: {
                    if (cmd.opts) |opts| {
                        var opt_tmplts: [opts.len]OptTemplateT = undefined;
                        for (opts, opt_tmplts[0..]) |opt, *tmplt| tmplt.* = OptTemplateT.from(opt);
                        break :setOpts opt_tmplts[0..];
                    }
                    else break :setOpts &.{};
                },
            };
        }

        ///// Custom JSON encoding for the ArgTemplate.
        //pub fn jsonStringify(self: *const @This(), writer: anytype) !void {
        //}
    };
}

/// The Option Template Type, built from a Option Type.
pub fn OptionTemplate(OptionT: type) type {
    return struct {
        const OptT: type = OptionT;

        /// Option Name
        name: []const u8,
        /// Option Description
        description: []const u8,
        /// Value Type Name
        val_type_name: []const u8,

        /// Create a Template from a Option.
        pub fn from(comptime opt: OptionT) @This() {
            return .{
                .name = opt.name,
                .description = opt.description,
                .val_type_name = opt.val.childType(),
            };
        }
    };
}

/// A Config for creating Argument Templates with `createArgTemplate()`.
pub const ArgTemplateConfig = struct{
    /// Script Local Filepath
    /// This is the local path the file will be placed in. The file name will be "`name`-completion.`shell_type`".
    local_filepath: []const u8 = "meta",

    /// Name of the program.
    /// Note, if this is left null, the provided CommandT's name will be used.
    name: ?[]const u8 = null,

    pub const TemplateKind = enum{
        json,
        kdl,
    };
};
/// Create an Argument Template.
pub fn createArgTemplate(
    comptime CommandT: type,
    comptime cmd: CommandT,
    comptime at_config: ArgTemplateConfig,
    comptime at_kind: ArgTemplateConfig.TemplateKind
) !void {
    const at_name = at_config.name orelse cmd.name;
    const filepath = genFilepath: {
        comptime var path = if (at_config.local_filepath.len >= 0) at_config.local_filepath else ".";
        comptime { if (mem.indexOfScalar(u8, &.{ '/', '\\' }, path[path.len - 1]) == null) path = path ++ "/"; }
        try fs.cwd().makePath(path);
        break :genFilepath path ++ at_name ++ "-template." ++ @tagName(at_kind);
    };
    var arg_template = try fs.cwd().createFile(filepath, .{});
    const at_writer = arg_template.writer();
    defer arg_template.close();

    const cmd_template = CommandTemplate(CommandT).from(cmd);

    switch (at_kind) {
        .json => try json.stringify(cmd_template, .{ .whitespace = .indent_4 }, at_writer),
        .kdl => {},
    }
    log.info("Generated '{s}' Argument Template for '{s}' into '{s}'.", .{ @tagName(at_kind), cmd.name, filepath });
}
