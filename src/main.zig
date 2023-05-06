//! Example usage of Cova.

const std = @import("std");
const mem = std.mem;
const proc = std.process;
const stdout = std.io.getStdOut().writer();
const testing = std.testing;

const eql = mem.eql;

const cova = @import("cova.zig");
const Command = cova.Command;
const Option = cova.Option;
const Value = cova.Value;

const cmd_in = Command.In{
    .name = "main",
    .help_prefix = "CovaDemo",
    .description = "A demo of the Cova command line argumnet parser.",
    .sub_cmds = &.{
        Command.In{
            .name = "help",
            .help_prefix = "CovaDemo",
            .description = "Show the CovaDemo help display.",
        }
    },
    .opts = &.{
        Option.In{ 
            .short_name = 's',
            .long_name = "stringOpt",
            .val = Value{
                .name = "stringVal",
                .description = "A string value.",
                .val_type = []u8,
            },
            .description = "A string option.",
        },
        Option.In{
            .short_name = 'i',
            .long_name = "intOpt",
            .val = Value{
                .name = "intVal",
                .description = "An integer value.",
                .val_type = u16,
            },
            .description = "An integer option.",
        },
        Option.In{
            .short_name = 't',
            .long_name = "toggle",
            .val = Value{
                .name = "toggleVal",
                .description = "A toggle/boolean value.",
                .val_type = bool,
            },
            .description = "A toggle/boolean option.",
        }
    },
    .vals = &.{
        Value{
            .name = "cmd_val",
            .description = "A command value.",
            .val_type = []u8,
        }
    }
}; 

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const args = try proc.argsWithAllocator(alloc);

    const cmd_out = cova.parseArgs(alloc, &args, cmd_in, stdout);

    if (eql(cmd_out.sub_cmd.name, "help")) try cmd_in.help(stdout);
}
