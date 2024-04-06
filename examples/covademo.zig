//! Example usage of Cova.
//! Comptime Setup, Runtime Use.

const std = @import("std");
const builtin = @import("builtin");
const fmt = std.fmt;
const io = std.io;
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
const ex_structs = @import("example_structs.zig");
const conf_optimized = Command.Config.optimized(.{});
pub const CommandT = Command.Custom(.{
    .global_help_prefix = "CovaDemo",
    .global_vals_mandatory = false,
    //.allow_arg_indices = false,
    //.global_usage_fn = struct{
    //    fn usage(self: anytype, writer: anytype, _: mem.Allocator) !void {
    //        const CmdT = @TypeOf(self.*);
    //        const OptT = CmdT.OptionT;
    //        const indent_fmt = CmdT.indent_fmt;
    //        var no_args = true;
    //        var pre_sep: []const u8 = "";

    //        try writer.print("USAGE\n", .{});
    //        if (self.opts) |opts| {
    //            no_args = false;
    //            try writer.print("{s}{s} [", .{ 
    //                indent_fmt,
    //                self.name,
    //            });
    //            for (opts) |opt| {
    //                try writer.print("{s} {s}{s} ", .{ 
    //                    pre_sep,
    //                    OptT.long_prefix orelse opt.short_prefix,
    //                    opt.long_name orelse &.{ opt.short_name orelse 0 },
    //                });
    //                pre_sep = "| ";
    //            }
    //            try writer.print("]\n", .{});
    //        }
    //        if (self.sub_cmds) |cmds| {
    //            no_args = false;
    //            try writer.print("{s}{s} [", .{ 
    //                indent_fmt,
    //                self.name,
    //            });
    //            pre_sep = "";
    //            for (cmds) |cmd| {
    //                try writer.print("{s} {s} ", .{ 
    //                    pre_sep,
    //                    cmd.name,
    //                });
    //                pre_sep = "| ";
    //            }
    //            try writer.print("]\n", .{});
    //        }
    //        if (no_args) try writer.print("{s}{s}{s}", .{ 
    //            indent_fmt, 
    //            indent_fmt,
    //            self.name,
    //        });
    //    }
    //}.usage,
    //.help_header_fmt = 
    //    \\HELP
    //    \\{s}COMMAND: {s}
    //    \\
    //    \\{s}DESCRIPTION: {s}
    //    \\
    //    \\
    //,
    //.global_help_fn = struct{
    //    fn help(self: anytype, writer: anytype, _: mem.Allocator) !void {
    //        const CmdT = @TypeOf(self.*);
    //        const OptT = CmdT.OptionT;
    //        const indent_fmt = CmdT.indent_fmt;
    //        
    //        try writer.print("{s}\n", .{ self.help_prefix });
    //        try self.usage(writer);
    //        try writer.print("\n", .{});
    //        try writer.print(CmdT.help_header_fmt, .{ 
    //            indent_fmt, self.name, 
    //            indent_fmt, self.description 
    //        });

    //        if (self.sub_cmds) |cmds| {
    //            try writer.print("SUBCOMMANDS\n", .{});
    //            for (cmds) |cmd| {
    //                try writer.print("{s}{s}: {s}\n", .{
    //                    indent_fmt,
    //                    cmd.name,
    //                    cmd.description, 
    //                });
    //            }
    //            try writer.print("\n", .{});
    //        }
    //        if (self.opts) |opts| {
    //            try writer.print("OPTIONS\n", .{});
    //            for (opts) |opt| {
    //                try writer.print(
    //                    \\{s}{s}{s} "{s} ({s})"
    //                    \\{s}{s}{s}
    //                    \\
    //                    \\
    //                    , .{
    //                        indent_fmt, 
    //                        OptT.long_prefix orelse OptT.short_prefix, opt.long_name orelse "", 
    //                        opt.val.name(), opt.val.childType(),
    //                        indent_fmt, indent_fmt,
    //                        opt.description, 
    //                    }
    //                );
    //            }
    //        }
    //        if (self.vals) |vals| {
    //            try writer.print("VALUES\n", .{});
    //            for (vals) |val| {
    //                try writer.print("{s}", .{ indent_fmt });
    //                try val.usage(writer);
    //                try writer.print("\n", .{});
    //            }
    //            try writer.print("\n", .{});
    //        }
    //    }
    //}.help,
    //.global_case_sensitive = false,
    .opt_config = .{
        .usage_fmt = "{u}{?u}{s} {s}{?s} <{s} ({s})>",
        //.allow_arg_indices = false,
        //.global_case_sensitive = false,
        //.usage_fn = struct{
        //    fn usage(self: anytype, writer: anytype, _: mem.Allocator) !void {
        //        const short_prefix = @TypeOf(self.*).short_prefix;
        //        const long_prefix = @TypeOf(self.*).long_prefix;
        //        try writer.print("{?u}{?u}, {?s}{?s}", .{
        //                short_prefix, 
        //                self.short_name, 
        //                long_prefix, 
        //                self.long_name,
        //            }
        //        );
        //    }
        //}.usage,
        .global_help_fn = struct{
            fn help(self: anytype, writer: anytype, _: mem.Allocator) !void {
                const indent_fmt = @TypeOf(self.*).indent_fmt;
                try self.usage(writer);
                try writer.print("\n{?s}{?s}{?s}{s}", .{ indent_fmt, indent_fmt, indent_fmt, self.description });
            }
        }.help
    },
    .val_config = .{
        //.allow_arg_indices = false,
        //.custom_types = &.{ DemoStruct.InnerEnum },
        //.custom_types = &.{ SimpleEnum },
        .child_type_parse_fns = &.{
            //.{
            //    .ChildT = bool,
            //    .parse_fn = Value.ParsingFns.Builder.altBool(
            //        &.{ "true", "t", "yes", "y", "1", "ok" },
            //        &.{ "false", "f", "no", "n", "0" },
            //        .Error
            //    )
            //},
            //.{
            //    .ChildT = u1024,
            //    .parse_fn = struct{ fn testFn(arg: []const u8, alloc: mem.Allocator) !u1024 { _ = arg; _ = alloc; return 69696969696969; } }.testFn,
            //},
        },
        .child_type_aliases = &.{
            .{
                .ChildT = []const u8,
                .alias = "text",
            },
        }
    },
    //.global_usage_fn = struct{ 
    //    fn usage(_: anytype, writer: anytype, _: mem.Allocator) !void { 
    //        // In a real implementation checks should be done to ensure `self` is a suitable Command Type and extract its sub Argument Types.
    //        try writer.print("This is an overriding usage message!\n\n", .{}); 
    //    } 
    //}.usage,
}); 
pub const ValueT = CommandT.ValueT;

//pub const log_level: log.Level = .err;

pub const SimpleEnum = enum{
    a,
    b,
};

pub const DemoStruct = struct{
    pub const InnerStruct = struct{
        in_bool: bool = false,
        in_float: f32 = 0,
    };
    pub const InnerEnum = enum(u2){
        red,
        blue,
        green,
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
    rgb_enum: ?InnerEnum = .blue,
    // Values
    struct_bool: bool = true,
    struct_str: []const u8 = "Demo Struct string.",
    struct_int: i64 = 8967,
    multi_int_val: [2]u16,
    _ignored_int: i8 = 15,
    // Cova Argument Types
    //cova_val_int: ValueT = ValueT.ofType(i8, .{
    //    .name = "cova_val_int",
    //    .description = "A test cova Value within a struct.",
    //    .default_val = 50,
    //}),
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
pub const setup_cmd: CommandT = .{
    .name = "covademo",
    .description = "A demo of the Cova command line argument parser.",
    .examples = &.{
        "covademo -b --string \"Optional String\"",
        "covademo -i 0 -i=1 -i2 -i=3,4,5 -i6,7 --int 8 --int=9",
        "covademo --file \"/some/file\"",
    },
    .cmd_groups = &.{ "RAW", "STRUCT-BASED", "FN-BASED" },
    .opt_groups = &.{ "INT", "BOOL", "STRING" },
    .val_groups = &.{ "INT", "BOOL", "STRING" },
    .sub_cmds_mandatory = false,
    .mandatory_opt_groups = &.{ "BOOL" },
    .sub_cmds = &.{
        .{
            .name = "sub-cmd",
            .alias_names = &.{ "alias-cmd", "test-alias" },
            .description = "A demo sub command.",
            .examples = &.{
                "covademo sub-cmd 3.14",
            },
            .cmd_group = "RAW",
            .opts = &.{
                .{
                    .name = "nested_int_opt",
                    .short_name = 'i',
                    //.long_name = "nested_int",
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
            .alias_names = &.{ "basic-cmd" },
            .description = "The most basic Command.",
            .cmd_group = "RAW",
        },
        .{
            .name = "nest-1",
            .description = "Nested Level 1.",
            .sub_cmds = &.{
                .{
                    .name = "nest-2",
                    .description = "Nested Level 2.",
                    .sub_cmds = &.{
                        .{
                            .name = "nest-3",
                            .description = "Nested Level 3.",
                            .sub_cmds = &.{
                                .{
                                    .name = "nest-4",
                                    .description = "Nested Level 4.",
                                }
                            },
                            .opts = &.{
                                .{
                                    .name = "inheritable",
                                    .description = "Inheritable Option",
                                    .inheritable = true,
                                    .short_name = 'i',
                                    .long_name = "inheritable",
                                }
                            }
                        }
                    }
                }
            }
        },
        CommandT.from(DemoStruct, .{
            .cmd_name = "struct-cmd",
            .cmd_description = "A demo sub command made from a struct.",
            .attempt_short_opts = false,
            //.cmd_hidden = true,
            .cmd_group = "STRUCT-BASED",
            .sub_cmds_mandatory = false,
            .default_val_opts = true,
            .sub_descriptions = &.{
                .{ "inner_cmd", "An inner/nested command for struct-cmd" },
                .{ "int", "The first Integer Value for the struct-cmd." },
            },
        }),
        CommandT.from(DemoUnion, .{
            .cmd_name = "union-cmd",
            .cmd_description = "A demo sub command made from a union.",
            .cmd_group = "STRUCT-BASED",
            .sub_descriptions = &.{
                .{ "int", "The first Integer Value for the union-cmd." },
                .{ "str", "The first String Value for the union-cmd." },
            },
        }),
        CommandT.from(@TypeOf(demoFn), .{
            .cmd_name = "fn-cmd",
            .cmd_description = "A demo sub command made from a function.",
            .cmd_group = "FN-BASED",
            .sub_descriptions = &.{
                .{ "inner_config", "An inner/nested command for fn-cmd" },
                .{ "int", "The first Integer Value for the fn-cmd." },
                .{ "string", "The first String Value for the fn-cmd." },
            },
            .ignore_incompatible = false,
        }),
        CommandT.from(ex_structs.add_user, .{
            .cmd_name = "add-user",
            .cmd_group = "STRUCT-BASED",
            .cmd_description = "A demo sub command for adding a user.",
        }),
    },
    .opts = &.{
        .{ 
            .name = "string_opt",
            .description = "A string option. (Can be given up to 4 times.)",
            //.hidden = true,
            .inheritable = true,
            .opt_group = "STRING",
            .short_name = 's',
            .long_name = "string",
            .alias_long_names = &.{ "text" },
            .val = ValueT.ofType([]const u8, .{
                .name = "string_val",
                .description = "A string value.",
                .default_val = "Default string value.",
                .alias_child_type = "string",
                .set_behavior = .Multi,
                .max_args = 4,
                .parse_fn = Value.ParsingFns.toUpper,
            }),
        },
        .{
            .name = "int_opt",
            .description = "An integer option. (Can be given up to 10 times.)",
            .opt_group = "INT",
            .short_name = 'i',
            .long_name = "int",
            .val = ValueT.ofType(i16, .{
                .name = "int_val",
                .description = "An integer value.",
                .valid_fn = struct{ fn valFn(int: i16, alloc: mem.Allocator) bool { _ = alloc; return int < 666; } }.valFn,
                .set_behavior = .Multi,
                .max_args = 10,
            }),
        },
        //.{
        //    .name = "uint_opt",
        //    .description = "An unsigned integer option. (Can be given up to 10 times.)",
        //    .opt_group = "INT",
        //    .short_name = 'U',
        //    .long_name = "uint",
        //    .val = ValueT.ofType(u1024, .{
        //        .name = "uint_val",
        //        .description = "An unsigned integer value.",
        //        .set_behavior = .Multi,
        //        .max_args = 10,
        //    }),
        //},
        .{
            .name = "float_opt",
            .description = "An float option. (Can be given up to 10 times.)",
            //.opt_group = "INT",
            .short_name = 'f',
            .long_name = "float",
            .val = ValueT.ofType(f16, .{
                .name = "float_val",
                .description = "A float value.",
                .valid_fn = Value.ValidationFns.Builder.inRange(f16, 0.0, 36_000.0, true),
                .set_behavior = .Multi,
                .max_args = 10,
            }),
        },
        .{
            .name = "file_opt",
            .description = "A filepath option.",
            .opt_group = "STRING",
            .short_name = 'F',
            .long_name = "file",
            .val = ValueT.ofType([]const u8, .{
                .name = "filepath",
                .description = "A filepath value.",
                .alias_child_type = "filepath",
                .valid_fn = Value.ValidationFns.validFilepath,
            }),
        },
        .{
            .name = "ordinal_opt",
            .description = "An ordinal number option.",
            .opt_group = "STRING",
            .short_name = 'o',
            .long_name = "ordinal",
            .val = ValueT.ofType([]const u8, .{
                .name = "ordinal_val",
                .description = "An ordinal number value.",
                .valid_fn = Value.ValidationFns.ordinalNum,
            }),
        },
        .{
            .name = "cardinal_opt",
            .description = "A cardinal number option.",
            .opt_group = "INT",
            .short_name = 'c',
            .long_name = "cardinal",
            .val = ValueT.ofType(u8, .{
                .name = "cardinal_val",
                .description = "A cardinal number value.",
                .parse_fn = Value.ParsingFns.Builder.asEnumType(enum(u8) { zero, one, two }),
                .set_behavior = .Multi,
                .max_args = 3,
            }),
        },
        .{
            .name = "toggle_opt",
            .description = "A toggle/boolean option.",
            .opt_group = "BOOL",
            .short_name = 't',
            .long_name = "toggle",
            .alias_long_names = &.{ "switch" },
            .val = ValueT.ofType(bool, .{
                .name = "toggle_val",
                .description = "A toggle/boolean value.",
            }),
        },
        .{
            .name = "bool_opt",
            .description = "A toggle/boolean option.",
            .opt_group = "BOOL",
            .short_name = 'b',
            .long_name = "bool",
            //.mandatory = true,
            .val = ValueT.ofType(bool, .{
                .name = "bool_val",
                .description = "A toggle/boolean value.",
                //.parse_fn = Value.ParsingFns.Builder.altBool(&.{ "true", "t", "yes", "y", "1" }, &.{}, .False),
            }),
        },
        .{
            .name = "verbosity_opt",
            .description = "Set the CovaDemo verbosity level. (WIP)",
            .inheritable = true,
            .short_name = 'v',
            .long_name = "verbosity",
            .val = ValueT.ofType(u4, .{
                .name = "verbosity_level",
                .description = "The verbosity level from 0 (err) to 3 (debug).",
                .default_val = 3,
                .valid_fn = struct{ fn valFn(val: u4, _: mem.Allocator) bool { return val >= 0 and val <= 3; } }.valFn,
            }),
        },
    },
    .vals = &.{
        ValueT.ofType([]const u8, .{
            .name = "cmd_str",
            .val_group = "STRING",
            .description = "A string value for the command.",
            .parse_fn = Value.ParsingFns.trimWhitespace,
        }),
        ValueT.ofType(bool, .{
            .name = "cmd_bool",
            .description = "A boolean value for the command.",
            .set_behavior = .Multi,
            .max_args = 10,
            .parse_fn = Value.ParsingFns.Builder.altBool(&.{ "true", "t", "yes", "y" }, &.{ "false", "f", "no", "n", "0" }, .Error),
        }),
        ValueT.ofType(u64, .{
            .name = "cmd_u64",
            .description = "A u64 value for the command.",
            .default_val = 654321,
            .set_behavior = .Multi,
            .max_args = 3,
            .parse_fn = struct{ fn parseFn(arg: []const u8, alloc: mem.Allocator) !u64 { _ = alloc; return (try fmt.parseInt(u64, arg, 0)) * 100; } }.parseFn, 
            .valid_fn = Value.ValidationFns.Builder.inRange(u64, 123456, 9999999999, true),
        }),
    }
};


pub fn main() !void {
    // Setup
    //var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    //var alloc_buf: [100 << 10]u8 = undefined;
    //var fba = std.heap.FixedBufferAllocator.init(alloc_buf[0..]);
    //var arena = std.heap.ArenaAllocator.init(fba.allocator());
    //defer arena.deinit();
    //const alloc = arena.allocator();
    var gpa = std.heap.GeneralPurposeAllocator(.{ .verbose_log = builtin.mode == .Debug }){};
    const alloc = gpa.allocator();
    defer {
        if (gpa.deinit() != .ok) {
            if (builtin.mode == .Debug and gpa.detectLeaks()) log.err("Memory leak detected!", .{});
        }
        else log.debug("Memory freed. No leaks detected.", .{});
    }
    const stdout_raw = io.getStdOut().writer();
    var stdout_bw = io.bufferedWriter(stdout_raw);
    const stdout = stdout_bw.writer();

    var main_cmd = try setup_cmd.init(alloc, .{});
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
    try stdout_bw.flush();

    // Analysis
    // - Debug Output of Commands after Parsing. 
    try stdout.print("\n", .{});
    try cova.utils.displayCmdInfo(CommandT, main_cmd, alloc, stdout);
    try stdout_bw.flush();


    // - Individual Command Analysis (this is how analysis would look in a normal program)
    log.info("Main Cmd", .{});

    // -- Get Values
    const val_map = try main_cmd.getVals(.{ .arg_group = "STRING" });
    var val_iter = val_map.valueIterator();
    log.debug("Get String Values:", .{});
    while (val_iter.next()) |str_val| log.debug("- {s}", .{ str_val.getAs([]const u8) catch "[value not set]" });
    // -- Check Options
    const opts_check_names: []const []const u8 = &.{ "int_opt", "string_opt", "float_opt", "bool_opt" };
    const and_opts_check = main_cmd.checkOpts(opts_check_names, .{ .logic = .AND });
    const or_opts_check = main_cmd.checkOpts(opts_check_names, .{ .logic = .OR });
    const xor_opts_check = main_cmd.checkOpts(opts_check_names, .{ .logic = .XOR });
    log.debug(
        \\ Check Options: {s}
        \\ - AND: {}
        \\ -  OR: {}
        \\ - XOR: {}
        \\
        , .{
            opts_check_names,
            and_opts_check,
            or_opts_check,
            xor_opts_check,
        }
    );
    //if (main_cmd.opts) |main_opts| {
    //    for (main_opts) |opt| log.debug("-> Opt: {s}, Idx: {d}", .{ opt.name, opt.arg_idx orelse continue });
    //}
    if (main_cmd.checkSubCmd("sub-cmd"))
        log.info("-> Sub Cmd", .{});
    if (main_cmd.matchSubCmd("add-user")) |add_user_cmd|
        log.info("-> Add User Cmd\nTo Struct:\n{any}\n\n", .{ try add_user_cmd.to(ex_structs.add_user, .{}) });
    if (main_cmd.matchSubCmd("struct-cmd")) |struct_cmd| structCmd: {
        log.debug("Parent Cmd (struct-cmd): {s]}", .{ struct_cmd.parent_cmd.?.name });
        log.debug("Parent Cmd (int-opt / int-val): {s} / {s}", optPar: {
            const struct_cmd_opts = struct_cmd.getOpts(.{}) catch break: optPar .{ "[no opts]", "" };
            const int_opt = struct_cmd_opts.get("int") orelse break: optPar .{ "[no int opt]", "" };
            break :optPar .{ if (int_opt.parent_cmd) |p_cmd| p_cmd.name else "[no parent?]", if (int_opt.val.parent_cmd) |p_cmd| p_cmd.name else "[no parent?]" };
        });
        const demo_struct = try struct_cmd.to(DemoStruct, .{ .default_val_opts = true });
        log.info("-> Struct Cmd\n{any}", .{ demo_struct });
        if (struct_cmd.matchSubCmd("inner-cmd")) |inner_cmd|
            log.info("->-> Inner Cmd\n{any}", .{ try inner_cmd.to(DemoStruct.InnerStruct, .{}) });
        //for (struct_cmd.opts orelse break :structCmd) |opt| log.debug("->-> Opt: {s}, Idx: {d}", .{ opt.name, opt.arg_idx orelse continue });
        break :structCmd;
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

    // Optimized Config
    log.debug("Optimized Config:\n{any}", .{ conf_optimized });
}
