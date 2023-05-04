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
pub fn parseArgs(alloc: mem.Allocator, args: *proc.ArgIterator, in_cmd: Command.In, writer: anytype) Command.Out {
    out_cmd = Command.Out { .name = in_cmd.name };
    var out_opts = std.ArrayList(Option.Out).init(alloc);
    var out_vals = std.ArrayList(Value)

    parseArg: while (args.*.next()) |arg| {
        // Check for a sub command first
        for (in_cmd.sub_cmds) |sub_cmd| {
            if (eql(u8, sub_cmd.name, arg)) out_cmd.sub_cmd = parseArgs(args, sub_cmd, writer);
            continue :parseArg;
        }
        // Then for any options
        // - Short Options
        if (arg[0] == '-' and arg[1] != '-') {
            const short_opts = arg[1..];
            for (short_opts, 0..) |short_opt, short_idx| {
                for (in_cmd.opts) |opt| {
                    if (short_idx == short_opts.len - 1) parseOpt
                    else 
                }
            }
        }
        // - Long Options
        if (eql(u8, args[0..2], "--")) {
            const opt_arg = arg[2..];
            for (in_cmd.opts) |opt| {

            }
        }

    }
    return out_cmd;
}

/// Parse an Option for the given Command.
fn parseOpt(args: *proc.ArgIterator, in_opt: Option.In) Option.Out {
    var out_opt = Option.Out { 
}
