//! Input and Output Command Structure.
const std = @import("std");
const log = std.log;
const mem = std.mem;
const StringHashMap = std.StringHashMap;

const Option = @import("Option.zig");
const Val = @import("Value.zig");


/// Config for custom Command types. 
pub const Config = struct {
    /// Option Config for this Command and all sub Commands.
    opt_config: Option.Config = .{},

    // Sub Commands Help Format.
    // Must support the following format types in this order:
    // - String (Command Name)
    // - String (Command Description)
    subcmds_help_fmt: []const u8 = "{s}: {s}",
    // Values Help Format.
    // Must support the following format types in this order:
    // - String (Value Name)
    // - String (Value Type)
    // - String (Value Description)
    vals_help_fmt: []const u8 = "{s} ({s}): {s}",
    
    // Sub Commands Usage Format.
    // Must support the following format types in this order:
    // - String (Command Name)
    subcmds_usage_fmt: []const u8 ="'{s}'", 
    // Values Usage Format.
    // Must support the following format types in this order:
    // - String (Value Name)
    // - String (Value Type)
    vals_usage_fmt: []const u8 = "\"{s} ({s})\"", 

};

/// Create an Custom Command type from the provided Config.
pub fn Custom(comptime config: Config) type {
    return struct {
        pub const CustomOption = Option.Custom(config.opt_config);
        pub const subcmds_help_fmt = config.subcmds_help_fmt;
        pub const vals_help_fmt = config.vals_help_fmt;
        pub const subcmds_usage_fmt = config.subcmds_usage_fmt;
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

        /// Validate this Command for distinct sub Commands, Options, and Values.
        /// TODO: Make this method a comptime check.
        pub fn validate(self: *const @This()) !void {
            // Check for distinct sub Commands.
            if (self.sub_cmds != null) {
                const cmds = self.sub_cmds.?;
                var distinct_cmd: [100][]const u8 = undefined;
                for (cmds, 0..) |cmd, idx| {
                    if (indexOfEql([]const u8, distinct_cmd[0..], cmd.name) != null) {
                        log.err("The sub Command '{s}' is set more than once.", .{ cmd.name });
                        return error.CommandNotDistinct;
                    } 
                    distinct_cmd[idx] = cmd.name;
                }
            }

            // Check for distinct Options.
            if (self.opts != null) {
                const opts = self.opts.?;
                var distinct_name: [100][]const u8 = undefined;
                var distinct_short: [100]u8 = undefined;
                var distinct_long: [100][]const u8 = undefined;
                for (opts, 0..) |opt, idx| {
                    if (indexOfEql([]const u8, distinct_name[0..], opt.name) != null) {
                        log.err("The Option '{s}' is set more than once.", .{ opt.name });
                        return error.OptionNotDistinct;
                    } 
                    distinct_name[idx] = opt.name;
                    if (opt.short_name != null and indexOfEql(u8, distinct_short[0..], opt.short_name.?) != null) {
                        log.err("The Option Short Name '{c}' is set more than once.", .{ opt.short_name.? });
                        return error.OptionShortNameNotDistinct;
                    } 
                    distinct_short[idx] = opt.short_name.?;
                    if (opt.long_name != null and indexOfEql([]const u8, distinct_long[0..], opt.long_name.?) != null) {
                        log.err("The Option Long Name '{s}' is set more than once.", .{ opt.long_name.? });
                        return error.OptionLongNameNotDistinct;
                    } 
                    distinct_long[idx] = opt.long_name.?;
                }
            }

            // Check for distinct Values.
            if (self.vals != null) {
                const vals = self.vals.?;
                var distinct_val: [100][]const u8 = undefined;
                for (vals, 0..) |val, idx| {
                    if (indexOfEql([]const u8, distinct_val[0..], val.name()) != null) {
                        log.err("The Value '{s}' is set more than once.", .{ val.name() });
                        return error.ValueNotDistinct;
                    } 
                    distinct_val[idx] = val.name();
                }
            }
        }
    
        /// Config for Setup of this Command.
        pub const SetupConfig = struct {
            /// Flag to Validate this Command.
            validate_cmd: bool = true,
            /// Flag to add Usage/Help message Commands.
            add_help_cmds: bool = true,
            /// Flag to add Usage/Help message Options.
            add_help_opts: bool = true,
        };

        /// Setup this Command based on the provided SetupConfig.
        pub fn setup(self_const: *const @This(), alloc: mem.Allocator, setup_config: SetupConfig) !void {
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

            if (setup_config.validate_cmd) try self_const.validate();
        }

        // Setup this Command based on the provided SetupConfig.
        //pub fn setup(self_const: *const @This(), alloc: mem.Allocator, setup_config: SetupConfig) !void {
        //    var self = @constCast(self_const);
        //    const usage_description = try mem.concat(alloc, u8, &.{ "Show the '", self.name, "' usage display." });
        //    const help_description = try mem.concat(alloc, u8, &.{ "Show the '", self.name, "' help display." });
        //    
        //    if (setup_config.add_help_cmds) {
        //        var help_sub_cmds = [2]*const @This(){
        //            &@This(){
        //                .name = "usage",
        //                .help_prefix = self.name,
        //                .description = usage_description, 
        //            },
        //            &@This(){
        //                .name = "help",
        //                .help_prefix = self.name,
        //                .description = help_description, 
        //            },
        //        };

        //        self.sub_cmds = if (self.sub_cmds != null) try mem.concat(alloc, *const @This(), &.{ self.sub_cmds.?, help_sub_cmds[0..] })
        //                        else help_sub_cmds[0..];
        //    }

        //    if (setup_config.add_help_opts) {
        //        var help_opts = [_]*const @This().CustomOption{
        //            &@This().CustomOption{
        //                .name = "usage",
        //                .short_name = 'u',
        //                .long_name = "usage",
        //                .description = usage_description, 
        //                .val = &Val.init(bool, .{ .name = "usageFlag" }),
        //            },
        //            &@This().CustomOption{
        //                .name = "help",
        //                .short_name = 'h',
        //                .long_name = "help",
        //                .description = help_description, 
        //                .val = &Val.init(bool, .{ .name = "helpFlag" }),
        //            },
        //            &@This().CustomOption{
        //                .name = "troubleshootOpt",
        //                .short_name = 'r',
        //                .long_name = "troubleshoot",
        //                .description = "An Option for troubleshooting.",
        //                .val = &Val.init(i32, .{
        //                    .name = "troubleshootVal",
        //                    .description = "An Option Value for troubleshooting.",
        //                    .default_val = 50,
        //                }),
        //            },
        //        };

        //        self.opts = if (self.opts != null) try mem.concat(alloc, *const @This().CustomOption, &.{ self.opts.?, help_opts[0..] })
        //                    else help_opts[0..];
        //    }

        //    if (setup_config.validate_cmd) try self_const.validate();
        //}
    };

}

