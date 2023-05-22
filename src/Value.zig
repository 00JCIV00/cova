//! Parseable Values for Commands and Options.

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


/// Create a Value with a specific Type.
pub fn Typed(comptime set_type: type) type {
    return struct {
        /// The inner Type of this Value.
        pub const val_type = set_type;

        /// The Raw Argument provided to this Value for Parsing and Validation.
        raw_arg: []const u8 = "",
        /// An optional Default Value.
        default_val: ?val_type = null,
        /// Flag to determine if this Value has been Parsed and Validated.
        is_set: bool = false,
        /// A Validation Function to be used in set() following normal Parsing.
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
        pub fn set(self: *const @This(), arg: []const u8) !void {
            const set_arg = if(eql(u8, arg, "")) self.raw_arg else arg;
            const parsed_val = try self.parse(set_arg);
            @constCast(self).is_set =
                if (self.val_fn != null) self.val_fn.?(parsed_val)
                else true;
            if (self.is_set) @constCast(self).raw_arg = set_arg
            else return error.InvalidValue;
        }

        /// Get the Parsed and Validated Value.
        pub fn get(self: *const @This()) !val_type {
            return 
                if (self.is_set) try self.parse(self.raw_arg)
                else if (val_type == bool) false
                else if (self.default_val != null) self.default_val.?
                else error.ValueNotSet;
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

        /// Get the inner Typed Value's name.
        pub fn name(self: *const @This()) []const u8 {
            return switch (meta.activeTag(self.*)) {
                inline else => |tag| @field(self, @tagName(tag)).name,
            };
        }
        /// Get the inner Typed Value's type.
        pub fn valType(self: *const @This()) []const u8 {
            return switch (meta.activeTag(self.*)) {
                inline else => |tag| @typeName(@TypeOf(@field(self, @tagName(tag))).getType()),
            };
        }
        /// Get the inner Typed Value's description.
        pub fn description(self: *const @This()) []const u8 {
            return switch (meta.activeTag(self.*)) {
                inline else => |tag| @field(self, @tagName(tag)).description,
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

/// Initialize a Generic Value with a specific Type.
/// TODO: Coerce Typed([]u8) to Typed([]const u8) 
pub fn init(comptime T: type, comptime typed_val: Typed(T)) Generic {
    const active_tag = if (T == []const u8 or T == []u8) "string" else @typeName(T);
    return @unionInit(Generic, active_tag, typed_val);
}

