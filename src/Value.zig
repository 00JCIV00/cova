//! Argument that is expected in a specific order and should be interpreted as a specific type.
//!
//! End User Example:
//!
//! ```
//! # Values belonging to a Command.
//! myapp "This string Value and the int Value after it both belong to the 'myapp' main Command." 13
//! # Values belonging to an Option.
//! myapp --string_opt "This Value belongs to the 'string_opt' Option."
//! ```

const std = @import("std");
const builtin = std.builtin;
const ascii = std.ascii;
const fmt = std.fmt;
const mem = std.mem;
const meta = std.meta;

const eql = std.mem.eql;
const toLower = ascii.lowerString;
const parseInt = fmt.parseInt;
const parseFloat = fmt.parseFloat;
const Type = builtin.Type;
const UnionField = Type.UnionField;

/// The Behavior for Setting Values.
/// These are currently only implemented for Values that are within Options.
pub const SetBehavior = enum {
    /// Keeps the First Argument this Value was Set to.
    First,
    /// Keeps the Last Argument this Value was Set to.
    Last,
    /// Keeps Multiple Arguments in this Value up to the set Max.
    Multi,
};

/// Create a Value with a specific Type.
pub fn Typed(comptime set_type: type) type {
    return struct {
        /// The inner Type of this Value.
        pub const val_type = set_type;

        /// The Parsed and Validated Argument(s) this Value has been set to.
        /// Internal Use.
        _set_args: [100]?val_type = .{ null } ** 100,
        /// The current Index of Raw Arguments for this Value.
        /// Internal Use.
        _arg_idx: u7 = 0,
        /// The Max number of Raw Arguments that can be provided.
        /// This must be between 1 - 100.
        max_args: u7 = 1,
        /// Set Behavior for this Value.
        set_behavior: SetBehavior = .Last,
        /// An optional Default Value.
        default_val: ?val_type = null,
        /// Flag to determine if this Value has been Parsed and Validated.
        is_set: bool = false,
        /// A Validation Function to be used in `set()` following normal Parsing.
        val_fn: ?*const fn(val_type) bool = struct{ fn valFn(val: val_type) bool { return @TypeOf(val) == val_type; } }.valFn,
            
        /// The Name of this Value for user identification and Usage/Help messages.
        name: []const u8 = "",
        /// The Description of this Value for Usage/Help messages.
        description: []const u8 = "",

        /// Parse the given Argument to this Value's Type.
        pub fn parse(self: *const @This(), arg: []const u8) !val_type {
            _ = self;
            var san_arg_buf: [100]u8 = undefined;
            const san_arg = toLower(san_arg_buf[0..], arg);
            return switch (@typeInfo(val_type)) {
                //.Null => error.ValueNotSet,
                .Bool => eql(u8, san_arg, "true"),
                .Pointer => arg,
                .Int => parseInt(val_type, arg, 0),
                .Float => parseFloat(val_type, arg),
                else => error.CannotParseArgToValue,
            };
        }

        /// Set this Value if the Argument can be Parsed and Validated.
        /// Blank ("") Arguments will be treated as the current Raw Argument of the Value.
        pub fn set(self: *const @This(), set_arg: []const u8) !void {
            const parsed_arg = try self.parse(set_arg);
            @constCast(self).is_set =
                if (self.val_fn != null) self.val_fn.?(parsed_arg)
                else true;
            if (self.is_set) {
                switch (self.set_behavior) {
                    .First => if (self._set_args[0] == null) { 
                        @constCast(self)._set_args[0] = parsed_arg;
                    },
                    .Last => @constCast(self)._set_args[0] = parsed_arg,
                    .Multi => if (self._arg_idx < self.max_args) {
                        @constCast(self)._set_args[self._arg_idx] = parsed_arg;
                        @constCast(self)._arg_idx += 1;
                    }
                }
            }
            else return error.InvalidValue;
        }

        /// Get the first Parsed and Validated Argument of this Value.
        /// This will pull the first value from `_set_args` and should be used with the `First` or `Last` Set Behaviors.
        pub fn get(self: *const @This()) !val_type {
            return 
                if (self.is_set) self._set_args[0].?
                else if (val_type == bool) false
                else if (self.default_val != null) self.default_val.?
                else error.ValueNotSet;
        }

        /// Get All Parsed and Validated Arguments of this Value.
        /// This will pull All values from `_set_args` and should be used with `Multi` Set Behavior.
        /// TODO: Make this more efficient.
        pub fn getAll(self: *const @This(), alloc: mem.Allocator) ![]val_type {
            if (!self.is_set) return error.ValueNotSet;
            var vals = try alloc.alloc(val_type, self._arg_idx);
            for (self._set_args[0..self._arg_idx], 0..) |arg, idx| vals[idx] = arg.?;
            return vals;
        }

        /// Get the Value Type
        pub fn getType() type { return val_type; }
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
        /// Comptime Only (TODO: See if this can be made Runtime)
        pub fn get(self: *const @This()) !switch (meta.activeTag(self.*)) { inline else => |tag| @TypeOf(@field(self, @tagName(tag))).getType(), } {
            return switch (meta.activeTag(self.*)) {
                inline else => |tag| try @field(self, @tagName(tag)).get(),
            };
        }
        /// Set the inner Typed Value if the provided Argument can be Parsed and Validated.
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
        /// Get the inner Typed Value's Type.
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

/// Create a Generic Value with a specific Type.
pub fn ofType(comptime T: type, comptime typed_val: Typed(T)) Generic {
    const active_tag = if (T == []const u8) "string" else @typeName(T);
    return @unionInit(Generic, active_tag, typed_val);
}
