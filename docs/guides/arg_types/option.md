# Option
An Option is an Argument type which wraps a Value and is ALWAYS optional. They should be used for Values that an end user is not always expected to provide. Additionally, unlike Values, they can be expected in any order since they are set by name.

## Configuring an Option Type
Similar to Commands, an Option Type should be configured before any Options are created. Fortunately, the process is virtually the same as with Command Types and both configurations are designed to be done simultaneously. The standard way to configure an Option Type is by configuring the `cova.Command.Config.opt_config` field during Command Type configuration. This field is a `cova.Option.Config` and works effectively the same way as its Command counterpart. If the field is not configured it will be set to the default configuration. Done this way, the Option Type will be a part of the Command Type and will have access to all of the respective functions and methods within `cova.Option.Custom`().

## Setting up an Option
The most straight forward way to set up an Option is to simply use Zig's standard syntax for filling out a struct. More specifically, Options can bet set up within the `opts` field of a Command using Anonymous Struct (or Tuple) syntax. Similarly, an Option's internal Value can also be set up this way via the Option's `val` field.

Alternatively, Options will be created automatically when using `cova.Command.Custom.from`().

## Additional Info
An Option must have a Short Name (ex: `-h`), a Long Name (ex: `--name "Lilly"`), or both. The prefixes for both Short and Long names are set by the library user during a normal setup. If the wrapped Value of an Option has a Boolean type it will default to False and can be set to True using the Option without a following argument token from the end user (ex: `-t` or `--toggle`). They also provide `usage()` and `help()` methods similar to Commands.

## Example:
```zig
// Within a Command
...
.opts = &.{
    .{
        .name = "string_opt",
        .description = "A string option.",
        .short_name = 's',
        .long_name = "string",
        .val = Value.init([]const u8, .{
            .name = "stringVal",
            .description = "A string value.",
        }),
    },
    .{
        .name = "int_opt",
        .description = "An integer option.",
        .short_name = 'i',
        .long_name = "int",
        .val = &Value.init(i16, .{
            .name = "int_opt_val",
            .description = "An integer option value.",
            .val_fn = struct{ fn valFn(int: i16) bool { return int < 666; } }.valFn
        }),
    },
},
```
