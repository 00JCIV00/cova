# Value
A Value (also known as a Positional Argument) is an Argument type that is expected in a specific order and should be interpreted as a specific type. The full list of available types can be seen in `src/Value.zig/Generic`, but the basics are Boolean, String (`[]const u8`), Integer (`u/i##`), or Float (`f##`). 

Values will be parsed to their corresponding types which can then be retrieved using `get()`. They can also be given a Default value using the `.default_val` field as well as an alternate Parsing Function and a Validation Function using the `.parse_fn` and `.valid_fn` fields respectively.

## Examples:
### Creation:
```
// Within a Command
...
.vals = &.{
	// Two ways to create directly
	// Using `ofType()`
    Value.ofType([]const u8, .{
        .name = "str_val",
        .description = "A string value for the command.",
    }),
	// Using Zig's union creation syntax
    .{ .u128, .{
        .name = "cmd_u128",
        .description = "A u128 value for the command.",
        // Default Value
        .default_val = 654321,
        // Validation Function
        .valid_fn = struct{ fn valFn(val: u128) bool { return val > 123 and val < 987654321; } }.valFn,
    } },
}
```

