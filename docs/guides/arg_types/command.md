# Command
A Command is a container Argument Type for sub-Commands, Options, and Values. It can contain any mix of those Argument Types or none at all if it's to be used as a standalone Command (i.e. `covademo help`). 

## Configuring a Command Type
Before a Command is used within a project, a Command Type should be configured. A Command Type is used to set common-to-all properties of each Command created from it. Typically, this will cover the main Command of a project and all of its sub-Commands. The easiest way to configure a Command Type is to simply use `cova.Command.Base`() which is the default Command Type. To configure a custom Command Type, use `cova.Command.Custom`() with a `cova.Command.Config` (`config`) which provides several customizations to set up the Option Type, Value Type, Help/Usage messages, Mandatory sub-Commands/Values, and max sub Arguments. Once configured, the Command Type has access to all of the functions under `cova.Command.Custom` and any Command created from the Command Type similarly has access to all of the corresponding methods.

## Setting up a Command
Commands are meant to be set up in Comptime and used in Runtime. This means that the Command and all of its subordinate Arguments (Commands, Options, and Values) should be Comptime-known, allowing for proper Validation which provides direct feedback to the library user during compilation instead of preventable errors to the end user during Runtime. 

There are two ways to set up a Command. The first is to use Zig's standard syntax for creating a struct instance and fill in the fields of the previously configured Command Type. Alternatively, if the project has a Struct, Union, or Function Type that can be represented as a Command, the `cova.Command.Custom.from`() function can be used to create the Command.

After they're set up, Commands should be Validated and Allocated to the heap for Runtime use. This is accomplished using `cova.Command.Custom.init()`. At this point, the data within the Command should be treated as read-only by the libary user, so the library is set up to handle initialized Commands as constants (`const`).

## Additional Info
For easy analysis, parsed Commands can be converted to valid Structs or Unions using the `cova.Command.Custom.to`() function, or called as Functions using the `cova.Command.Custom.callAs`() function. Other functions for analysis include creating a String HashMap<Name, Value/Option> for Options or Values using the respective `cova.Command.Custom.getOpts`() or `cova.Command.Custom.getVals`() methods, and using the `cova.Command.Custom.checkFlag`() method to simply check if a sub-Argument was set. Usage and Help statements for a Command can also be generated using the `cova.Command.Custom.usage`() and `cova.Command.Custom.help`() methods respectively.

## Example:
```zig
...
pub const cova = @import("cova");
pub const CommandT = cova.Command.Custom(.{ global_help_prefix = "CovaDemo" });

// Comptime Setup
const setup_cmd: CommandT = .{
    .name = "covademo",
    .description = "A demo of the Cova command line argument parser.",
    .sub_cmds = &.{
        .{
            .name = "sub_cmd",
            .description = "This is a Sub Command within the 'covademo' main Command.",
        },
        command_from_elsewhere,
        CommandT.from(SomeValidStructType),
    }
    .opts = { ... },
    .vals = { ... }
}

pub fn main() !void {
    ...
    // Runtime Use
    const main_cmd = try setup_cmd.init(alloc);
    defer main_cmd.deinit();

    cova.parseArgs(..., main_cmd, ...);
    utils.displayCmdInfo(CustomCommand, main_cmd, alloc, stdout);
}
```
