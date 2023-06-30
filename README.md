# cova
Commands, Options, Values, Arguments. A simple yet robust command line argument parsing library for Zig.
___

## Overview
Cova is based on the idea that Arguments will fall into one of three types: Commands, Options, or Values. These types are assembled into a single Command struct which is then used to parse argument tokens.

## Demo
![cova_demo](./docs/cova_demo.gif)

## Features
- **Comptime Setup. Runtime Use.**
  - Cova is designed to have Argument types set up at Compile Time so they can be validated during each compilation, thus providing the library user with immediate feedback.
  - Once validated, Argument types are initialized to memory for Runtime use where app user arguments are parsed then made ready to be analyzed by library user code.
- **Simple Design:**
  - All Argument tokens are parsed to Commands, Options, or Values.
  - These Argument types can be Created From or Converted To Structs and their corresponding Fields.
  - The most Basic Setup requires only Cova imports, a library user Struct, and a few function calls for parsing.
  - POSIX Compliant (as defined [here](https://www.gnu.org/software/libc/manual/html_node/Argument-Syntax.html)) by default.
  - Multiplatform. Tested across:
    - x86_64-linux
	- aarch64-linux
	- x86_64-windows
	- *Should support all POSIX compliant systems.*
  - Commands:
    - Contain sub Commands, Options, and Values.
    - Precede their Options and Values when parsed (i.e. `command --option opt_val "value"`)
    - Auto-generated Help and Usage message functions that can be invoked as Commands and/or Options (i.e. `command help` or `command -h/--help`)
	- Can be Nested (i.e `main-cmd --main-opt sub-cmd --sub-opt "sub val"`)
  - Options:
    - Wrap Values to make them optional and allow them to be given in any order.
    - Can be given multiple times in any valid format (i.e `--int 1 --int=2 -i 3 -i4`)
	- Can be Delimited (i.e. `-i100,58,80 -f 100.1,84.96,74.58 --bools=true,false,false,true`)
    - Short Options:
  	  - Begin w/ `-`
  	  - Chainable (i.e. `-abc` = `-a -b -c`)
  	  - Variable Separators (i.e. `-c Tokyo` = `-c=Tokyo` = `-cTokyo`)
    - Long Options:
      - Begin w/ `--`
      - Variable Separators (i.e. `--city Tokyo` = `--city=Tokyo`)
      - Can be Abbreviated (i.e. `--long-option` = `--long`)
  - Values:
    - Also known as Positional Arguments.
	- Do not use prefixes (i.e. `command "string value"`)
	- Must be a specific type given in a specific order. (i.e. `command "string_val" 10 true`)
	- Can be given multiple times (i.e. `my-cmd "string val 1" "string val 2" "string val 3"`)
	- Can be Delimited (i.e. `my-cmd 50,100,68`)
- **Granular, Robust Customization:**
  - Cova offers deep customization through the Fields of the Argument types as well as several Config Structs, allowing library users to only configure what they need.
  - Parsing:
  	- Mandate all Values be filled.
	- Customize Separator Character(s) between Options and their Values.
	- Allow/Prevent Abbreviated Long Options.
  - Commands:
	- Customize Templates for auto-generated Command Help/Usage messages.
	- Set Rules for converting From/To a Struct.
  - Options:
	- Customize Templates for Option Help/Usage messages.
    - Customize short and long prefixes (i.e. `/s` or `__long-opt`).
	- Set up the internally wrapped Value.
  - Values:
  	- Create Values with a specific type (Bool, Uint, Int, Float, or String)
    - Configure Values to be Individual or Multi (allowing multiple of the same type to be stored in a single Value).
	- Set the Rules for how Values are Set through custom Parsing and Validation Functions!

## Goals
### Pre Public Release
- [x] Implement basic Argument Parsing for Commands, Options, and Values.
- [x] Advanced Parsing:
  - [x] Handle '=' instead of ' ' between an Option and its Value.
  - [x] Handle the same Option given multiple times. (Currently takes last value.)
  - [x] Handle no space ' ' between a Short Option and its Value.
  - [x] Abbreviated Long Option parsing (i.e. '--long' working for '--long-opt').
- [x] Parsing Customization:
  - [x] Mandate Values be filled.
  - [x] Custom prefixes for Options.
  - [x] Custom separator between Options and Values.
  - [x] Choose behavior for having the same option given multiple times.
  - [x] Choose whether or not to skip the first Argument (the executable's name).
- [x] Setup Features:
  - [x] Set up the build.zig and build.zig.zon for install and use in other codebases.
  - [x] Proper library tests. 
  - [x] Initialization `Custom()` methods for Commands and Options.
    - [x] Setup in Comptime. Use in Runtime.
    - [x] Validate unique sub Commands, Options, and Values.
    - [x] Generate Usage/Help sub Commands.
    - [x] Generate Usage/Help Options.
    - [x] User formatting options for Usage/Help messages.
  - [x] Generate Commands from a struct and vice versa.
    - [x] Compatible nullable fields become Options.
    - [x] Compatible non-nullable fields become Values.

### Post Public Release
- [ ] Pull Argument type metadata via AST Parsing of struct/field comments.
- [ ] Tab Completion (long-term goal).
  
## Documentation
- [API](https://00jciv00.github.io/cova/#A;cova)
- [Guides](https://00jciv00.github.io/cova/#G;) (WIP. Awaiting improvements in the Markdown formatting of Zig's Autodoc feature.)

## Install
### Package Manager
1. Add the dependency to `build.zig.zon`:
```zig
.dependencies = .{
    .cova = .{
        .url = "https://github.com/00JCIV00/cova/archive/5199fec02e34f11ac2b36b91a087f232076eb9fc.tar.gz",
    },
},
```
2. Add the dependency and module to `build.zig`:
```zig
// Cova Dependency
const cova_dep = b.dependency("cova", .{ .target = target });
// Cova Module
const cova_mod = cova_dep.module("cova");
// Executable
const exe = b.addExecutable(.{
    .name = "cova_example",
    .root_source_file = .{ .path = "src/main.zig" },
    .target = target,
    .optimize = optimize,
});
// Add the Cova Module to the Executable
exe.addModule("cova", cova_mod);
```
3. Run `zig build project_exe` to get the hash.
4. Insert the hash into `build.zig.zon`:
```zig
.dependencies = .{
    .cova = .{
        .url = "https://github.com/00JCIV00/cova/archive/5199fec02e34f11ac2b36b91a087f232076eb9fc.tar.gz",
	.hash = "hash from step 3 here",
    },
},
```

### Build the Demo from source
1. Use Zig v0.11 for your system. Available [here](https://ziglang.org/download/).
2. Run the following in whichever directory you'd like to install to:
```bash
git clone https://github.com/00JCIV00/cova.git
cd cova
zig build demo
```
3. Try it out!
```bash
./covademo help
```

## Usage
The following are two working examples to get cova integrated into a project quickly. The library contains many more features that can be found in the Documentation section above.

### Quick Setup
- This is a minimum working demo of Cova integrated into a project.
```zig
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

#### Breakdown
- Imports
```zig
...
// The main cova library module. This is added via `build.zig` & `build.zig.zon` during installation.
const cova = @import("cova");
// The Base Command type. This will be the Command type for all Commands in this project.
const BaseCommand = cova.Command.Base();
// Utilities. This module has a helper function that will display the result of a successfully parsed Command and all of its sub Arguments.
const utils = cova.utils;
...
```

- A Valid Project Struct. The rules for what makes a Valid struct and how they're converted into Commands can be found in the API Documentation under `cova.Command.Custom.from()`.
```zig
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
```zig
...
// `from()` method will convert the above Struct into a Command.
// This must be done at Comptime for proper Validation before Initialization to memory for Runtime use.
const setup_cmd = BaseCommand.from(ProjectStruct);
...
```

- Command Validation and Initialization to memory for Runtime Use.
```zig
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
```zig
pub fn main() {
	...

	// The ArgIteratorGeneric is used to step through argument tokens. By default (using `init()`), it will provide Zig's native, cross-platform ArgIterator with app user argument tokens. There's also cova's RawArgIterator that can be used to parse any slice of strings as argument tokens.
    var args_iter = try cova.ArgIteratorGeneric.init(alloc);
    defer args_iter.deinit();
	...
}
```

- Parse argument tokens and Display the result.
```zig
pub fn main() !void {
	...

	/// The `parseArgs()` function will parse the provided ArgIterator's (`&args_iter`) tokens into Argument types within the provided Command (`main_cmd`).
    try cova.parseArgs(&args_iter, BaseCommand, main_cmd, stdout, .{});
	/// Once parsed, the provided Command will be available for analysis by the project code. Using `utils.displayCmdInfoi()` will create a neat display of the parsed Command for debugging.
    try utils.displayCmdInfo(BaseCommand, main_cmd, alloc, stdout);
}
```

### Adding in Metadata and Advanced Features:
- Import the required modules from the Cova Library. This time creating a Custom Command.
```zig
const std = @import("std");
const cova = @import("cova");

// Using Command.Custom() allows for custom configurations that apply to all Commands of this type, which will usually mean all Commands within a project.
const CustomCommand = cova.Command.Custom(.{
	// The Global Help Prefix of this Command Type will be used as the default prefix for the auto-generated Help and Usage messages of a Command and all of its Sub Commands.
	.global_help_prefix = "CovaDemo w/ Advanced Features",
	// The Sub Commands Help Format changes how Sub Commands are listed in Help auto-generated Help messages. There are similar fields for Options and Values as well as all of their corresponding Usage messages.
	.subcmds_help_fmt = "'{s}' -> {s}",
});
const Value = cova.Value;
const utils = cova.utils;
```

- Create a Command directly in comptime. This will allow for more granular configuration of the Command and its sub Argument types.
```zig
const setup_cmd: CustomCommand = .{
    // The Name of the Command is what app users will use. Similar fields exist for Options and Values as well.
	.name = "cova_demo",
	// The Description of the Command will be displayed in the auto-generated Help message. Similar fields exist for Options and Values as well.
    .description = "A demo of a few of the advanced features in the Cova Library.",

	// The `sub_cmds` field is a slice of all of the Sub Commands of this Command.
    .sub_cmds = &.{
        .{
            .name = "hello-cova",
            .description = "Hello from Cova!",
        },
    },

	// The `opts` field is a slice of all of the Options of this Command.
    .opts = &.{
        .{
            .name = "string_opt",
            .description = "This is a string Option. It will be validated to ensure the argument length is less than 10.",
            .short_name = 's',
            .long_name = "string",
            .val = Value.ofType([]const u8, .{
                .name = "string_opt_val",
                .description = "This is the Option's wrapped Value. It will handle the validation.",
				// Validation Functions are a powerful feature to ensure app user input matches what a project expects. Parsing Functions similarly allow a library user to customize how an argument token is parsed into a specific type.
                .valid_fn = struct { fn lessThanTen(arg: []const u8) bool { return arg.len < 10; } }.lessThanTen,
            }),
        },
    },

	// The `vals` field is a slice of all of the Values of this Command.
    .vals = &.{
        Value.ofType(i16, .{
            .name = "int_val",
            .description = "This is an integer Value. It can be set/used up to 5 times.",
			// The Set Behavior determines what happens when an app user attempts to use an Option or Value multiple times.
            .set_behavior = .Multi,
            .max_args = 5,
        }),
    },
};
```

- The `main()` function is pretty close to before, but now the `parseArgs()` function has been configured with additional options.
```zig
pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    const stdout = std.io.getStdOut().writer();

    const main_cmd = &(try setup_cmd.init(alloc, .{}));
    defer main_cmd.deinit();

    var args_iter = try cova.ArgIteratorGeneric.init(alloc);
    defer args_iter.deinit();

    try cova.parseArgs(&args_iter, CustomCommand, main_cmd, stdout, .{
		// This effectively makes Values optional, but when provided they must still appear in the correct order.
		.vals_mandatory = false,
		// This will determine which characters are valid to separate an Option from its Value.
		.opt_val_seps = "=.^",
		// This will disallow the abbreviation of Long Options.
		.allow_abbreviated_long_opts = false, 
	});
    try utils.displayCmdInfo(CustomCommand, main_cmd, alloc, stdout);
}
``` 

#### Putting it all together
```zig
const std = import("std");
const CustomCommand = cova.Command.Custom(.{
	.global_help_prefix = "CovaDemo w/ Advanced Features",
	.subcmds_help_fmt = "'{s}' -> {s}",
});
const Value = cova.Value;
const utils = cova.utils;

const setup_cmd: CustomCommand = .{
    .name = "cova_demo",
    .description = "A demo of a few of the advanced features in the Cova Library.",
    .sub_cmds = &.{
        .{
            .name = "hello-cova",
            .description = "Hello from Cova!",
        },
    },
    .opts = &.{
        .{
            .name = "string_opt",
            .description = "This is a string Option. It will be validated to ensure the argument length is less than 10.",
            .short_name = 's',
            .long_name = "string",
            .val = Value.ofType([]const u8, .{
                .name = "string_opt_val",
                .description = "This is the Option's wrapped Value. It will handle the validation.",
                .valid_fn = struct { fn lessThanTen(arg: []const u8) bool { return arg.len < 10; } }.lessThanTen,
            }),
        },
    },
    .vals = &.{
        Value.ofType(i16, .{
            .name = "int_val",
            .description = "This is an integer Value. It can be set/used up to 5 times.",
            .set_behavior = .Multi,
            .max_args = 5,
        }),
    },
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    const stdout = std.io.getStdOut().writer();

    const main_cmd = &(try setup_cmd.init(alloc, .{}));
    defer main_cmd.deinit();

    var args_iter = try cova.ArgIteratorGeneric.init(alloc);
    defer args_iter.deinit();

    try cova.parseArgs(&args_iter, CustomCommand, main_cmd, stdout, .{
		.vals_mandatory = false,
		.opt_val_seps = "=.^",
		.allow_abbreviated_long_opts = false, 
	});
    try utils.displayCmdInfo(CustomCommand, main_cmd, alloc, stdout);
}
``` 
