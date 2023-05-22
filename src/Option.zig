//! Optional Argument Structure.

const std = @import("std");
const ascii = std.ascii;

const toUpper = ascii.upperString;

const Val = @import("Value.zig");

/// This Options Short Name (ex: `-s`).
short_name: ?u8,
/// This Options long name (ex: `--intOpt`).
long_name: ?[]const u8,
/// This Option's wrapped Value.
val: *const Val.Generic = &Val.init(bool, .{}),

/// The Name of this Option for user identification and Usage/Help messages.
name: []const u8,
/// The Description of this Option for Usage/Help messages.
description: []const u8 = "",

/// Creates the Help message for this Option and Writes it to the provided Writer.
pub fn help(self: *const @This(), writer: anytype) !void {
    var upper_name_buf: [100]u8 = undefined;
    var upper_name = toUpper(upper_name_buf[0..], self.name);
    try writer.print("{s}: ", .{ upper_name });
    
    try self.usage(writer);
    try writer.print(": {s}", .{ self.description });
}

/// Creates the Usage message for this Option and Writes it to the provided Writer.
pub fn usage(self: *const @This(), writer: anytype) !void {
    try writer.print("[-{?c},--{?s} \"{s} ({s})\"]", .{ 
        self.short_name,
        self.long_name,
        self.val.name(),
        self.val.valType(),
    });
}

