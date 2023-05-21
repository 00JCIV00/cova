//! Example usage of Cova.

const std = @import("std");
const mem = std.mem;
const meta = std.meta;
const proc = std.process;
const stdout = std.io.getStdOut().writer();
const testing = std.testing;

const eql = mem.eql;

const cova = @import("cova.zig");
const Command = cova.Command;
const Option = cova.Option;
const Value = cova.Value;

const ct_cmd = Command{
    .name = "covademo",
    .help_prefix = "CovaDemo",
    .description = "A demo of the Cova command line argument parser.",
    .sub_cmds = subCmdsSetup: {
        var setup_cmds = [_]*const Command{
            &Command{
                .name = "help",
                .help_prefix = "CovaDemo",
                .description = "Show the CovaDemo help display.",
            },
            &Command{
                .name = "usage",
                .help_prefix = "CovaDemo",
                .description = "Show the CovaDemo usage display.",
            },
            &Command{
                .name = "demo_cmd",
                .help_prefix = "CovaDemo",
                .description = "A demo sub command.",
                .sub_cmds = nestedSubCmdsSetup: {
                    var nested_setup_cmds = [_]*const Command{
                        &Command{
                            .name = "help",
                            .help_prefix = "CovaDemo -> DemoCommand",
                            .description = "Show the DemoCommand help display.",
                        },
                        &Command{
                            .name = "usage",
                            .help_prefix = "CovaDemo -> DemoCommand",
                            .description = "Show the DemoCommand usage display.",
                        },
                    };
                    break :nestedSubCmdsSetup nested_setup_cmds[0..];
                },
                .opts = optsSetup: {
                    var setup_opts = [_]*const Option{
                        &Option{
                            .short_name = 'n',
                            .long_name = "nested_int_opt",
                            .val = &Value.init(u8, .{
                                .name = "nested_int_val",
                                .description = "A nested integer value.",
                                .raw_arg = "203",
                            }),
                            .description = "A nested integer option.",
                        },
                    };
                    break :optsSetup setup_opts[0..];
                },
            }
        };
        break :subCmdsSetup setup_cmds[0..];
    },
    .opts = optsSetup: {
        var setup_opts = [_]*const Option{
            &Option{ 
                .short_name = 's',
                .long_name = "stringOpt",
                .val = &Value.init([]const u8, .{
                    .name = "stringVal",
                    .description = "A string value.",
                }),
                .description = "A string option.",
            },
            &Option{
                .short_name = 'i',
                .long_name = "intOpt",
                .val = &Value.init(i16, .{
                    .name = "intVal",
                    .description = "An integer value.",
                    .val_fn = struct{ fn valFn(int: i16) bool { return int < 666; } }.valFn
                }),
                .description = "An integer option.",
            },
            &Option{
                .short_name = 't',
                .long_name = "toggle",
                .val = &Value.init(bool, .{
                    .name = "toggleVal",
                    .description = "A toggle/boolean value.",
                }),
                .description = "A toggle/boolean option.",
            }
        };
        break :optsSetup setup_opts[0..];
    },
    .vals = valsSetup: {
        var setup_vals = [_]*const Value.Generic{
            &Value.init([]const u8, .{
                .name = "cmdStr",
                .description = "A string value for the command.",
            }),
            &Value.init(u128, .{
                .name = "cmd_u128",
                .description = "A u128 value for the command.",
                .raw_arg = "654321",
            }),
        };
        break :valsSetup setup_vals[0..];
    }
}; 

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const args = try proc.argsWithAllocator(alloc);
    const cmd = try alloc.create(Command);
    cmd.* = ct_cmd;
    try cova.parseArgs(&args, cmd, stdout);

    std.debug.print("\n\n", .{});

    if (cmd.sub_cmd != null and eql(u8, cmd.sub_cmd.?.name, "help")) try cmd.help(stdout);
    if (cmd.sub_cmd != null and eql(u8, cmd.sub_cmd.?.name, "usage")) try cmd.usage(stdout);
    for (cmd.opts.?) |opt| { 
        switch (meta.activeTag(opt.val.*)) {
            inline else => |tag| {
                std.debug.print("Opt: {?s}, Data: {any}\n", .{ 
                    opt.long_name, 
                    @field(opt.val, @tagName(tag)).get() catch null,
                });
            },
        }
    }
    for (cmd.vals.?) |val| { 
        switch (meta.activeTag(val.*)) {
            inline else => |tag| {
                std.debug.print("Val: {?s}, Data: {any}\n", .{ 
                    val.name(), 
                    @field(val, @tagName(tag)).get() catch null,
                });
            },
        }
    }

    if (cmd.sub_cmd != null and cmd.sub_cmd.?.sub_cmd != null and eql(u8, cmd.sub_cmd.?.sub_cmd.?.name, "help")) try cmd.sub_cmd.?.help(stdout);
    if (cmd.sub_cmd != null and cmd.sub_cmd.?.sub_cmd != null and eql(u8, cmd.sub_cmd.?.sub_cmd.?.name, "usage")) try cmd.sub_cmd.?.usage(stdout);
}
