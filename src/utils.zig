//! Utility Functions for the Cova Library.

// Standard
const std = @import("std");
const mem = std.mem;
const meta = std.meta;

// Cova
const Command = @import("Command.zig");
const Option = @import("Option.zig");
const Value = @import("Value.zig");


/// Display what is captured within a Command `display_cmd` after Cova parsing.
pub fn displayCmdInfo(comptime CustomCommand: type, display_cmd: *const CustomCommand, alloc: mem.Allocator, writer: anytype) !void {
    var cur_cmd: ?*const CustomCommand = display_cmd;
    while (cur_cmd != null) {
        const cmd = cur_cmd.?;

        //_ = try cmd.checkUsageHelp(writer);

        try writer.print("- Command: {s}\n", .{ cmd.name });
        if (cmd.opts != null) {
            for (cmd.opts.?) |opt| try displayValInfo(CustomCommand.ValueT, opt.val, opt.long_name, true, alloc, writer);
        }
        if (cmd.vals != null) {
            for (cmd.vals.?) |val| try displayValInfo(CustomCommand.ValueT, val, val.name(), false, alloc, writer);
        }
        try writer.print("\n", .{});
        cur_cmd = cmd.sub_cmd;
    }
}

/// Display what is captured within an Option or Value after Cova parsing.
/// Meant for use within `displayCmdInfo()`.
fn displayValInfo(comptime CustomValue: type, val: CustomValue, name: ?[]const u8, isOpt: bool, alloc: mem.Allocator, writer: anytype) !void {
    const prefix = if (isOpt) "Opt" else "Val";

    switch (meta.activeTag(val.generic)) {
        .string => {
            try writer.print("    {s}: {?s}, Data: \"{s}\"\n", .{
                prefix,
                name, 
                mem.join(alloc, "\" \"", val.generic.string.getAll(alloc) catch &.{ "" }) catch "",
            });
        },
        inline else => |tag| {
            const tag_self = @field(val.generic, @tagName(tag));
            if (tag_self.set_behavior == .Multi) {
                const raw_data: ?[]const @TypeOf(tag_self).ChildT = rawData: { 
                    if (tag_self.getAll(alloc) catch null) |data| break :rawData data;
                    const data: ?@TypeOf(tag_self).ChildT = tag_self.get() catch null;
                    if (data != null) break :rawData &.{ data.? };
                    break :rawData null;
                };
                try writer.print("    {s}: {?s}, Data: {any}\n", .{ 
                    prefix,
                    name, 
                    raw_data,
                });
            }
            else {
                try writer.print("    {s}: {?s}, Data: {any}\n", .{ 
                    prefix,
                    name, 
                    tag_self.get() catch null,
                });
            }
        },
    }
}

/// Find the Index of a Scalar or Slice `needle` within a Slice `haystack`. (Why is this not in std.mem?!?!? Did I miss it?)
pub fn indexOfEql(comptime T: type, haystack: []const T, needle: T) ?usize {
    switch (@typeInfo(T)) {
        .Pointer => |ptr| {
            for (haystack, 0..) |hay, idx| if (mem.eql(ptr.child, hay, needle)) return idx;
            return null;
        },
        inline else => return mem.indexOfScalar(T, haystack, needle),
    }
}
