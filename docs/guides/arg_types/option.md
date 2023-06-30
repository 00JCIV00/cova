# Option
An Option is an Argument type which wraps a Value and is ALWAYS optional. It may have a Short Name (ex: `-h`), a Long Name (ex: `--name "Lilly"`), or both. The prefixes for both Short and Long names can be set by the library user. 

If the wrapped Value has a Boolean type it will default to False and can be set to True using the Option without a following Argument (ex: `-t` or `--toggle`). They also provide `usage()` and `help()` methods similar to Commands.
## Examples:
### Creation:
```
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
