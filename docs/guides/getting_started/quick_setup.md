# Quick Setup
- This is a minimum working demo of Cova integrated into a project.

```
const std = @import("std");
const cova = @import("cova");
const BaseCommand = cova.Command.Base();
const utils = cova.utils;

pub const ProjectStruct = struct {
	pub const SubStruct = struct {
		sub_uint: ?u8 = 5,
		sub_string: []const u8,
	},

	subcmd: SubStruct = .{},
	int: ?i4 = 10,
	flag: ?bool = false,
	strings: [3]const []const u8 = .{ "Three", "default", "strings." },
};

const setup_cmd = BaseCommand.from(ProjectStruct);

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    const stdout = std.io.getStdOut().writer();

    const main_cmd = &(try setup_cmd.init(alloc, .{}));
    defer main_cmd.deinit();

    var args_iter = try cova.ArgIteratorGeneric.init(alloc);
    defer args_iter.deinit();

    try cova.parseArgs(&args_iter, BaseCommand, main_cmd, stdout, .{});
    try utils.displayCmdInfo(BaseCommand, main_cmd, alloc, stdout);
}
``` 

## Breakdown
- Imports
```
...
// The main cova library module. This is added via `build.zig` & `build.zig.zon` during installation.
const cova = @import("cova");
// The Base Command type. This will be Command type for all Commands in this project.
const BaseCommand = cova.Command.Base();
// Utilities. This module has a helper function that will display the result of a successfully parsed Command and all of its sub Arguments.
const utils = cova.utils;
...
```

- A Valid Project Struct. The rules for what makes a Valid struct and how they're converted into Commands can be found in the API Documentation under `cova.Command.Custom.from()`.
```
...
// This comptime struct is valid to be parsed into a cova Command.
pub const ProjectStruct = struct {
	// This nested struct is also valid.
	pub const SubStruct = struct {
		// Optional Primitive type fields will be converted into cova Options.
		// By default, Options will be given a long name and a short name based on the field name. (i.e. int = `-i` or `--int`)
		sub_uint: ?u8 = 5,
		// Primitive type fields will be converted into Values.
		sub_string: []const u8,
	},

	// Struct fields will be converted into cova Commands.
	subcmd: SubStruct = .{},
	// The default values of Primitive type fields will be applied as the default value of the converted Option or Value.
	int: ?i4 = 10,
	// Optional Booleans will become cova Options that don't take a Value and are set to true simply by calling the Option's short or long name.
	flag: ?bool = false,
	// Arrays will be turned into Multi-Values or Multi-Options based on the array's child type.
	strings: [3]const []const u8 = .{ "Three", "default", "strings." },
};
...
```

- Creating the Comptime Command.
```
...
// `from()` method will convert the above Struct into a Command.
// This must be done at Comptime for proper Validation before Initialization to memory for Runtime use.
const setup_cmd = BaseCommand.from(ProjectStruct);
...
```

- Command Validation and Initialization to memory for Runtime Use.
```
...
pub fn main() !void {
	...

	// The `init()` method of a Command instance will Validate the Command's Argument Types for correctness and distinct names, then it will return a memory allocated copy of the Command for argument token parsing and follow on analysis.
    const main_cmd = &(try setup_cmd.init(alloc, .{}));
    defer main_cmd.deinit();
	
	...
}
```

- Set up the Argument Iterator.
```
pub fn main() {
	...

	// The ArgIteratorGeneric is used to step through argument tokens. By default (using `init()`), it will provide Zig's native, cross-platform ArgIterator with app user argument tokens. There's also cova's RawArgIterator that can be used to parse any slice of strings as argument tokens.
    var args_iter = try cova.ArgIteratorGeneric.init(alloc);
    defer args_iter.deinit();
	...
}
```

- Parse argument tokens and Display the result.
```
pub fn main() !void {
	...

	/// The `parseArgs()` function will parse the provided ArgIterator's (`&args_iter`) tokens into Argument types within the provided Command (`main_cmd`).
    try cova.parseArgs(&args_iter, BaseCommand, main_cmd, stdout, .{});
	/// Once parsed, the provided Command will be available for analysis by the project code. Using `utils.displayCmdInfoi()` will create a neat display of the parsed Command for debugging.
    try utils.displayCmdInfo(BaseCommand, main_cmd, alloc, stdout);
}
```
