//! Container Argument for sub Commands, Options, and Values.
//!
//! A Command may contain any mix of those Arguments or none at all if it's to be used as a standalone Command.
//!
//! End User Example:
//!
//! ```
//! # Standalone Command
//! myapp help
//! # Command w/ Options and Values
//! myapp -d "This Value belongs to the 'd' Option." --toggle "This is a standalone Value."
//! # Command w/ sub Command
//! myapp --opt "Option for 'myapp' Command." subcmd --subcmd_opt "Option for 'subcmd' sub Command."
//! ```

const std = @import("std");
const log = std.log;
const mem = std.mem;
const StringHashMap = std.StringHashMap;

const Option = @import("Option.zig");
const Val = @import("Value.zig");


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

/// Create an Custom Command type from the provided Config.
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
        vals: ?[]*const Val.Generic = null,

        /// The Name of this Command for user identification and Usage/Help messages.
        name: []const u8,
        /// The Prefix used immediately before a Usage/Help message is displayed.
        help_prefix: []const u8 = "",
        /// The Description of this Command for Usage/Help messages.
        description: []const u8 = "",

        /// Sets the active Sub-Command for this Command.
        pub fn setSubCmd(self: *const @This(), set_cmd: *const @This()) void {
            @constCast(self).*.sub_cmd = @constCast(set_cmd);
        }

        /// Gets a StringHashMap of this Command's Options.
        pub fn getOpts(self: *const @This(), alloc: mem.Allocator) !StringHashMap(*const CustomOption) {
            if (self.opts == null) return error.NoOptionsInCommand;
            var map = StringHashMap(*const CustomOption).init(alloc);
            for (self.opts.?) |opt| { try map.put(opt.name, opt); }
            return map;
        }

        /// Gets a StringHashMap of this Command's Values.
        pub fn getVals(self: *const @This(), alloc: mem.Allocator) !StringHashMap(*const Val) {
            if (self.vals == null) return error.NoValuesInCommand;
            var map = StringHashMap(*const Val).init(alloc);
            for (self.vals.?) |val| { try map.put(val.name, val); }
            return map;
        }

        /// Creates the Help message for this Command and Writes it to the provided Writer.
        pub fn help(self: *const @This(), writer: anytype) !void {
            try writer.print("{s}\n", .{ self.help_prefix });

            try self.usage(writer);

            try writer.print(\\HELP:
                             \\    Command: {s}
                             \\
                             \\    Description: {s}
                             \\
                             \\
                             , .{ self.name, self.description });
            
            if (self.sub_cmds != null) {
                try writer.print("    Sub Commands:\n", .{});
                for (self.sub_cmds.?) |cmd| {
                    try writer.print("        ", .{});
                    try writer.print(subcmds_help_fmt, .{cmd.name, cmd.description});
                    try writer.print("\n", .{});
                }
            }
            try writer.print("\n", .{});

            if (self.opts != null) {
                try writer.print("    Options:\n", .{});
                for (self.opts.?) |opt| {
                    try writer.print("        ", .{});
                    try opt.help(writer);
                    try writer.print("\n", .{});
                }
            }
            try writer.print("\n", .{});

            if (self.vals != null) {
                try writer.print("    Values:\n", .{});
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

        /// Find the Index of a Slice (Why is this not in std.mem?!?!?)
        fn indexOfEql(comptime T: type, haystack: []const T, needle: T) ?usize {
            switch (@typeInfo(T)) {
                .Pointer => |ptr| {
                    for (haystack, 0..) |hay, idx| if (mem.eql(ptr.child, hay, needle)) return idx;
                    return null;
                },
                inline else => return mem.indexOfScalar(T, haystack, needle),
            }
        }

        /// Validate this Command during Comptime for distinct sub Commands, Options, and Values. 
        /// This will also Validate sub Commands recursively.
        pub fn validate(comptime self: *const @This()) void {
            comptime {
                @setEvalBranchQuota(100_000);
                // Check for distinct sub Commands and Validate them.
                if (self.sub_cmds != null) {
                    const cmds = self.sub_cmds.?;
                    var distinct_cmd: [100][]const u8 = .{ "" } ** 100;
                    for (cmds, 0..) |cmd, idx| {
                        if (indexOfEql([]const u8, distinct_cmd[0..idx], cmd.name) != null) 
                            @compileError("The sub Command '" ++ cmd.name ++ "' is set more than once.");
                        cmd.validate();
                        distinct_cmd[idx] = cmd.name;
                    }
                }

                // Check for distinct Options.
                if (self.opts != null) {
                    const opts = self.opts.?;
                    var distinct_name: [100][]const u8 = .{ "" } ** 100;
                    var distinct_short: [100]u8 = .{ ' ' } ** 100;
                    var distinct_long: [100][]const u8 = .{ "" } ** 100;
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
                    var distinct_val: [100][]const u8 = .{ "" } ** 100;
                    for (vals, 0..) |val, idx| {
                        if (indexOfEql([]const u8, distinct_val[0..], val.name()) != null) 
                            @compileError("The Value '" ++ val.name ++ "' is set more than once.");
                        distinct_val[idx] = val.name();
                    }
                }
            }
        }
    
        /// Config for Setup of this Command.
        pub const SetupConfig = struct {
            /// Flag to Validate this Command.
            validate_cmd: bool = true,
            /// Flag to add Usage/Help message Commands to this Command.
            add_help_cmds: bool = true,
            /// Flag to add Usage/Help message Options to this Command.
            add_help_opts: bool = true,
        };

        /// Setup this Command during Runtime based on the provided SetupConfig.
        pub fn setupAlloc(self_const: *const @This(), alloc: mem.Allocator, setup_config: SetupConfig) !void {
            var self = @constCast(self_const);
            const usage_description = try mem.concat(alloc, u8, &.{ "Show the '", self.name, "' usage display." });
            const help_description = try mem.concat(alloc, u8, &.{ "Show the '", self.name, "' help display." });

            if (setup_config.add_help_cmds) {
                var help_sub_cmds = try alloc.alloc(*const @This(), 2);

                help_sub_cmds[0] = try alloc.create(@This());
                @constCast(help_sub_cmds[0]).* = .{
                    .name = "usage",
                    .help_prefix = self.name,
                    .description = usage_description,
                };
                help_sub_cmds[1] = try alloc.create(@This());
                @constCast(help_sub_cmds[1]).* = .{
                    .name = "help",
                    .help_prefix = self.name,
                    .description = help_description,
                };

                self.sub_cmds = if (self.sub_cmds != null) try mem.concat(alloc, *const @This(), &.{ self.sub_cmds.?, help_sub_cmds[0..] })
                                else help_sub_cmds[0..];
            }

            if (setup_config.add_help_opts) {
                var help_opts = try alloc.alloc(*const @This().CustomOption, 2);
                help_opts[0] = try alloc.create(@This().CustomOption);
                @constCast(help_opts[0]).* = .{
                    .name = "usage",
                    .short_name = 'u',
                    .long_name = "usage",
                    .description = usage_description,
                    .val = usageVal: {
                        var usage_val = try alloc.create(Val.Generic);
                        usage_val.* = Val.init(bool, .{ .name = "usageFlag" });
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
                        var help_val = try alloc.create(Val.Generic);
                        help_val.* = Val.init(bool, .{ .name = "helpFlag" });
                        break :helpVal help_val;
                    },
                };

                self.opts = if (self.opts != null) try mem.concat(alloc, *const @This().CustomOption, &.{ self.opts.?, help_opts[0..] })
                            else help_opts[0..];
            }
        }

        /// Setup this Command during Comptime based on the provided SetupConfig.
        /// (WIP)
        pub fn setup(comptime self: *const @This(), comptime setup_config: SetupConfig) void {
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
                            .val = &Val.init(bool, .{ .name = "usageFlag" }),
                        },
                        &@This().CustomOption{
                            .name = "help",
                            .short_name = 'h',
                            .long_name = "help",
                            .description = help_description, 
                            .val = &Val.init(bool, .{ .name = "helpFlag" }),
                        },
                    };
                    self.opts = 
                        if (self.opts != null) self.opts.? ++ help_opts[0..]
                        else help_opts[0..];
                }
                if (setup_config.validate_cmd) self.validate();
            }
        }

        /// Initialize this Command by duplicating it with an Allocator for Runtime use.
        /// This should be used after this Command has been created in Comptime and, optionally, after `setup()` or `validate()` have been called on it.
        pub fn init(comptime self: *const @This(), alloc: mem.Allocator) !*@This() {
            return &(try alloc.dupe(@This(), &.{ self.* }))[0];
        }

        /// De-initialize this Command with its original Allocator.
        pub fn deinit(self: *const @This(), alloc: mem.Allocator) void {
            alloc.destroy(self);
        }
    };

}

