//! Wrapper Argument for a Value which is typically optional.
//!
//! End-User Example:
//!
//! ```
//! # Short Options
//! -n "Bill" -a=5 -t
//! 
//! # Long Options
//! --name="Dion" --age 47 --toggle
//! ```

const std = @import("std");
const ascii = std.ascii;
const mem = std.mem;
const meta = std.meta;

const toUpper = ascii.toUpper;

const Value = @import("Value.zig");

/// Config for custom Option types.
pub const Config = struct {
    /// Command Type.
    /// This will be filled in automatically.
    CommandT: ?type = null,

    /// Value Config for this Option type.
    /// This will default to the same Value.Config used by the overarching custom Command Type of this custom Option Type.
    val_config: Value.Config = .{},

    /// A custom Help function to override the default `help()` function globally for ALL Option instances of this custom Option Type.
    /// This function is 2nd in precedence.
    ///
    /// Function parameters:
    /// 1. OptionT (This should be the `self` parameter. As such it needs to match the Option Type the function is being called on.)
    /// 2. Writer (This is the Writer that will be written to.)
    /// 3. Allocator (This does not have to be used within in the function, but must be supported in case it's needed.)
    global_help_fn: ?*const fn(anytype, anytype, mem.Allocator)anyerror!void = null,
    /// A custom Usage function to override the default `usage()` function globally for ALL Option instances of this custom Option Type.
    /// This function is 2nd in precedence.
    ///
    /// Function parameters:
    /// 1. OptionT (This should be the `self` parameter. As such it needs to match the Option Type the function is being called on.)
    /// 2. Writer (This is the Writer that will be written to.)
    /// 3. Allocator (This does not have to be used within in the function, but must be supported in case it's needed.)
    global_usage_fn: ?*const fn(anytype, anytype, mem.Allocator)anyerror!void = null,
    /// Custom Help functions to override the default `help()` function for all Option instances with a matching Value Child Type.
    /// These functions are 1st in precedence.
    child_type_help_fns: ?[]const struct{ 
        /// The Child Type this function applies to.
        ChildT: type,
        /// The custom Help Function.
        ///
        /// Function parameters:
        /// 1. OptionT (This should be the `self` parameter. As such it needs to match the Option Type the function is being called on.)
        /// 2. Writer (This is the Writer that will be written to.)
        /// 3. Allocator (This does not have to be used within in the function, but must be supported in case it's needed.)
        help_fn: *const fn(anytype, anytype, mem.Allocator)anyerror!void,
    } = null,
    /// Custom Usage functions to override the default `usage()` function for all Option instances with a matching Value Child Type.
    /// These functions are 1st in precedence.
    child_type_usage_fns: ?[]const struct{ 
        /// The Child Type this function applies to.
        ChildT: type,
        /// The custom Usage Function.
        ///
        /// Function parameters:
        /// 1. OptionT (This should be the `self` parameter. As such it needs to match the Option Type the function is being called on.)
        /// 2. Writer (This is the Writer that will be written to.)
        /// 3. Allocator (This does not have to be used within in the function, but must be supported in case it's needed.)
        usage_fn: *const fn(anytype, anytype, mem.Allocator)anyerror!void,
    } = null,

    /// Indent string used for Usage/Help formatting.
    /// Note, if this is left null, it will inherit from the Command Config. 
    indent_fmt: ?[]const u8 = null,
    /// Format for the Help message. 
    ///
    // Must support the following format types in this order:
    /// 1. String (Name)
    /// 2. String (Description)
    help_fmt: ?[]const u8 = null,
    /// Name Separator Format
    name_sep_fmt: []const u8 = ",",
    /// Format for the Usage message.
    ///
    /// Must support the following format types in this order:
    /// 1. Character (Short Prefix) 
    /// 2. Optional Character "{?u}" (Short Name)
    /// 3. String Name Separator
    /// 4. String (Long Prefix)
    /// 5. Optional String "{?s}" (Long Name)
    /// 6. String (Value Name)
    /// 7. String (Value Type)
    ///
    /// Note, a comma "," will automatically be placed between the short and long name if they both exist.
    usage_fmt: []const u8 = "{u}{?u}{s}{s}{?s} <{s} ({s})>",

    /// Prefix for Short Options.
    short_prefix: ?u8 = '-',
    /// Prefix for Long Options.
    long_prefix: ?[]const u8 = "--",

    /// During parsing, allow there to be no space ' ' between Options and Values.
    /// This is allowed per the POSIX standard, but may not be ideal as it interrupts the parsing of chained booleans even in the event of a misstype.
    allow_opt_val_no_space: bool = true,
    /// Specify custom Separators between Options and their Values for parsing. (i.e. `--opt=value`)
    /// Spaces ' ' are implicitly included.
    opt_val_seps: []const u8 = "=",
    /// During parsing, allow Abbreviated Long Options. (i.e. '--long' working for '--long-opt')
    /// This is allowed per the POSIX standard, but may not be ideal in every use case.
    /// Note, this does not check for uniqueness and will simply match on the first Option matching the abbreviation.
    allow_abbreviated_long_opts: bool = true,
    /// During parsing, mandate that Option instances of this Option Type must be used in a case-sensitive manner when called by their Long Name.
    /// This will also affect Command Validation, but will NOT affect Tab-Completion.
    global_case_sensitive: bool = true,
    /// Include tracking of Argument Indices.
    /// If not included, this feature wil be `void`ed to reduce binary size.
    include_arg_indices: bool = true,

    /// Return an Option Config that is optimized for smaller binary sizes.
    pub fn optimized(comptime OptimizeConfig: type, optimize_config: OptimizeConfig) @This() {
        var config: @This() = .{
            .include_arg_indices = !optimize_config.remove_features,
        };
        config.val_config = Value.Config.optimized(OptimizeConfig, optimize_config);
        if (optimize_config.no_formats) {
            inline for (meta.fields(@This())) |field| {
                if (mem.endsWith(u8, field.name, "_fmt")) @field(config, field.name) = "";
            }
        }
        const conf = config;
        return conf;
    }
};

/// Create an Option type with the Base (default) configuration.
pub fn Base() type { return Custom(.{}); }

/// Create a Custom Option type from the provided Config (`config`).
pub fn Custom(comptime config: Config) type {
    if (config.short_prefix == null and config.long_prefix == null) @compileError("Either a Short or Long prefix must be set for Option Types!");
    return struct {
        /// The Custom Command Type of the overall project.
        const CommandT = config.CommandT.?;
        /// The Custom Value Type used by this Custom Option Type.
        const ValueT = Value.Custom(config.val_config);

        /// Custom Global Help Function.
        /// Check (`Command.Config`) for details.
        pub const global_help_fn = config.global_help_fn;
        /// Custom Global Usage Function.
        /// Check (`Command.Config`) for details.
        pub const global_usage_fn = config.global_usage_fn;

        /// Indent Format.
        /// Check (`Command.Config`) for details.
        pub const indent_fmt = config.indent_fmt;
        /// Name Separator Format.
        /// Check (`Command.Config`) for details.
        pub const name_sep_fmt = config.name_sep_fmt;
        /// Help Format.
        /// Check `Options.Config` for details.
        pub const help_fmt = config.help_fmt;
        /// Usage Format.
        /// Check `Options.Config` for details.
        pub const usage_fmt = config.usage_fmt;

        /// Short Prefix.
        /// Check `Options.Config` for details.
        pub const short_prefix = config.short_prefix;
        /// Long Prefix. 
        /// Check `Options.Config` for details.
        pub const long_prefix = config.long_prefix;

        /// Allow no space between Options and Values.
        /// Check `Options.Config` for details.
        pub const allow_opt_val_no_space = config.allow_opt_val_no_space;
        /// Custom Separators between Options and Values.
        /// Check `Options.Config` for details.
        pub const opt_val_seps = config.opt_val_seps;
        /// Allow Abbreviated Long Options.
        /// Check `Options.Config` for details.
        pub const allow_abbreviated_long_opts = config.allow_abbreviated_long_opts;
        /// Include Argument Indices.
        /// Check (`Option.Config`) for details.
        pub const include_arg_indices = config.include_arg_indices;

        /// The Allocator for this Option's parent Command.
        /// This is set during the `init()` call of this Option's parent Command.
        ///
        /// **Internal Use.**
        _alloc: ?mem.Allocator = null,

        /// The Parent Command of this Option.
        /// This will be filled in during Initialization.
        parent_cmd: ?*const CommandT = null,

        /// Allows this Option to be Inherited by sub-Commands of this Option's Parent Command.
        /// An Option is only inherited if it doesn't exist in a sub-Command.
        /// Note that `cova.ParseConfig.allow_inherited_opts` must be enabled for this behavior.
        inheritable: bool = false,

        /// Option Group of this Option.
        /// This must line up with one of the Option Groups in the `opt_groups` of the parent Command or it will be ignored.
        /// This can be Validated using `Command.Custom.ValidateConfig.check_arg_groups`.
        opt_group: ?[]const u8 = null,

        /// The Argument Indeces of this Option which are determined during parsing.
        ///
        /// *This should be Read-Only for library users.*
        //arg_idx: ?[]u8 = null,
        arg_idx: if (include_arg_indices) ?[]u8 else void = if (include_arg_indices) null else {},

        /// This Option's Short Name (ex: `-s`).
        short_name: ?u8 = null,
        /// This Option's Long Name (ex: `--intOpt`).
        long_name: ?[]const u8 = null,
        /// A list of Alias Names for this Option that can be used in place of `long_name`.
        /// Note, each Option may have up to 16 aliases and these will NOT be Validated against any long name abbreviations.
        alias_long_names: ?[]const []const u8 = null,
        /// This Option's wrapped Value.
        val: ValueT = ValueT.ofType(bool, .{}),

        /// The Name of this Option for user identification and Usage/Help messages.
        /// Limited to 100B.
        name: []const u8,
        /// The Description of this Option for Usage/Help messages.
        description: []const u8 = "",
        /// Hide thie Command from Usage/Help messages.
        hidden: bool = false,

        /// During parsing, mandate that THIS Option must be used in a case-sensitive manner when called by its Long Name.
        /// This will NOT affect Option Validation, nor will it carry over to Tab-Completions.
        case_sensitive: bool = config.global_case_sensitive,
        /// During parsing, mandate that this Option is given.
        /// This will do nothing if this Option's Value has a default value.
        mandatory: bool = false,

        // (WIP) TODO: Figure out if this is possible
        ///// A custom Help function to override the default `help()` function for this custom Option INSTANCE.
        ///// This function is 1st in precedence.
        /////
        ///// Function signature:
        ///// `fn(anytype, anytype, mem.Allocator)anyerror!void = null`
        ///// Function parameters:
        ///// 1. OptionT (This should be the `self` parameter. As such it needs to match the Option Type the function is being called on.)
        ///// 2. Writer (This is the Writer that will be written to.)
        ///// 3. Allocator (This does not have to be used within in the function, but must be supported in case it's needed.)
        //help_fn: ?*anyopaque = null, 
        ///// A custom Usage function to override the default `usage()` function for this custom Option INSTANCE.
        ///// This function is 1st in precedence.
        /////
        ///// Function signature:
        ///// `fn(anytype, anytype, mem.Allocator)anyerror!void = null`
        ///// Function parameters:
        ///// 1. OptionT (This should be the `self` parameter. As such it needs to match the Option Type the function is being called on.)
        ///// 2. Writer (This is the Writer that will be written to.)
        ///// 3. Allocator (This does not have to be used within in the function, but must be supported in case it's needed.)
        //usage_fn: ?*anyopaque = null,

        /// Set a new Argument Index for this Option.
        pub fn setArgIdx(self: *const @This(), arg_idx: u8) !void {
            if (!include_arg_indices) return;
            const alloc = self._alloc orelse return error.OptionNotInitialized;
            if (self.arg_idx == null) {
                @constCast(self).*.arg_idx = try alloc.alloc(u8, 1);
                @constCast(self).*.arg_idx.?[0] = arg_idx;
                return;
            }
            switch (self.val.setBehavior()) {
                .First, .Last => @constCast(self).*.arg_idx.?[0] = arg_idx,
                .Multi => {
                    var idx_list = std.ArrayList(u8).fromOwnedSlice(alloc, @constCast(self).arg_idx.?);
                    try idx_list.append(arg_idx);
                    @constCast(self).*.arg_idx = try idx_list.toOwnedSlice();
                },
            }
        }

        /// Creates the Help message for this Option and Writes it to the provided Writer (`writer`).
        pub fn help(self: *const @This(), writer: anytype) !void {
            // (WIP)
            //if (self.help_fn) |help_fn_opaque| { 
            //    const helpFn = @as(*const fn(anytype, anytype, mem.Allocator) anyerror!void, @alignCast(@ptrCast(help_fn_opaque)));
            //    return helpFn(self, writer, self._alloc orelse return error.OptionNotInitialized);
            //}
            if (typeHelpFn: {
                const val_child_type = self.val.childType();
                for (config.child_type_help_fns orelse break :typeHelpFn null) |elm| {
                    if (mem.eql(u8, @typeName(elm.ChildT), val_child_type)) 
                        break :typeHelpFn elm.help_fn;
                }
                else break :typeHelpFn null;
            }) |helpFn| return helpFn(self, writer, self._alloc orelse return error.OptionNotInitialized);
            if (global_help_fn) |helpFn| return helpFn(self, writer, self._alloc orelse return error.OptionNotInitialized);

            var upper_name_buf: [100]u8 = undefined;
            const upper_name = upper_name_buf[0..self.name.len];
            upper_name[0] = toUpper(self.name[0]);
            for(upper_name[1..self.name.len], 1..) |*c, i| c.* = self.name[i];
            if (help_fmt) |h_fmt| return try writer.print(h_fmt, .{ upper_name, self.description });
            try writer.print("{s}:\n{?s}{?s}{?s}", .{ upper_name, indent_fmt, indent_fmt, indent_fmt });
            try self.usage(writer);
            try writer.print("\n{?s}{?s}{?s}{s}", .{ indent_fmt, indent_fmt, indent_fmt, self.description });
        }

        /// Creates the Usage message for this Option and Writes it to the provided Writer (`writer`).
        pub fn usage(self: *const @This(), writer: anytype) !void {
            // (WIP)
            //if (self.usage_fn) |usage_fn_opaque| { 
            //    const usageFn = @as(*const fn(anytype, anytype, mem.Allocator) anyerror!void, @alignCast(@ptrCast(usage_fn_opaque)));
            //    return usageFn(self, writer, self._alloc orelse return error.OptionNotInitialized);
            //}
            if (typeUsageFn: {
                const val_child_type = self.val.childType();
                for (config.child_type_usage_fns orelse break :typeUsageFn null) |elm| {
                    if (mem.eql(u8, @typeName(elm.ChildT), val_child_type)) 
                        break :typeUsageFn elm.usage_fn;
                }
                else break :typeUsageFn null;
            }) |usageFn| return usageFn(self, writer, self._alloc orelse return error.OptionNotInitialized);
            if (global_usage_fn) |usageFn| return usageFn(self, writer, self._alloc orelse return error.OptionNotInitialized);

            try writer.print(usage_fmt, .{ 
                @as(u21, if (self.short_name != null) short_prefix orelse 0x200B else 0x200B),
                @as(u21, if (short_prefix != null) self.short_name orelse 0x200B else 0x200B),
                if (self.short_name != null and self.long_name != null) name_sep_fmt else "",
                if (long_prefix != null and self.long_name != null) long_prefix.? else "",
                if (long_prefix != null) self.long_name orelse "" else "",
                self.val.name(),
                self.val.childType(),
            });
        }

        /// Config for creating Options from Struct Fields using `from()`.
        pub const FromConfig = struct {
            /// Name for the Option.
            name: ?[]const u8 = null,
            /// Short Name for the Option.
            short_name: ?u8 = null,
            /// Long Name for the Option.
            long_name: ?[]const u8 = null,
            /// Ignore Incompatible types or error during Comptime.
            ignore_incompatible: bool = true,
            /// Description for the Option.
            opt_description: ?[]const u8 = null,
            // (WIP)
            ///// Custom Help function.
            ///// Check `Option.Custom.help_fn` for details.
            //help_fn: ?*anyopaque = null,
            ///// Custom Usage function.
            ///// Check `Option.Custom.usage_fn` for details.
            //usage_fn: ?*anyopaque = null,
        };

        /// Create an Option from a Valid Optional StructField or UnionField (`field`) with the provided FromConfig (`from_config`).
        pub fn from(comptime field: anytype, from_config: FromConfig) ?@This() {
            const FieldT = @TypeOf(field);
            if (FieldT != std.builtin.Type.StructField and FieldT != std.builtin.Type.UnionField) 
                @compileError("The provided `field` must be a StructField or UnionField but a '" ++ @typeName(FieldT) ++ "' was provided.");
            const optl_info = @typeInfo(field.type);
            //const optl =
            //    if (optl_info == .Optional) optl_info.Optional
            //    else if (optl_info == .Array and @typeInfo(optl_info.Array.child) == .Optional) @typeInfo(optl_info.Array.child).Optional
            //    else @compileError("The field '" ++ field.name ++ "' is not a Valid Optional or Array of Optionals.");
            const child_info = switch(optl_info) {
                .Optional => @typeInfo(optl_info.Optional.child),
                .Array => |ary| aryInfo: {
                    const ary_info = @typeInfo(ary.child);
                    break :aryInfo
                        if (ary_info == .Optional) @typeInfo(ary_info.Optional.child)
                        else ary_info;
                },
                inline else => optl_info,
            };
            return .{
                .name = if (from_config.name) |name| name else field.name,
                .description = from_config.opt_description orelse "The '" ++ field.name ++ "' Option of type '" ++ @typeName(field.type) ++ "'.",
                .long_name = if (from_config.long_name) |long_name| long_name else field.name,
                .short_name = from_config.short_name, 
                //.help_fn = from_config.help_fn,
                //.usage_fn = from_config.usage_fn,
                .val = optVal: {
                    //const child_info = @typeInfo(optl.child);
                    switch (child_info) {
                        .Bool, .Int, .Float, .Pointer, .Enum => break :optVal ValueT.from(field, .{
                            .ignore_incompatible = from_config.ignore_incompatible,
                            .val_name = from_config.name,
                            .val_description = from_config.opt_description,
                        }) orelse return null,
                        inline else => {
                            if (!from_config.ignore_incompatible) 
                                @compileError("The field '" ++ field.name ++ "' of type '" ++ @typeName(field.type) ++ "' is incompatible as it cannot be converted to a Valid Option or Value.")
                            else return null;
                        },
                    }
                }
            };
        
        }

        /// Initialize this Option with the provided Allocator (`alloc`).
        pub fn init(self: *const @This(), alloc: mem.Allocator) @This() {
            var opt = self.*;
            opt._alloc = alloc;
            opt.val = self.*.val.init(alloc);
            return opt;
        }
    };
} 


