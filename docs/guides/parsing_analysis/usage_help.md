# Usage & Help Message
By default, Usage and Help messages are created based on the metadata of Arguments, and are displayed when there's an error during Parsing. Setting up the display for Usage and Help messages is as simple as setting up each Argument as seen in their respective guides. That said, the way they are created and the criteria for when they're displayed can be fully customized by the libary user. 

## Parsing Error Messages
The `cova.ParseConfig.err_reaction` field is used to help control what the end user sees if there's an error during parsing. In particular, it allows for a Usage message, a Help message, or no message at all to be displayed following an error.  

## Argument Usage & Help Functions
Each Argument Type has `usage()` and `help()` functions that can be called on an Argument to create messages. The most commonly used of these functions are `cova.Command.Custom.usage`() and `cova.Command.Custom.help`() which create and write out a Usage or Help message based on the Command's sub Arguments.

## Custom Usage & Help Formats
The Config for each Argument Type provides Format fields with the `_fmt` suffix that can be used to customize how Usage and Help messages are displayed. These Format fields are each documented with their required format placeholders (details for those can be found in `std.fmt.format`). 

Example:
```zig
pub const CommandT = cova.Command.Custom(.{
    .global_help_prefix="Cova Usage & Help Example",
    .help_header_fmt = 
        \\ {s}COMMAND: {s}
        \\ 
        \\ {s}DESCRIPTION: {s}
        \\
        \\
    ,
    .opt_config = .{
        usage_fmt = "{c}{?c}, {s}{?s} <{s} ({s})>",
    },
});
```

## Custom Usage & Help Callback Functions
For greater flexibiliy, custom Usage & Help callback functions can be provided for each Argument Type. These functions can be given directly to an Argument, to each Value or Option with a specific Child Type, or globally to all Arguments of an Argument Type; in that order of precendence.

Example:
```zig
pub const CommandT = cova.Command.Custom(.{
    .global_help_prefix="Cova Usage & Help Example",
    // Command Global Help Function
    .global_help_fn = struct{
        fn help(self: anytype, writer: anytype, _: mem.Allocator) !void {
            const CmdT = @TypeOf(self.*);
            const OptT = CmdT.OptionT;
            const indent_fmt = CmdT.indent_fmt;
    
            try writer.print("{s}\n", .{ self.help_prefix });
            try self.usage(writer);
            try writer.print("\n", .{});
            try writer.print(CmdT.help_header_fmt, .{
                indent_fmt, self.name,
                indent_fmt, self.description
            });

            if (self.sub_cmds) |cmds| {
                try writer.print("SUBCOMMANDS\n", .{});
                for (cmds) |cmd| {
                    try writer.print("{s}{s}: {s}\n", .{
                        indent_fmt,
                        cmd.name,
                        cmd.description,
                    });
                }
                try writer.print("\n", .{});
            }
            if (self.opts) |opts| {
                try writer.print("OPTIONS\n", .{});
                for (opts) |opt| {
                    try writer.print(
                        \\{s}{s}{s} "{s} ({s})"
                        \\{s}{s}{s}
                        \\
                        \\
                        , .{
                            indent_fmt,
                            OptT.long_prefix orelse OptT.short_prefix, opt.long_name orelse "",
                            opt.val.name(), opt.val.childType(),
                            indent_fmt, indent_fmt,
                            opt.description,
                        }
                    );
                }
            }
            if (self.vals) |vals| {
                try writer.print("VALUES\n", .{});
                for (vals) |val| {
                    try writer.print("{s}", .{ indent_fmt });
                    try val.usage(writer);
                    try writer.print("\n", .{});
                }
                try writer.print("\n", .{});
            }
        }
    }.help,
    .opt_config = .{
        // Option Global Help Function
       .global_help_fn = struct{
            fn help(self: anytype, writer: anytype, _: mem.Allocator) !void {
                const indent_fmt = @TypeOf(self.*).indent_fmt;
                try self.usage(writer);
                try writer.print("\n{?s}{?s}{?s}{s}", .{ indent_fmt, indent_fmt, indent_fmt, self.description }); 
            }
        }.help
    },
```

