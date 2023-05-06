//! Optional Argument Structures

const std = @import("std");
const ascii = std.ascii;

const toUpper = ascii.upperString;

const Val = @import("Value.zig");

pub const In = struct {
    short_name: ?u8,
    long_name: ?[]const u8,

    val: Val = Val{},

    description: []const u8 = "",

    pub fn getOpt(self: *@This()) Out {
        return Out {
            .long_name = self.long_name,
            .val = self.val,
        };
    }

    pub fn help(self: *@This(), writer: anytype) !void {
        var upper_name_buf: [100]u8 = undefined;
        var upper_name = toUpper(upper_name_buf[0..], self.long_name);
        try writer.print("{s}: ", .{ upper_name });
        try self.usage(writer);
        try writer.print(": {s}", .{ self.description });
    }

    pub fn usage(self: *@This(), writer: anytype) !void {
        try writer.print("-{c}|--{s} [{s} (s)]", .{ 
            self.short_name,
            self.long_name,
            self.val.name,
            @typeName(self.val.val_type),
        });
    }
};

pub const Out = struct {
    name: ?[]u8,

    val: Val,
};
