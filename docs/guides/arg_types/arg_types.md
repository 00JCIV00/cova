# Overview
Cova is based on the idea that Arguments will fall into one of three types: Commands, Options, or Values. These types are assembled into a single Command struct which is then used to parse argument tokens.

## Argument Types
### Command
A Command is a container Argument for sub Commands, Options, and Values. It can contain any mix of those Arguments or none at all if it's to be used as a standalone command (for instance `covademo help`). The [`checkCmd()`](`cova.Command.Custom.checkCmd`) A HashMap<Name, Value/Option> for Options or Values can be created using either the `getOpts()` or `getVals()` method. Usage and Help statements for a Command can also be generated using the `usage()` and `help()` methods respectively.
#### Example:
```zig
const cmd = try alloc.create(Command);
cmd.* = .{
    .name = "covademo",
    .help_prefix = "CovaDemo",
    .description = "A demo of the Cova command line argument parser.",
    .sub_cmds = subCmdsSetup: { 
        var setup_cmds = [_]*const Command{
            &Command{
                .name = "help",
                .help_prefix = "CovaDemo",
                .description = "Show the CovaDemo help display.",
            },
            &Command{
                .name = "usage",
                .help_prefix = "CovaDemo",
                .description = "Show the CovaDemo usage display.",
            },
        };
        break :subCmdsSetup setup_cmds[0..];
    },
    .opts = { ... },
    .vals = { ... }
}
defer alloc.destroy(cmd);
```

### Option
An Option is an Argument which wraps a Value and is ALWAYS optional. It may have a Short Name (ex: `-h`), a Long Name (ex: `--name "Lilly"`), or both. The prefixes for both Short and Long names can be set by the library user. If the wrapped Value has a Boolean type it will default to False and can be set to True using the Option without a following Argument (ex: `-t` or `--toggle`). They also provide `usage()` and `help()` methods similar to Commands.
#### Example:
```zig
.opts = optsSetup: {
    var setup_opts = [_]*const Option{
        &Option{
            .name = "stringOpt",
            .short_name = 's',
            .long_name = "stringOpt",
            .val = &Value.init([]const u8, .{
                .name = "stringVal",
                .description = "A string value.",
            }),
            .description = "A string option.",
        },
        &Option{
            .name = "intOpt",
            .short_name = 'i',
            .long_name = "intOpt",
            .val = &Value.init(i16, .{
                .name = "intVal",
                .description = "An integer value.",
                .val_fn = struct{ fn valFn(int: i16) bool { return int < 666; } }.valFn
            }),
            .description = "An integer option.",
        },
        &Option{
            .name = "help",
            .short_name = 'h',
            .long_name = "help",
            .val = &Value.init(bool, .{
                .name = "helpFlag",
                .description = "Flag for help!",
            }),
            .description = "Show the CovaDemo help display.",
        },
    };
    break :optsSetup setup_opts[0..];
},
```

### Value
A Value (also known as a Positional Argument) is an Argument that is expected in a specific order and should be interpreted as a specific type. The full list of available types can be seen in `src/Value.zig/Generic`, but the basics are Boolean, String (`[]const u8`), Integer (`u/i##`), or Float (`f##`). A Value will be parsed to its corresponding type and can be retrieved using `get()`. They can also be given a Default value using the `.default_val` field and a Validation Function using the `.val_fn` field.
#### Example:
```zig
.vals = valsSetup: {
    var setup_vals = [_]*const Value.Generic{
        &Value.init([]const u8, .{
            .name = "cmdStr",
            .description = "A string value for the command.",
        }),
        &Value.init(u128, .{
            .name = "cmd_u128",
            .description = "A u128 value for the command.",
            // Default Value
            .default_val = 654321,
            // Validation Function
            .val_fn = struct{ fn valFn(val: u128) bool { return val > 123456 and val < 987654; } }.valFn,
        }),
    };
    break :valsSetup setup_vals[0..];
}
```

### Parsing
Parsing is handled by the `parseArgs()` function in cova.zig. It takes in an ArgIterator, a Command, and a Writer, then parses each token sequentially. The results of a successful parse are stored in the provided Command which can then be analyzed by the user.
#### Example:
```zig
pub fn main() !void {
    // Parse Arguments
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const cmd = try alloc.create(Command);
    cmd.* = .{ ... };
    defer alloc.destroy(cmd);

    const args = try proc.argsWithAllocator(alloc);
    try cova.parseArgs(&args, cmd, stdout);
    
    // Analyze Data
    // - Check for the "help" Sub Command and run its help() method
    if (cmd.sub_cmd != null and std.mem.eql(u8, cmd.sub_cmd.?.name, "help")) try cmd.help(stdout);
    // - Get a HashMap of the Command's Options
    if (cmd.opts != null) {
        var opt_map: StringHashMap(*const Option) = try cmd.getOpts(alloc);
        defer opt_map.deinit();
    }
    // - Print out all of the Command's Values
    for (cmd.vals orelse return) |val| {
        switch (meta.activeTag(val.*)) {
            .string => {
                std.debug.print("    Val: {?s}, Data: {s}\n", .{
                    val.name(),
                    val.string.get() catch "",
                });
            },
            inline else => |tag| {
                std.debug.print("    Val: {?s}, Data: {any}\n", .{
                    val.name(),
                    @field(val, @tagName(tag)).get() catch null,
                });
            },
        }
    }
}
```
