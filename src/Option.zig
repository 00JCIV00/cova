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
    /// Value Config for this Option type.
    /// This will default to the same Value.Config used by the overarching custom Command type of this custom Option type.
    val_config: Value.Config = .{},

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

    /// During parsing, allow there to be no space ' ' between Options and Values.
    /// This is allowed per the POSIX standard, but may not be ideal as it interrupts the parsing of chained booleans even in the event of a misstype.
    allow_opt_val_no_space: bool = true,
    /// Specify custom Separators between Options and their Values for parsing. (i.e. `--opt=value`)
    /// Spaces ' ' are implicitly included.
    opt_val_seps: []const u8 = "=",
    /// During parsing, allow Abbreviated Long Options. (i.e. '--long' working for '--long-opt')
    /// This is allowed per the POSIX standard, but may not be ideal in every use case.
    /// Note, this does not check for uniqueness and will simply match on the first Option matching the abbreviation.
    allow_abbreviated_long_opts: bool = true,
};

/// Create a Option type with the Base (default) configuration.
pub fn Base() type { return Custom(.{}); }

/// Create a Custom Option type from the provided Config (`config`).
pub fn Custom(comptime config: Config) type {
    return struct {
        /// The Custom Value type used by this Custom Option type.
        const ValueT = Value.Custom(config.val_config);

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

        /// Allow no space between Options and Values.
        /// Check `Options.Config` for details.
        pub const allow_opt_val_no_space = config.allow_opt_val_no_space;
        /// Custom Separators between Options and Values.
        /// Check `Options.Config` for details.
        pub const opt_val_seps = config.opt_val_seps;
        /// Allow Abbreviated Long Options.
        /// Check `Options.Config` for details.
        pub const allow_abbreviated_long_opts = config.allow_abbreviated_long_opts;

        /// This Option's Short Name (ex: `-s`).
        short_name: ?u8 = null,
        /// This Option's Long Name (ex: `--intOpt`).
        long_name: ?[]const u8 = null,
        /// This Option's wrapped Value.
        val: ValueT = ValueT.ofType(bool, .{}),

        /// The Name of this Option for user identification and Usage/Help messages.
        /// Limited to 100B.
        name: []const u8,
        /// The Description of this Option for Usage/Help messages.
        description: []const u8 = "",

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
            /// Name for the Option.
            name: ?[]const u8 = null,
            /// Short Name for the Option.
            short_name: ?u8 = null,
            /// Long Name for the Option.
            long_name: ?[]const u8 = null,
            /// Ignore Incompatible types or error during Comptime.
            ignore_incompatible: bool = true,
            /// Description for the Option.
            opt_description: ?[]const u8 = null,
        };

        /// Create an Option from a Valid Optional StructField or UnionField (`field`) with the provided FromConfig (`from_config`).
        pub fn from(comptime field: anytype, from_config: FromConfig) ?@This() {
            const FieldT = @TypeOf(field);
            if (FieldT != std.builtin.Type.StructField and FieldT != std.builtin.Type.UnionField) 
                @compileError("The provided `field` must be a StructField or UnionField but a '" ++ @typeName(FieldT) ++ "' was provided.");
            const optl_info = @typeInfo(field.type);
            const optl =
                if (optl_info == .Optional) optl_info.Optional
                else if (optl_info == .Array and @typeInfo(optl_info.Array.child) == .Optional) @typeInfo(optl_info.Array.child).Optional
                else @compileError("The field '" ++ field.name ++ "' is not a Valid Optional or Array of Optionals.");
            return .{
                .name = if (from_config.name) |name| name else field.name,
                .description = from_config.opt_description orelse "The '" ++ field.name ++ "' Option of type '" ++ @typeName(field.type) ++ "'.",
                .long_name = if (from_config.long_name) |long_name| long_name else field.name,
                .short_name = from_config.short_name, 
                .val = optVal: {
                    const child_info = @typeInfo(optl.child);
                    switch (child_info) {
                        .Bool, .Int, .Float, .Pointer => break :optVal ValueT.from(field, .{
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


