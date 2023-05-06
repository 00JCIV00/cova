//! Parseable Values for Commands and Options.

const std = @import("std");
const ascii = std.ascii;
const fmt = std.fmt;
const mem = std.mem;

const eql = std.mem.eql;
const toLower = ascii.lowerString;
const parseInt = fmt.parseInt;
const parseFloat = fmt.parseFloat;


raw_arg: []const u8 = "",
val_type: type = bool,
is_set: bool = false,
val_fn: ?*const fn(anytype) bool = null,
    
name: []const u8 = "",
description: []const u8 = "",

/// Parse the given Argument to this Value's Type.
pub fn parse(self: *@This(), arg: []u8) !self.val_type {
    var san_arg_buf: [100]u8 = undefined;
    const san_arg = toLower(san_arg_buf[0..], arg);
    return switch (@typeInfo(self.val_type)) {
        .Null => error.ValueNotSet,
        .Bool => eql(u8, san_arg, "false"),
        .Pointer => arg,
        .Int => parseInt(self.val_type, arg, 0),
        .Float => parseFloat(self.val_type, arg),
        else => error.CannotParseArgToValue,
    };
}

/// Set this Value if the Argument can be Parsed and Validated.
/// Blank ("") Arguments will be treated as the current Raw Argument of the Value.
pub fn set(self: *@This(), arg: []u8) !void {
    const set_arg = if(eql(u8, arg, "")) self.raw_arg else arg;
    const parsed_val = try self.parse(set_arg) catch return false;
    self.is_set =
        if (self.val_fn != null) self.val_fn.?(parsed_val)
        else true;
    if (self.is_set) self.raw_arg = set_arg
    else return error.InvalidValue;
}

/// Get the Parsed and Validated Value.
pub fn get(self: *@This()) !self.val_type {
    return 
        if (self.is_set) try self.parse(self.raw_arg)
        else error.ValueNotSet;
}

