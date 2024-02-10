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
        const ValTemplateT: type = ValueTemplate(CommandT.ValueT);

        /// Command Name
        name: []const u8,
        /// Command Description
        description: []const u8,
        /// Option Aliases
        aliases: ?[]const []const u8,
        /// Option Group
        group: ?[]const u8,

        /// Sub-Commands
        sub_cmds: ?[]const @This() = null,
        /// Options
        opts: ?[]const OptionTemplate(CommandT.OptionT) = null,
        /// Values
        vals: ?[]const ValueTemplate(CommandT.ValueT) = null,


        /// Create a Template from a Command (`cmd`) using the provided Argument Template Config (`at_config`).
        pub fn from(comptime cmd: CommandT, comptime at_config: ArgTemplateConfig) @This() {
            return .{
                .name = cmd.name,
                .description = cmd.description,
                .aliases = cmd.alias_names,
                .group = cmd.cmd_group,
                .sub_cmds = comptime subCmds: {
                    if (!at_config.include_cmds) break :subCmds null;
                    const sub_cmds = cmd.sub_cmds orelse break :subCmds null;
                    var cmd_tmplts: [sub_cmds.len]@This() = undefined;
                    for (sub_cmds, cmd_tmplts[0..]) |sub_cmd, *tmplt| tmplt.* = from(sub_cmd, at_config);
                    break :subCmds cmd_tmplts[0..];
                },
                .opts = comptime setOpts: {
                    if (!at_config.include_opts) break :setOpts null;
                    const opts = cmd.opts orelse break :setOpts null;
                    var opt_tmplts: [opts.len]OptTemplateT = undefined;
                    for (opts, opt_tmplts[0..]) |opt, *tmplt| tmplt.* = OptTemplateT.from(opt);
                    break :setOpts opt_tmplts[0..];
                },
                .vals = comptime setvals: {
                    if (!at_config.include_vals) break :setvals null;
                    const vals = cmd.vals orelse break :setvals null;
                    var val_tmplts: [vals.len]ValTemplateT = undefined;
                    for (vals, val_tmplts[0..]) |val, *tmplt| tmplt.* = ValTemplateT.from(val);
                    break :setvals val_tmplts[0..];
                },
            };
        }
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
        /// Option Aliases
        aliases: ?[]const []const u8,
        /// Option Group
        group: ?[]const u8,

        /// Value Type Name
        type_name: []const u8,
        /// Value Set Behavior
        set_behavior: []const u8,
        /// Value Max Arguments
        max_args: u8,

        /// Create a Template from a Option.
        pub fn from(comptime opt: OptionT) @This() {
            return .{
                .name = opt.name,
                .description = opt.description,
                .aliases = opt.alias_long_names,
                .group = opt.opt_group,
                .type_name = opt.val.childType(),
                .set_behavior = @tagName(opt.val.setBehavior()),
                .max_args = opt.val.maxArgs(),
            };
        }
    };
}

/// The Value Template Type, built from a Value Type.
pub fn ValueTemplate(ValueT: type) type {
    return struct {
        const ValT: type = ValueT;

        /// Value Name
        name: []const u8,
        /// Value Description
        description: []const u8,
        /// Value Group
        group: ?[]const u8,

        /// Value Type Name
        type_name: []const u8,
        /// Value Set Behavior
        set_behavior: []const u8,
        /// Value Max Arguments
        max_args: u8,

        /// Create a Template from a Value.
        pub fn from(comptime val: ValueT) @This() {
            return .{
                .name = val.name(),
                .description = val.description(),
                .group = val.valGroup(),
                .type_name = val.childType(),
                .set_behavior = @tagName(val.setBehavior()),
                .max_args = val.maxArgs(),
            };
        }
    };
}

/// Meta Info Template
pub const MetaInfoTemplate = struct{
    /// Name of the program.
    name: ?[]const u8 = null,
    /// Description of the program.
    description: ?[]const u8 = null,
    /// Version of the program.
    version: ?[]const u8 = null,
    /// Date of the program version.
    ver_date: ?[]const u8 = null,
    /// Author of the program.
    author: ?[]const u8 = null,
    /// Copyright info.
    copyright: ?[]const u8 = null,
};

/// A Config for creating Argument Templates with `createArgTemplate()`.
pub const ArgTemplateConfig = struct{
    /// Script Local Filepath
    /// This is the local path the file will be placed in. The file name will be "`name`-template.`template_kind`".
    local_filepath: []const u8 = "meta",

    /// Name of the program.
    /// Note, if this is left null, the provided CommandT's name will be used.
    name: ?[]const u8 = null,
    /// Description of the program.
    /// Note, if this is left null, the provided CommandT's description will be used.
    description: ?[]const u8 = null,
    /// Version of the program.
    version: ?[]const u8 = null,
    /// Date of the program version.
    ver_date: ?[]const u8 = null,
    /// Author of the program.
    author: ?[]const u8 = null,
    /// Copyright info.
    copyright: ?[]const u8 = null,

    /// Include Commands for Argument Templates.
    include_cmds: bool = true,
    /// Include Options for Argument Templates.
    include_opts: bool = true,
    /// Include Values for Argument Templates.
    include_vals: bool = true,

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
    const at_description = at_config.description orelse cmd.description;
    const filepath = genFilepath: {
        comptime var path = if (at_config.local_filepath.len >= 0) at_config.local_filepath else ".";
        comptime { if (mem.indexOfScalar(u8, &.{ '/', '\\' }, path[path.len - 1]) == null) path = path ++ "/"; }
        try fs.cwd().makePath(path);
        break :genFilepath path ++ at_name ++ "-template." ++ @tagName(at_kind);
    };
    var arg_template = try fs.cwd().createFile(filepath, .{});
    const at_writer = arg_template.writer();
    defer arg_template.close();

    const meta_info_template = MetaInfoTemplate{
        .name = at_name,
        .description = at_description,
        .version = at_config.version,
        .ver_date = at_config.ver_date,
        .author = at_config.author,
        .copyright = at_config.copyright,
    };
    const cmd_template = CommandTemplate(CommandT).from(cmd, at_config);

    switch (at_kind) {
        .json => {
            const json_opts_config = json.StringifyOptions{ 
                .whitespace = .indent_4,
                .emit_null_optional_fields = false,
            };
            try at_writer.print("\"Meta Info\": ", .{});
            try json.stringify(
                meta_info_template,
                json_opts_config,
                at_writer,
            );
            try at_writer.print(",\n\"Arguments\": ", .{});
            try json.stringify(
                cmd_template,
                json_opts_config,
                at_writer
            );
        },
        .kdl => {
            try at_writer.print("The KDL format generator is not yet available. When it is, it will be formatted to match the `usage` tool: https://sr.ht/~jdx/usage/", .{});
        },
    }
    log.info("Generated '{s}' Argument Template for '{s}' into '{s}'.", .{ @tagName(at_kind), cmd.name, filepath });
}
