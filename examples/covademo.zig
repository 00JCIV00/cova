//! Example usage of Cova.
//! Comptime Setup, Runtime Use.

const std = @import("std");
const fmt = std.fmt;
const log = std.log;
const mem = std.mem;
const meta = std.meta;
const proc = std.process;
const ComptimeStringMap = std.ComptimeStringMap;
const StringHashMap = std.StringHashMap;
const testing = std.testing;

const cova = @import("cova");
const Command = cova.Command;
const Option = cova.Option;
const Value = cova.Value;
const utils = cova.utils;
const ex_structs = @import("example_structs.zig");
pub const CommandT = Command.Custom(.{ 
    .global_help_prefix = "CovaDemo",
    .vals_mandatory = false,
}); 
pub const ValueT = CommandT.ValueT;

//pub const log_level: log.Level = .err;

pub const DemoStruct = struct {
    pub const InnerStruct = struct {
        in_bool: bool = false,
        in_float: f32 = 0,
    };
    // Command
    inner_cmd: InnerStruct = .{
        .in_bool = true,
        .in_float = 0,
    },
    // Options
    int: ?i32 = 26,
    str: ?[]const u8 = "Demo Opt string.",
    str2: ?[]const u8 = "Demo Opt string 2.",
    flt: ?f16 = 0,
    int2: ?u16 = 0,
    multi_int: [3]?u8,
    multi_str: [5]?[]const u8,
    // Values
    struct_bool: bool = false,
    struct_str: []const u8 = "Demo Struct string.",
    struct_int: i64,
    multi_int_val: [2]u16,
    _ignored_int: i8 = 15,
    // Cova Argument Types
    cova_val_int: ValueT = ValueT.ofType(i8, .{
        .name = "cova_val_int",
        .description = "A test cova Value within a struct.",
        .default_val = 50,
    }),
};

pub const DemoUnion = union(enum) {
    // Options
    int: ?i32,
    str: ?[]const u8,
    // Values
    union_uint: u8,
    union_str: []const u8,
};

pub fn demoFn(int: i32, string: []const u8) void {
    log.info("Demo function result:\n - Int: {d}\n - String: {s}", .{ int, string });
}

// Comptime Setup Command
const setup_cmd: CommandT = .{
    .name = "covademo",
    .description = "A demo of the Cova command line argument parser.",
    .sub_cmds_mandatory = false,
    .sub_cmds = &.{
        .{
            .name = "sub-cmd",
            .description = "A demo sub command.",
            .opts = &.{
                .{
                    .name = "nested_int_opt",
                    .short_name = 'i',
                    .long_name = "nested_int",
                    .val = ValueT.ofType(u8, .{
                        .name = "nested_int_val",
                        .description = "A nested integer value.",
                        .default_val = 203,
                    }),
                    .description = "A nested integer option.",
                },
                .{
                    .name = "nested_str_opt",
                    .short_name = 's',
                    .long_name = "nested_str",
                    .val = ValueT.ofType([]const u8, .{
                        .name = "nested_str_val",
                        .description = "A nested string value.",
                        .default_val = "A nested string value.",
                    }),
                    .description = "A nested string option.",
                },
            },
            .vals = &.{
                ValueT.ofType(f32, .{
                    .name = "nested_float_val",
                    .description = "A nested float value.",
                    .default_val = 0,
                }),
            }
        },
        .{
            .name = "basic",
            .description = "The most basic Command.",
        },
        CommandT.from(DemoStruct, .{
            .cmd_name = "struct-cmd",
            .cmd_description = "A demo sub command made from a struct.",
            .sub_cmds_mandatory = false,
            .sub_descriptions = &.{
                .{ "inner_cmd", "An inner/nested command for struct-cmd" },
                .{ "int", "The first Integer Value for the struct-cmd." },
            },
        }),
        CommandT.from(DemoUnion, .{
            .cmd_name = "union-cmd",
            .cmd_description = "A demo sub command made from a union.",
            .sub_descriptions = &.{
                .{ "int", "The first Integer Value for the union-cmd." },
                .{ "str", "The first String Value for the union-cmd." },
            },
        }),
        CommandT.from(@TypeOf(demoFn), .{
            .cmd_name = "fn-cmd",
            .cmd_description = "A demo sub command made from a function.",
            .sub_descriptions = &.{
                .{ "inner_config", "An inner/nested command for fn-cmd" },
                .{ "int", "The first Integer Value for the fn-cmd." },
                .{ "string", "The first String Value for the fn-cmd." },
            },
            .ignore_incompatible = false,
        }),
        CommandT.from(ex_structs.add_user, .{
            .cmd_name = "add-user",
            .cmd_description = "A demo sub command for adding a user.",
        }),
    },
    .opts = &.{
        .{ 
            .name = "string_opt",
            .short_name = 's',
            .long_name = "string",
            .val = ValueT.ofType([]const u8, .{
                .name = "string_val",
                .description = "A string value.",
                .default_val = "A string value.",
                .set_behavior = .Multi,
                .max_args = 4,
            }),
            .description = "A string option. (Can be given up to 4 times.)",
        },
        .{
            .name = "int_opt",
            .short_name = 'i',
            .long_name = "int",
            .val = ValueT.ofType(i16, .{
                .name = "int_val",
                .description = "An integer value.",
                .valid_fn = struct{ fn valFn(int: i16) bool { return int < 666; } }.valFn,
                .set_behavior = .Multi,
                .max_args = 10,
            }),
            .description = "An integer option. (Can be given up to 10 times.)",
        },
        .{
            .name = "float_opt",
            .short_name = 'f',
            .long_name = "float",
            .val = ValueT.ofType(f16, .{
                .name = "float_val",
                .description = "A float value.",
                .valid_fn = Value.ValidationFns.Builder.inRange(f16, 0.0, 36_000.0, true),
                .set_behavior = .Multi,
                .max_args = 10,
            }),
            .description = "An float option. (Can be given up to 10 times.)",
        },
        .{
            .name = "file_opt",
            .short_name = 'F',
            .long_name = "file",
            .val = ValueT.ofType([]const u8, .{
                .name = "file_val",
                .description = "A filepath value.",
                .valid_fn = Value.ValidationFns.validFilepath,
            }),
            .description = "A filepath option.",
        },
        .{
            .name = "ordinal_opt",
            .short_name = 'o',
            .long_name = "ordinal",
            .val = ValueT.ofType([]const u8, .{
                .name = "ordinal_val",
                .description = "An ordinal number value.",
                .valid_fn = Value.ValidationFns.ordinalNum,
            }),
            .description = "An ordinal number option.",
        },
        .{
            .name = "cardinal_opt",
            .short_name = 'c',
            .long_name = "cardinal",
            .val = ValueT.ofType(u8, .{
                .name = "cardinal_val",
                .description = "A cardinal number value.",
                .parse_fn = Value.ParsingFns.Builder.asEnumType(enum(u8) { zero, one, two }),
                .set_behavior = .Multi,
                .max_args = 3,
            }),
            .description = "A cardinal number option.",
        },
        .{
            .name = "toggle_opt",
            .short_name = 't',
            .long_name = "toggle",
            .val = ValueT.ofType(bool, .{
                .name = "toggle_val",
                .description = "A toggle/boolean value.",
            }),
            .description = "A toggle/boolean option.",
        },
        .{
            .name = "verbosity_opt",
            .short_name = 'v',
            .long_name = "verbosity",
            .val = ValueT.ofType(u4, .{
                .name = "verbosity_level",
                .description = "The verbosity level from 0 (err) to 3 (debug).",
                .default_val = 3,
                .valid_fn = struct{ fn valFn(val: u4) bool { return val >= 0 and val <= 3; } }.valFn,
            }),
            .description = "Set the CovaDemo verbosity level. (WIP)",
        },
    },
    .vals = &.{
        ValueT.ofType([]const u8, .{
            .name = "cmd_str",
            .description = "A string value for the command.",
            .parse_fn = Value.ParsingFns.trimWhitespace,
        }),
        ValueT.ofType(bool, .{
            .name = "cmd_bool",
            .description = "A boolean value for the command.",
            .parse_fn = Value.ParsingFns.Builder.altTrue(&.{ "potatoe" }),
        }),
        ValueT.ofType(u128, .{
            .name = "cmd_u128",
            .description = "A u128 value for the command.",
            .default_val = 654321,
            .set_behavior = .Multi,
            .max_args = 3,
            .parse_fn = struct{ fn parseFn(arg: []const u8) !u128 { return (try fmt.parseInt(u128, arg, 0)) * 100; } }.parseFn, 
            .valid_fn = Value.ValidationFns.Builder.inRange(u128, 123456, 9999999999, true),
        }),
    }
};

pub fn main() !void {
    // Setup
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    const stdout = std.io.getStdOut().writer();

    const main_cmd = &(try setup_cmd.init(alloc, .{})); 
    defer main_cmd.deinit();
    var args_iter = try cova.ArgIteratorGeneric.init(alloc);
    defer args_iter.deinit();

    // Parsing
    cova.parseArgs(&args_iter, CommandT, main_cmd, stdout, .{ 
        //.auto_handle_usage_help = false,
    }) catch |err| switch (err) {
        error.UsageHelpCalled => {},
        else => return err,
    };

    // Analysis
    // - Debug Output of Commands after Parsing. 
    try stdout.print("\n", .{});
    try utils.displayCmdInfo(CommandT, main_cmd, alloc, stdout);

    // - Individual Command Analysis (this is how analysis would look in a normal program)
    log.info("Main Cmd", .{});
    if (main_cmd.checkSubCmd("sub-cmd"))
        log.info("-> Sub Cmd", .{});
    if (main_cmd.matchSubCmd("add-user")) |add_user_cmd|
        log.info("-> Add User Cmd\nTo Struct:\n{any}\n\n", .{ try add_user_cmd.to(ex_structs.add_user, .{}) });
    if (main_cmd.matchSubCmd("struct-cmd")) |struct_cmd| {
        const demo_struct = try struct_cmd.to(DemoStruct, .{});
        log.info("-> Struct Cmd\n{any}", .{ demo_struct });
        if (struct_cmd.matchSubCmd("inner-cmd")) |inner_cmd|
            log.info("->-> Inner Cmd\n{any}", .{ try inner_cmd.to(DemoStruct.InnerStruct, .{}) });
    }
    if (main_cmd.checkSubCmd("union-cmd"))
        log.info("-> Union Cmd\nTo Union:\n{any}\n\n", .{ meta.activeTag(try main_cmd.sub_cmd.?.to(DemoUnion, .{})) });
    if (main_cmd.matchSubCmd("fn-cmd")) |fn_cmd| {
        log.info("-> Fn Cmd", .{});
        try fn_cmd.callAs(demoFn, null, void);
    }

    // Tokenization Example
    const arg_str = "cova struct-cmd --multi-str \"demo str\" -m 'a \"quoted string\"' -m \"A string using an 'apostrophe'\" -m (quick parans test) 50";
    const args = try cova.tokenizeArgs(arg_str, alloc, .{ .groupers_open = "\"'(", .groupers_close = "\"')" });
    defer alloc.free(args);
    log.debug("Tokenized Args:\n{s}", .{ args });
}
