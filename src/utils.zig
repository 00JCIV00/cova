//! Utility Functions for the Cova Library.

// Standard
const std = @import("std");
const ascii = std.ascii;
const mem = std.mem;
const meta = std.meta;

// Cova
const Command = @import("Command.zig");
const Option = @import("Option.zig");
const Value = @import("Value.zig");

/// Display what is captured within a Command (`display_cmd`) after Cova parsing.
pub fn displayCmdInfo(
    comptime CommandT: type,
    display_cmd: *const CommandT,
    alloc: mem.Allocator,
    writer: anytype,
    hide_unset: bool,
) !void {
    var cur_cmd: ?*const CommandT = display_cmd;
    while (cur_cmd) |cmd| {
        try writer.print("- Command: {s}\n", .{cmd.name});
        if (cmd.opts) |opts| {
            for (opts) |opt| {
                if (hide_unset and !opt.val.isSet()) continue;
                try displayValInfo(CommandT.ValueT, opt.val, opt.long_name, true, alloc, writer);
            }
        }
        if (cmd.vals) |vals| {
            for (vals) |val| {
                if (hide_unset and !val.isSet()) continue;
                try displayValInfo(CommandT.ValueT, val, val.name(), false, alloc, writer);
            }
        }
        try writer.print("\n", .{});
        cur_cmd = cmd.sub_cmd;
    }
}

/// Display what is captured within an Option or Value after Cova parsing.
/// Meant for use within `displayCmdInfo()`.
fn displayValInfo(
    comptime ValueT: type,
    val: ValueT,
    name: ?[]const u8,
    isOpt: bool,
    alloc: mem.Allocator,
    writer: anytype,
) !void {
    const prefix = if (isOpt) "Opt" else "Val";

    switch (meta.activeTag(val.generic)) {
        .string => {
            const str_vals = val.generic.string.getAllAlloc(alloc) catch noVal: {
                const no_val = alloc.dupe([]const u8, &.{""}) catch @panic("OOM");
                break :noVal no_val;
            };
            defer alloc.free(str_vals);
            const full_str = mem.join(alloc, "\" \"", str_vals) catch @panic("OOM");
            defer alloc.free(full_str);
            try writer.print("    {s}: {?s}, Data: \"{s}\"\n", .{
                prefix,
                name,
                full_str,
            });
        },
        inline else => |tag| {
            const tag_self = @field(val.generic, @tagName(tag));
            if (tag_self.set_behavior == .Multi) {
                const raw_data: ?[]const @TypeOf(tag_self).ChildT = rawData: {
                    if (tag_self.getAllAlloc(alloc) catch null) |data| break :rawData data;
                    const data: ?@TypeOf(tag_self).ChildT = tag_self.get() catch null;
                    if (data) |_data| {
                        var data_slice = alloc.alloc(@TypeOf(tag_self).ChildT, 1) catch @panic("OOM");
                        data_slice[0] = _data;
                        break :rawData data_slice;
                    }
                    break :rawData null;
                };
                defer if (raw_data) |raw| alloc.free(raw);
                try writer.print("    {s}: {?s}, Data: {any}\n", .{
                    prefix,
                    name,
                    raw_data,
                });
            } else {
                try writer.print("    {s}: {?s}, Data: {any}\n", .{
                    prefix,
                    name,
                    tag_self.get() catch null,
                });
            }
        },
    }
}

/// Find the Index of any Type, Scalar or Slice, (`needle`) within a Slice of that Type (`haystack`). (Why is this not in std.mem?!?!? Did I miss it?)
pub fn indexOfEql(comptime T: type, haystack: []const T, needle: T) ?usize {
    switch (@typeInfo(T)) {
        .Pointer => |ptr| {
            for (haystack, 0..) |hay, idx| if (mem.eql(ptr.child, hay, needle)) return idx;
            return null;
        },
        inline else => return mem.indexOfScalar(T, haystack, needle),
    }
}

/// Find the Index of a String (`needle`) within a Slice of Strings `haystack`. (Why is this not in std.mem?!?!? Did I miss it?)
pub fn indexOfEqlIgnoreCase(haystack: []const []const u8, needle: []const u8) ?usize {
    for (haystack, 0..) |hay, idx| if (ascii.eqlIgnoreCase(hay, needle)) return idx;
    return null;
}
