# Command
A Command is a container Argument type for sub Commands, Options, and Values. It can contain any mix of those Argument types or none at all if it's to be used as a standalone Command (i.e. `covademo help`). 

They can be converted from and to valid Structs for easy setup and analysis. Other functions for analysis include creating a HashMap<Name, Value/Option> for Options or Values using the respective the `getOpts()` or `getVals()` methods, and using the `checkFlag()` method to simply check if an Argument type was set. Usage and Help statements for a Command can also be generated using the `usage()` and `help()` methods respectively.

Command's are meant to be set up in Comptime and used in Runtime. This means that the Command and all of its sub Argument types (Commands, Options, and Values) should be Comptime-known, allowing for proper Validation which provides direct feedback to the library user during compilation instead of preventable errors to the app user during Runtime. After they're set up and Validated, Command's are allocated to the heap for Runtime use. At this point, the data within the Command should be treated as read-only by the libary user, so the library is set up to handle initialized Commands as constants (`const`).

## Examples:
### Direct Creation
```
...
pub const cova = @import("cova");
pub const CustomCommand = cova.CustomCommand(.{ global_help_prefix = "CovaDemo" });

// Comptime Setup
const setup_cmd: CustomCommand = .{
    .name = "covademo",
    .description = "A demo of the Cova command line argument parser.",
    .sub_cmds = &.{
        .{
            .name = "sub_cmd",
            .description = "This is a Sub Command within the 'covademo' main Command.",
        },
        command_from_elsewhere,
        CustomCommand.from(some_valid_struct),
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
