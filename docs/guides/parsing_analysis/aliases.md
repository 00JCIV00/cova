# Aliases
Cova allows aliasing in two areas, Commands and Value Child Types.

## Command Aliases
Command aliases are created with the `cova.Command.Custom.alias_names` field and can be used to allow more than one name to be recognized as the same Command. These aliases are validated during initialization to ensure they don't conflict with other Commands or aliases. 

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
};
```

## Value Child Type Aliases
Aliases can also be created for the Child Types of Values, allowing Usage and Help messages to be changed without changing the actual underlying Type. For instance, Value's with a `[]const u8` can be changed to show `string` instead using the following set up:

```zig
.val = ValueT.ofType([]const u8, .{
	.name = "string_val",
	.description = "A string value.",
	.default_val = "A string value.",
	.child_type_alias = "string",
}),

```
