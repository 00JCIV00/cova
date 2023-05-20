//! Optional Argument Structure.

const std = @import("std");
const ascii = std.ascii;

const toUpper = ascii.upperString;

const Val = @import("Value.zig");


short_name: ?u8,
long_name: ?[]const u8,
val: *const Val.Generic = &Val.init(bool, .{}),
description: []const u8 = "",

/// Gets the inner value of the Value of this Option.
pub fn get(self: *const @This()) !self.val.val_type {
    return try self.val.get();
}

/// Creates the Help message for this Option and Writes it to the provided Writer.
pub fn help(self: *const @This(), writer: anytype) !void {
    if (self.long_name != null) {
        var upper_name_buf: [100]u8 = undefined;
        var upper_name = toUpper(upper_name_buf[0..], self.long_name.?);
    try writer.print("{s}: ", .{ upper_name });
    }
    try self.usage(writer);
    try writer.print(": {s}", .{ self.description });
}

/// Creates the Usage message for this Option and Writes it to the provided Writer.
pub fn usage(self: *const @This(), writer: anytype) !void {
    try writer.print("[-{?c},--{?s} \"{s} ({s})\"]", .{ 
        self.short_name,
        self.long_name,
        @constCast(self.val).*.name(),
        @constCast(self.val).*.valType(),
    });
}

