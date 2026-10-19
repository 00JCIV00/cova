# Overview
Cova is based on the idea that Arguments will fall into one of three types: Commands, Options, or Values. These types are assembled into a single Command struct which is then used to parse argument tokens.

## Argument Types
### Command
A Command is a container Argument for sub Commands, Options, and Values. It can contain any mix of those Arguments or none at all if it's to be used as a standalone command (for instance `covademo help`). The `checkSubCmd()` and `matchSubCmd()` methods can be used to check for or retrieve the active sub-Command. A HashMap<Name, Value/Option> for Options or Values can be created using either the `getOpts()` or `getVals()` method. Usage and Help statements for a Command can also be generated using the `usage()` and `help()` methods respectively.
#### Example:
```zig
const CommandT = cova.Command.Custom(.{});
const setup_cmd: CommandT = .{
    .name = "covademo",
    .description = "A demo of the Cova command line argument parser.",
    .sub_cmds = &.{
        .{
            .name = "open",
            .description = "Open a file.",
        },
        .{
            .name = "close",
            .description = "Close a file.",
        },
    },
    .opts = &.{},
    .vals = &.{},
};
```

### Option
An Option is an Argument which wraps a Value and is ALWAYS optional. It may have a Short Name (ex: `-h`), a Long Name (ex: `--name "Lilly"`), or both. The prefixes for both Short and Long names can be set by the library user. If the wrapped Value has a Boolean type it will default to False and can be set to True using the Option without a following Argument (ex: `-t` or `--toggle`). They also provide `usage()` and `help()` methods similar to Commands.
#### Example:
```zig
.opts = &.{
    .{
        .name = "string_opt",
        .description = "A string option.",
        .short_name = 's',
        .long_name = "string",
        .val = ValueT.ofType([]const u8, .{
            .name = "stringVal",
            .description = "A string value.",
        }),
    },
    .{
        .name = "int_opt",
        .description = "An integer option.",
        .short_name = 'i',
        .long_name = "int",
        .val = ValueT.ofType(i16, .{
            .name = "intVal",
            .description = "An integer value.",
            .valid_fn = struct{ fn valFn(int: i16, _: std.mem.Allocator) bool { return int < 666; } }.valFn,
        }),
    },
},
```

### Value
A Value (also known as a Positional Argument) is an Argument that is expected in a specific order and should be interpreted as a specific type. The full list of available types can be seen in `cova.Value.Generic` and customized via `cova.Value.Custom`, but the basics are Boolean, String (`[]const u8`), Integer (`u/i##`), or Float (`f##`). A Value will be parsed to its corresponding type and can be retrieved using `get()` (or `getAs()` for a Generic Value). They can also be given a Default value using the `.default_val` field and a Validation Function using the `.valid_fn` field.
#### Example:
```zig
.vals = &.{
    ValueT.ofType([]const u8, .{
        .name = "cmdStr",
        .description = "A string value for the command.",
    }),
    ValueT.ofType(u64, .{
        .name = "cmd_u64",
        .description = "A u64 value for the command.",
        // Default Value
        .default_val = 654321,
        // Validation Function
        .valid_fn = struct{ fn valFn(val: u64, _: std.mem.Allocator) bool { return val > 123456 and val < 987654; } }.valFn,
    }),
},
```

### Parsing
Parsing is handled by the `parseArgs()` function in cova.zig. It takes in an ArgIterator, a Command Type, a pointer to an initialized Command, a Writer, and a ParseConfig, then parses each token sequentially. The results of a successful parse are stored in the provided Command which can then be analyzed by the user.
#### Example:
```zig
pub fn main(init: std.process.Init) !void {
    // Parse Arguments
    const alloc = init.gpa;

    const main_cmd = try setup_cmd.init(alloc, .{});
    defer main_cmd.deinit();

    var args_iter: cova.ArgIteratorGeneric = try .init(alloc, init.minimal.args);
    defer args_iter.deinit();

    var stdout_file = std.Io.File.stdout();
    var stdout_buf: [4096]u8 = undefined;
    var stdout_writer = stdout_file.writer(init.io, stdout_buf[0..]);
    const stdout = &stdout_writer.interface;

    cova.parseArgs(&args_iter, CommandT, main_cmd, stdout, .{}) catch |err| switch (err) {
        error.UsageHelpCalled => return,
        else => return err,
    };

    // Analyze Data
    // - Check for the "help" Sub Command and run its help() method
    if (main_cmd.checkSubCmd("open")) try main_cmd.help(stdout);
    // - Get a HashMap of the Command's Options
    if (main_cmd.opts != null) {
        const opt_map = try main_cmd.getOpts(.{});
        _ = opt_map;
    }
    // - Display the parsed Command
    try cova.utils.displayCmdInfo(CommandT, main_cmd, alloc, stdout, false);
}
```
