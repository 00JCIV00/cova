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
pub fn parseArgs(alloc: mem.Allocator, args: *proc.ArgIterator, comptime in_cmd: Command.In, writer: anytype) !Command.Out {
    var out_cmd = Command.Out { .name = in_cmd.name };
    var out_opts = std.ArrayList(Option.Out).init(alloc);
    var out_vals = std.ArrayList(Value).init(alloc);
    var val_idx: u8 = 0;

    parseArg: while (args.*.next()) |arg| {
        // Check for a Sub Command first...
        if (in_cmd.sub_cmds != null) {
            for (in_cmd.?.sub_cmds) |sub_cmd| {
                if (eql(u8, sub_cmd.name, arg)) out_cmd.sub_cmd = parseArgs(args, sub_cmd, writer);
                continue :parseArg;
            }
        }
        // ...Then for any Options...
        if (in_cmd.opts != null) {
            // - Short Options
            if (arg[0] == '-' and arg[1] != '-') {
                const short_opts = arg[1..];
                for (short_opts, 0..) |short_opt, short_idx| {
                    for (in_cmd.?.opts) |opt| {
                        if (short_opt == opt.short_name) {
                            if (short_idx == short_opts.len - 1) {
                                out_opts.append(parseOpt(args, opt) catch {
                                    try writer.print("Could not parse Option '{s}'.", .{ opt.short_name });
                                    try opt.usage(writer);
                                    try writer.print("\n\n");
                                    return error.CouldNotParseOption;
                                });
                            }
                            else {
                                var out_opt = opt.getOpt();
                                out_opt.val.is_set = true;
                                out_opts.append(out_opt);
                            }
                        }
                    }
                }
            }
            // - Long Options
            if (eql(u8, args[0..2], "--")) {
                const opt_arg = arg[2..];
                for (in_cmd.?.opts) |opt| {
                    if (eql(u8, opt_arg, opt.long_name)) {
                        out_opts.append(parseOpt(args, opt) catch {
                            try writer.print("Could not parse Option '{s}'.", .{ opt.long_name });
                            try opt.usage(writer);
                            try writer.print("\n\n");
                            return error.CouldNotParseOption;
                        });
                    }
                }
            }
        }
        // ...Finally, for any Values.
        if (in_cmd.vals != null) {
            if (val_idx >= in_cmd.vals.?.len) {
                try writer.print("Too many values provided for Command '{s}'.\n", .{ in_cmd.name });
                try in_cmd.usage(writer);
                return error.TooManyValues;
            }
            
        }
    }

    out_cmd.opts = try out_opts.toOwnedSlice();
    out_cmd.vals = try out_vals.toOwnedSlice();
    return out_cmd;
}

/// Parse an Option for the given Command.
fn parseOpt(args: *proc.ArgIterator, in_opt: Option.In) !Option.Out {
    var out_opt = in_opt.getOpt();
    const peak_arg = argsPeak(args);
    const set_arg = 
        if (peak_arg == null or peak_arg.?[0] == '-') ""
        else args.next();
    try out_opt.val.set(set_arg);

    return out_opt;
}

/// Peak at the next Argument in the provided ArgIterator without advancing the index.
fn argsPeak(args: *proc.ArgIterator) ?[]u8 {
    const peak_arg = args.next();
    args.inner.index -= 1;
    return peak_arg;
}
