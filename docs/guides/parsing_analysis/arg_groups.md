# Argument Groups
Argument Groups can be used to organize Arguments based on similarities between them. For instance Commands might be organized into different categories for what they do while Options and Values can be grouped based on the kind of data they provide. These groups will be validated during the initialization to ensure that each group assigned to an Argument exists within the respective Group List for that Argument's parent Command.

Example:
```zig
pub const setup_cmd: CommandT = .{
    .name = "covademo",
    .description = "A demo of the Cova command line argument parser.",
    .cmd_groups = &.{ "RAW", "STRUCT-BASED", "FN-BASED" },
    .opt_groups = &.{ "INT", "BOOL", "STRING" },
    .val_groups = &.{ "INT", "BOOL", "STRING" },
    .sub_cmds_mandatory = false,
    .mandatory_opt_groups = &.{ "BOOL" },
    .sub_cmds = &.{
        .{
            .name = "sub-cmd",
            .description = "A demo sub command.",
            .cmd_group = "RAW",
        },
        .{
            .name = "basic",
            .description = "The most basic Command.",
            .cmd_group = "RAW",
        },
        CommandT.from(DemoStruct, .{
            .cmd_name = "struct-cmd",
            .cmd_description = "A demo sub command made from a struct.",
            .cmd_group = "STRUCT-BASED",
        }),
        CommandT.from(DemoUnion, .{
            .cmd_name = "union-cmd",
            .cmd_description = "A demo sub command made from a union.",
            .cmd_group = "STRUCT-BASED",
        }),
        CommandT.from(@TypeOf(demoFn), .{
            .cmd_name = "fn-cmd",
            .cmd_description = "A demo sub command made from a function.",
            .cmd_group = "FN-BASED",
        }),
        CommandT.from(ex_structs.add_user, .{
            .cmd_name = "add-user",
            .cmd_description = "A demo sub command for adding a user.",
            .cmd_group = "STRUCT-BASED",
        }),
    },
    .opts = &.{
        .{
            .name = "string_opt",
            .description = "A string option. (Can be given up to 4 times.)",
            .opt_group = "STRING",
            .short_name = 's',
            .long_name = "string",
            .val = ValueT.ofType([]const u8, .{}),
        },
        .{
            .name = "int_opt",
            .description = "An integer option. (Can be given up to 10 times.)",
            .opt_group = "INT",
            .short_name = 'i',
            .long_name = "int",
            .val = ValueT.ofType(i16, .{}),
        },
    },
    .vals = &.{
        ValueT.ofType([]const u8, .{
            .name = "cmd_str",
            .description = "A string value for the command.",
            .val_group = "STRING",
        }),
        ValueT.ofType(bool, .{
            .name = "cmd_bool",
            .description = "A boolean value for the command.",
            .val_group = "BOOL",
        }),
    }
};
```

## Usage & Help Messages
If these groups are used, they will be shown in Usage and Help Messages. Their are two Format fields, `cova.Command.Config.group_title_fmt` and `cova.Command.Config.group_sep_fmt`, that can be used to customize how the groups are displayed.

## Parsing
Argument Groups can be used to mandate certain groups of Options are used by setting the `cova.Command.Custom.mandatory_opt_groups` field.

Example:
```zig
pub const setup_cmd: CommandT = .{
    .name = "covademo",
    .description = "A demo of the Cova command line argument parser.",
    .opt_groups = &.{ "INT", "BOOL", "STRING" },
    .mandatory_opt_groups = &.{ "BOOL" },
    .opts = &.{
        .{
            .name = "cardinal_opt",
            .description = "A cardinal number option.",
            .opt_group = "INT",
            .short_name = 'c',
            .long_name = "cardinal",
            .val = ValueT.ofType(u8, .{}),
        },
        .{
            .name = "toggle_opt",
            .description = "A toggle/boolean option.",
            .opt_group = "BOOL",
            .short_name = 't',
            .long_name = "toggle",
        },
        .{
            .name = "bool_opt",
            .description = "A toggle/boolean option.",
            .opt_group = "BOOL",
            .short_name = 'b',
            .long_name = "bool",
        },
    },
};
```

## Analysis
They can also be used to Get, Check, or Match the Values and Options of a Command. For Options, an Option Group can be passed to `cova.Command.Custom.getOpts`(), `cova.Command.Custom.checkOpt`(), or `cova.Command.Custom.matchOpt`(). For Values, a Value Group can be passed to `cova.Command.Custom.getVals`().
