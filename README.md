![cova_icon_v2 1](https://github.com/00JCIV00/cova/assets/68087632/0b485f6b-ddf4-4772-96eb-899d4606f9cc)

# Commands **⋅** Options **⋅** Values **⋅** Arguments 
A simple yet robust cross-platform command line argument parsing library for Zig.

[![Static Badge](https://img.shields.io/badge/v0.12(nightly)-orange?logo=Zig&logoColor=Orange&label=Zig&labelColor=Orange)](https://ziglang.org/download/)
[![Static Badge](https://img.shields.io/badge/v0.9.1b-blue?logo=GitHub&label=Release)](https://github.com/00JCIV00/cova/releases/tag/v0.9.1-beta)
[![GitHub commit activity](https://img.shields.io/github/commits-since/00JCIV00/cova/latest/v0.10.0?include_prereleases&logo=Github&label=Commits%20(v0.10.0b))](https://github.com/00JCIV00/cova/commits/v0.10.0/) 
[![Static Badge](https://img.shields.io/badge/MIT-silver?label=License)](https://github.com/00JCIV00/cova/blob/main/LICENSE)

___

## Overview
Cova is based on the idea that Arguments will fall into one of three types: Commands, Options, or Values. These Types are assembled into a single Command struct which is then used to parse argument tokens. Whether you're looking for simple argument parsing or want to create something as complex as the [`ip`](https://www.man7.org/linux/man-pages/man8/ip.8.html) or [`git`](https://www.man7.org/linux/man-pages/man1/git.1.html) commands, Cova makes it easy.

## Get Started Quickly!
- [Quick Start Guide](https://github.com/00JCIV00/cova/wiki/Getting-Started)
- [Full Wiki Guide](https://github.com/00JCIV00/cova/wiki/)
- [API Docs](https://00jciv00.github.io/cova/#A;cova)

## Features
- **[Comptime Setup](#comptime-setup). [Runtime Use](#runtime-use).**
  - Cova is designed to have Argument Types set up at ***compile time*** so they can be validated during each compilation, thus providing you with immediate feedback.
  - Once validated, Argument Types are initialized to memory for ***runtime*** use where end user argument tokens are parsed then made ready to be analyzed by your code.
- **[Build-time Bonuses](#build-time-bonuses)!** Cova also provides a simple build step to generate Help Docs, Tab Completion Scripts, and Argument Templates at **build-time**!
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
Cova makes it easy to set up your Argument Types at _comptime_ and use the input provided by your end users at _runtime_!

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
        // Usage Ex: `basic-app new -f Bruce -l Wayne -a 40 -p "555 555 5555" -A " 1007 Mountain Drive, Gotham" true`
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
        // Usage Ex: `basic-app open users.csv`
        CommandT.from(@TypeOf(open), .{
            .cmd_name = "open",
            .cmd_description = "Open or create a users file.",
            .cmd_group = "INTERACT",
        }),
        // A manually created Command, same as the parent `setup_cmd`.
        // Usage Ex: `basic-app clean` or `basic-app delete --file users.csv`
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
    var gpa = std.heap.GeneralPurposeAllocator(.{ .verbose_log = builtin.mode == .Debug }){};
    const alloc = gpa.allocator();

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
- [basic-app](./examples/basic_app.zig): Where the above examples come from.
- [covademo](./examples/covademo.zig): This is the testbed for Cova, but its a good demo of virtually every feature in the library.

## Build-time Bonuses
Cova's simple Meta Doc Generator build step lets you quickly and easily generate documents in the following formats based on the Commands you set up at comptime:
- Help Docs:
  - Manpages
  - Markdown
- Tab Completion Scripts:
  - Bash
  - Zsh
  - Powershell
- Argument Templates:
  - JSON
  - KDL
 
```zig
// Within 'build.zig'
pub fn build(b: *std.Build) void {
    // Set up your build variables as normal.

    const cova_dep = b.dependency("cova", .{ .target = target, .optimize = optimize });
    const cova_mod = cova_dep.module("cova");

    // Set up your exe step as you normally would.

    const cova_gen = @import("cova").addCovaDocGenStep(b, cova_dep, exe, .{
        .kinds = &.{ .all },
        .version = "0.10.0",
        .ver_date = "06 APR 2024",
        .author = "00JCIV00",
        .copyright = "MIT License",
    });
    const meta_doc_gen = b.step("gen-meta", "Generate Meta Docs using Cova");
    meta_doc_gen.dependOn(&cova_gen.step);
}
```

## Demo
![cova_demo](./docs/cova_demo.gif)
  
## Alternatives
- [yazap](https://github.com/PrajwalCH/yazap)
- [zig-args](https://github.com/masterQ32/zig-args)
- [zig-clap](https://github.com/Hejsil/zig-clap)
- [zig-cli](https://github.com/sam701/zig-cli)
- [zig-parse-args](https://github.com/winksaville/zig-parse-args)
