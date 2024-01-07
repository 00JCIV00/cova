# cova

Commands, Options, Values, Arguments. A simple yet robust cross-platform command line argument parsing library for Zig.
___

## Overview
Cova is based on the idea that Arguments will fall into one of three types: Commands, Options, or Values. These Types are assembled into a single Command struct which is then used to parse argument tokens. _This extended Readme is the original. It's a bit more verbose, but has addtional information without requiring a search through the Docs and Guides._

## Table of Contents
- [Demo](#demo)
- [Features](#features)
- [Goals](#goals)
  - [Pre-Public Beta Release](#pre-public-beta-release)
  - [Public Beta Release](#public-beta-release)
- [Documentation](#documentation)
- [Install](#install)
  - [Package Manager](#package-manager)
  - [Demo from source](#build-the-basic-app-demo-from-source)
- [Usage](#usage)
  - [Quick Setup](#quick-setup)
  - [Basic Setup](#basic-setup)
  - [Advanced Setup](#advanced-setup)
- [Alternatives](#alternatives)

## Demo
![cova_demo](./docs/cova_demo.gif)

## Features
- **Comptime Setup. Runtime Use.**
  - Cova is designed to have Argument Types set up at ***compile time*** so they can be validated during each compilation, thus providing the library user with immediate feedback.
  - Once validated, Argument Types are initialized to memory for ***runtime*** use where end user argument tokens are parsed then made ready to be analyzed by library user code.
- **Simple Design:**
  - All Argument tokens are parsed to Commands, Options, or Values.
  - These Argument Types can be *created from* or *converted to* Structs, Unions, and Functions along with their corresponding Fields and Parameters.
  - The most Basic Setup requires only Cova imports, a library user Struct, and a few function calls for parsing.
  - POSIX Compliant (as defined [here](https://www.gnu.org/software/libc/manual/html_node/Argument-Syntax.html)) by default.
  - Multiplatform. Tested across:
    - x86-linux
    - x86_64-linux
    - arm-linux
    - aarch64-linux
    - x86_64-windows
    - x86_64-macos
    - *Should support all POSIX compliant systems.*
  - Commands:
    - Contain sub-Commands, Options, and Values.
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
  - Cova offers deep customization through the fields of the Argument Types and the several Config Structs. These Types and Structs all provide simple and predictable defaults, allowing library users to only configure what they need.
  - Parsing:
    - Auto-handle Usage/Help calls.
    - Choose how errors should be reacted to with either a Usage/Help message or no reaction.
    - Decide if Option parsing should be terminated after a standalone long prefix such as `--`.
  - Commands:
    - Configure Templates or Callback Functions for generated Command Help/Usage messages.
    - Set Rules for converting From/To a Struct, Union, or Function.
    - Mandate that a Command takes a sub-Command if available.
    - Mandate all Values be filled.
  - Options:
    - Configure Templates or Callback Functions for generated Option Help/Usage messages.
    - Customize Short and Long prefixes (i.e. `/s` or `__long-opt`).
    - Set the allowed Separator Character(s) between Options and their Values.
    - Allow/Disallow Abbreviated Long Options (i.e `--long-opt` can be `--long`).
  - Values:
    - Create Values with a specific type (Bool, Uint, Int, Float, or String) or even add custom Types.
    - Configure Values to be Individual or Multi, allowing multiple of the same type to be stored in a single Value.
    - Set the allowed Delimiter Characters between data elements provided to a single Value (i.e `my-cmd multi,string,value`).
    - Set the Rules for how Values are *set* through **custom Parsing and Validation Functions!**
  - ***And much more!***_********

## Goals
### Pre Public Beta Release
- [v0.7.0-beta](https://github.com/00JCIV00/cova/issues/9)
### Public Beta Release
- [v0.8.0-beta](https://github.com/00JCIV00/cova/issues?q=milestone%3Av0.8.0-beta)
- [v0.9.0-beta](https://github.com/00JCIV00/cova/issues?q=milestone%3Av0.9.0-beta)
- [v0.10.0-beta](https://github.com/00JCIV00/cova/issues?q=milestone%3Av0.10.0-beta)
  
## Documentation
- [API](https://00jciv00.github.io/cova/#A;cova)
- [Guides](https://00jciv00.github.io/cova/#G;) 

## Install
### Package Manager
1. Find the latest `v#.#.#` commit [here](https://github.com/00JCIV00/cova/commits/main).
2. Copy the full SHA for the commit.
3. Add the dependency to `build.zig.zon`:
```bash
zig fetch --save "https://github.com/00JCIV00/cova/archive/<GIT COMMIT SHA FROM STEP 2 HERE>.tar.gz"
```
4. Add the dependency and module to `build.zig`:
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
exe.root_module.addImport("cova", cova_mod);
```

### Package Manager - Alternative
Note, this method makes Cova easier to update by simply re-running `zig fetch --save https://github.com/00JCIV00/cova/archive/[BRANCH].tar.gz`. However, it can lead to non-reproducible builds because the url will always point to the newest commit of the provided branch. Details can be found in [this discussion](https://ziggit.dev/t/feature-or-bug-w-zig-fetch-save/2565).
1. Choose a branch to stay in sync with. 
- `main` is the latest stable branch.
- The highest `v#.#.#` is the development branch.
2. Add the dependency to `build.zig.zon`:
 ```shell
 zig fetch --save https://github.com/00JCIV00/cova/archive/[BRANCH FROM STEP 1].tar.gz
 ```
3. Continue from Step 4 above.

### Build the Basic-App Demo from source
1. Use the latest Zig (v0.12) for your system. Available [here](https://ziglang.org/download/).
2. Run the following in whichever directory you'd like to install to:
```bash
git clone https://github.com/00JCIV00/cova.git
cd cova
zig build basic-app
```
3. Try it out!
```bash
cd bin
./basic-app help
```

## Usage
The following are a few working examples to get cova integrated into a project quickly. The library contains many more features that can be found in the Documentation section above.

### Quick Setup
- This is a minimum working demo of Cova integrated into a project.
```zig
const std = @import("std");
const cova = @import("cova");
const CommandT = cova.Command.Base();

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

const setup_cmd = CommandT.from(ProjectStruct);

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    const stdout = std.io.getStdOut().writer();

    const main_cmd = try setup_cmd.init(alloc, .{});
    defer main_cmd.deinit();

    var args_iter = try cova.ArgIteratorGeneric.init(alloc);
    defer args_iter.deinit();

    cova.parseArgs(&args_iter, CommandT, &main_cmd, stdout, .{}) catch |err| switch(err) {
        error.UsageHelpCalled,
        else => return err,
    }
    try cova.utils.displayCmdInfo(CommandT, &main_cmd, alloc, stdout);
}
``` 

#### Breakdown
- Imports
```zig
...
// The main cova library module. This is added via `build.zig` & `build.zig.zon` during
// installation.
const cova = @import("cova");
// The Command Type for all Commands in this project.
const CommandT = cova.Command.Base();
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
        // By default, Options will be given a long name and a short name based on the
        // field name. (i.e. int = `-i` or `--int`)
        sub_uint: ?u8 = 5,

        // Primitive type fields will be converted into Values.
        sub_string: []const u8,
    },

    // Struct fields will be converted into cova Commands.
    subcmd: SubStruct = .{},

    // The default values of Primitive type fields will be applied as the default value
    // of the converted Option or Value.
    int: ?i4 = 10,

    // Optional Booleans will become cova Options that don't take a Value and are set to
    // `true` simply by calling the Option's short or long name.
    flag: ?bool = false,

    // Arrays will be turned into Multi-Values or Multi-Options based on the array's
    // child type.
    strings: [3]const []const u8 = .{ "Three", "default", "strings." },
};
...
```

- Creating the Comptime Command.
```zig
...
// `from()` method will convert the above Struct into a Command.
// This must be done at Comptime for proper Validation before Initialization to memory
// for Runtime use.
const setup_cmd = CommandT.from(ProjectStruct);
...
```

- Command Validation and Initialization to memory for Runtime Use.
```zig
...
pub fn main() !void {
    ...

    // The `init()` method of a Command instance will Validate the Command's
    // Argument Types for correctness and distinct names, then it will return a
    // memory allocated copy of the Command for argument token parsing and
    // follow on analysis.
    const main_cmd = try setup_cmd.init(alloc, .{});
    defer main_cmd.deinit();
    
    ...
}
```

- Set up the Argument Iterator.
```zig
pub fn main() {
    ...

    // The ArgIteratorGeneric is used to step through argument tokens.
    // By default (using `init()`), it will provide Zig's native, cross-platform ArgIterator
    // with end user argument tokens. There's also cova's RawArgIterator that can be used to
    // parse any slice of strings as argument tokens.
    var args_iter = try cova.ArgIteratorGeneric.init(alloc);
    defer args_iter.deinit();

    ...
}
```

- Parse argument tokens and Display the result.
```zig
pub fn main() !void {
    ...

    // The `parseArgs()` function will parse the provided ArgIterator's (`&args_iter`)
    // tokens into Argument Types within the provided Command (`main_cmd`).
    try cova.parseArgs(&args_iter, CommandT, &main_cmd, stdout, .{});

    // Once parsed, the provided Command will be available for analysis by the
    // project code. Using `utils.displayCmdInfo()` will create a neat display
    // of the parsed Command for debugging.
    try utils.displayCmdInfo(CommandT, &main_cmd, alloc, stdout);
}
```

### Basic Setup
- [Basic App](./examples/basic_app.zig)
- This is a well-documented example of how to integrate Cova into a basic project and utilize many of its standout features.

### Advanced Setup
- [Advanced Demo](./examples/covademo.zig)
- The `covademo` is a showcase of most of Cova's features. This demo also serves as a test bed for features that are in development, so it's not well-documented in several areas. That said, it can still be a useful reference for how certain features can be used.


## Alternatives
- [yazap](https://github.com/PrajwalCH/yazap)
- [zig-args](https://github.com/masterQ32/zig-args)
- [zig-clap](https://github.com/Hejsil/zig-clap)
- [zig-cli](https://github.com/sam701/zig-cli)
- [zig-parse-args](https://github.com/winksaville/zig-parse-args)
