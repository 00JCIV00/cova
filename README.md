# cova
Commands, Options, Values, Arguments. A simple command line argument parsing library for Zig.
___

## Overview
Cova is based on the idea that Arguments will fall into one of three categories: Commands, Options, or Values. These componenets are assembled into a single struct which is then used to parse argument tokens.

## Demo
![cova_demo](./docs/cova_demo.gif)

## Goals
- [x] Implement basic Argument Parsing for Commands, Options, and Values.
- [ ] Advanced Parsing:
  - [x] Handle '=' instead of ' ' between an Option and its Value.
  - [ ] Handle the same Option given multiple times. 
  - [ ] Tab Completion (long-term goal).
- [ ] Parsing Customization:
  - [ ] Mandate Values be filled.
  - [ ] Custom prefixes for Options.
  - [ ] Custom separator between Options and Values. (Currently accepts ' ' or '=').
  - [ ] Choose behavior for having the same option given multiple times.
  - [ ] Choose whether or not to skip the first Argument (the executable's name).
- [ ] Setup Features:
  - [ ] Set up the build.zig and build.zig.zon for install and use in other codebases.
  - [ ] Initialization methods for Commands and Options.
    - [ ] Validate unique sub Commands, Options, and Values.
    - [ ] Generate Usage/Help sub Commands.
    - [ ] Generate Usage/Help Options.
    - [ ] User formatting options for Usage/Help messages.
  - [ ] Generate Commands from a struct and vice versa.
    - [ ] Compatible nullable fields become Options.
    - [ ] Compatible non-nullable fields become Values.
  
## Documentation
[Docs](https://00jciv00.github.io/cova/#A;cova)

## Install
### Package Manager
(WIP) Will use the Zig Package Manager in Zig v0.11.

### Build the Demo from source
1. Use Zig v0.11 for your system. Available [here](https://ziglang.org/download/).
2. Run the following in whichever directory you'd like to install to:
```bash
git clone https://github.com/00JCIV00/cova.git
cd cova
zig build-exe -O ReleaseSafe covademo.zig
```
3. Try it out!
```bash
./covademo help
```

## Usage
### Command
A Command is a container Argument for sub Commands, Options, and Values. It can contain any mix of those Arguments or none at all if it's to be used as a standalone command (for instance `covademo help`). A HashMap<Name, Value/Option> for Options or Values can be created using either the `getOpts()` or `getVals()` method. Usage and Help statements for a Command can also be generated using the `usage()` and `help()` methods respectively.
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
An Option is an Argument which wraps a Value and is ALWAYS optional. In the current implementation, an Option may have a Short Name (ex: `-h`), a Long Name (ex: `--name "Lilly"`), or both. If the wrapped Value has a Boolean type it will default to False and can be set to True using the Option without a following Argument (ex: `-t` or `--toggle`). They also provide `usage()` and `help()` methods similar to Commands.
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
A Value (also known as a Positional Argument) is an Argument that is expected in a specific order and should be interpreted as a specific type. The full list of available types can be seen in src/Value.zig/Generic, but the basics are Boolean, String ([]const u8), Integer (u/i##), or Float (f##). A Value will be parsed to its corresponding type and can be retrieved using `get()`. They can also be given a Default value using the `.default_val` field and a Validation Function using the `.val_fn` field.
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
