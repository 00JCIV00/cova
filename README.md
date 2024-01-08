![cova_icon_v2 1](https://github.com/00JCIV00/cova/assets/68087632/0b485f6b-ddf4-4772-96eb-899d4606f9cc)

# Commands **⋅** Options **⋅** Values **⋅** Arguments 
A simple yet robust cross-platform command line argument parsing library for Zig.

[![Static Badge](https://img.shields.io/badge/v0.12(nightly)-orange?logo=Zig&logoColor=Orange&label=Zig&labelColor=Orange)](https://ziglang.org/download/)
 [![Static Badge](https://img.shields.io/badge/v0.9.1b-blue?logo=GitHub&label=Release)](https://github.com/00JCIV00/cova/releases/tag/v0.9.1-beta)
[![GitHub commit activity](https://img.shields.io/github/commit-activity/m/00JCIV00/cova?logo=GitHub&label=Commits&color=blue)](https://github.com/00JCIV00/cova/commits/main/) 
[![Static Badge](https://img.shields.io/badge/MIT-silver?label=License)](https://github.com/00JCIV00/cova/blob/main/LICENSE)

___

## Overview
Cova is based on the idea that Arguments will fall into one of three types: Commands, Options, or Values. These Types are assembled into a single Command struct which is then used to parse argument tokens. Whether you're looking for simple argument parsing or want to create something as complex as the [`ip`](https://www.man7.org/linux/man-pages/man8/ip.8.html) or [`git`](https://www.man7.org/linux/man-pages/man1/git.1.html) commands, Cova makes it easy.

## Table of Contents
- [Features](#features)
- [Usage](#usage)
  - [Comptime Setup](#comptime-setup)
  - [Runtime Use](#runtime-use)
- [Demo](#demo)
- [Versions & Milestones](#versions--milestones)
- [Documentation](#documentation)
- [Install](#install)
  - [Package Manager](#package-manager)
  - [Demo from source](#build-the-basic-app-demo-from-source)
- [Alternatives](#alternatives)

## Features
- **Comptime Setup. Runtime Use.**
  - Cova is designed to have Argument Types set up at ***compile time*** so they can be validated during each compilation, thus providing you with immediate feedback.
  - Once validated, Argument Types are initialized to memory for ***runtime*** use where end user argument tokens are parsed then made ready to be analyzed by your code.
- **Simple Design:**
  - All argument tokens are parsed to Argument Types: Commands, Options, or Values.
    - Options = _Flags_ and Values = _Positional Arguments_
  - These Argument Types can be *created from* or *converted to* your Structs, Unions, and Functions along with their corresponding Fields and Parameters.
- **Multiplatform.** Tested across common architectures of Linux, Mac, and Windows.
- **Granular, Robust Customization:**
  - [POSIX Compliant](https://www.gnu.org/software/libc/manual/html_node/Argument-Syntax.html) by default, with plenty of ways to configure to whatever standard you'd like.
    - Ex: `command --option option_string "standalone value" subcmd -i 42 --bool`
  - Cova offers deep customization through the Argument Types and several Config Structs. These Types and Structs all provide simple and predictable defaults, allowing library users to only configure what they need.
- [***And much more!***](./docs/README_extended.md#features)

## Usage
Cova makes it easy to both set up your Argument Types at _comptime_ and use the input provided by your end users at _runtime_!

### Comptime Setup
There are two main ways to set up your Argument Types. You can either convert existing Zig Types within your project or create them manually. You can even mix and match these techniques to get the best of both.

```zig
const std = @import("std");
const cova = @import("cova");
pub const CommandT = cova.Command.Base();
pub const OptionT = CommandT.OptionT;
pub const ValueT = CommandT.ValueT;

pub const setup_cmd: CommandT = .{
    .name = "basic-app",
    .description = "A basic user management application designed to highlight key features of the Cova library.",
    .cmd_groups = &.{ "INTERACT", "VIEW" },
    .sub_cmds = &.{
        // A Command created from converting a Struct named `User`.
        CommandT.from(User, .{
            .cmd_name = "new",
            .cmd_description = "Add a new user.",
            .cmd_group = "INTERACT",
            .sub_descriptions = &.{
                .{ "is_admin", "Add this user as an admin?" },
                .{ "first_name", "User's First Name." }, 
                .{ "last_name", "User's Last Name." },
                .{ "age", "User's Age." },
                .{ "phone", "User's Phone #." },
                .{ "address", "User's Address." },
            },
        }),
        // A Command created from a Function named `open`.
        CommandT.from(@TypeOf(open), .{
            .cmd_name = "open",
            .cmd_description = "Open or create a users file.",
            .cmd_group = "INTERACT",
        }),
        // A manually created Command, same as the parent `setup_cmd`.
        CommandT{
            .name = "clean",
            .description = "Clean (delete) the default users file (users.csv) and persistent variable file (.ba_persist).",
            .alias_names = &.{ "delete", "wipe" },
            .cmd_group = "INTERACT",
            .opts = &.{
                OptionT{
                    .name = "clean_file",
                    .description = "Specify a single file to be cleaned (deleted) instead of the defaults.",
                    .alias_long_names = &.{ "delete_file" },
                    .short_name = 'f',
                    .long_name = "file",
                    .val = ValueT.ofType([]const u8, .{
                        .name = "clean_file",
                        .description = "The file to be cleaned.",
                        .alias_child_type = "filepath",
                        .valid_fn = cova.Value.ValidationFns.validFilepath,
                    }),
                },
            },
        },
    }
};
// Continue to the Runtime Use...
```

### Runtime Use
Once Cova has parsed input from your end users it puts that data into the Command you set up. 
You can call various methods on the Command to use that data however you need.

```zig
// ...continued from the Comptime Setup.
pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator;
    defer arena.deinit();
    const alloc = arena.allocator();

    // Initializing the `setup_cmd` with an allocator will make it available for Runtime use.
    const main_cmd = try setup_cmd.init(alloc, .{}); 
    defer main_cmd.deinit();

    // Parsing
    var args_iter = try cova.ArgIteratorGeneric.init(alloc);
    defer args_iter.deinit();
    const stdout = std.io.getStdOut().writer();

    cova.parseArgs(&args_iter, CommandT, &main_cmd, stdout, .{}) catch |err| switch (err) {
        error.UsageHelpCalled,
        error.TooManyValues,
        error.UnrecognizedArgument,
        error.UnexpectedArgument,
        error.CouldNotParseOption => {},
        else => return err,
    };

    // Analysis (Using the data.)
    if (builtin.mode == .Debug) try cova.utils.displayCmdInfo(CommandT, &main_cmd, alloc, &stdout);
    
    // Glossing over some project variables here.

    // Convert a Command back into a Struct.
    if (main_cmd.matchSubCmd("new")) |new_cmd| {
        var new_user = try new_cmd.to(User, .{});
        new_user._id = getNextID();
        try users.append(new_user);
        try users_mal.append(alloc, new_user);
        var user_buf: [512]u8 = .{ 0 } ** 512;
        try user_file.writer().print("{s}\n", .{ try new_user.to(user_buf[0..]) });
        try stdout.print("Added:\n{s}\n", .{ new_user });
    }
    // Convert a Command back into a Function and call it.
    if (main_cmd.matchSubCmd("open")) |open_cmd| {
        user_file = try open_cmd.callAs(open, null, std.fs.File);
    }
    // Get the provided sub Command and check an Option from that sub Command.
    if (main_cmd.matchSubCmd("clean")) |clean_cmd| cleanCmd: {
        if ((try clean_cmd.getOpts(.{})).get("clean_file")) |clean_opt| {
            if (clean_opt.val.isSet()) {
                const filename = try clean_opt.val.getAs([]const u8);
                try delete(filename);
                break :cleanCmd;
            }
        }
        try delete("users.csv");
        try delete(".ba_persist");
    }
}
```

### More Examples
- [Simpler Example](./docs/README_extended.md#quick-setup)
- [basic-app](./examples/basic_app.zig): Where the above examples come from.
- [covademo](./examples/covademo.zig): This is the testbed for Cova, but its a good demo of virtually every feature in the library.

## Demo
![cova_demo](./docs/cova_demo.gif)

## Versions & Milestones
- [v0.7.0-beta](https://github.com/00JCIV00/cova/issues/9)
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

## Alternatives
- [yazap](https://github.com/PrajwalCH/yazap)
- [zig-args](https://github.com/masterQ32/zig-args)
- [zig-clap](https://github.com/Hejsil/zig-clap)
- [zig-cli](https://github.com/sam701/zig-cli)
- [zig-parse-args](https://github.com/winksaville/zig-parse-args)
