//! Input and Output Command Structure.

const Opt = @import("Option.zig");
const Val = @import("Value.zig");


sub_cmds: ?[]*const @This() = null,
sub_cmd: ?*const @This() = null,
opts: ?[]*const Opt = null,
vals: ?[]*const Val.Generic = null,

name: []const u8,
help_prefix: []const u8 = "",
description: []const u8 = "",

/// Sets the active Sub-Command for this Command.
pub fn setSubCmd(self: *const @This(), set_cmd: *const @This()) void {
    @constCast(self).*.sub_cmd = @constCast(set_cmd);
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

