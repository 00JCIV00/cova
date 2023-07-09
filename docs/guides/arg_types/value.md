# Value
A Value (also known as a Positional Argument) is an Argument type that is expected in a specific order and should be interpreted as a specific type. The full list of available types can be seen in `src/Value.zig/Generic`, but the basics are Boolean, String (`[]const u8`), Integer (`u/i##`), or Float (`f##`). A single Value can store individual or multiple instances of one of these data types. Values are also used to hold and represent the data held by an Option via the Option's `.val` field. As such, anything that applies to Values is also "inherited" by Options.

## Understanding Generic Values vs Typed Values
The base data for a Value is held within a `cova.Value.Typed` instance. However, to provide flexibility for the cova library and library users, the `cova.Value.Generic` union will wrap any `cova.Value.Typed` and provide access to several common-to-all methods. This allows Values to be handled in a generic manner in cases such as function parameters, function returns, collections, etc. However, if the actual parsed data of the Value is needed, the appropriate `cova.Value.Generic` field must be used. Field names for this union are simply the data type name with the exception of `[]const u8` which is the `.string` field.

## Setting up a Value
Similar to Options, Values are designed to be set up within a Command. Specifically, within a Command's `.vals` field. This can be done using a combination of Zig's Union and Anonymous Struct (Tuple) syntax or by using the `cova.Value.ofType`() function.

Values can be given a Default value using the `.default_val` field as well as an alternate Parsing Function and a Validation Function using the `.parse_fn` and `.valid_fn` fields respectively. An example of how to create an anonymous function for these fields can be seen below. There are also common functions and function builders available within both `cova.Value.ParsingFns` and `cova.Value.ValidationFns`. 

These functions allow for simple and powerful additions to how Values are parsed. For instance, the `true` value for Booleans can be expanded to include more words (i.e. `true = "yes", "y", "on"`), a numeric value can be limited to a certain range of numbers (i.e. `arg > 10 and arg <= 1000`), or an arbitrary string can be converted to something else (i.e. `"eight" = 8`). Moreover, since these functions all follow normal Zig syntax, they can be combined into higher level functions for more complex parsing and validation.

## Additional Info 
Values will be parsed to their corresponding types which can then be retrieved using `get()` for Inidivual Values or `getAll()` for Multi-Values. 

## Example:
```zig
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

