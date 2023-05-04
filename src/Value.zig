//! Parseable Values for Commands and Options.

const std = @import("std");
const ascii = std.ascii;
const fmt = std.fmt;
const mem = std.mem;

const eql = std.mem.eql;
const toLower = ascii.lowerString;
const parseInt = fmt.parseInt;
const parseFloat = fmt.parseFloat;


raw_arg: []u8 = "",
val_type: type = bool,
is_set: bool = false,
val_fn: *const fn(val_type) bool,
name: []u8 = "",
description: []u8 = "",

/// Parse the set Raw Argument to the given Value Type.
pub fn parse(self: *@This()) !val_type {
    var san_arg_buf: [100]u8 = undefined;
    const san_arg = toLower(san_val_buf[0..], raw_arg.?);
    return switch (@typeInfo(val_type)) {
        .Null => error.ValueNotSet,
        .Bool => eql(u8, san_arg, "false"),
        .Pointer => raw_arg,
        .Int => parseInt(val_type, san_arg, 0),
        .Float => parseFloat(val_type, san_arg),
        else => error.CannotParseArgToValue,
    };
}

/// Validate the Parsed Value.
pub fn validate(self: *@This()) bool {
    const parsed_val = self.asType() catch return false;
    return val_fn(parsed_val);
}

/// Get the Parsed and Validated Value.
pub fn get(self: *@This()) !val_type {
    return if (self.validate()) self.parse()
           else error.InvalidValue;
}

