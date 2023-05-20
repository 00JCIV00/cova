//! Cova. Commands, Options, Values, Arguments. A simple command line argument parser for Zig.

// Standard
const std = @import("std");
const mem = std.mem;
const proc = std.process;

const eql = mem.eql;

//Cova
pub const Command = @import("Command.zig");
pub const Option = @import("Option.zig");
pub const Value = @import("Value.zig");

/// Parse provided arguments into Commands, Options, and Values.
pub fn parseArgs(args: *const proc.ArgIterator, comptime cmd: *const Command, writer: anytype) !void {
    var val_idx: u8 = 0;
    var unmatched = false;

    parseArg: while (@constCast(args).*.next()) |arg| {
        // Check for a Sub Command first...
        if (cmd.sub_cmds != null) {
            inline for (cmd.sub_cmds.?) |sub_cmd| {
                if (eql(u8, sub_cmd.name, arg)) {
                    parseArgs(args, sub_cmd, writer) catch { 
                        try writer.print("Could not parse Command '{s}'.\n", .{ sub_cmd.name });
                        try sub_cmd.usage(writer);
                        try writer.print("\n\n", .{});
                        return error.CouldNotParseCommand;
                    };
                    try writer.print("Parsed Command '{s}'\n", .{ sub_cmd.name });
                    cmd.setSubCmd(sub_cmd); 
                    continue :parseArg;
                }
            }
            unmatched = true;
        }
        // ...Then for any Options...
        else if (cmd.opts != null) {
            // - Short Options
            if (arg[0] == '-' and arg[1] != '-') {
                const short_opts = arg[1..];
                for (short_opts, 0..) |short_opt, short_idx| {
                    inline for (cmd.opts.?) |*opt| {
                        if (short_opt == opt.short_name) {
                            if (short_idx == short_opts.len - 1) {
                                parseOpt(args, opt) catch {
                                    try writer.print("Could not parse Option '{s}'.\n", .{ opt.short_name });
                                    try opt.usage(writer);
                                    try writer.print("\n\n");
                                    return error.CouldNotParseOption;
                                };
                            }
                            else opt.*.val.set("");
                        }
                    }
                }
            }
            // - Long Options
            else if (eql(u8, args[0..2], "--")) {
                const opt_arg = arg[2..];
                inline for (cmd.opts.?) |*opt| {
                    if (eql(u8, opt_arg, opt.long_name)) {
                        parseOpt(args, opt) catch {
                            try writer.print("Could not parse Option '{s}'.", .{ opt.long_name });
                            try opt.usage(writer);
                            try writer.print("\n\n");
                            return error.CouldNotParseOption;
                        };
                    }
                }
            }
            unmatched = true;
        }
        // ...Finally, for any Values.
        else if (cmd.vals != null) {
            if (val_idx >= cmd.vals.?.len) {
                try writer.print("Too many Values provided for Command '{s}'.\n", .{ cmd.name });
                try cmd.usage(writer);
                return error.TooManyValues;
            }

            val_idx += 1;

            unmatched = true;
        }

        // Check if the Command expected an argument but didn't get a match.
        else if (unmatched) {
            try writer.print("Unrecognized Argument '{s}' for Command '{s}'.\n", .{ arg, cmd.name });
            try cmd.help(writer);
            return error.UnrecognizedArgument;
        }
        // For Commands that expect no arguments but are given one, fail to usage
        //else {
            try writer.print("Command '{s}' does not expect any arguments.\n", .{ cmd.name });
            try cmd.help(writer);
            return error.UnexpectedArgument;
        //}
    }
}

/// Parse an Option for the given Command.
fn parseOpt(args: *const proc.ArgIterator, opt: *Option) !void {
    try parseVal(args, &opt.*.val);
}

/// Parse a Value for the given Command.
fn parseVal(args: *const proc.ArgIterator, val: *Value) !void {
    const peak_arg = argsPeak(args);
    const set_arg = 
        if (peak_arg == null or peak_arg.?[0] == '-') ""
        else args.next();
    try val.set(set_arg);
}

/// Peak at the next Argument in the provided ArgIterator without advancing the index.
fn argsPeak(args: *const proc.ArgIterator) ?[]u8 {
    const peak_arg = args.next();
    args.inner.index -= 1;
    return peak_arg;
}
