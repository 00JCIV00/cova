# Value
A Value (also known as a Positional Argument) is an Argument Type that is expected in a specific order and should be interpreted as a specific Type. The full list of available Types can be seen in `cova.Value.Generic` and customized via `cova.Value.Custom`, but the basics are Boolean, String (`[]const u8`), Integer (`u/i##`), or Float (`f##`). A single Value can store individual or multiple instances of one of these Types. Values are also used to hold and represent the data held by an Option via the `cova.Option.Custom.val` field. As such, anything that applies to Values is also "inherited" by Options.

## Understanding Typed vs Generic vs Custom Values
The base data for a Value is held within a `cova.Value.Typed` instance. However, to provide flexibility for the cova library and library users, the `cova.Value.Generic` union will wrap any `cova.Value.Typed` and provide access to several common-to-all methods. This allows Values to be handled in a generic manner in cases such as function parameters, function returns, collections, etc. However, if the actual parsed data of the Value is needed, the appropriate `cova.Value.Generic` field must be used. Field names for this union are simply the Value's Child Type name with the exception of `[]const u8` which is the `.string` field.

Finally, the `cova.Value.Custom` sets up and wraps `cova.Value.Generic` union. This Type is used similary to `cova.Command.Custom` and `cova.Option.Custom`. It allows common-to-all properties of Values within a project to be configured and provides easy methods for accessing properties of individual Values. 

## Configuring a Value Type
This process mirrors that of Option Types nearly one-for-one. A `cova.Value.Config` can be configured directly within the Command Config via the `cova.Command.Config.val_config` field. If not configured, the defaults will be used. A major feature of the Custom Value Type and Generic Value Union combination is the ability to set custom types for the Generic Value Union. This is accomplished via the `cova.Value.Config`, by setting the `cova.Value.Config.custom_types` field.

## Setting up a Value
Similar to Options, Values are designed to be set up within a Command. Specifically, within a Command's `cova.Command.Custom.vals` field. This can be done using a combination of Zig's Union and Anonymous Struct (Tuple) syntax or by using the `cova.Value.ofType`() function.

Values can be given a Default value using the `cova.Value.Typed.default_val` field as well as an alternate Parsing Function and a Validation Function using the `cova.Value.Typed.parse_fn` and `cova.Value.Typed.valid_fn` fields respectively. An example of how to create an anonymous function for these fields can be seen below. There are also common functions and function builders available within both `cova.Value.ParsingFns` and `cova.Value.ValidationFns`. 

These functions allow for simple and powerful additions to how Values are parsed. For instance, the `true` value for Booleans can be expanded to include more words (i.e. `true = "yes", "y", "on"`), a numeric value can be limited to a certain range of numbers (i.e. `arg > 10 and arg <= 1000`), or an arbitrary string can be converted to something else (i.e. `"eight" = 8`). Moreover, since these functions all follow normal Zig syntax, they can be combined into higher level functions for more complex parsing and validation. Finally, the custom parsing functions in particular allow Custom Types to be parsed directly from a given argument token. Foe example, converting a given filepath into a `std.fs.File`.

## Additional Info 
Values will be parsed to their corresponding types which can then be retrieved using `get()` for Inidivual Values or `getAll()` for Multi-Values. 

## Example:
```zig
// Within a Command
...
.vals = &.{
    Value.ofType([]const u8, .{
        .name = "str_val",
        .description = "A string value for the command.",
    }),
	// Using Zig's union creation syntax
    .{ .generic = .{ .u128, .{
        .name = "cmd_u128",
        .description = "A u128 value for the command.",
        // Default Value
        .default_val = 654321,
        // Validation Function
        .valid_fn = struct{ fn valFn(val: u128) bool { return val > 123 and val < 987654321; } }.valFn,
    } } },
}
```

