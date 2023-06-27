//! Utility Functions for the Cova Library.

// Standard
const std = @import("std");
const mem = std.mem;
const meta = std.meta;

// Cova
const Command = @import("Command.zig");
const Option = @import("Option.zig");
const Value = @import("Value.zig");


/// Display what is captured within a Command after Cova parsing.
pub fn displayCmdInfo(comptime CustomCommand: type, display_cmd: *const CustomCommand, alloc: mem.Allocator) !void {
    const stdout = std.io.getStdOut().writer();
    var cur_cmd: ?*const CustomCommand = display_cmd;
    while (cur_cmd != null) {
        const cmd = cur_cmd.?;

        if (cmd.checkFlag("help")) try cmd.help(stdout);
        if (cmd.checkFlag("usage")) try cmd.usage(stdout);

        try stdout.print("- Command: {s}\n", .{ cmd.name });
        if (cmd.opts != null) {
            for (cmd.opts.?) |opt| try displayValInfo(opt.val, opt.long_name, true, alloc);
        }
        if (cmd.vals != null) {
            for (cmd.vals.?) |val| try displayValInfo(val, val.name(), false, alloc);
        }
        try stdout.print("\n", .{});
        cur_cmd = cmd.sub_cmd;
    }
}

/// Display what is captured within an Option of Value after Cova parsing.
/// Meant for use within `displayCmdInfo()`.
fn displayValInfo(val: Value.Generic, name: ?[]const u8, isOpt: bool, alloc: mem.Allocator) !void {
    const stdout = std.io.getStdOut().writer();
    const prefix = if (isOpt) "Opt" else "Val";

    switch (meta.activeTag(val)) {
        .string => {
            try stdout.print("    {s}: {?s}, Data: \"{s}\"\n", .{
                prefix,
                name, 
                mem.join(alloc, "\" \"", val.string.getAll(alloc) catch &.{ "" }) catch "",
            });
        },
        inline else => |tag| {
            const tag_self = @field(val, @tagName(tag));
            if (tag_self.set_behavior == .Multi) {
                const raw_data: ?[]const @TypeOf(tag_self).val_type = rawData: { 
                    if (tag_self.getAll(alloc) catch null) |data| break :rawData data;
                    const data: ?@TypeOf(tag_self).val_type = tag_self.get() catch null;
                    if (data != null) break :rawData &.{ data.? };
                    break :rawData null;
                };
                try stdout.print("    {s}: {?s}, Data: {any}\n", .{ 
                    prefix,
                    name, 
                    raw_data,
                });
            }
            else {
                try stdout.print("    {s}: {?s}, Data: {any}\n", .{ 
                    prefix,
                    name, 
                    tag_self.get() catch null,
                });
            }
        },
    }
}

/// Find the Index of a Scalar or Slice within Slice. (Why is this not in std.mem?!?!? Did I miss it?)
pub fn indexOfEql(comptime T: type, haystack: []const T, needle: T) ?usize {
    switch (@typeInfo(T)) {
        .Pointer => |ptr| {
            for (haystack, 0..) |hay, idx| if (mem.eql(ptr.child, hay, needle)) return idx;
            return null;
        },
        inline else => return mem.indexOfScalar(T, haystack, needle),
    }
}
