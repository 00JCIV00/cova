//! Example usage of Cova.

const std = @import("std");
const log = std.log;
const mem = std.mem;
const meta = std.meta;
const proc = std.process;
const stdout = std.io.getStdOut().writer();
const StringHashMap = std.StringHashMap;
const testing = std.testing;

const eql = mem.eql;

const cova = @import("src/cova.zig");
const Command = cova.Command;
const Option = cova.Option;
const Value = cova.Value;

pub const log_level: log.Level = .err;
    
pub const CustomCommand = Command.Custom(.{
    .subcmds_help_fmt = "Name: {s}, Description: {s}",
}); 

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const cmd = try alloc.create(CustomCommand);
    cmd.* = .{
        .name = "covademo",
        .help_prefix = "CovaDemo",
        .description = "A demo of the Cova command line argument parser.",
        .sub_cmds = subCmdsSetup: {
            var setup_cmds = [_]*const CustomCommand{
                //&CustomCommand{
                //    .name = "help",
                //    .help_prefix = "CovaDemo",
                //    .description = "Show the CovaDemo help display.",
                //},
                //&CustomCommand{
                //    .name = "usage",
                //    .help_prefix = "CovaDemo",
                //    .description = "Show the CovaDemo usage display.",
                //},
                &CustomCommand{
                    .name = "demo_cmd",
                    .help_prefix = "CovaDemo",
                    .description = "A demo sub command.",
                    .sub_cmds = nestedSubCmdsSetup: {
                        var nested_setup_cmds = [_]*const CustomCommand{
                            &CustomCommand{
                                .name = "help",
                                .help_prefix = "CovaDemo -> DemoCommand",
                                .description = "Show the DemoCommand help display.",
                            },
                            &CustomCommand{
                                .name = "usage",
                                .help_prefix = "CovaDemo -> DemoCommand",
                                .description = "Show the DemoCommand usage display.",
                            },
                        };
                        break :nestedSubCmdsSetup nested_setup_cmds[0..];
                    },
                    .opts = optsSetup: {
                        var setup_opts = [_]*const CustomCommand.CustomOption{
                            &CustomCommand.CustomOption{
                                .name = "nestedIntOpt",
                                .short_name = 'n',
                                .long_name = "nestedIntOpt",
                                .val = &Value.init(u8, .{
                                    .name = "nestedIntVal",
                                    .description = "A nested integer value.",
                                    .default_val = 203,
                                }),
                                .description = "A nested integer option.",
                            },
                            &CustomCommand.CustomOption{
                                .name = "help",
                                .short_name = 'h',
                                .long_name = "help",
                                .val = &Value.init(bool, .{
                                    .name = "helpFlag",
                                    .description = "Flag for help!",
                                }),
                                .description = "Show the DemoCommand help display.",
                            },
                            &CustomCommand.CustomOption{
                                .name = "usage",
                                .short_name = 'u',
                                .long_name = "usage",
                                .val = &Value.init(bool, .{
                                    .name = "usageFlag",
                                    .description = "Flag for usage!",
                                }),
                                .description = "Show the DemoCommand usage display.",
                            },
                        };
                        break :optsSetup setup_opts[0..];
                    },
                }
            };
            break :subCmdsSetup setup_cmds[0..];
        },
        .opts = optsSetup: {
            var setup_opts = [_]*const CustomCommand.CustomOption{
                &CustomCommand.CustomOption{ 
                    .name = "stringOpt",
                    .short_name = 's',
                    .long_name = "stringOpt",
                    .val = &Value.init([]const u8, .{
                        .name = "stringVal",
                        .description = "A string value.",
                    }),
                    .description = "A string option.",
                },
                &CustomCommand.CustomOption{
                    .name = "intOpt",
                    .short_name = 'i',
                    .long_name = "intOpt",
                    .val = &Value.init(i16, .{
                        .name = "intVal",
                        .description = "An integer value.",
                        .val_fn = struct{ fn valFn(int: i16) bool { return int < 666; } }.valFn
                    }),
                    .description = "An integer option.",
                },
                &CustomCommand.CustomOption{
                    .name = "toggle",
                    .short_name = 't',
                    .long_name = "toggle",
                    .val = &Value.init(bool, .{
                        .name = "toggleVal",
                        .description = "A toggle/boolean value.",
                    }),
                    .description = "A toggle/boolean option.",
                },
                //&CustomCommand.CustomOption{
                //    .name = "help",
                //    .short_name = 'h',
                //    .long_name = "help",
                //    .val = &Value.init(bool, .{
                //        .name = "helpFlag",
                //        .description = "Flag for help!",
                //    }),
                //    .description = "Show the CovaDemo help display.",
                //},
                &CustomCommand.CustomOption{
                    .name = "verbosity",
                    .short_name = 'v',
                    .long_name = "verbosity",
                    .val = &Value.init(u4, .{
                        .name = "verbosityLevel",
                        .description = "The verbosity level from 0 (err) to 3 (debug).",
                        .default_val = 3,
                        .val_fn = struct{ fn valFn(val: u4) bool { return val >= 0 and val <= 3; } }.valFn,
                    }),
                    .description = "Set the CovaDemo verbosity level. (WIP)",
                },
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
                    .default_val = 654321,
                    .val_fn = struct{ fn valFn(val: u128) bool { return val > 123456 and val < 987654; } }.valFn,
                }),
            };
            break :valsSetup setup_vals[0..];
        }
    };
    defer alloc.destroy(cmd);
    try cmd.setup(alloc, .{});

    const args = try proc.argsWithAllocator(alloc);
    try cova.parseArgs(&args, CustomCommand, cmd, stdout);
    try stdout.print("\n", .{});
    try displayCmdInfo(cmd, alloc);

    // Verbosity Change (WIP)
    //@constCast(&log_level).* = verbosity: {
    //    var opt_map = try cmd.getOpts(alloc);
    //    defer opt_map.deinit();
    //    const log_lvl = try opt_map.get("verbosity").?.val.u4.get();
    //    break :verbosity @intToEnum(log.Level, log_lvl);
    //};
    //try stdout.print("\n\nLogging Level ({any}):\n", .{ log.default_level });
    //log.err("Err", .{});
    //log.warn("Warn", .{});
    //log.info("Info", .{});
    //log.debug("Debug", .{});
}

fn displayCmdInfo(display_cmd: *const CustomCommand, alloc: mem.Allocator) !void {
    var cur_cmd: ?*const CustomCommand = display_cmd;
    while (cur_cmd != null) {
        const cmd = cur_cmd.?;

        if (cmd.sub_cmd != null and eql(u8, cmd.sub_cmd.?.name, "help")) try cmd.help(stdout);
        if (cmd.sub_cmd != null and eql(u8, cmd.sub_cmd.?.name, "usage")) try cmd.usage(stdout);

        try stdout.print("- Command: {s}\n", .{ cmd.name });
        if (cmd.opts != null) {
            var opt_map: StringHashMap(*const @TypeOf(cmd.*).CustomOption) = try cmd.getOpts(alloc);
            defer opt_map.deinit();
            if (try opt_map.get("help").?.val.bool.get()) try cmd.help(stdout);
            if (try opt_map.get("usage").?.val.bool.get()) try cmd.usage(stdout);
            for (cmd.opts.?) |opt| { 
                switch (meta.activeTag(opt.val.*)) {
                    .string => {
                        try stdout.print("    Opt: {?s}, Data: \"{s}\"\n", .{ 
                            opt.long_name, 
                            opt.val.string.get() catch "",
                        });
                    },
                    inline else => |tag| {
                        try stdout.print("    Opt: {?s}, Data: {any}\n", .{ 
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
                        try stdout.print("    Val: {?s}, Data: \"{s}\"\n", .{ 
                            val.name(), 
                            val.string.get() catch "",
                        });
                    },
                    inline else => |tag| {
                        try stdout.print("    Val: {?s}, Data: {any}\n", .{ 
                            val.name(), 
                            @field(val, @tagName(tag)).get() catch null,
                        });
                    },
                }
            }
        }
        try stdout.print("\n", .{});
        cur_cmd = cmd.sub_cmd;
    }
}
