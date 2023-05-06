//! Input and Output Command Structures.

const Opt = @import("Option.zig");
const Val = @import("Value.zig");

pub const In = struct {
    sub_cmds: ?[]const In = null,
    opts: ?[]const Opt.In = null,
    vals: ?[]const Val = null,

    name: []const u8,
    help_prefix: []const u8 = "",
    description: []const u8 = "",

    pub fn help(self: *const @This(), writer: anytype) !void {
        try writer.print("{s}\n", .{ self.help_prefix });

        try self.usage(writer);

        try writer.print(\\HELP:
                         \\   Command: {s}
                         \\
                         \\   Description: {s}
                         \\
                         \\
                         , .{ self.name, self.description });

        try writer.print("    Options:\n", .{});
        for (self.opts) |opt| {
            try writer.print("        ", .{});
            opt.help(writer);
            try writer.print("\n", .{});
        }
        try writer.print("\n\n", .{});

        try writer.print("    Values:\n", .{});
        for (self.vals) |val| {
            try writer.print("        {s} ({s}): {s}\n", .{ val.name, @typeName(val.val_type), val.description });
            try writer.print("\n", .{});
        }
        try writer.print("\n\n", .{});
    }

    pub fn usage(self: *const @This(), writer: anytype) !void {
        try writer.print("USAGE: {s} ", .{ self.name });
        for (self.opts) |opt| try opt.usage(writer);
        try writer.print(" ", .{});
        for (self.vals) |val| try writer.print("[{s} ({s})] ", .{ val.name, val.val_type });
        try writer.print("\n\n", .{});
    }
};

pub const Out = struct {
    name: []u8,
    sub_cmd: ?*Out = null,
    opts: ?[]Opt.Out = null,
    vals: ?[]Val = null,
};
