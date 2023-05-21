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
pub fn parseArgs(args: *const proc.ArgIterator, cmd: *const Command, writer: anytype) !void {
    var val_idx: u8 = 0;
    var unmatched = false;

    // Bypass argument 0 (the filename being executed);
    if (@constCast(args).inner.index == 0) _ = @constCast(args).next();

    parseArg: while (@constCast(args).next()) |arg| {
        // Check for a Sub Command first...
        if (cmd.sub_cmds != null) {
            try writer.print("Attempting to Parse Commands...\n", .{});
            for (cmd.sub_cmds.?) |sub_cmd| {
                if (eql(u8, sub_cmd.name, arg)) {
                    parseArgs(args, sub_cmd, writer) catch { 
                        try writer.print("Could not parse Command '{s}'.\n", .{ sub_cmd.name });
                        try sub_cmd.usage(writer);
                        try writer.print("\n\n", .{});
                        return error.CouldNotParseCommand;
                    };
                    try writer.print("Parsed Command '{s}'\n", .{ sub_cmd.name });
                    //@constCast(cmd).sub_cmd = @constCast(sub_cmd);
                    cmd.setSubCmd(sub_cmd); 
                    continue :parseArg;
                }
            }
            unmatched = true;
        }
        // ...Then for any Options...
        if (cmd.opts != null) {
            try writer.print("Attempting to Parse Options...\n", .{});
            // - Short Options
            if (arg[0] == '-' and arg[1] != '-') {
                const short_opts = arg[1..];
                shortOpts: for (short_opts, 0..) |short_opt, short_idx| {
                    for (cmd.opts.?) |opt| {
                        if (opt.short_name != null and short_opt == opt.short_name.?) {
                            try if (short_idx == short_opts.len - 1) { //TODO: Figure out why this if statement needs a "try." Possibly due to subtraction underflow?
                                parseOpt(args, opt) catch {
                                    try writer.print("Could not parse Option '{?c}: {s}'.\n", .{ opt.short_name, opt.name });
                                    try opt.usage(writer);
                                    try writer.print("\n\n", .{});
                                    return error.CouldNotParseOption;
                                };
                                try writer.print("Parsed Option '{?c}'.\n", .{ opt.short_name });
                                continue :parseArg;
                            }
                            else @constCast(opt).val.set("true");
                            try writer.print("Parsed Option '{?c}'.\n", .{ opt.short_name });
                            continue :shortOpts;
                        }
                    }
                    try writer.print("Could not parse Option '-{?c}'.\n", .{ short_opt });
                    try cmd.usage(writer);
                    try writer.print("\n\n", .{});
                    return error.CouldNotParseOption;
                }
            }
            // - Long Options
            else if (eql(u8, arg[0..2], "--")) {
                const opt_arg = arg[2..];
                for (cmd.opts.?) |opt| {
                    if (opt.long_name != null and eql(u8, opt_arg, opt.long_name.?)) {
                        parseOpt(args, opt) catch {
                            try writer.print("Could not parse Option '{?s}: {s}'.\n", .{ opt.long_name, opt.name });
                            try opt.usage(writer);
                            try writer.print("\n\n", .{});
                            return error.CouldNotParseOption;
                        };
                        try writer.print("Parsed Option '{?s}'.\n", .{ opt.long_name });
                        continue :parseArg;
                    }
                }
                try writer.print("Could not parse Option '--{?s}'.\n", .{ opt_arg });
                try cmd.usage(writer);
                try writer.print("\n\n", .{});
                return error.CouldNotParseOption;
            }
            unmatched = true;
        }
        // ...Finally, for any Values.
        if (cmd.vals != null) {
            try writer.print("Attempting to Parse Values...\n", .{});
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

            try writer.print("Parsed Value '{?s}'.\n", .{ val.name() });
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
            try writer.print("Command '{s}' does not expect any arguments.\n", .{ cmd.name });
            try cmd.help(writer);
            return error.UnexpectedArgument;
        }
    }
}

/// Parse an Option for the given Command.
fn parseOpt(args: *const proc.ArgIterator, opt: *const Option) !void {
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
