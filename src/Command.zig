//! Container Argument for Sub Commands, Options, and Values.
//!
//! A Command may contain any mix of those Arguments or none at all if it's to be used as a standalone Command.
//!
//! End User Example:
//!
//! ```
//! # Standalone Command
//! myapp help
//!
//! # Command w/ Options and Values
//! myapp -d "This Value belongs to the 'd' Option." --toggle "This is a standalone Value."
//! 
//! # Command w/ Sub Command
//! myapp --opt "Option for 'myapp' Command." subcmd --subcmd_opt "Option for 'subcmd' Sub Command."
//! ```

const std = @import("std");
const ascii = std.ascii;
const log = std.log;
const mem = std.mem;
const meta = std.meta;
const ComptimeStringMap = std.ComptimeStringMap;
const StringHashMap = std.StringHashMap;

const eql = mem.eql;
const toLower = ascii.toLower;
const toUpper = ascii.toUpper;

const Option = @import("Option.zig");
const Value = @import("Value.zig");


/// Config for custom Command types. 
pub const Config = struct {
    /// Option Config for this Command type.
    opt_config: Option.Config = .{},

    /// Sub Commands Help Format.
    /// Must support the following format types in this order:
    /// 1. String (Command Name)
    /// 2. String (Command Description)
    subcmds_help_fmt: []const u8 = "{s}: {s}",
    /// Values Help Format.
    /// Must support the following format types in this order:
    /// 1. String (Value Name)
    /// 2. String (Value Type)
    /// 3. String (Value Description)
    vals_help_fmt: []const u8 = "{s} ({s}): {s}",
    
    /// Sub Commands Usage Format.
    /// Must support the following format types in this order:
    /// 1. String (Command Name)
    subcmds_usage_fmt: []const u8 ="'{s}'", 
    /// Values Usage Format.
    /// Must support the following format types in this order:
    /// 1. String (Value Name)
    /// 2. String (Value Type)
    vals_usage_fmt: []const u8 = "\"{s} ({s})\"",

    /// The Global Help Prefix for all instances of this Command type.
    /// This can be overwritten per instance using the `help_prefix` field. 
    global_help_prefix: []const u8 = "",

    /// The Default Max Number of Arguments for Commands, Options, and Values individually.
    /// This is used in for both `init()` and `from()` but can be overwritten for the latter.
    max_args: u8 = 100, 

};

/// Create a Custom Command type from the provided Config.
pub fn Custom(comptime config: Config) type {
    return struct {
        /// The Custom Option type to be used by this Custom Command type.
        pub const CustomOption = Option.Custom(config.opt_config);
        /// Sub Commands Help Format.
        /// Check `Command.Config` for details.
        pub const subcmds_help_fmt = config.subcmds_help_fmt;
        /// Values Help Format.
        /// Check `Command.Config` for details.
        pub const vals_help_fmt = config.vals_help_fmt;
        /// Sub Commands Usage Format.
        /// Check `Command.Config` for details.
        pub const subcmds_usage_fmt = config.subcmds_usage_fmt;
        /// Values Usage Format.
        /// Check `Command.Config` for details.
        pub const vals_usage_fmt = config.vals_usage_fmt;
        /// Global Help Prefix.
        /// Check `Command.Config` for details.
        pub const global_help_prefix = config.global_help_prefix;
        /// Max Args.
        /// Check `Command.Config` for details.
        pub const max_args = config.max_args;

        /// Flag denoting if this Command has been initialized to memory using `init()`.
        ///
        /// **Internal Use.**
        _is_init: bool = false,
        /// The Allocator for this Command.
        /// This is set using `init()`.
        ///
        /// **Internal Use.**
        _alloc: ?mem.Allocator = null,

        /// The list of Sub Commands this Command can take.
        sub_cmds: ?[]const @This() = null,
        /// The Sub Command assigned to this Command during Parsing (optional).
        sub_cmd: ?*const @This() = null,
        /// The list of Options this Command can take.
        opts: ?[]const CustomOption = null,
        /// The list of Values this Command can take.
        vals: ?[]const Value.Generic = null,

        /// The Name of this Command for user identification and Usage/Help messages.
        name: []const u8,
        /// The Prefix message used immediately before a Usage/Help message is displayed.
        help_prefix: []const u8 = global_help_prefix,
        /// The Description of this Command for Usage/Help messages.
        description: []const u8 = "",

        /// Sets the active Sub-Command for this Command.
        pub fn setSubCmd(self: *const @This(), set_cmd: *const @This()) void {
            @constCast(self).*.sub_cmd = set_cmd;
        }

        /// Gets a StringHashMap of this Command's Options.
        pub fn getOpts(self: *const @This()) !StringHashMap(CustomOption) {
            if (!self._is_init) return error.CommandNotInitialized;
            return getOptsAlloc(self._alloc.?);
        }
        /// Gets a StringHashMap of this Command's Options using the provided Allocator.
        pub fn getOptsAlloc(self: *const @This(), alloc: mem.Allocator) !StringHashMap(CustomOption) {
            if (self.opts == null) return error.NoOptionsInCommand;
            var map = StringHashMap(CustomOption).init(alloc);
            for (self.opts.?) |opt| { try map.put(opt.name, opt); }
            return map;
        }

        /// Gets a StringHashMap of this Command's Values.
        pub fn getVals(self: *const @This()) !StringHashMap(Value) {
            if (!self._is_init) return error.CommandNotInitialized;
            return getValsAlloc(self._alloc.?);
        }
        /// Gets a StringHashMap of this Command's Values.
        pub fn getValsAlloc(self: *const @This(), alloc: mem.Allocator) !StringHashMap(Value) {
            if (self.vals == null) return error.NoValuesInCommand;
            var map = StringHashMap(Value).init(alloc);
            for (self.vals.?) |val| { try map.put(val.name, val); }
            return map;
        }

        /// Creates the Help message for this Command and Writes it to the provided Writer.
        pub fn help(self: *const @This(), writer: anytype) !void {
            try writer.print("{s}\n", .{ self.help_prefix });

            try self.usage(writer);

            try writer.print(\\HELP:
                             \\    COMMAND: {s}
                             \\
                             \\    DESCRIPTION: {s}
                             \\
                             \\
                             , .{ self.name, self.description });
            
            if (self.sub_cmds != null) {
                try writer.print("    SUB COMMANDS:\n", .{});
                for (self.sub_cmds.?) |cmd| {
                    try writer.print("        ", .{});
                    try writer.print(subcmds_help_fmt, .{cmd.name, cmd.description});
                    try writer.print("\n", .{});
                }
            }
            try writer.print("\n", .{});

            if (self.opts != null) {
                try writer.print("    OPTIONS:\n", .{});
                for (self.opts.?) |opt| {
                    try writer.print("        ", .{});
                    try opt.help(writer);
                    try writer.print("\n", .{});
                }
            }
            try writer.print("\n", .{});

            if (self.vals != null) {
                try writer.print("    VALUES:\n", .{});
                for (self.vals.?) |val| {
                    try writer.print("        ", .{});
                    try writer.print(vals_help_fmt, .{ val.name(), val.valType(), val.description() });
                    try writer.print("\n", .{});
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
                for (self.vals.?) |val| {
                    try writer.print(vals_usage_fmt, .{ val.name(), val.valType() });
                    try writer.print(" ", .{});
                }
                try writer.print("| ", .{});
            }
            if (self.sub_cmds != null) {
                for (self.sub_cmds.?) |cmd| {
                    try writer.print(subcmds_usage_fmt, .{ cmd.name });
                    try writer.print(" ", .{});
                    //try writer.print("| ", .{});
                }
            } 

            try writer.print("\n\n", .{});
        }

        /// Check if a Flag has been set on this Command as a Command, an Option, or a Value.
        /// This is particularly useful for checking if Help or Usage has been called.
        pub fn checkFlag(self: *const @This(), toggle_name: []const u8) bool {
            return (
                (self.sub_cmd != null and eql(u8, self.sub_cmd.?.name, toggle_name)) or
                checkOpt: {
                    if (self.opts != null) {
                        for (self.opts.?) |opt| {
                            if (eql(u8, opt.name, toggle_name) and 
                                eql(u8, opt.val.valType(), "bool") and 
                                opt.val.bool.get() catch false)
                                    break :checkOpt true;
                        }
                    }
                    break :checkOpt false;
                } or
                checkVal: {
                    if (self.vals != null) {
                        for (self.vals.?) |val| {
                            if (eql(u8, val.name(), toggle_name) and
                                eql(u8, val.valType(), "bool") and
                                val.bool.get() catch false)
                                    break :checkVal true;
                        }
                    }
                    break :checkVal false;
                }
            );
        }

        /// Find the Index of a Slice (Why is this not in std.mem?!?!? Did I miss it?)
        fn indexOfEql(comptime T: type, haystack: []const T, needle: T) ?usize {
            switch (@typeInfo(T)) {
                .Pointer => |ptr| {
                    for (haystack, 0..) |hay, idx| if (eql(ptr.child, hay, needle)) return idx;
                    return null;
                },
                inline else => return mem.indexOfScalar(T, haystack, needle),
            }
        }

        /// Config for creating Commands from Structs using `from()`.
        pub const FromConfig = struct {
            /// Ignore incompatible types.
            ignore_incompatible: bool = true,
            /// Attempt to create Short Options.
            /// This will attempt to make a short option name from the first letter of the field name in lowercase then uppercase, sequentially working through each next letter if the previous one has already been used. (Note, user must deconflict for 'u' and 'h' if using auto-generated Usage/Help Options.)
            attempt_short_opts: bool = true,
            /// A Name for the Command.
            /// A blank value will default to the type name of the Struct.
            cmd_name: []const u8 = "",
            /// A Description for the Command.
            cmd_description: []const u8 = "",
            /// A Help Prefix for the Command.
            cmd_help_prefix: []const u8 = "",

            /// Descriptions of the Command's Sub Commands, Options, and Values.
            /// These Descriptions will be used across this Command and all of its Sub Commands.
            sub_descriptions: []const struct { []const u8, []const u8 } = &.{ .{ "__nosubdescriptionsprovided__", "" } },

            /// Max number of Sub Commands.
            max_cmds: u8 = max_args,
            /// Max number of Options.
            max_opts: u8 = max_args,
            /// Max number of Values.
            max_vals: u8 = max_args,
        };

        /// Create a Command from the provided Struct.
        /// The provided Struct must be Comptime-known.
        /// Types are converted as follows:
        /// - Structs = Commands
        /// - Valid Values = Single-Values (Valid Values can be found under `Value.zig/Generic`.)
        /// - Valid Optionals = Single-Options (Valid Optionals are nullable versions of Valid Values.)
        /// - Arrays of Valid Values = Multi-Values
        /// - Arrays of Valid Optionals = Multi-Options 
        pub fn from(comptime from_struct: type, comptime from_config: FromConfig) @This() {
            const from_info = @typeInfo(from_struct);
            if (from_info != .Struct) @compileError("Provided Type is not a Struct.");

            var from_cmds_buf: [from_config.max_cmds]@This() = undefined;
            const from_cmds = from_cmds_buf[0..];
            var cmds_idx: u8 = 0;
            var from_opts_buf: [from_config.max_opts]CustomOption = undefined;
            const from_opts = from_opts_buf[0..];
            var opts_idx: u8 = 0;
            var short_names_buf: [from_config.max_opts]u8 = undefined;
            var short_names = short_names_buf[0..];
            var short_idx: u8 = 0;
            var from_vals_buf: [from_config.max_vals]Value.Generic = undefined;
            const from_vals = from_vals_buf[0..];
            var vals_idx: u8 = 0;

            const arg_descriptions = ComptimeStringMap([]const u8, from_config.sub_descriptions);

            const fields = meta.fields(from_struct);
            inline for (fields) |field| {
                const arg_description = arg_descriptions.get(field.name);
                const field_info = @typeInfo(field.type);
                switch (field_info) {
                    // Commands
                    .Struct => {
                        const sub_config = comptime subConfig: {
                            var new_config = from_config;
                            new_config.cmd_name = field.name;
                            new_config.cmd_description = arg_description orelse "The '" ++ field.name ++ "' Command.";
                            break :subConfig new_config;
                        };
                        from_cmds[cmds_idx] = from(field.type, sub_config);
                        cmds_idx += 1;
                    },
                    // Options
                    .Optional => {
                        const short_name = shortName: {
                            if (!from_config.attempt_short_opts) break :shortName null;
                            for (field.name) |char| {
                                const ul_chars: [2]u8 = .{ toLower(char), toUpper(char) };
                                for (ul_chars) |ul| {
                                    if (short_idx > 0 and indexOfEql(u8, short_names[0..short_idx], ul) != null) continue;
                                    short_names[short_idx] = ul;
                                    short_idx += 1;
                                    break :shortName ul;
                                }
                            }
                            break :shortName null;
                        };
                        from_opts[opts_idx] = (CustomOption.from(field, .{ 
                            .short_name = short_name, 
                            .ignore_incompatible = from_config.ignore_incompatible,
                            .opt_description = arg_description
                        }) orelse continue);
                        opts_idx += 1;
                    },
                    // Values
                    .Bool, .Int, .Float, .Pointer => {
                        from_vals[vals_idx] = (Value.from(field, .{
                            .ignore_incompatible = from_config.ignore_incompatible,
                            .val_description = arg_description
                        }) orelse continue);
                        vals_idx += 1;
                    },
                    // Multi
                    .Array => |ary| {
                        const ary_info = @typeInfo(ary.child);
                        switch (ary_info) {
                            .Optional => {
                                const short_name = shortName: {
                                    if (!from_config.attempt_short_opts) break :shortName null;
                                    for (field.name) |char| {
                                        const ul_chars: [2]u8 = .{ toLower(char), toUpper(char) };
                                        for (ul_chars) |ul| {
                                            if (short_idx > 0 and indexOfEql(u8, short_names[0..short_idx], ul) != null) continue;
                                            short_names[short_idx] = ul;
                                            short_idx += 1;
                                            break :shortName ul;
                                        }
                                    }
                                    break :shortName null;
                                };
                                from_opts[opts_idx] = CustomOption.from(field, .{
                                    .short_name = short_name, 
                                    .ignore_incompatible = from_config.ignore_incompatible,
                                    .opt_description = arg_description
                                }) orelse continue;
                                opts_idx += 1;
                            },
                            .Bool, .Int, .Float, .Pointer => {
                                from_vals[vals_idx] = Value.from(field, .{
                                    .ignore_incompatible = from_config.ignore_incompatible,
                                    .val_description = arg_description
                                }) orelse continue;
                                vals_idx += 1;
                            },
                            else => if (!from_config.ignore_incompatible) @compileError("The field '" ++ field.name ++ "' of type 'Array' is incompatible. Arrays must contain one of the following types: Bool, Int, Float, Pointer (const u8), or their Optional counterparts."),
                        }
                    },
                    // Incompatible
                    else => if (!from_config.ignore_incompatible) @compileError("The field '" ++ field.name ++ "' of type '" ++ @typeName(field.type) ++ "' is incompatible as it cannot be converted to a Command, Option, or Value."),
                }
            }

            return @This(){
                .name = if (from_config.cmd_name.len > 0) from_config.cmd_name else @typeName(from_struct),
                .description = from_config.cmd_description,
                .help_prefix = from_config.cmd_help_prefix,
                .sub_cmds = if (cmds_idx > 0) from_cmds[0..cmds_idx] else null,
                .opts = if (opts_idx > 0) from_opts[0..opts_idx] else null,
                .vals = if (vals_idx > 0) from_vals[0..vals_idx] else null,
            };
        }

        /// Config for creating Structs from Commands using `to()`.
        pub const ToConfig = struct {
            /// Allow Unset Options and Values to be included.
            /// When this is active, an attempt will be made to use the Struct's default value (if available) in the event of an Unset Option/Value.
            allow_unset: bool = true,
            /// Ignore Incompatible types. Incompatible types are those that fall outside of the conversion rules listed under `from()`.
            /// When this is active, an attempt will be made to use the Struct's default value (if available) in the event of an Incompatible type.
            allow_incompatible: bool = true,
        };

        /// Convert this Command to an instance of the provided Struct Type.
        /// This is the inverse of `from()`.
        /// Types are converted as follows:
        /// - Commmands: Structs by recursively calling `to()`.
        /// - Single-Options: Optional versions of Values.
        /// - Single-Values: Booleans, Integers (Signed/Unsigned), and Pointers (`[]const u8` only)
        /// - Multi-Options/Values: Arrays of the corresponding Optionals or Values.
        // TODO: Catch more error cases for incompatible types (i.e. Pointer not `[]const u8`).
        pub fn to(self: *const @This(), comptime T: type, to_config: ToConfig) !T {
            var out: T = undefined;
            const fields = meta.fields(T);
            inline for (fields) |field| {
                const field_info = @typeInfo(field.type);
                switch (field_info) {
                    .Struct => if (self.sub_cmd != null and eql(u8, self.sub_cmd.?.name, field.name)) {
                        @field(out, field.name) = try self.sub_cmd.?.to(field.type);
                    },
                    .Optional => |f_opt| if (self.opts != null) {
                        for (self.opts.?) |opt| {
                            if (eql(u8, opt.name, field.name)) {
                                if (!opt.val.isSet()) {
                                    if (!to_config.allow_unset) return error.ValueNotSet;
                                    if (field.default_value != null) 
                                        @field(out, field.name) = @ptrCast(*field.type, @alignCast(@alignOf(field.type), @constCast(field.default_value))).*;
                                    break;
                                }
                                const val_tag = if (f_opt.child == []const u8) "string" else @typeName(f_opt.child);
                                @field(out, field.name) = try @field(opt.val, val_tag).get();
                            }
                        }
                    },
                    .Bool, .Int, .Float, .Pointer => if (self.vals != null) {
                        for (self.vals.?) |val| {
                            if (eql(u8, val.name(), field.name)) {
                                if (!val.isSet() and val.argIdx() == val.maxArgs()) {
                                    if (!to_config.allow_unset) return error.ValueNotSet;
                                    if (field.default_value != null) 
                                        @field(out, field.name) = @ptrCast(*field.type, @alignCast(@alignOf(field.type), @constCast(field.default_value))).*;
                                    break;
                                }
                                const val_tag = if (field.type == []const u8) "string" else @typeName(field.type);
                                @field(out, field.name) = try @field(val, val_tag).get();
                            }
                        } 
                    },
                    .Array => |ary| {
                        const ary_info = @typeInfo(ary.child);
                        switch (ary_info) {
                            .Optional => |a_opt| if (self.opts != null) {
                                for (self.opts.?) |opt| {
                                    if (eql(u8, opt.name, field.name)) {
                                        if (!opt.val.isSet()) {
                                            if (!to_config.allow_unset) return error.ValueNotSet;
                                            if (field.default_value != null) 
                                                @field(out, field.name) = @ptrCast(*field.type, @alignCast(@alignOf(field.type), @constCast(field.default_value))).*;
                                            break;
                                        }
                                        const val_tag = if (a_opt.child == []const u8) "string" else @typeName(a_opt.child);
                                        var f_ary: field.type = undefined;
                                        const f_ary_slice = f_ary[0..];
                                        for (f_ary_slice, 0..) |*elm, idx| elm.* = @field(opt.val, val_tag)._set_args[idx];
                                        @field(out, field.name) = f_ary;
                                        break;
                                    }
                                }
                            },
                            .Bool, .Int, .Float, .Pointer => if (self.vals != null) {
                                for (self.vals.?) |val| {
                                    if (eql(u8, val.name(), field.name)) {
                                        if (!val.isSet() and val.argIdx() == val.maxArgs()) {
                                            if (!to_config.allow_unset) return error.ValueNotSet;
                                            if (field.default_value != null) 
                                                @field(out, field.name) = @ptrCast(*field.type, @alignCast(@alignOf(field.type), @constCast(field.default_value))).*;
                                            break;
                                        }
                                        const val_tag = if (ary.child == []const u8) "string" else @typeName(ary.child);
                                        var f_ary: field.type = undefined;
                                        const f_ary_slice = f_ary[0..];
                                        for (f_ary_slice, 0..) |*elm, idx| elm.* = @field(val, val_tag)._set_args[idx];
                                        @field(out, field.name) = f_ary;
                                        break;
                                    }
                                } 
                            },
                            else => {
                                if (!to_config.allow_incompatible) return error.IncompatibleType;
                            },
                        }
                    },
                    else => {
                        if (!to_config.allow_incompatible) return error.IncompatibleType;
                    },
                }
            }
            return out;
        }

        /// Validate this Command during Comptime for distinct Sub Commands, Options, and Values. 
        /// This will not check for Usage/Help Message Commands/Options that are added via `
        pub fn validate(comptime self: *const @This()) void {
            comptime {
                @setEvalBranchQuota(100_000);
                // Check for distinct Sub Commands and Validate them.
                if (self.sub_cmds != null) {
                    const cmds = self.sub_cmds.?;
                    var distinct_cmd: [max_args][]const u8 = .{ "" } ** max_args;
                    for (cmds, 0..) |cmd, idx| {
                        if (indexOfEql([]const u8, distinct_cmd[0..idx], cmd.name) != null) 
                            @compileError("The Sub Command '" ++ cmd.name ++ "' is set more than once.");
                        //cmd.validate();
                        distinct_cmd[idx] = cmd.name;
                    }
                }

                // Check for distinct Options.
                if (self.opts != null) {
                    const opts = self.opts.?;
                    var distinct_name: [max_args][]const u8 = .{ "" } ** max_args;
                    var distinct_short: [max_args]u8 = .{ ' ' } ** max_args;
                    var distinct_long: [max_args][]const u8 = .{ "" } ** max_args;
                    for (opts, 0..) |opt, idx| {
                        if (indexOfEql([]const u8, distinct_name[0..], opt.name) != null) 
                            @compileError("The Option '" ++ opt.name ++ "' is set more than once.");
                        distinct_name[idx] = opt.name;
                        if (opt.short_name != null and indexOfEql(u8, distinct_short[0..], opt.short_name.?) != null) 
                            @compileError("The Option Short Name '" ++ .{ opt.short_name.? } ++ "' is set more than once.");
                        distinct_short[idx] = opt.short_name.?;
                        if (opt.long_name != null and indexOfEql([]const u8, distinct_long[0..], opt.long_name.?) != null) 
                            @compileError("The Option Long Name '" ++ opt.long_name.? ++ "' is set more than once.");
                        distinct_long[idx] = opt.long_name.?;
                    }
                }

                // Check for distinct Values.
                if (self.vals != null) {
                    const vals = self.vals.?;
                    var distinct_val: [max_args][]const u8 = .{ "" } ** max_args;
                    for (vals, 0..) |val, idx| {
                        if (indexOfEql([]const u8, distinct_val[0..], val.name()) != null) 
                            @compileError("The Value '" ++ val.name ++ "' is set more than once.");
                        distinct_val[idx] = val.name();
                    }
                }
            }
        }
    
        /// Config for Setup of this Command.
        const SetupConfig = struct {
            /// Flag to Validate this Command.
            validate_cmd: bool = true,
            /// Flag to add Usage/Help message Commands to this Command.
            add_help_cmds: bool = true,
            /// Flag to add Usage/Help message Options to this Command.
            add_help_opts: bool = true,
        };

        /// Setup this Command during Comptime based on the provided SetupConfig.
        /// (WIP) At this time, this functionality is rolled into `init()`. If I can figure out how to edit a struct instance at Comptime, it'll be moved to here.
        fn setup(comptime self: *const @This(), comptime setup_config: SetupConfig) void {
            comptime {
                const usage_description = "Show the '" ++ self.name ++ "' usage display.";
                const help_description = "Show the '" ++ self.name ++ "' help display.";
                
                if (setup_config.add_help_cmds) {
                    const help_sub_cmds = [_]*const @This(){
                        &@This(){
                            .name = "usage",
                            .help_prefix = self.name,
                            .description = usage_description, 
                        },
                        &@This(){
                            .name = "help",
                            .help_prefix = self.name,
                            .description = help_description, 
                        },
                    };
                    _ = help_sub_cmds;

                    @constCast(self).sub_cmds = self.sub_cmds;//help_sub_cmds[0..];
                        //if (self.sub_cmds != null) self.sub_cmds.? ++ help_sub_cmds[0..]
                        //else help_sub_cmds[0..];
                }

                if (setup_config.add_help_opts) {
                    const help_opts = [_]*const @This().CustomOption{
                        &@This().CustomOption{
                            .name = "usage",
                            .short_name = 'u',
                            .long_name = "usage",
                            .description = usage_description,
                            .val = &Value.ofType(bool, .{ .name = "usageFlag" }),
                        },
                        &@This().CustomOption{
                            .name = "help",
                            .short_name = 'h',
                            .long_name = "help",
                            .description = help_description, 
                            .val = &Value.ofType(bool, .{ .name = "helpFlag" }),
                        },
                    };
                    self.opts = 
                        if (self.opts != null) self.opts.? ++ help_opts[0..]
                        else help_opts[0..];
                }
                if (setup_config.validate_cmd) self.validate();
            }
        }

        /// Config for the Initialization of this Command.
        pub const InitConfig = struct {
            /// Flag to Validate this Command.
            validate_cmd: bool = true,
            /// Flag to add Usage/Help message Commands to this Command.
            add_help_cmds: bool = true,
            /// Flag to add Usage/Help message Options to this Command.
            add_help_opts: bool = true,
            /// Flag to initialize Sub Commands.
            init_subcmds: bool = true,
        };

        /// Initialize this Command with the provided Config by duplicating it with an Allocator for Runtime use.
        /// This should be used after this Command has been created in Comptime. Notably, Validation is done during Comptime and must happen before usage/help Commands/Options are added.
        pub fn init(comptime self: *const @This(), alloc: mem.Allocator, init_config: InitConfig) !@This() {
            if (init_config.validate_cmd) self.validate();

            var init_cmd = (try alloc.dupe(@This(), &.{ self.* }))[0];

            if (init_config.init_subcmds and self.sub_cmds != null) {
                var init_subcmds = try alloc.alloc(@This(), self.sub_cmds.?.len);
                inline for (self.sub_cmds.?, 0..) |cmd, idx| init_subcmds[idx] = try cmd.init(alloc, init_config); 
                init_cmd.sub_cmds = init_subcmds;
            }

            const usage_description = try mem.concat(alloc, u8, &.{ "Show the '", init_cmd.name, "' usage display." });
            const help_description = try mem.concat(alloc, u8, &.{ "Show the '", init_cmd.name, "' help display." });

            if (init_config.add_help_cmds) {
                var help_sub_cmds = try alloc.alloc(@This(), 2);

                help_sub_cmds[0] = .{
                    .name = "usage",
                    .help_prefix = init_cmd.name,
                    .description = usage_description,
                    ._is_init = true,
                    ._alloc = alloc,
                };
                help_sub_cmds[1] = .{
                    .name = "help",
                    .help_prefix = init_cmd.name,
                    .description = help_description,
                    ._is_init = true,
                    ._alloc = alloc,
                };

                init_cmd.sub_cmds = 
                    if (init_cmd.sub_cmds != null) try mem.concat(alloc, @This(), &.{ init_cmd.sub_cmds.?, help_sub_cmds[0..] })
                    else help_sub_cmds[0..];
            }

            if (init_config.add_help_opts) {
                var help_opts = try alloc.alloc(@This().CustomOption, 2);
                help_opts[0] = .{
                    .name = "usage",
                    .short_name = 'u',
                    .long_name = "usage",
                    .description = usage_description,
                    .val = Value.ofType(bool, .{ .name = "usageFlag" }),
                };
                help_opts[1] = .{
		    .name = "help",
                    .short_name = 'h',
                    .long_name = "help",
                    .description = help_description,
                    .val = Value.ofType(bool, .{ .name = "helpFlag" }),
                };

                init_cmd.opts = 
                    if (init_cmd.opts != null) try mem.concat(alloc, @This().CustomOption, &.{ init_cmd.opts.?, help_opts[0..] })
                    else help_opts[0..];
            }

            init_cmd._is_init = true;
            init_cmd._alloc = alloc;

            return init_cmd; 
        }

        /// De-initialize this Command with its original Allocator.
        /// If this Command has not yet been initialized, this does nothing.
        pub fn deinit(self: *const @This()) void {
            if (!self._is_init) return;
            if (self.sub_cmds != null)
                for (self.sub_cmds.?) |*cmd| cmd.deinit();
            self._alloc.?.destroy(self);
        }
    };
}

