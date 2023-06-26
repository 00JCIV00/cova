//! Cova. Commands, Options, Values, Arguments. A simple command line argument parser for Zig.
//!
//! Cova is based on the idea that Arguments will fall into one of three categories: Commands, Options, or Values. These componenets are assembled into a single struct which is then used to parse argument tokens.

// Standard
const builtin = @import("builtin");
const std = @import("std");
const log = std.log;
const mem = std.mem;
const meta = std.meta;
const proc = std.process;
const testing = std.testing;

const eql = mem.eql;

// Cova
pub const Command = @import("Command.zig");
pub const Option = @import("Option.zig");
pub const Value = @import("Value.zig");

/// A basic Raw Argument Iterator.
/// This is intended for testing, but can also be used to process an externally sourced slice of utf8 argument tokens.
pub const RawArgIterator = struct {
    index: u16 = 0,
    args: []const [:0]const u8,

    /// Get the Next argument token and advance this Iterator.
    pub fn next(self: *@This()) ?[:0]const u8 {
        self.index += 1;
        return if (self.index > self.args.len) null else self.args[self.index - 1];
    }

    /// Peak at the next argument token without advancing this Iterator.
    pub fn peak(self: *@This()) ?[:0]const u8 {
        const peak_arg = self.next();
        self.index -= 1;
        return peak_arg;
    }
};

/// A Generic Interface for ArgumentIterators.
pub const ArgIteratorGeneric = union(enum) {
    raw: RawArgIterator,
    zig: proc.ArgIterator,

    /// Get the Next argument token and advance this Iterator.
    pub fn next(self: *@This()) ?[:0]const u8 {
        return switch (meta.activeTag(self.*)) {
            inline else => |tag| @field(self, @tagName(tag)).next(),
        };
    }

    /// Peak at the next argument token without advancing this Iterator.
    pub fn peak(self: *@This()) ?[:0]const u8 {
        switch (meta.activeTag(self.*)) {
            .raw => return self.raw.peak(),
            inline else => |tag| {
                var iter = @field(self, @tagName(tag));
                // TODO: Create a PR for this in `std.process`?
                if (builtin.os.tag != .windows) {
                    const peak_arg = iter.next();
                    iter.inner.index -= 1;
                    return peak_arg;
                }
                else {
                    const iter_idx = iter.inner.index;
                    const iter_start = iter.inner.start;
                    const iter_end = iter.inner.end;
                    const peak_arg = iter.next();
                    iter.inner.index = iter_idx; 
                    iter.inner.start = iter_start; 
                    iter.inner.end = iter_end; 
                    return peak_arg;
                } 
            },
        }
    }

    /// Get the current Index of this Iterator.
    pub fn index(self: *@This()) usize {
        return switch (meta.activeTag(self.*)) {
            .raw => self.raw.index,
            .zig => self.zig.inner.index,
        };
    }
    
    /// Create a copy of this Generic Interface from the provided ArgIterator
    pub fn from(arg_iter: anytype) @This() {
        const iter_type = @TypeOf(arg_iter);
        return genIter: inline for (meta.fields(@This())) |field| {
            if (field.type == iter_type) break :genIter @unionInit(@This(), field.name, arg_iter);
        }
        else @compileError("The provided type '" ++ @typeName(iter_type) ++ "' is not supported by ArgIteratorGeneric.");
    }

    /// Initialize a copy of this Generic Interface as a `std.process.ArgIterator` which is Zig's cross-platform ArgIterator.
    pub fn init(alloc: mem.Allocator) !@This() {
        return from(try proc.argsWithAllocator(alloc));
    }

    /// De-initialize a copy of this Generic Interface made with `init()`.
    pub fn deinit(self: *@This()) void {
        if (meta.activeTag(self.*) == .zig) self.zig.deinit();
        return;
    }
};

/// Config for custom Parsing options.
pub const ParseConfig = struct {
    /// Mandate that all Values must be filled, otherwise error out.
    /// This should generally be set to `true`. Prefer to use Options over Values for Arguments that are not mandatory.
    vals_mandatory: bool = true,
    /// Skip the first Argument (the executable's name).
    /// This should generally be set to `true`, but the option is here for unforeseen outliers.
    skip_exe_name_arg: bool = true,
    /// Allow there to be no space ' ' between Options and Values.
    /// This is allowed per the POSIX standard, but may not be ideal as it interrupts the parsing of chained booleans even in the event of a misstype.
    allow_opt_val_no_space: bool = true,
    /// Specify custom Separators between Options and their Values.
    /// Spaces ' ' are implicitly included.
    opt_val_seps: []const u8 = "=",
    /// Allow Abbreviated Long Options. (i.e. '--long' working for '--long-opt')
    /// This is allowed per the POSIX standard, but may not be ideal in every use case.
    /// Note, this does not check for uniqueness and will simply match on the first Option matching the abbreviation.
    allow_abbreviated_long_opts: bool = true,
};

var usage_help_flag: bool = false;
/// Parse provided Argument tokens into Commands, Options, and Values.
/// The resulted is stored to the provided CustomCommand `cmd` for user analysis.
pub fn parseArgs(
    args: *ArgIteratorGeneric,
    comptime CustomCommand: type, 
    cmd: *const CustomCommand, 
    writer: anytype,
    parse_config: ParseConfig,
) !void {
    if (!cmd._is_init) return error.CommandNotInitialized;

    var val_idx: u8 = 0;
    const optType = @TypeOf(cmd.*).CustomOption;

    // Bypass argument 0 (the filename being executed);
    const init_arg = if (parse_config.skip_exe_name_arg and args.index() == 0) args.next() else args.peak();
        //else argsPeak(args); 
    log.debug("Parsing Command '{s}'...", .{ cmd.name });
    log.debug("Initial Arg: {?s}", .{ init_arg orelse "END OF ARGS!" });
    defer log.debug("Finished Parsing '{s}'.", .{ cmd.name });

    parseArg: while (args.next()) |arg| {
        log.debug("Current Arg: {s}", .{ arg });
        if (init_arg == null) break :parseArg;
        var unmatched = false;
        // Check for a Sub Command first...
        if (cmd.sub_cmds != null) {
            log.debug("Attempting to Parse Commands...", .{});
            for (cmd.sub_cmds.?) |*sub_cmd| {
                if (eql(u8, sub_cmd.name, arg)) {
                    parseArgs(args, CustomCommand, sub_cmd, writer, parse_config) catch { 
                        try writer.print("Could not parse Command '{s}'.\n", .{ sub_cmd.name });
                        try sub_cmd.usage(writer);
                        try writer.print("\n\n", .{});
                        return error.CouldNotParseCommand;
                    };
                    cmd.setSubCmd(sub_cmd); 
                    continue :parseArg;
                }
            }
            unmatched = true;
            log.debug("No Commands Matched for Command '{s}'.", .{ cmd.name });
        }
        // ...Then for any Options...
        if (cmd.opts != null) {
            log.debug("Attempting to Parse Options...", .{});
            const short_pf = optType.short_prefix;
            const long_pf = optType.long_prefix;
            // - Short Options
            if (arg[0] == short_pf and arg[1] != short_pf) {
                const short_opts = arg[1..];
                shortOpts: for (short_opts, 0..) |short_opt, short_idx| {
                    for (cmd.opts.?) |*opt| {
                        if (opt.short_name != null and short_opt == opt.short_name.?) {
                            // Handle Argument provided to this Option with '=' instead of ' '.
                            if (mem.indexOfScalar(u8, parse_config.opt_val_seps, short_opts[short_idx + 1]) != null) {
                                if (eql(u8, opt.val.valType(), "bool")) {
                                    try writer.print("The Option '{c}{?c}: {s}' is a Boolean/Toggle and cannot take an argument.\n", .{ 
                                        short_pf, 
                                        opt.short_name, 
                                        opt.name 
                                    });
                                    try opt.usage(writer);
                                    try writer.print("\n\n", .{});
                                    return error.BoolCannotTakeArgument;
                                }
                                if (short_idx + 2 >= short_opts.len) return error.EmptyArgumentProvidedToOption;
                                const opt_arg = short_opts[(short_idx + 2)..];
                                opt.val.set(opt_arg) catch {
                                    try writer.print("Could not parse Option '{c}{?c}: {s}'.\n", .{ 
                                        short_pf,
                                        opt.short_name, 
                                        opt.name 
                                    });
                                    try opt.usage(writer);
                                    try writer.print("\n\n", .{});
                                    return error.CouldNotParseOption;
                                };
                                log.debug("Parsed Option '{?c}'.", .{ opt.short_name });
                                continue :parseArg;
                            }
                            // Handle final Option in a chain of Short Options
                            else if (short_idx == short_opts.len - 1) { 
                                if (eql(u8, opt.val.valType(), "bool")) try @constCast(opt).val.set("true")
                                else {
                                    parseOpt(args, @TypeOf(opt.*), opt) catch {
                                        try writer.print("Could not parse Option '{c}{?c}: {s}'.\n", .{ 
                                            short_pf,
                                            opt.short_name, 
                                            opt.name 
                                        });
                                        try opt.usage(writer);
                                        try writer.print("\n\n", .{});
                                        return error.CouldNotParseOption;
                                    };
                                }
                                log.debug("Parsed Option '{?c}'.", .{ opt.short_name });
                                continue :parseArg;
                            }
                            // Handle a boolean Option before the final Short Option in a chain.
                            else if (eql(u8, opt.val.valType(), "bool")) {
                                try @constCast(opt).val.set("true");
                                log.debug("Parsed Option '{?c}'.", .{ opt.short_name });
                                continue :shortOpts;
                            }
                            // Handle a non-boolean Option which is given a Value without a space ' ' to separate them.
                            else if (parse_config.allow_opt_val_no_space) {
                                var short_names_buf: [100]u8 = undefined;
                                const short_names = short_names_buf[0..];
                                for (cmd.opts.?, 0..) |s_opt, idx| short_names[idx] = s_opt.short_name.?;
                                if (mem.indexOfScalar(u8, short_names, short_opts[short_idx + 1]) == null) {
                                    try @constCast(opt).val.set(short_opts[(short_idx + 1)..]);
                                    log.debug("Parsed Option '{?c}'.", .{ opt.short_name });
                                    continue :parseArg;
                                }
                            }
                        }
                    }
                    try writer.print("Could not parse Option '{c}{?c}'.\n", .{ short_pf, short_opt });
                    try cmd.usage(writer);
                    try writer.print("\n\n", .{});
                    return error.CouldNotParseOption;
                }
            }
            // - Long Options
            else if (eql(u8, arg[0..long_pf.len], long_pf)) {
                const split_idx = (mem.indexOfAny(u8, arg[long_pf.len..], parse_config.opt_val_seps) orelse arg.len - long_pf.len) + long_pf.len;
                const long_opt = arg[long_pf.len..split_idx]; 
                const sep_arg = if (split_idx < arg.len) arg[split_idx + 1..] else "";
                const sep_flag = mem.indexOfAny(u8, arg[long_pf.len..], parse_config.opt_val_seps) != null; 
                for (cmd.opts.?) |*opt| {
                    if (opt.long_name != null) {
                        if (
                            eql(u8, long_opt, opt.long_name.?) or
                            (parse_config.allow_abbreviated_long_opts and mem.indexOf(u8, opt.long_name.?, long_opt) != null and opt.long_name.?[0] == long_opt[0])
                        ) {
                            if (sep_flag) {
                                if (eql(u8, opt.val.valType(), "bool")) {
                                    try writer.print("The Option '{s}{?s}: {s}' is a Boolean/Toggle and cannot take an argument.\n", .{ 
                                        long_pf, 
                                        opt.long_name, 
                                        opt.name 
                                    });
                                    try opt.usage(writer);
                                    try writer.print("\n\n", .{});
                                    return error.BoolCannotTakeArgument;
                                }
                                if (sep_arg.len == 0) return error.EmptyArgumentProvidedToOption;
                                opt.val.set(sep_arg) catch {
                                    try writer.print("Could not parse Option '{s}{?s}: {s}'.\n", .{ 
                                        long_pf,
                                        opt.long_name, 
                                        opt.name 
                                    });
                                    try opt.usage(writer);
                                    try writer.print("\n\n", .{});
                                    return error.CouldNotParseOption;
                                };
                                log.debug("Parsed Option '{?s}'.", .{ opt.long_name });
                                continue :parseArg;
                            }
                        
                            // Handle normally provided Value to Option

                            // Handle Boolean/Toggle Option.
                            if (eql(u8, opt.val.valType(), "bool")) try @constCast(opt).val.set("true")
                            // Handle Option with normal Argument.
                            else {
                                parseOpt(args, @TypeOf(opt.*), opt) catch {
                                    try writer.print("Could not parse Option '{s}{?s}: {s}'.\n", .{ 
                                        long_pf,
                                        opt.long_name, 
                                        opt.name 
                                    });
                                    try opt.usage(writer);
                                    try writer.print("\n\n", .{});
                                    return error.CouldNotParseOption;
                                };
                            }
                            log.debug("Parsed Option '{?s}'.", .{ opt.long_name });
                            continue :parseArg;
                        }
                    }
                }
                try writer.print("Could not parse Argument '{s}{?s}' to an Option.\n", .{ long_pf, long_opt });
                try cmd.usage(writer);
                try writer.print("\n\n", .{});
                return error.CouldNotParseOption;
            }
            unmatched = true;
            log.debug("No Options Matched for Command '{s}'.", .{ cmd.name });
        }
        // ...Finally, for any Values.
        if (cmd.vals != null) {
            log.debug("Attempting to Parse Values...", .{});
            if (val_idx >= cmd.vals.?.len) {
                try writer.print("Too many Values provided for Command '{s}'.\n", .{ cmd.name });
                try cmd.usage(writer);
                return error.TooManyValues;
            }
            const val = &cmd.vals.?[val_idx];
            val.set(arg) catch {
                try writer.print("Could not parse Argument '{s}' to Value '{s}'.\n", .{ arg, val.name() });
                try cmd.usage(writer);
                try writer.print("\n", .{});
            };

            if (val.argIdx() == val.maxArgs()) val_idx += 1;

            log.debug("Parsed Value '{?s}'.", .{ val.name() });
            continue :parseArg;
        }

        // Check if the Command expected an Argument but didn't get a match.
        if (unmatched) {
            try writer.print("Unrecognized Argument '{s}' for Command '{s}'.\n", .{ arg, cmd.name });
            try cmd.help(writer);
            return error.UnrecognizedArgument;
        }
        // For Commands that expect no Arguments but are given one, fail to the Help message.
        else {
            try writer.print("Command '{s}' does not expect any arguments, but '{s}' was passed.\n", .{ cmd.name, arg });
            try cmd.help(writer);
            return error.UnexpectedArgument;
        }
    }
    // Check for missing Values if they are Mandated.
    if (!usage_help_flag) usage_help_flag = (cmd.checkFlag("help") or cmd.checkFlag("usage"));
    if (parse_config.vals_mandatory and 
        cmd.vals != null and 
        val_idx < cmd.vals.?.len and
        !usage_help_flag
    ) {
        try writer.print("Command '{s}' expects {d} Values, but only recieved {d}.\n", .{
            cmd.name,
            cmd.vals.?.len,
            val_idx,
        });
        try cmd.help(writer);
        return error.ExpectedMoreValues;
    }
}

/// Parse an Option for the given Command.
fn parseOpt(args: *ArgIteratorGeneric, comptime opt_type: type, opt: *const opt_type) !void {
    const peak_arg = args.peak();
    const set_arg = 
        if (peak_arg == null or peak_arg.?[0] == '-') setArg: {
            if (!eql(u8, opt.val.valType(), "bool")) return error.EmptyArgumentProvidedToOption;
            _ = args.next();
            break :setArg "true";
        }
        else args.next().?;
    log.debug("Current Arg: {s}", .{ set_arg });
    try opt.val.set(set_arg);
}


