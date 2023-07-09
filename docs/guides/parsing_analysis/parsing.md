# Parsing
Parsing is handled by the `cova.parseArgs()` function. It takes in a pointer to an ArgIterator (`args`), a Command type (`CommandT`), a pointer to an initialized Command (`cmd`), a Writer (`writer`), and a ParseConfig (`parse_config`), then parses each argument token sequentially. The results of a successful parse are stored in the provided Command (`cmd`) which can then be analyzed by the library user's project code.

## Default Setup
For the default setup, all that's needed is a pointer to an initialized `ArgIteratorGeneric` (`&args_iter`), the project's Command Type (`CommandT`), a pointer to an initialized Command (`main_cmd`), a Writer to stdout (`stdout`), and the default `ParseConfig` (`.{}`) as shown here:

```
const cova = @import("cova");

// Command Type
const CommandT = cova.Command.Custom(.{});

// Comptime Setup Command
const setup_cmd: CommandT = .{ ... };

pub fn main() !void {
    // Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    // Command
    // Note, the Command Type and `setup_cmd` are created during comptime before the `main()` function.
    const main_cmd = &(try setup_cmd.init(alloc, .{})); 
    defer main_cmd.deinit();

    // Argument Iterator
    var args_iter = try cova.ArgIteratorGeneric.init(alloc);
    defer args_iter.deinit();

    // Writer to stdout
    const stdout = std.io.getStdOut().writer();

    // Parse Function
    try cova.parseArgs(&args_iter, CommandT, main_cmd, stdout, .{});
}
```

## Custom Setup
### Choosing an ArgIterator
There are two implementations to choose from within `cova.ArgIteratorGeneric`: `.zig` and `.raw`.
- `.zig`: This implementatino uses a `std.process.ArgIterator`, the default, cross-platform ArgIterator for Zig. It should be the most common choice for normal argument token parsing. Setup is handled by the `.init()` method as shown above.
- `.raw`: This implementation uses the `cova.RawArgIterator` and is intended for testing, but can also be useful parsing externally sourced argument tokens. "Externally sourced" meaning argument tokens that aren't provided by the OS or Shell when the project application is run. It's set up as follows:
```
const test_args: []const [:0]const u8 = &.{ "test-cmd", "--string", "opt string 1", "-s", "opt string 2", "--int=1,22,333,444,555,666", "--flo", "f10.1,20.2,30.3", "-t", "val string", "sub-test-cmd", "--sub-s=sub_opt_str", "--sub-int", "21523", "help" }; 
var raw_iter = RawArgIterator{ .args = test_args };
var test_iter = ArgIteratorGeneric.from(raw_iter);
try parseArgs(&test_iter...);
```

### Creating a Command Type and a Command
The specifics for this can be found under `cova.Command` in the API and `Argument Types/Command` in the Guides.

The basic steps are:
1. Configure a Command Type.
2. Create a comptime-known Command.
3. Initialize the comptime-known Command for runtime-use.

### Setting up a Writer
The Writer is used to output error data to the app user in the event of an error during parsing. The standard is to use a Writer to `stdout` or `stderr` for this as shown above. However, a Writer to a different file can also be used to avoid outputting to the app user as shown here:
```
var arena = std.heap.ArenaAllocator.init(testing.allocator);
defer arena.deinit();
const alloc = arena.allocator();

var writer_list = std.ArrayList(u8).init(alloc);
defer writer_list.deinit();
const writer = writer_list.writer();
```

### Parsing Configuration
The `cova.ParseConfig` allows for customization of how argument tokens are parsed. There are 5 customizations available, the details of which can be found under the API documentation in `cova.ParseConfig`.
