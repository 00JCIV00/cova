//! Input and Output Command Structure.
const std = @import("std");
const mem = std.mem;
const StringHashMap = std.StringHashMap;

const Opt = @import("Option.zig");
const Val = @import("Value.zig");

/// The list of Sub Commands this Command can take.
sub_cmds: ?[]*const @This() = null,
/// The Sub Command assigned to this Command during Parsing (optional).
sub_cmd: ?*const @This() = null,
/// The list of Options this Command can take.
opts: ?[]*const Opt = null,
/// The list of Values this Command can take.
vals: ?[]*const Val.Generic = null,

/// The Name of this Command for user identification and Usage/Help messages.
name: []const u8,
/// The Prefix used immediately before a Usage/Help message is displayed.
help_prefix: []const u8 = "",
/// The Description of this Command for Usage/Help messages.
description: []const u8 = "",

/// Sets the active Sub-Command for this Command.
pub fn setSubCmd(self: *const @This(), set_cmd: *const @This()) void {
    @constCast(self).*.sub_cmd = @constCast(set_cmd);
}

/// Gets a StringHashMap of this Command's Options.
pub fn getOpts(self: *const @This(), alloc: mem.Allocator) !StringHashMap(*const Opt) {
    if (self.opts == null) return error.NoOptionsInCommand;
    var map = StringHashMap(*const Opt).init(alloc);
    for (self.opts.?) |opt| { try map.put(opt.name, opt); }
    return map;
}

/// Gets a StringHashMap of this Command's Values.
pub fn getVals(self: *const @This(), alloc: mem.Allocator) !StringHashMap(*const Val) {
    if (self.vals == null) return error.NoValuesInCommand;
    var map = StringHashMap(*const Val).init(alloc);
    for (self.vals.?) |val| { try map.put(val.name, val); }
    return map;
}

/// Creates the Help message for this Command and Writes it to the provided Writer.
pub fn help(self: *const @This(), writer: anytype) !void {
    try writer.print("{s}\n", .{ self.help_prefix });

    try self.usage(writer);

    try writer.print(\\HELP:
                     \\    Command: {s}
                     \\
                     \\    Description: {s}
                     \\
                     \\
                     , .{ self.name, self.description });
    
    if (self.sub_cmds != null) {
        try writer.print("    Sub Commands:\n", .{});
        for (self.sub_cmds.?) |cmd| {
            try writer.print("        {s}: {s}\n", .{cmd.name, cmd.description});
        }
    }
    try writer.print("\n", .{});

    if (self.opts != null) {
        try writer.print("    Options:\n", .{});
        for (self.opts.?) |opt| {
            try writer.print("        ", .{});
            try opt.help(writer);
            try writer.print("\n", .{});
        }
    }
    try writer.print("\n", .{});

    if (self.vals != null) {
        try writer.print("    Values:\n", .{});
        for (self.vals.?) |val| {
            try writer.print("        {s} ({s}): {s}\n", .{ val.name(), val.valType(), val.description() });
        }
    }
    try writer.print("\n", .{});
}

/// Creates the Usage message for this Command and Writes it to the provided Writer.
pub fn usage(self: *const @This(), writer: anytype) !void {
    try writer.print("USAGE: {s} ", .{ self.name });
    if (self.opts != null) {
        for (self.opts.?) |opt| {
            try opt.usage(writer);
            try writer.print(" ", .{});
        }
        try writer.print("| ", .{});
    }
    if (self.vals != null) {
        for (self.vals.?) |val| try writer.print("\"{s} ({s})\" ", .{ val.name(), val.valType() });
        try writer.print("| ", .{});
    }
    if (self.sub_cmds != null) {
        for (self.sub_cmds.?) |cmd| try writer.print("'{s}' ", .{ cmd.name });
        //try writer.print("| ", .{});
    } 

    try writer.print("\n\n", .{});
}

