//! Optional Argument Structure.

const std = @import("std");
const ascii = std.ascii;

const toUpper = ascii.upperString;

const Val = @import("Value.zig");

/// This Option's Short Name (ex: `-s`).
short_name: ?u8,
/// This Option's long name (ex: `--intOpt`).
long_name: ?[]const u8,
/// This Option's wrapped Value.
val: *const Val.Generic = &Val.init(bool, .{}),

/// The Name of this Option for user identification and Usage/Help messages.
name: []const u8,
/// The Description of this Option for Usage/Help messages.
description: []const u8 = "",

/// Format for the Help message. (Comptime Only! null = default format)
/// Must support the following format types in this order:
/// - String (Name)
/// - String (Description)
comptime help_fmt: ?[]const u8 = null,

/// Format for the Usage message. (Comptime Only!)
/// Must support the following format types in this order: 
/// - Optional Character "{?c} (Short Name)
/// - Optional String "{?s}" (Long Name)
/// - String (Value Name)
/// - String (Value Type)
comptime usage_fmt: []const u8 = "[-{?c},--{?s} \"{s} ({s})\"]",

/// Creates the Help message for this Option and Writes it to the provided Writer.
pub fn help(self: *const @This(), writer: anytype) !void {
    var upper_name_buf: [100]u8 = undefined;
    var upper_name = toUpper(upper_name_buf[0..], self.name);
    if (self.help_fmt == null) {
        try writer.print("{s}:\n            ", .{ upper_name });
        
        try self.usage(writer);
        try writer.print("\n            {s}", .{ self.description });
        return;
    }
    try writer.print(self.help_fmt.?, .{ upper_name, self.description });
}

/// Creates the Usage message for this Option and Writes it to the provided Writer.
pub fn usage(self: *const @This(), writer: anytype) !void {
    try writer.print(self.usage_fmt, .{ 
        self.short_name,
        self.long_name,
        self.val.name(),
        self.val.valType(),
    });
}

