//! Argument that is expected in a specific order and should be interpreted as a specific type.
//!
//! End User Example:
//!
//! ```
//! # Values belonging to a Command.
//! myapp "This string Value and the int Value after it both belong to the 'myapp' main Command." 13
//!
//! # Values belonging to an Option.
//! myapp --string_opt "This Value belongs to the 'string_opt' Option."
//! ```

const std = @import("std");
const builtin = std.builtin;
const ascii = std.ascii;
const fmt = std.fmt;
const fs = std.fs;
const mem = std.mem;
const meta = std.meta;

const toLower = ascii.lowerString;
const toUpper = ascii.upperString;
const parseInt = fmt.parseInt;
const parseFloat = fmt.parseFloat;
const Type = builtin.Type;
const UnionField = Type.UnionField;

/// The Behavior for Setting Values with `set()`.
/// This applies to Values within Options and standalone Values.
pub const SetBehavior = enum {
    /// Keeps the First Argument this Value was `set()` to.
    First,
    /// Keeps the Last Argument this Value was `set()` to.
    Last,
    /// Keeps Multiple Arguments in this Value up to the Value's `max_args`.
    Multi,
};

/// Create a Value with a specific Type (`SetT`).
pub fn Typed(comptime SetT: type) type {
    return struct {
        /// The child Type of this Value.
        pub const ChildT = SetT;

        /// The Parsed and Validated Argument(s) this Value has been set to.
        ///
        /// **Internal Use.**
        _set_args: [100]?ChildT = .{ null } ** 100,
        /// The current Index of Raw Arguments for this Value.
        ///
        /// **Internal Use.**
        _arg_idx: u7 = 0,
        /// The Max number of Raw Arguments that can be provided.
        /// This must be between 1 - 100.
        max_args: u7 = 1,
        /// Flag to determine if this Value is at max capacity for Raw Arguments.
        ///
        /// *This should be Read-Only for library users.*
        is_maxed: bool = false,
        /// Delimiter Characters that can be used to split up Multi-Values or Multi-Options.
        /// This is only applicable if `set_behavior = .Multi`.
        arg_delims: []const u8 = ",;",
        /// Set Behavior for this Value.
        set_behavior: SetBehavior = .Last,
        /// An optional Default value for this Value.
        default_val: ?ChildT = null,
        /// Flag to determine if this Value has been Parsed and Validated.
        ///
        /// *This should be Read-Only for library users.*
        is_set: bool = false,

        /// A Parsing Function to be used in place of the normal `parse()` for Argument Parsing.
        /// Note that any error caught from this function will be returned as `error.CannotParseArgToValue`.
        parse_fn: ?*const fn([]const u8) anyerror!ChildT = null,
        /// A Validation Function to be used for Argument Validation in `set()` following Argument Parsing with `parse()`.
        valid_fn: ?*const fn(ChildT) bool = struct{ fn valFn(val: ChildT) bool { return @TypeOf(val) == ChildT; } }.valFn,
            
        /// The Name of this Value for user identification and Usage/Help messages.
        name: []const u8 = "",
        /// The Description of this Value for Usage/Help messages.
        description: []const u8 = "",

        /// Parse the given argument token (`arg`) to this Value's Type.
        pub fn parse(self: *const @This(), arg: []const u8) !ChildT {
            if (self.parse_fn != null) return self.parse_fn.?(arg) catch error.CannotParseArgToValue;
            var san_arg_buf: [512]u8 = undefined;
            var san_arg = toLower(san_arg_buf[0..], arg);
            return switch (@typeInfo(ChildT)) {
                .Bool => isTrue: {
                    const true_words = [_][]const u8{ "true", "t", "yes", "y" };
                    for (true_words[0..]) |word| { if (mem.eql(u8, word, san_arg)) break :isTrue true; } else break :isTrue false;
                },
                .Pointer => arg,
                .Int => parseInt(ChildT, arg, 0),
                .Float => parseFloat(ChildT, arg),
                else => error.CannotParseArgToValue,
            };
        }

        /// Set this Value if the provided argument token (`set_arg`) can be Parsed and Validated.
        pub fn set(self: *const @This(), set_arg: []const u8) !void {
            // Delimited Args
            var arg_delim: u8 = ' ';
            const check_delim: bool = checkDelim: {
                for (self.arg_delims) |delim| {
                    if (mem.indexOfScalar(u8, set_arg, delim) != null) {
                        arg_delim = delim;
                        break :checkDelim true;
                    }
                }
                break :checkDelim false;
            };
            if (self.set_behavior == .Multi and meta.activeTag(@typeInfo(ChildT)) != .Pointer and check_delim) {
                var split_args = mem.splitScalar(u8, set_arg, arg_delim);
                while (split_args.next()) |arg| try self.set(arg);
                return;
            }

            // Single Arg
            const parsed_arg = try self.parse(set_arg);
            @constCast(self).is_set =
                if (self.valid_fn != null) self.valid_fn.?(parsed_arg)
                else true;
            if (self.is_set) {
                switch (self.set_behavior) {
                    .First => if (self._set_args[0] == null) { 
                        @constCast(self)._set_args[0] = parsed_arg;
                        @constCast(self)._arg_idx += 1;
                    },
                    .Last => {
                        @constCast(self)._set_args[0] = parsed_arg;
                        if (self._arg_idx < 1) @constCast(self)._arg_idx += 1;
                    },
                    .Multi => if (self._arg_idx < self.max_args) {
                        @constCast(self)._set_args[self._arg_idx] = parsed_arg;
                        @constCast(self)._arg_idx += 1;
                    }
                }
                @constCast(self).is_maxed = self._arg_idx == self.max_args;
            }
            else return error.InvalidValue;
        }

        /// Get the first Parsed and Validated value of this Value.
        /// This will pull the first value from `_set_args` and should be used with the `First` or `Last` Set Behaviors.
        pub fn get(self: *const @This()) !ChildT {
            return 
                if (self.is_set) self._set_args[0].?
                else if (ChildT == bool) false
                else if (self.default_val != null) self.default_val.?
                else error.ValueNotSet;
        }

        /// Get All Parsed and Validated Arguments of this Value.
        /// This will pull All values from `_set_args` and should be used with `Multi` Set Behavior.
        pub fn getAll(self: *const @This(), alloc: mem.Allocator) ![]ChildT {
            if (!self.is_set) return error.ValueNotSet;
            var vals = try alloc.alloc(ChildT, self._arg_idx);
            for (self._set_args[0..self._arg_idx], 0..) |arg, idx| vals[idx] = arg.?;
            return vals;
        }

        /// Get the Value Type
        pub fn getType() type { return ChildT; }
    };
}

/// Generic Value to handle a Value regardless of its inner type.
pub const Generic = genUnion: {
    var gen_union = union(enum){
        bool: Typed(bool),
        
        string: Typed([]const u8),
        
        u4: Typed(u4),
        u8: Typed(u8),
        u16: Typed(u16),
        u32: Typed(u32),
        u64: Typed(u64),
        u128: Typed(u128),
        u256: Typed(u256),

        i4: Typed(i4),
        i8: Typed(i8),
        i16: Typed(i16),
        i32: Typed(i32),
        i64: Typed(i64),
        i128: Typed(i128),
        i256: Typed(i256),

        f16: Typed(f16),
        f32: Typed(f32),
        f64: Typed(f64),
        f128: Typed(f128),

        /// Get the Parsed and Validated Value of the inner Typed Value.
        /// Comptime Only 
        // TODO: See if this can be made Runtime
        pub fn get(self: *const @This()) !switch (meta.activeTag(self.*)) { inline else => |tag| @TypeOf(@field(self, @tagName(tag))).getType(), } {
            return switch (meta.activeTag(self.*)) {
                inline else => |tag| try @field(self, @tagName(tag)).get(),
            };
        }
        /// Set the inner Typed Value if the provided Argument (`arg`) can be Parsed and Validated.
        pub fn set(self: *const @This(), arg: []const u8) !void { 
            switch (meta.activeTag(self.*)) {
                inline else => |tag| try @field(self, @tagName(tag)).set(arg),
            }
        }

        /// Get the inner Typed Value's Name.
        pub fn name(self: *const @This()) []const u8 {
            return switch (meta.activeTag(self.*)) {
                inline else => |tag| @field(self, @tagName(tag)).name,
            };
        }
        /// Get the inner Typed Value's Type Name.
        pub fn valType(self: *const @This()) []const u8 {
            return switch (meta.activeTag(self.*)) {
                inline else => |tag| @typeName(@TypeOf(@field(self, @tagName(tag))).getType()),
            };
        }
        /// Get the inner Typed Value's Description.
        pub fn description(self: *const @This()) []const u8 {
            return switch (meta.activeTag(self.*)) {
                inline else => |tag| @field(self, @tagName(tag)).description,
            };
        }
        /// Check the inner Typed Value's is Set.
        pub fn isSet(self: *const @This()) bool {
            return switch (meta.activeTag(self.*)) {
                inline else => |tag| @field(self, @tagName(tag)).is_set,
            };
        }
        /// Get the inner Typed Value's Argument Index.
        pub fn argIdx(self: *const @This()) u7 {
            return switch (meta.activeTag(self.*)) {
                inline else => |tag| @field(self, @tagName(tag))._arg_idx,
            };
        }
        /// Get the inner Typed Value's Max Arguments.
        pub fn maxArgs(self: *const @This()) u7 {
            return switch (meta.activeTag(self.*)) {
                inline else => |tag| @field(self, @tagName(tag)).max_args,
            };
        }
    };

    // TODO: See if there's another way to add these fields procedurally to avoid the declaration reification issue with @Type(builtin.Type{})
    //var fields: []const UnionField = meta.fields(gen_union);
    //@setEvalBranchQuota(2000);
    //inline for (1..255) |bit_width| {
    //    fields = fields ++ .{ UnionField {
    //       .name = @typeName(meta.Int(.unsigned, bit_width)),
    //       .type = meta.Int(.unsigned, bit_width),
    //       .alignment = @alignOf(meta.Int(.unsigned, bit_width)),
    //    } };
    //    fields = fields ++ .{ UnionField {
    //       .name = @typeName(meta.Int(.signed, bit_width)),
    //       .type = meta.Int(.signed, bit_width),
    //       .alignment = @alignOf(meta.Int(.signed, bit_width)),
    //    } };
    //}

    break :genUnion gen_union;
};

/// Parsing Functions for various common requirements to be used with `parse_fn` in place of normal `parse()`.
/// Note, `parse_fn` is in no way limited to these functions.
pub const ParsingFns = struct {
    /// Builder Functions for common Parsing Functions.
    pub const Builder = struct {
        /// Check for Alternate True Words (`true_words`) when parsing the provided Argument (`arg`) to a Boolean.
        pub fn altTrue(comptime true_words: []const []const u8) fn([]const u8) anyerror!bool {
            return struct {
                fn isTrue(arg: []const u8) !bool {
                    for (true_words[0..]) |word| { if (mem.eql(u8, word, arg)) return true; } else return false;
                }
            }.isTrue;
        }

        /// Parse the given Integer (`arg`) as Base (`base`). Base options:
        /// - 0: Uses the 2 character prefix to determine the base. Default is Base 10. (This is also the default parsing option for Integers.)
        /// - 2: Base 2 / Binary
        /// - 8: Base 8 / Octal
        /// - 10: Base 10 / Decimal
        /// - 16: Base 16 / Hexadecimal
        pub fn asBase(comptime NumT: type, comptime base: u8) fn([]const u8) anyerror!NumT {
            return struct { fn toBase(arg: []const u8) !NumT { return fmt.parseInt(NumT, arg, base); } }.toBase;
        }

        /// Parse the given argument token (`arg`) to an Enum Tag of the provided `EnumT`.
        pub fn asEnumType(comptime EnumT: type) enumFnType: {
            const enum_info = @typeInfo(EnumT);
            if (enum_info != .Enum) @compileError("The type of `EnumT` must be Enum!");
            break :enumFnType fn([]const u8) anyerror!enum_info.Enum.tag_type;
        } {
            const EnumTagT: type = @typeInfo(EnumT).Enum.tag_type;
            return struct { 
                fn enumInt(arg: []const u8) !EnumTagT { 
                    const enum_tag = meta.stringToEnum(EnumT, arg) orelse return error.EnumTagDoesNotExist;
                    return @intFromEnum(enum_tag);
                }
            }.enumInt;
        }

    };

    /// Trim all Whitespace from the beginning and end of the provided argument token (`arg`).
    pub fn trimWhitespace(arg: []const u8) anyerror![]const u8 {
        return mem.trim(u8, arg, ascii.whitespace[0..]);
    }
};

/// Validation Functions for various common requirements to be used with `valid_fn`.
/// Note, `valid_fn` is in no way limited to these functions.
pub const ValidationFns = struct {
    /// Builder Functions for common Validation Functions.
    pub const Builder = struct {
        /// Check if the provided `NumT` (`num`) is within an inclusive or exclusive range.
        pub fn inRange(comptime NumT: type, comptime start: NumT, comptime end: NumT, comptime inclusive: bool) fn(NumT) bool {
            const num_info = @typeInfo(NumT);
            switch (num_info) {
                .Int, .Pointer => {},
                inline else => @compileError("The provided type '" ++ @typeName(NumT) ++ "' is not a numeric type. It must be an Integer or a Float."),
            }

            return 
                if (inclusive) struct { fn inRng(num: NumT) bool { return num >= start and num <= end; } }.inRng
                else struct { fn inRng(num: NumT) bool { return num > start and num < end; } }.inRng;
        }
    };

    /// Check if the provided argument token (`filepath`) is a valid filepath.
    pub fn validFilepath(filepath: []const u8) bool {
        const test_file = fs.cwd().openFile(filepath, .{}) catch return false;
        test_file.close();
        return true;
    } 
    /// Check if the provided argument token (`num_str`) is a valid Ordinal Number.
    pub fn ordinalNum(num_str: []const u8) bool {
        const ordinals = enum {
            first,
            second,
            third,
            fourth,
            fifth,
            sixth,
            seventh,
            eigth,
            ninth,
            tenth,
        };
        var lower_buf: [100]u8 = undefined;
        const lower_slice = toLower(lower_buf[0..], num_str);
        return meta.stringToEnum(ordinals, lower_slice) != null;
    }
};

/// Create a Generic Value with a specific Type (`T`).
pub fn ofType(comptime T: type, comptime typed_val: Typed(T)) Generic {
    const active_tag = if (T == []const u8) "string" else @typeName(T);
    return @unionInit(Generic, active_tag, typed_val);
}

/// Config for creating Values from Struct Fields using `from()`.
pub const FromConfig = struct {
    /// Ignore Incompatible types or error during compile time.
    ignore_incompatible: bool = true,
    /// Description for the Value.
    val_description: ?[]const u8 = null,
};

/// Create a Generic Value from a Valid Value StructField (`field`) using the provided FromConfig (`from_config`).
/// This is intended for use with the corresponding `from()` methods in Command and Option, which ultimately create a Command from a given Struct.
pub fn from(comptime field: std.builtin.Type.StructField, from_config: FromConfig) ?Generic {
    const field_info = @typeInfo(field.type);
    if (field_info == .Pointer and field_info.Pointer.child != u8) {
        if (!from_config.ignore_incompatible) @compileError("The field '" ++ field.name ++ "' of type '" ++ @typeName(field.type) ++ "' is incompatible. Pointers must be of type '[]const u8'.")
        else return null;
    }
    const field_type = switch (field_info) {
        .Optional => field_info.Optional.child,
        .Array => aryType: {
            const ary_info = @typeInfo(field_info.Array.child);
            if (ary_info == .Optional) break :aryType ary_info.Optional.child
            else break :aryType field_info.Array.child;
        },
        .Bool, .Int, .Float, .Pointer => field.type,
        else => { 
            if (!from_config.ignore_incompatible) @compileError("The field '" ++ field.name ++ "' of type '" ++ @typeName(field.type) ++ "' is incompatible.")
            else return null;
        },
    };
    return ofType(field_type, .{
        .name = field.name,
        .description = from_config.val_description orelse "The '" ++ field.name ++ "' Value of type '" ++ @typeName(field.type) ++ "'.",
        .max_args = 
            if (field_info == .Array) field_info.Array.len
            else 1,
        .set_behavior =
            if (field_info == .Array) .Multi
            else .Last,
        .default_val = 
            if (field.default_value != null and field_info != .Array) @as(*field.type, @ptrCast(@alignCast(@constCast(field.default_value)))).*
            else null,
    });
}
