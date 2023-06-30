//! Wrapper Argument for a Value that is ALWAYS optional.
//!
//! End-User Example:
//!
//! ```
//! # Short Options
//! -n "Bill" -a=5 -t
//! 
//! # Long Options
//! --name="Dion" --age 47 --toggle
//! ```

const std = @import("std");
const ascii = std.ascii;

const toUpper = ascii.toUpper;

const Value = @import("Value.zig");
    
/// Config for custom Option types.
pub const Config = struct {
    /// Format for the Help message. 
    ///
    /// Must support the following format types in this order:
    /// 1. String (Name)
    /// 2. String (Description)
    help_fmt: ?[]const u8 = null,

    /// Format for the Usage message.
    ///
    /// Must support the following format types in this order:
    /// 1. Character (Short Prefix) 
    /// 2. Optional Character "{?c} (Short Name)
    /// 3. String (Long Prefix)
    /// 4. Optional String "{?s}" (Long Name)
    /// 5. String (Value Name)
    /// 6. String (Value Type)
    usage_fmt: []const u8 = "[{c}{?c},{s}{?s} \"{s} ({s})\"]",

    /// Prefix for Short Options.
    short_prefix: u8 = '-',

    /// Prefix for Long Options.
    long_prefix: []const u8 = "--",
};

/// Create a Option type with the Base (default) configuration.
pub fn Base() type { return Custom(.{}); }

/// Create a Custom Option type from the provided Config (`config`).
pub fn Custom(comptime config: Config) type {
    return struct {
        /// This Option's Short Name (ex: `-s`).
        short_name: ?u8 = null,
        /// This Option's Long Name (ex: `--intOpt`).
        long_name: ?[]const u8 = null,
        /// This Option's wrapped Value.
        val: Value.Generic = Value.ofType(bool, .{}),

        /// The Name of this Option for user identification and Usage/Help messages.
        /// Limited to 100B.
        name: []const u8,
        /// The Description of this Option for Usage/Help messages.
        description: []const u8 = "",

        /// Help Format.
        /// Check `Options.Config` for details.
        const help_fmt = config.help_fmt;
        /// Usage Format.
        /// Check `Options.Config` for details.
        const usage_fmt = config.usage_fmt;

        /// Short Prefix.
        /// Check `Options.Config` for details.
        pub const short_prefix = config.short_prefix;
        /// Long Prefix. 
        /// Check `Options.Config` for details.
        pub const long_prefix = config.long_prefix;

        /// Creates the Help message for this Option and Writes it to the provided Writer (`writer`).
        pub fn help(self: *const @This(), writer: anytype) !void {
            var upper_name_buf: [100]u8 = undefined;
            const upper_name = upper_name_buf[0..self.name.len];
            upper_name[0] = toUpper(self.name[0]);
            for(upper_name[1..self.name.len], 1..) |*c, i| c.* = self.name[i];
            if (help_fmt == null) {
                try writer.print("{s}:\n            ", .{ upper_name });
                try self.usage(writer);
                try writer.print("\n            {s}", .{ self.description });
                return;
            }
            try writer.print(help_fmt.?, .{ upper_name, self.description });
        }

        /// Creates the Usage message for this Option and Writes it to the provided Writer (`writer`).
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

        /// Config for creating Options from Struct Fields using `from()`.
        pub const FromConfig = struct {
            /// Short Name for the Option.
            short_name: ?u8 = null,
            /// Ignore Incompatible types or error during Comptime.
            ignore_incompatible: bool = true,
            /// Description for the Option.
            opt_description: ?[]const u8 = null,
        };

        /// Create an Option from a Valid Optional StructField (`field`) with the provided FromConfig (`from_config`).
        pub fn from(comptime field: std.builtin.Type.StructField, from_config: FromConfig) ?@This() {
            const field_info = @typeInfo(field.type);
            const optl =
                if (field_info == .Optional) field_info.Optional
                else if (field_info == .Array and @typeInfo(field_info.Array.child) == .Optional) @typeInfo(field_info.Array.child).Optional
                else @compileError("The field '" ++ field.name ++ "' is not an Optional or Array of Optionals.");
            return .{
                .name = field.name,
                .description = from_config.opt_description orelse "The '" ++ field.name ++ "' Option of type '" ++ @typeName(field.type) ++ "'.",
                .long_name = field.name,
                .short_name = from_config.short_name, 
                .val = optVal: {
                    const optl_info = @typeInfo(optl.child);
                    switch (optl_info) {
                        .Bool, .Int, .Float, .Pointer => break :optVal Value.from(field, .{
                            .ignore_incompatible = from_config.ignore_incompatible,
                            .val_description = from_config.opt_description,
                        }) orelse return null,
                        inline else => {
                            if (!from_config.ignore_incompatible) @compileError("The field '" ++ field.name ++ "' of type '" ++ @typeName(field.type) ++ "' is incompatible as it cannot be converted to a Valid Option or Value.")
                            else return null;
                        },
                    }
                }
            };
        
        }
    };
} 


