# Parsing
Parsing is handled by the `cova.parseArgs`() function. It takes in a pointer to an ArgIterator (`args`), a Command type (`CommandT`), a pointer to an initialized Command (`cmd`), a Writer (`writer`), and a ParseConfig (`parse_config`), then parses each argument token sequentially. The results of a successful parse are stored in the provided Command (`cmd`) which can then be analyzed by the library user's project code.

Notably, the `cova.parseArgs`() function can return several errorrs, most of which (especially `error.UsageHelpCalled`) can be safely ignored when using the default behavior. This is demonstrated below.

## Default Setup
For the default setup, all that's needed is a pointer to an initialized `cova.ArgIteratorGeneric` (`&args_iter`), the project's Command Type (`CommandT`), a pointer to an initialized Command (`&main_cmd`), a Writer to stdout (`stdout`), and the default `ParseConfig` (`.{}`) as shown here:

```zig
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
    const main_cmd = try setup_cmd.init(alloc, .{}); 
    defer main_cmd.deinit();

    // Argument Iterator
    var args_iter = try cova.ArgIteratorGeneric.init(alloc);
    defer args_iter.deinit();

    // Writer to stdout
    const stdout = std.io.getStdOut().writer();

    // Parse Function
    cova.parseArgs(&args_iter, CommandT, &main_cmd, stdout, .{}) catch |err| switch (err) {
        error.UsageHelpCalled,
        else => return err,
    };
}
```

## Custom Setup
### Choosing an ArgIterator
There are two implementations to choose from within `cova.ArgIteratorGeneric`: `.zig` and `.raw`.
- `.zig`: This implementation uses a `std.process.ArgIterator`, which is the default, cross-platform ArgIterator for Zig. It should be the most common choice for normal argument token parsing since it pulls the argument string from the process and tokenizes it into iterable arguments. Setup is handled by the `.init()` method as shown above.
- `.raw`: This implementation uses the `cova.RawArgIterator` and is intended for testing, but can also be useful parsing externally sourced argument tokens. "Externally sourced" meaning argument tokens that aren't provided by the process from the OS or Shell when the project application is run. It's set up as follows:
```zig
const test_args: []const [:0]const u8 = &.{ "test-cmd", "--string", "opt string 1", "-s", "opt string 2", "--int=1,22,333,444,555,666", "--flo", "f10.1,20.2,30.3", "-t", "val string", "sub-test-cmd", "--sub-s=sub_opt_str", "--sub-int", "21523", "help" }; 
var raw_iter = RawArgIterator{ .args = test_args };
var test_iter = ArgIteratorGeneric.from(raw_iter);
try parseArgs(&test_iter...);
```

#### Tokenization
As mentioned, the `std.process.ArgIterator` tokenizes its arguments automatically. However, if the `cova.RawArgIterator` is needed, then the `cova.tokenizeArgs`() function can be used to convert an argument string (`[]const u8`) into a slice of argument token strings (`[]const []const u8`). This slice can then be provided to `cova.RawArgIterator`. The `cova.TokenizeConfig` can be used to configure how the argument string is tokenized. Example:
```zig
var arena = std.heap.ArenaAllocator.init(testing.allocator);
defer arena.deinit();
const alloc = arena.allocator();
const arg_str = "cova struct-cmd --multi-str \"demo str\" -m 'a \"quoted string\"' -m \"A string using an 'apostrophe'\" 50";
const test_args = try tokenizeArgs(arg_str, alloc, .{});
```

### Creating a Command Type and a Command
As described above, the parsing process relies on the creation of a Command Type and a main Command. The specifics for this can be found under `cova.Command` in the API and the [Command Guide](../arg_types/command) in the Guides.

The basic steps are:
1. Configure a Command Type.
2. Create a comptime-known Command.
3. Initialize the comptime-known Command for runtime-use.

### Setting up a Writer
The Writer is used to output Usage/Help messages to the end user in the event of an error during parsing. The standard is to use a Writer to `stdout` or `stderr` for this as shown above. However, a Writer to a different file can also be used to avoid outputting to the end user as shown here:
```zig
var arena = std.heap.ArenaAllocator.init(testing.allocator);
defer arena.deinit();
const alloc = arena.allocator();

var writer_list = std.ArrayList(u8).init(alloc);
defer writer_list.deinit();
const writer = writer_list.writer();
```

### Parsing Configuration
The `cova.ParseConfig` allows for several configurations pertaining to how argument tokens are parsed.

### Custom Parsing & Validation Functions
#### Parsing Functions
Values and, by extension, Options can be given custom functions for parsing from an argument token to the Value's Child Type. These functions will take precedence over the default parsing and can be given at two levels, directly to the Value and to all Value's with a specific Child Type. Regardless of which level these functions are provided at, they must follow the same general structure. The first parameters must be a `[]const u8` for the argument token and the second must be a `std.mem.Allocator` that will be provided by Cova based on the Allocator given during Command Initialization (though this can be skipped using `_: std.mem.Allocator`). Finally, the Return Type must be an Error Union with the Value's Child Type.

1. `Value.Typed.parse_fn` is the field used to provide a parsing function directly to a Value as it's being set up. This function has the highest priority and is used as follows:
```zig
//Within a Command
.vals = &.{
    ValueT.ofType(bool, .{
        .name = "pos_or_neg",
        .description = "An example boolean that must be set as 'positive' or 'negative'.",
        .parse_fn = struct{
            pub fn parseBool(arg: []const u8, _: std.mem.Allocator) !bool {
                if (std.ascii.eqlIgnoreCase(arg, "positive") return true;
                if (std.ascii.eqlIgnoreCase(arg, "negative") return false;
                else return error.BoolParseError;
            }
        }.parseBool,
    }),
},
```
2. `Value.Config.child_type_parse_fn` is the field used to provide a parsing function to all Value's that have a specific Child Type. These functions rank second in priority, behind `Value.Typed.parse_fn` but ahead of the default parsing. An example can be seen [here](../arg_types/value.md#adding-custom-child-types).

#### Validation Functions
Validation Functions are set up very similarly to Parsing Functions. They differ in that they're used to validate a Value after it's been parsed to its Child Type. As such, their structure differs by requiring the first parameter to be an instance of the Value's Child Type and the Return Type to be an Error Union with a Boolean. Notably, these functions can only be applied directly to a Value.

Example:
```zig
// Within a Command
.opts = &.{
    .{
        .name = "verbosity_opt",
        .description = "Set the CovaDemo verbosity level. (WIP)",
        .short_name = 'v',
        .long_name = "verbosity",
        .val = ValueT.ofType(u4, .{
            .name = "verbosity_level",
            .description = "The verbosity level from 0 (err) to 3 (debug).",
            .default_val = 3,
            .valid_fn = struct{ fn valFn(val: u4, _: mem.Allocator) bool { return val >= 1 and val <= 3; } }.valFn,
        }),
    },
},
```
