//! Input and Output Command Structures.

const Opt = @import("Option.zig");
const Val = @import("Value.zig");

pub const In = struct {
    name: []u8,
    sub_cmds: ?[]In = null,
    opts: ?[]Opt.In = null,
    vals: ?[]Val = null,

    description: []u8 = "",

    pub fn help(self: *@This(), writer: anytype) !void {
        try writer.print(\\HELP:
                         \\   Command: {s}
                         \\
                         \\   Description: {s}
                         \\
                         \\
                         , .{ self.name, self.description });

        self.usage(writer);

        try writer.print("    Options:\n", .{});
        for (self.opts) |opt| {
            opt.help(writer);
            try writer.print("\n\n", .{});
        }

        try writer.print("    Values:\n", .{});
        for (self.vals) |val| {
            try writer.print("        {s}: {s}\n", .{ val.name, val.description });
            try writer.print("\n\n", .{});
        }
    }

    pub fn usage(self: *@This(), writer: anytype) !void {
        try writer.print("    Usage: {s} ", .{ self.name });
        for (self.opts) |opt| opt.usage(writer);
        try writer.print(" ", .{});
        for (self.vals) |val| try writer.print("[{s}] ", .{val.name});
        try writer.print("\n\n", .{});
    }
};

pub const Out = struct {
    name: []u8,
    sub_cmd: ?Out = null,
    opts: ?[]Opt.Out = null,
    vals: ?[]Val = null,
};
