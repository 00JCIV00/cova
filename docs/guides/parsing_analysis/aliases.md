# Aliases
Cova allows aliasing in two areas: Commands & Options and Value Child Types.

## Command & Option Aliases
Command aliases are created with the `cova.Command.Custom.alias_names` field and can be used to allow more than one name to be recognized as the same Command. Similarly, Option aliases are created with the `cova.Option.Custom.alias_long_names` field and can be used to allow more than one long name to be recognized as the same Option. These aliases are validated during initialization to ensure they don't conflict with other Commands/Options or their respective aliases. 

Example:
```zig
pub const setup_cmd: CommandT = .{
    .name = "covademo",
    .description = "A demo of the Cova command line argument parser.",
    .sub_cmds = &.{
        .{
            .name = "sub-cmd",
            .description = "A demo sub command.",
            .alias_names = &.{ "alias-cmd", "test-alias" },
        }
    },
    .opts = &.{
        .{
            .name = "toggle_opt",
            .description = "A toggle/boolean option.",
            .short_name = 't',
            .long_name = "toggle",
            .alias_long_names = &.{ "switch", "bool" },
        },
    }
};
```

## Value Child Type Aliases
Aliases can also be created for the Child Types of Values, allowing Usage and Help messages to be changed without changing the actual underlying Type. This can be done with either `cova.Value.Typed.alias_child_type` for a single Value or `cova.Value.Config.child_type_aliases` for all Values with a specific Child Type. For instance, Values with a `[]const u8` can be changed to show `text` instead using the following set up:
```zig
pub const CommandT = cova.Command.Custom(.{
    .val_config = .{
        .child_type_aliases = &.{
            .{
                .ChildT = []const u8,
                .alias = "text",
            },
        },
    },
});
```

Or a single Value with a Child Type of `i8` can be changed to show `number` like so:
```zig
.val = ValueT.ofType(i8, .{
    .name = "num_val",
    .description = "A number value.",
    .default_val = 42,
    .alias_child_type = "number",
}),
```
