//! Example usage of Cova.

const std = @import("std");
const mem = std.mem;
const meta = std.meta;
const proc = std.process;
const stdout = std.io.getStdOut().writer();
const testing = std.testing;

const eql = mem.eql;

const cova = @import("src/cova.zig");
const Command = cova.Command;
const Option = cova.Option;
const Value = cova.Value;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const cmd = try alloc.create(Command);
    cmd.* = .{
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
                    .short_name = 'h',
                    .long_name = "help",
                    .val = &Value.init(bool, .{
                        .name = "helpFlag",
                        .description = "Flag for help!",
                    }),
                    .description = "Show the CovaDemo help display.",
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

    const args = try proc.argsWithAllocator(alloc);
    try cova.parseArgs(&args, cmd, stdout);

    std.debug.print("\n\n", .{});

    try displayCmdInfo(cmd);
}

fn displayCmdInfo(display_cmd: *const Command) !void {
    var cur_cmd: ?*const Command = display_cmd;
    while (cur_cmd != null) {
        const cmd = cur_cmd.?;
        
        if (cmd.sub_cmd != null and eql(u8, cmd.sub_cmd.?.name, "help")) try cmd.help(stdout);
        if (cmd.sub_cmd != null and eql(u8, cmd.sub_cmd.?.name, "usage")) try cmd.usage(stdout);

        std.debug.print("- Command: {s}\n", .{ cmd.name });
        if (cmd.opts != null) {
            for (cmd.opts.?) |opt| { 
                switch (meta.activeTag(opt.val.*)) {
                    .string => {
                        std.debug.print("    Opt: {?s}, Data: {s}\n", .{ 
                            opt.long_name, 
                            opt.val.string.get() catch "",
                        });
                    },
                    inline else => |tag| {
                        std.debug.print("    Opt: {?s}, Data: {any}\n", .{ 
                            opt.long_name, 
                            @field(opt.val, @tagName(tag)).get() catch null,
                        });
                    },
                }
            }
        }
        if (cmd.vals != null) {
            for (cmd.vals.?) |val| { 
                switch (meta.activeTag(val.*)) {
                    .string => {
                        std.debug.print("    Val: {?s}, Data: {s}\n", .{ 
                            val.name(), 
                            val.string.get() catch "",
                        });
                    },
                    inline else => |tag| {
                        std.debug.print("    Val: {?s}, Data: {any}\n", .{ 
                            val.name(), 
                            @field(val, @tagName(tag)).get() catch null,
                        });
                    },
                }
            }
        }
        std.debug.print("\n", .{});
        cur_cmd = cmd.sub_cmd;
    }
}
