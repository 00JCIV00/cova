//! Optional Argument Structure.

const std = @import("std");
const ascii = std.ascii;

const toUpper = ascii.upperString;

const Val = @import("Value.zig");
    
/// Config for custom Option types.
pub const Config = struct {
    /// Format for the Help message. (Comptime Only! null = default format)
    /// Must support the following format types in this order:
    /// - String (Name)
    /// - String (Description)
    help_fmt: ?[]const u8 = null,

    /// Format for the Usage message. (Comptime Only!)
    /// Must support the following format types in this order:
    /// - Character (Short Prefix) 
    /// - Optional Character "{?c} (Short Name)
    /// - String (Long Prefix)
    /// - Optional String "{?s}" (Long Name)
    /// - String (Value Name)
    /// - String (Value Type)
    usage_fmt: []const u8 = "[{c}{?c},{s}{?s} \"{s} ({s})\"]",

    /// Prefix for Short Options.
    short_prefix: u8 = '-',

    /// Prefix for Long Options.
    long_prefix: []const u8 = "--",
};

/// Create a Custom Option type from the provided Config.
pub fn Custom(comptime config: Config) type {
    return struct {
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

        /// Help Format.
        /// Check Options.Config for details.
        const help_fmt = config.help_fmt;
        /// Usage Format.
        /// Check Options.Config for details.
        const usage_fmt = config.usage_fmt;

        /// Short Prefix.
        /// Check Options.Config for details.
        pub const short_prefix = config.short_prefix;
        /// Long Prefix. 
        /// Check Options.Config for details.
        pub const long_prefix = config.long_prefix;

        /// Creates the Help message for this Option and Writes it to the provided Writer.
        pub fn help(self: *const @This(), writer: anytype) !void {
            var upper_name_buf: [100]u8 = undefined;
            var upper_name = toUpper(upper_name_buf[0..], self.name);
            if (help_fmt == null) {
                try writer.print("{s}:\n            ", .{ upper_name });
                try self.usage(writer);
                try writer.print("\n            {s}", .{ self.description });
                return;
            }
            try writer.print(help_fmt.?, .{ upper_name, self.description });
        }

        /// Creates the Usage message for this Option and Writes it to the provided Writer.
        pub fn usage(self: *const @This(), writer: anytype) !void {
            try writer.print(usage_fmt, .{ 
                short_prefix,
                self.short_name,
                long_prefix,
                self.long_name,
                self.val.name(),
                self.val.valType(),
            });
        }
    };
} 


