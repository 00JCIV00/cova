//! Cova. Commands, Options, Values, Arguments. A simple command line argument parser for Zig.

// Standard
const std = @import("std");
const log = std.log;
const mem = std.mem;
const proc = std.process;

const eql = mem.eql;

// Cova
pub const Command = @import("Command.zig");
pub const Option = @import("Option.zig");
pub const Value = @import("Value.zig");

/// Parse provided Argument tokens into Commands, Options, and Values.
pub fn parseArgs(args: *const proc.ArgIterator, comptime CustomCommand: type, cmd: *const CustomCommand, writer: anytype) !void {
    var val_idx: u8 = 0;

    const optType = @TypeOf(cmd.*).CustomOption;

    // Bypass argument 0 (the filename being executed);
    const init_arg = if (@constCast(args).inner.index == 0) @constCast(args).next()
                     else argsPeak(args); 
    log.debug("Initial Arg: {?s}", .{ init_arg orelse "END OF ARGS!" });

    parseArg: while (@constCast(args).next()) |arg| {
        if (init_arg == null) return;
        var unmatched = false;
        // Check for a Sub Command first...
        if (cmd.sub_cmds != null) {
            log.debug("Attempting to Parse Commands...\n", .{});
            for (cmd.sub_cmds.?) |sub_cmd| {
                if (eql(u8, sub_cmd.name, arg)) {
                    parseArgs(args, CustomCommand, sub_cmd, writer) catch { 
                        try writer.print("Could not parse Command '{s}'.\n", .{ sub_cmd.name });
                        try sub_cmd.usage(writer);
                        try writer.print("\n\n", .{});
                        return error.CouldNotParseCommand;
                    };
                    log.debug("Parsed Command '{s}'\n", .{ sub_cmd.name });
                    cmd.setSubCmd(sub_cmd); 
                    continue :parseArg;
                }
            }
            unmatched = true;
        }
        // ...Then for any Options...
        if (cmd.opts != null) {
            log.debug("Attempting to Parse Options...\n", .{});
            const short_pf = optType.short_prefix;
            const long_pf = optType.long_prefix;
            // - Short Options
            if (arg[0] == short_pf and arg[1] != short_pf) {
                const short_opts = arg[1..];
                shortOpts: for (short_opts, 0..) |short_opt, short_idx| {
                    for (cmd.opts.?) |opt| {
                        if (opt.short_name != null and short_opt == opt.short_name.?) {
                            //TODO: Figure out why these if statements need a "try". Possibly due to subtraction underflow?
                            // Handle Argument provided to this Option with '=' instead of ' '.
                            try if (short_opts[short_idx + 1] == '=') {
                                if (eql(u8, opt.val.valType(), "bool")) {
                                    try writer.print("The Option '{c}{?c}: {s}' is a Boolean/Toggle and cannot take an argument.\n", .{ 
                                        short_pf, 
                                        opt.short_name, 
                                        opt.name 
                                    });
                                    try opt.usage(writer);
                                    try writer.print("\n\n", .{});
                                    return error.BoolCannotTakeArgument;
                                }
                                if (short_idx + 2 >= short_opts.len) return error.EmptyArgumentProvidedToOption;
                                const opt_arg = short_opts[(short_idx + 2)..];
                                opt.val.set(opt_arg) catch {
                                    try writer.print("Could not parse Option '{c}{?c}: {s}'.\n", .{ 
                                        short_pf,
                                        opt.short_name, 
                                        opt.name 
                                    });
                                    try opt.usage(writer);
                                    try writer.print("\n\n", .{});
                                    return error.CouldNotParseOption;
                                };
                                continue :parseArg;
                            }
                            // Handle final Option in a chain of Short Options
                            else if (short_idx == short_opts.len - 1) { 
                                try if (eql(u8, opt.val.valType(), "bool")) @constCast(opt).val.set("true")
                                else {
                                    parseOpt(args, @TypeOf(opt.*), opt) catch {
                                        try writer.print("Could not parse Option '{c}{?c}: {s}'.\n", .{ 
                                            short_pf,
                                            opt.short_name, 
                                            opt.name 
                                        });
                                        try opt.usage(writer);
                                        try writer.print("\n\n", .{});
                                        return error.CouldNotParseOption;
                                    };
                                };
                                log.debug("Parsed Option '{?c}'.\n", .{ opt.short_name });
                                continue :parseArg;
                            }
                            else @constCast(opt).val.set("true");
                            log.debug("Parsed Option '{?c}'.\n", .{ opt.short_name });
                            continue :shortOpts;
                        }
                    }
                    try writer.print("Could not parse Option '{c}{?c}'.\n", .{ short_pf, short_opt });
                    try cmd.usage(writer);
                    try writer.print("\n\n", .{});
                    return error.CouldNotParseOption;
                }
            }
            // - Long Options
            else if (eql(u8, arg[0..2], long_pf)) {
                const long_opt = arg[2..];
                for (cmd.opts.?) |opt| {
                    const long_len = opt.long_name.?.len;
                    if (opt.long_name != null) {
                        // Handle Value provided to this Option with '=' instead of ' '.
                        if (long_opt.len > opt.long_name.?.len and eql(u8, long_opt[0..long_len], opt.long_name.?)) {
                            if (long_opt[long_len] == '=') {
                                if (eql(u8, opt.val.valType(), "bool")) {
                                    try writer.print("The Option '{s}{?s}: {s}' is a Boolean/Toggle and cannot take an argument.", .{ 
                                        long_pf, 
                                        opt.long_name, 
                                        opt.name 
                                    });
                                    try opt.usage(writer);
                                    try writer.print("\n\n", .{});
                                    return error.BoolCannotTakeArgument;
                                }
                                if (long_len + 1 >= long_opt.len) return error.EmptyArgumentProvidedToOption;
                                const opt_arg = long_opt[(long_len + 1)..];
                                opt.val.set(opt_arg) catch {
                                    try writer.print("Could not parse Option '{s}{?s}: {s}'.\n", .{ 
                                        long_pf,
                                        opt.long_name, 
                                        opt.name 
                                    });
                                    try opt.usage(writer);
                                    try writer.print("\n\n", .{});
                                    return error.CouldNotParseOption;
                                };
                                log.debug("Parsed Option '{?s}'.\n", .{ opt.long_name });
                                continue :parseArg;
                            }
                        }
                        // Handle normally provided Value to Option
                        else if (eql(u8, long_opt, opt.long_name.?)) {
                            // Handle Boolean/Toggle Option.
                            try if (eql(u8, opt.val.valType(), "bool")) @constCast(opt).val.set("true")
                            // Handle Option with normal Argument.
                            else {
                                parseOpt(args, @TypeOf(opt.*), opt) catch {
                                    try writer.print("Could not parse Option '{s}{?s}: {s}'.\n", .{ 
                                        long_pf,
                                        opt.long_name, 
                                        opt.name 
                                    });
                                    try opt.usage(writer);
                                    try writer.print("\n\n", .{});
                                    return error.CouldNotParseOption;
                                };
                            };
                            log.debug("Parsed Option '{?s}'.\n", .{ opt.long_name });
                            continue :parseArg;
                        }
                    }
                }
                try writer.print("Could not parse Argument '{s}{?s}' to an Option.\n", .{ long_pf, long_opt });
                try cmd.usage(writer);
                try writer.print("\n\n", .{});
                return error.CouldNotParseOption;
            }
            unmatched = true;
        }
        // ...Finally, for any Values.
        if (cmd.vals != null) {
            log.debug("Attempting to Parse Values...\n", .{});
            if (val_idx >= cmd.vals.?.len) {
                try writer.print("Too many Values provided for Command '{s}'.\n", .{ cmd.name });
                try cmd.usage(writer);
                return error.TooManyValues;
            }
            const val = cmd.vals.?[val_idx];
            val.set(arg) catch {
                try writer.print("Could not parse Argument '{s}' to Value '{s}'\n", .{ arg, val.name() });
                try cmd.usage(writer);
                try writer.print("\n", .{});
            };
            val_idx += 1;

            log.debug("Parsed Value '{?s}'.\n", .{ val.name() });
            continue :parseArg;
        }

        // Check if the Command expected an argument but didn't get a match.
        if (unmatched) {
            try writer.print("Unrecognized Argument '{s}' for Command '{s}'.\n", .{ arg, cmd.name });
            try cmd.help(writer);
            return error.UnrecognizedArgument;
        }
        // For Commands that expect no arguments but are given one, fail to usage
        else {
            try writer.print("Command '{s}' does not expect any arguments, but '{s}' was passed.\n", .{ cmd.name, arg });
            try cmd.help(writer);
            return error.UnexpectedArgument;
        }
    }
}

/// Parse an Option for the given Command.
fn parseOpt(args: *const proc.ArgIterator, comptime opt_type: type, opt: *const opt_type) !void {
    const peak_arg = argsPeak(args);
    const set_arg = 
        if (peak_arg == null or peak_arg.?[0] == '-') setArg: {
            _ = @constCast(args).next();
            break :setArg "true";
        }
        else @constCast(args).next().?;
    try opt.val.set(set_arg);
}

/// Peak at the next Argument in the provided ArgIterator without advancing the index.
fn argsPeak(args: *const proc.ArgIterator) ?[]const u8 {
    const peak_arg = @constCast(args).next();
    @constCast(args).inner.index -= 1;
    return peak_arg;
}
