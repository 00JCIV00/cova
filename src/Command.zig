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
const StringHashMap = std.StringHashMap;

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

        /// The list of Sub Commands this Command can take.
        sub_cmds: ?[]*const @This() = null,
        /// The Sub Command assigned to this Command during Parsing (optional).
        sub_cmd: ?*const @This() = null,
        /// The list of Options this Command can take.
        opts: ?[]*const CustomOption = null,
        /// The list of Values this Command can take.
        vals: ?[]*const Value.Generic = null,

        /// The Name of this Command for user identification and Usage/Help messages.
        name: []const u8,
        /// The Prefix message used immediately before a Usage/Help message is displayed.
        help_prefix: []const u8 = "",
        /// The Description of this Command for Usage/Help messages.
        description: []const u8 = "",

        /// Sets the active Sub-Command for this Command.
        pub fn setSubCmd(self: *const @This(), set_cmd: *const @This()) void {
            //@constCast(self).*.sub_cmd = @constCast(set_cmd);
            @constCast(self).*.sub_cmd = set_cmd;
        }

        /// Gets a StringHashMap of this Command's Options.
        pub fn getOpts(self: *const @This(), alloc: mem.Allocator) !StringHashMap(*const CustomOption) {
            if (self.opts == null) return error.NoOptionsInCommand;
            var map = StringHashMap(*const CustomOption).init(alloc);
            for (self.opts.?) |opt| { try map.put(opt.name, opt); }
            return map;
        }

        /// Gets a StringHashMap of this Command's Values.
        pub fn getVals(self: *const @This(), alloc: mem.Allocator) !StringHashMap(*const Value) {
            if (self.vals == null) return error.NoValuesInCommand;
            var map = StringHashMap(*const Value).init(alloc);
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
                (self.sub_cmd != null and mem.eql(u8, self.sub_cmd.?.name, toggle_name)) or
                checkOpt: {
                    if (self.opts != null) {
                        for (self.opts.?) |opt| {
                            if (mem.eql(u8, opt.name, toggle_name) and 
                                mem.eql(u8, opt.val.valType(), "bool") and 
                                opt.val.bool.get() catch false)
                                    break :checkOpt true;
                        }
                    }
                    break :checkOpt false;
                } or
                checkVal: {
                    if (self.vals != null) {
                        for (self.vals.?) |val| {
                            if (mem.eql(u8, val.name(), toggle_name) and
                                mem.eql(u8, val.valType(), "bool") and
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
                    for (haystack, 0..) |hay, idx| if (mem.eql(ptr.child, hay, needle)) return idx;
                    return null;
                },
                inline else => return mem.indexOfScalar(T, haystack, needle),
            }
        }

        /// Config for creating Commands from Structs.
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

            /// Max number of Sub Commands.
            max_cmds: u8 = 100,
            /// Max number of Options.
            max_opts: u8 = 100,
            /// Max number of Values.
            max_vals: u8 = 100,
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

            var from_cmds_buf: [from_config.max_cmds]*const @This() = undefined;
            const from_cmds = from_cmds_buf[0..];
            var cmds_idx: u8 = 0;
            var from_opts_buf: [from_config.max_opts]*const CustomOption = undefined;
            const from_opts = from_opts_buf[0..];
            var opts_idx: u8 = 0;
            var short_names_buf: [from_config.max_opts]u8 = undefined;
            var short_names = short_names_buf[0..];
            var short_idx: u8 = 0;
            var from_vals_buf: [from_config.max_vals]*const Value.Generic = undefined;
            const from_vals = from_vals_buf[0..];
            var vals_idx: u8 = 0;

            const fields = meta.fields(from_struct);
            inline for (fields) |field| {
                const field_info = @typeInfo(field.type);
                switch (field_info) {
                    // Commands
                    .Struct => {
                        const sub_config = comptime subConfig: {
                            var new_config = from_config;
                            new_config.cmd_name = field.name;
                            new_config.cmd_description = "The '" ++ field.name ++ "' Command.";
                            break :subConfig new_config;
                        };
                        from_cmds[cmds_idx] = &from(field.type, sub_config);
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
                        from_opts[opts_idx] = &(CustomOption.from(field, short_name, from_config.ignore_incompatible) orelse continue);
                        opts_idx += 1;
                    },
                    // Values
                    .Bool, .Int, .Float, .Pointer => {
                        from_vals[vals_idx] = &(Value.from(field, from_config.ignore_incompatible) orelse continue);
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
                                from_opts[opts_idx] = &(CustomOption.from(field, short_name, from_config.ignore_incompatible) orelse continue);
                                opts_idx += 1;
                            },
                            .Bool, .Int, .Float, .Pointer => {
                                from_vals[vals_idx] = &(Value.from(field, from_config.ignore_incompatible) orelse continue);
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

        /// Validate this Command during Comptime for distinct Sub Commands, Options, and Values. 
        /// This will also Validate Sub Commands recursively.
        pub fn validate(comptime self: *const @This()) void {
            comptime {
                @setEvalBranchQuota(100_000);
                // This is an arbitrary (but hopefully higher than needed) limit to the number of Arguments than be Validated each of Commands, Options, and Values.
                const max_args = 100;
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
        pub fn init(comptime self: *const @This(), alloc: mem.Allocator, init_config: InitConfig) !*@This() {
            if (init_config.validate_cmd) self.validate();

            const init_cmd = &(try alloc.dupe(@This(), &.{ self.* }))[0];

            if (init_config.init_subcmds and self.sub_cmds != null) {
                var init_subcmds = try alloc.alloc(*@This(), self.sub_cmds.?.len);
                inline for (self.sub_cmds.?, 0..) |cmd, idx| init_subcmds[idx] = try cmd.init(alloc, init_config); 
                init_cmd.sub_cmds = init_subcmds;
            }

            const usage_description = try mem.concat(alloc, u8, &.{ "Show the '", init_cmd.name, "' usage display." });
            const help_description = try mem.concat(alloc, u8, &.{ "Show the '", init_cmd.name, "' help display." });

            if (init_config.add_help_cmds) {
                var help_sub_cmds = try alloc.alloc(*const @This(), 2);

                help_sub_cmds[0] = try alloc.create(@This());
                @constCast(help_sub_cmds[0]).* = .{
                    .name = "usage",
                    .help_prefix = init_cmd.name,
                    .description = usage_description,
                };
                help_sub_cmds[1] = try alloc.create(@This());
                @constCast(help_sub_cmds[1]).* = .{
                    .name = "help",
                    .help_prefix = init_cmd.name,
                    .description = help_description,
                };

                @constCast(init_cmd).sub_cmds = 
                    if (init_cmd.sub_cmds != null) try mem.concat(alloc, *const @This(), &.{ init_cmd.sub_cmds.?, help_sub_cmds[0..] })
                    else help_sub_cmds[0..];
            }

            if (init_config.add_help_opts) {
                var help_opts = try alloc.alloc(*const @This().CustomOption, 2);
                help_opts[0] = try alloc.create(@This().CustomOption);
                @constCast(help_opts[0]).* = .{
                    .name = "usage",
                    .short_name = 'u',
                    .long_name = "usage",
                    .description = usage_description,
                    .val = usageVal: {
                        var usage_val = try alloc.create(Value.Generic);
                        usage_val.* = Value.ofType(bool, .{ .name = "usageFlag" });
                        break :usageVal usage_val;
                    },
                };
                help_opts[1] = try alloc.create(@This().CustomOption);
                @constCast(help_opts[1]).* = .{
		    .name = "help",
                    .short_name = 'h',
                    .long_name = "help",
                    .description = help_description,
                    .val = helpVal: {
                        var help_val = try alloc.create(Value.Generic);
                        help_val.* = Value.ofType(bool, .{ .name = "helpFlag" });
                        break :helpVal help_val;
                    },
                };

                @constCast(init_cmd).opts = 
                    if (init_cmd.opts != null) try mem.concat(alloc, *const @This().CustomOption, &.{ init_cmd.opts.?, help_opts[0..] })
                    else help_opts[0..];
            }

            return init_cmd; 
        }

        /// De-initialize this Command with its original Allocator.
        pub fn deinit(self: *const @This(), alloc: mem.Allocator) void {
            alloc.destroy(self);
        }
    };
}

