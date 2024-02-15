//!zig-autodoc-section: Getting Started
//!zig-autodoc-guide: ./../docs/guides/overview.md 
//!zig-autodoc-guide: ./../docs/guides/getting_started/install.md 
//!zig-autodoc-guide: ./../docs/guides/getting_started/quick_setup.md 
//!zig-autodoc-guide: ./../docs/guides/getting_started/naming_conventions.md
//!zig-autodoc-section: Argument Types
//!zig-autodoc-guide: ./../docs/guides/arg_types/command.md 
//!zig-autodoc-guide: ./../docs/guides/arg_types/option.md 
//!zig-autodoc-guide: ./../docs/guides/arg_types/value.md 
//!zig-autodoc-section: Parsing & Analysis
//!zig-autodoc-guide: ./../docs/guides/parsing_analysis/parsing.md 
//!zig-autodoc-guide: ./../docs/guides/parsing_analysis/analysis.md 
//!zig-autodoc-guide: ./../docs/guides/parsing_analysis/usage_help.md 
//!zig-autodoc-guide: ./../docs/guides/parsing_analysis/arg_groups.md 
//!zig-autodoc-guide: ./../docs/guides/parsing_analysis/aliases.md 

//! Cova. Commands, Options, Values, Arguments. A simple yet robust command line argument parsing library for Zig.
//!
//! Cova is based on the idea that Arguments will fall into one of three types: Commands, Options, or Values. These types are assembled into a single Command struct which is then used to parse argument tokens.

// Standard
const builtin = @import("builtin");
const std = @import("std");
const ascii = std.ascii;
const log = std.log;
const mem = std.mem;
const meta = std.meta;
const proc = std.process;
const testing = std.testing;

// Cova
pub const Command = @import("Command.zig");
pub const Option = @import("Option.zig");
pub const Value = @import("Value.zig");
pub const generate = @import("generate.zig");
pub const utils = @import("utils.zig");


/// Config for custom argument tokenization using `tokenizeArgs()`.
pub const TokenizeConfig = struct{
    /// Delimiter Characters
    delimiters: []const u8 = " ",
    /// Grouping Open Characters
    /// Note, these Characters must line up with `groupers_close` in pairs. These pairs represent either side of a grouped argument.
    /// For example, setting open to `'('` and closed to `')'` will group all tokens between parantheses into one argument as seen here:
    ///
    /// `my-cmd --str-opt (this whole string will be one argument.)`
    groupers_open: []const u8 = "\"'",
    /// Grouping Close Characters
    /// Refer to `groupers_open` for more info.
    groupers_close: []const u8 = "\"'",
};

/// Tokenize an Argument String (`arg_str`) into a slice of Strings using the provided Allocator (`alloc`) and TokenizeConfig (`token_config`).
/// By default, this handles basic quoting using single or double quotes (`'` or `"`) with no support for escape sequences.
pub fn tokenizeArgs(arg_str: []const u8, alloc: mem.Allocator, token_config: TokenizeConfig) ![]const []const u8 {
    var start: usize = 0;
    var end: usize = 0;
    var quote_char: ?u8 = null;
    var args_list = std.ArrayList([]const u8).init(alloc);

    if (token_config.groupers_open.len != token_config.groupers_close.len) {
        log.err("The length of `token_config.groupers_open` must match that of `token_config.groupers_close`. These should be open/close pairs.", .{});
        return error.UnbalancedGrouperPairs;
    }

    for (arg_str, 0..) |char, idx| {
        if (mem.indexOfScalar(u8, token_config.delimiters, char) != null and quote_char == null) {
            end = idx;
            if (start == end) {
                start += 1;
                continue;
            }
            //try args_list.append(try alloc.dupe(u8, arg_str[start..end]));
            try args_list.append(arg_str[start..end]);
            start = end + 1;
        }
        else if (quote_char == null and mem.indexOfScalar(u8, token_config.groupers_open, char) != null) {
            if (mem.indexOfScalar(u8, token_config.groupers_open, char)) |close_idx| {
                quote_char = token_config.groupers_close[close_idx];
                start = idx + 1;
            }
        }
        else if (quote_char) |q_char| {
            if (char == q_char) {
                end = idx;
                //try args_list.append(try alloc.dupe(u8, arg_str[start..end]));
                try args_list.append(arg_str[start..end]);
                start = end + 1;
                quote_char = null;
            }
        }
        else if (idx == arg_str.len - 1) {
            end = arg_str.len;
            //try args_list.append(try alloc.dupe(u8, arg_str[start..end]));
            try args_list.append(arg_str[start..end]);
        }
    }

    return try args_list.toOwnedSlice();
}

/// A basic Raw Argument Iterator.
/// This is intended for testing, but can also be used to process an externally sourced slice of utf-8 argument tokens.
pub const RawArgIterator = struct {
    index: u16 = 0,
    args: []const [:0]const u8,

    /// Get the Next argument token and advance this Iterator.
    pub fn next(self: *@This()) ?[:0]const u8 {
        self.index += 1;
        return if (self.index > self.args.len) null else self.args[self.index - 1];
    }

    /// Peek at the next argument token without advancing this Iterator.
    pub fn peek(self: *@This()) ?[:0]const u8 {
        const peek_arg = self.next();
        self.index -= 1;
        return peek_arg;
    }
};

/// A Generic Interface for Argument Iterators.
pub const ArgIteratorGeneric = union(enum) {
    raw: RawArgIterator,
    zig: proc.ArgIterator,

    /// Get the Next argument token and advance this Iterator.
    pub fn next(self: *@This()) ?[:0]const u8 {
        return switch (meta.activeTag(self.*)) {
            inline else => |tag| @field(self, @tagName(tag)).next(),
        };
    }

    /// Peek at the next argument token without advancing this Iterator.
    pub fn peek(self: *@This()) ?[:0]const u8 {
        switch (meta.activeTag(self.*)) {
            .raw => return self.raw.peek(),
            inline else => |tag| {
                var iter = @field(self, @tagName(tag));
                // TODO: Create a PR for this in `std.process`?
                if (builtin.os.tag != .windows) {
                    const peek_arg = iter.next();
                    iter.inner.index -= 1;
                    return peek_arg;
                }
                else {
                    const iter_idx = iter.inner.index;
                    const iter_start = iter.inner.start;
                    const iter_end = iter.inner.end;
                    const peek_arg = iter.next();
                    iter.inner.index = iter_idx; 
                    iter.inner.start = iter_start; 
                    iter.inner.end = iter_end; 
                    return peek_arg;
                } 
            },
        }
    }

    /// Reset this Argument Iterator.
    pub fn reset(self: *@This()) void {
        switch (meta.activeTag(self.*)) {
            .raw => self.raw.index = 0,
            inline else => |tag| {
                var iter = &@field(self, @tagName(tag));
                if (builtin.os.tag != .windows) iter.inner.index = 0
                else {
                    iter.inner.index = 0; 
                    iter.inner.start = 0; 
                    iter.inner.end = 0; 
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
    
    /// Create a copy of this Generic Interface from the provided ArgIterator (`arg_iter`).
    pub fn from(arg_iter: anytype) @This() {
        const iter_type = @TypeOf(arg_iter);
        return genIter: inline for (meta.fields(@This())) |field| {
            if (field.type == iter_type) break :genIter @unionInit(@This(), field.name, arg_iter);
        }
        else @compileError("The provided type '" ++ @typeName(iter_type) ++ "' is not supported by the ArgIteratorGeneric Interface.");
    }

    /// Initialize a copy of this Generic Interface as a `std.process.ArgIterator` which is Zig's cross-platform ArgIterator. If needed, this will use the provided Allocator (`alloc`).
    pub fn init(alloc: mem.Allocator) !@This() {
        return from(try proc.argsWithAllocator(alloc));
    }

    /// De-initialize a copy of this Generic Interface made with `init()`.
    pub fn deinit(self: *@This()) void {
        if (meta.activeTag(self.*) == .zig) self.zig.deinit();
        return;
    }
};

/// Config for custom argument token Parsing using `parseArgs()`.
pub const ParseConfig = struct {
    /// Skip the first Argument (the executable's name).
    /// This should generally be set to `true`, but the option is here for unforeseen outliers.
    skip_exe_name_arg: bool = true,
    /// Auto-handle Usage/Help messages during parsing.
    /// This is especially useful if used in conjuction with the default auto-generated Usage/Help messages from Command and Option.
    /// Note, this will return with `error.UsageHelpCalled` so the library user can terminate the program early afterwards if desired.
    auto_handle_usage_help: bool = true,
    /// Decide how to react to parsing errors.
    err_reaction: ParseErrorReaction = .Help,
    /// Enable Option Termination using the long prefix without an Option (default `--` per the POSIX standard).
    /// Note, this will cause the remainder of the argument tokens to be read in as either Commands or Values.
    enable_opt_termination: bool = true,
    /// Override the Optiion Termination Symbol.
    /// Leaving this null will default to the long prefix of the associated Option Type.
    set_opt_termination_symbol: ?[]const u8 = null,

    /// Reactions for Parsing Errors.
    const ParseErrorReaction = enum {
        /// Display the current Argument's Usage message.
        Usage,
        /// Display the current Argument's Help message.
        Help,
        /// Do nothing. This is useful for custom handling.
        None,
    };
};

/// Parse the provided Argument tokens (`args`) into Commands, Options, and Values.
/// The parsed result is stored to the provided `CommandT` (`cmd`) for user analysis.
pub fn parseArgs(
    args: *ArgIteratorGeneric,
    comptime CommandT: type, 
    cmd: *const CommandT, 
    writer: anytype,
    parse_config: ParseConfig,
) !void {
    var parse_ctx: ParseCtx = .{
        .arg_idx = if (parse_config.skip_exe_name_arg) 1 else 0,
    };
    try parseArgsCtx(
        args,
        CommandT,
        cmd,
        writer,
        parse_config,
        &parse_ctx,
    );
}


const ParseCtx = struct{
    usage_help_flag: bool = false,
    arg_idx: u8 = 0,
};
/// Parse the provided Argument tokens (`args`) into Commands, Options, and Values.
/// The parsed result is stored to the provided `CommandT` (`cmd`) for user analysis.
fn parseArgsCtx(
    args: *ArgIteratorGeneric,
    comptime CommandT: type, 
    cmd: *const CommandT, 
    writer: anytype,
    parse_config: ParseConfig,
    parse_ctx: *ParseCtx,
) !void {
    if (cmd._alloc == null) return error.CommandNotInitialized;

    var val_idx: u8 = 0;
    var opt_term: bool = false;
    const OptionT = CommandT.OptionT;

    // Bypass argument 0 (the filename being executed);
    const init_arg = if (parse_config.skip_exe_name_arg and args.index() == 0) args.next() else args.peek();
    log.debug("Parsing Command '{s}'...", .{ cmd.name });
    log.debug("Initial Arg: {?s}", .{ init_arg orelse "END OF ARGS!" });
    defer log.debug("Finished Parsing '{s}'.", .{ cmd.name });


    parseArg: while (args.next()) |arg| {
        // Check for Usage/Help flags and run their respective methods.
        if (parse_config.auto_handle_usage_help and try cmd.checkUsageHelp(writer)) return error.UsageHelpCalled; 

        log.debug("Current Arg: {s}", .{ arg });
        if (init_arg == null) break :parseArg;
        var unmatched = false;
        // Check for a Sub Command first...
        if (cmd.sub_cmds) |cmds| {
            log.debug("Attempting to Parse Commands...", .{});
            checkCmds: for (cmds) |*sub_cmd| {
                const should_parse = shouldParse: {
                    if (sub_cmd.case_sensitive) {
                        if (mem.eql(u8, sub_cmd.name, arg)) break :shouldParse true
                        else for (sub_cmd.alias_names orelse continue :checkCmds) |alias| if (mem.eql(u8, alias, arg)) break :shouldParse true;
                    }
                    else {
                        if (ascii.eqlIgnoreCase(sub_cmd.name, arg)) break :shouldParse true
                        else for (sub_cmd.alias_names orelse continue :checkCmds) |alias| if (ascii.eqlIgnoreCase(alias, arg)) break :shouldParse true;
                    }
                    break :shouldParse false;
                };
                if (should_parse) {
                    cmd.setArgIdx(parse_ctx.arg_idx);
                    parse_ctx.*.arg_idx += 1;
                    parseArgsCtx(args, CommandT, sub_cmd, writer, parse_config, parse_ctx) catch |err| return err;
                    cmd.setSubCmd(sub_cmd);
                    continue :parseArg;
                }
            }
            unmatched = true;
            log.debug("No Commands Matched for Command '{s}'.", .{ cmd.name });
        }
        // ...Then for any Options...
        var inherit_cmd: ?*const CommandT = cmd;
        var inheriting = false;
        inheritOpts: while (inherit_cmd) |opts_cmd| : ({
            if (cmd.allow_inheritable_opts) {
                inherit_cmd = inherit_cmd.?.parent_cmd;
                inheriting = true;
                if (inherit_cmd) |i_cmd| log.debug("Attempting to Parse Inherited Options for '{s}'...", .{ i_cmd.name })
                else log.debug("No higher parent Command to inherit from for '{s}'.", .{ opts_cmd.name });
            }
            else inherit_cmd = null;
        }) {
            if (opts_cmd.opts != null and !opt_term) {
                log.debug("Attempting to Parse Options...", .{});
                // - Check for Option Termination
                opt_term = optTerm: {
                    const opt_term_sym =
                        parse_config.set_opt_termination_symbol orelse
                        OptionT.long_prefix orelse
                        break :optTerm false;
                    if (mem.eql(u8, arg, opt_term_sym) and parse_config.enable_opt_termination) {
                        log.debug("Terminated Option Parsing!", .{});
                        break :optTerm true;
                    }
                    break :optTerm false;
                };
                if (opt_term) continue :parseArg;
                // - Short Options
                if (OptionT.short_prefix) |short_pf| checkShortOpt: {
                    if (!(arg[0] == short_pf and arg[1] != short_pf)) break :checkShortOpt;
                    log.debug("Parsing Short Option...", .{});
                    const short_opts = arg[1..];
                    shortOpts: for (short_opts, 0..) |short_opt, short_idx| {
                        for (opts_cmd.opts.?) |*opt| {
                            if (cmd.allow_inheritable_opts and inheriting and !opt.inheritable) continue :shortOpts;
                            if (opt.short_name != null and short_opt == opt.short_name.?) {
                                // Handle Argument provided to this Option with the Option/Value Separator (like '=') instead of ' '.
                                if (mem.indexOfScalar(u8, CommandT.OptionT.opt_val_seps, short_opts[short_idx + 1]) != null) {
                                    if (mem.eql(u8, opt.val.childType(), "bool") and !opt.val.hasCustomParseFn()) {
                                        log.err("The Option '{c}{?c}: {s}' is a Boolean/Toggle and cannot take an argument.", .{ 
                                            short_pf, 
                                            opt.short_name, 
                                            opt.name 
                                        });
                                        try errReaction(parse_config.err_reaction, opt, writer);
                                        try writer.print("\n", .{});
                                        return error.BoolCannotTakeArgument;
                                    }
                                    if (short_idx + 2 >= short_opts.len) return error.EmptyArgumentProvidedToOption;
                                    const opt_arg = short_opts[(short_idx + 2)..];
                                    opt.val.set(opt_arg) catch {
                                        if (cmd.allow_inheritable_opts) continue :inheritOpts;
                                        log.err("Could not parse Option '{c}{?c}: {s}'.", .{ 
                                            short_pf,
                                            opt.short_name, 
                                            opt.name 
                                        });
                                        try errReaction(parse_config.err_reaction, opt, writer);
                                        try writer.print("\n", .{});
                                        return error.CouldNotParseOption;
                                    };
                                    try opt.setArgIdx(parse_ctx.arg_idx);
                                    parse_ctx.*.arg_idx += 1;
                                    log.debug("Parsed Option '{?c}'.", .{ opt.short_name });
                                    continue :parseArg;
                                }
                                // Handle final Option in a chain of Short Options
                                else if (short_idx == short_opts.len - 1) { 
                                    if (mem.eql(u8, opt.val.childType(), "bool")) try @constCast(opt).val.set("true")
                                    else {
                                        parseOpt(args, OptionT, opt) catch {
                                            if (cmd.allow_inheritable_opts) continue :inheritOpts;
                                            log.err("Could not parse Option '{c}{?c}: {s}'.", .{ 
                                                short_pf,
                                                opt.short_name, 
                                                opt.name 
                                            });
                                            try errReaction(parse_config.err_reaction, opt, writer);
                                            try writer.print("\n", .{});
                                            return error.CouldNotParseOption;
                                        };
                                    }
                                    try opt.setArgIdx(parse_ctx.arg_idx);
                                    parse_ctx.*.arg_idx += 1;
                                    log.debug("Parsed Option '{?c}'.", .{ opt.short_name });
                                    continue :parseArg;
                                }
                                // Handle a boolean Option before the final Short Option in a chain.
                                else if (mem.eql(u8, opt.val.childType(), "bool")) {
                                    try @constCast(opt).val.set("true");
                                    try opt.setArgIdx(parse_ctx.arg_idx);
                                    parse_ctx.*.arg_idx += 1;
                                    log.debug("Parsed Option '{?c}'.", .{ opt.short_name });
                                    continue :shortOpts;
                                }
                                // Handle a non-boolean Option which is given a Value without a space ' ' to separate them.
                                else if (CommandT.OptionT.allow_opt_val_no_space) {
                                    var short_names_buf: [CommandT.max_args]u8 = undefined;
                                    const short_names = short_names_buf[0..];
                                    for (cmd.opts.?, 0..) |s_opt, idx| short_names[idx] = s_opt.short_name.?;
                                    if (mem.indexOfScalar(u8, short_names, short_opts[short_idx + 1]) == null) {
                                        try @constCast(opt).val.set(short_opts[(short_idx + 1)..]);
                                        try opt.setArgIdx(parse_ctx.arg_idx);
                                        parse_ctx.*.arg_idx += 1;
                                        log.debug("Parsed Option '{?c}'.", .{ opt.short_name });
                                        continue :parseArg;
                                    }
                                }
                            }
                        }
                        if (cmd.allow_inheritable_opts) continue :inheritOpts;
                        log.err("Could not parse Option '{c}{?c}'.", .{ short_pf, short_opt });
                        try errReaction(parse_config.err_reaction, cmd, writer);
                        try writer.print("\n", .{});
                        return error.CouldNotParseOption;
                    }
                }
                // - Long Options
                if (OptionT.long_prefix) |long_pf| checkLongOpt: {
                    if (!mem.eql(u8, arg[0..long_pf.len], long_pf)) break :checkLongOpt;
                    log.debug("Parsing Long Option...", .{});
                    const split_idx = (mem.indexOfAny(u8, arg[long_pf.len..], OptionT.opt_val_seps) orelse arg.len - long_pf.len) + long_pf.len;
                    const long_opt = arg[long_pf.len..split_idx]; 
                    const sep_arg = if (split_idx < arg.len) arg[split_idx + 1..] else "";
                    const sep_flag = mem.indexOfAny(u8, arg[long_pf.len..], OptionT.opt_val_seps) != null; 
                    longOpts: for (opts_cmd.opts.?) |*opt| {
                        if (cmd.allow_inheritable_opts and inheriting and !opt.inheritable) continue :longOpts;
                        const opt_long_name = opt.long_name orelse continue :longOpts;
                        var long_names: [17][]const u8 = undefined;
                        var long_names_len: usize = 1;
                        long_names[0] = opt_long_name;
                        if (opt.alias_long_names) |aliases| {
                            long_names_len += aliases.len;
                            for (aliases, 0..) |alias, idx| long_names[idx + 1] = alias;
                        }
                        for (long_names[0..long_names_len]) |long_name| {
                            if (matchOpt: {
                                break :matchOpt if (opt.case_sensitive)
                                    mem.eql(u8, long_opt, long_name) or
                                    (OptionT.allow_abbreviated_long_opts and mem.indexOf(u8, long_name, long_opt) != null and long_name[0] == long_opt[0])
                                else
                                    ascii.eqlIgnoreCase(long_opt, long_name) or
                                    (
                                        OptionT.allow_abbreviated_long_opts and 
                                        ascii.indexOfIgnoreCase(long_name, long_opt) != null and 
                                        ascii.eqlIgnoreCase(long_name[0..1], long_opt[0..1])
                                    );
                            }) {
                                if (sep_flag) {
                                    if (mem.eql(u8, opt.val.childType(), "bool") and !opt.val.hasCustomParseFn()) {
                                        log.err("The Option '{s}{?s}: {s}' is a Boolean/Toggle and cannot take an argument.", .{ 
                                            long_pf, 
                                            long_name, 
                                            opt.name 
                                        });
                                        try errReaction(parse_config.err_reaction, opt, writer);
                                        try writer.print("\n", .{});
                                        return error.BoolCannotTakeArgument;
                                    }
                                    if (sep_arg.len == 0) return error.EmptyArgumentProvidedToOption;
                                    opt.val.set(sep_arg) catch {
                                        if (cmd.allow_inheritable_opts) continue :inheritOpts;
                                        log.err("Could not parse Option '{s}{?s}: {s}'.", .{ 
                                            long_pf,
                                            long_name, 
                                            opt.name 
                                        });
                                        try errReaction(parse_config.err_reaction, opt, writer);
                                        try writer.print("\n", .{});
                                        return error.CouldNotParseOption;
                                    };
                                    try opt.setArgIdx(parse_ctx.arg_idx);
                                    parse_ctx.*.arg_idx += 1;
                                    log.debug("Parsed Option '{?s}'.", .{ opt.long_name });
                                    continue :parseArg;
                                }

                                // Handle normally provided Value to Option

                                // Handle Boolean/Toggle Option.
                                if (mem.eql(u8, opt.val.childType(), "bool")) try @constCast(opt).val.set("true")
                                // Handle Option with normal Argument.
                                else {
                                    parseOpt(args, OptionT, opt) catch {
                                        if (cmd.allow_inheritable_opts) continue :inheritOpts;
                                        log.err("Could not parse Option '{s}{?s}: {s}'.", .{ 
                                            long_pf,
                                            long_name, 
                                            opt.name 
                                        });
                                        try errReaction(parse_config.err_reaction, opt, writer);
                                        try writer.print("\n", .{});
                                        return error.CouldNotParseOption;
                                    };
                                }
                                try opt.setArgIdx(parse_ctx.arg_idx);
                                parse_ctx.*.arg_idx += 1;
                                log.debug("Parsed Option '{?s}'.", .{ opt.long_name });
                                continue :parseArg;
                            }
                        }
                    }
                    if (cmd.allow_inheritable_opts) continue :inheritOpts;
                    log.err("Could not parse Argument '{s}{?s}' to an Option.", .{ long_pf, long_opt });
                    try errReaction(parse_config.err_reaction, cmd, writer);
                    try writer.print("\n", .{});
                    return error.CouldNotParseOption;
                }
                unmatched = true;
                log.debug("No Options Matched for Command '{s}'.", .{ opts_cmd.name });
                if (cmd.allow_inheritable_opts) continue :inheritOpts;
            }
        }
        // ...Finally, for any Values.
        if (cmd.vals) |vals| {
            log.debug("Attempting to Parse Values...", .{});
            if (val_idx >= vals.len) {
                log.err("Too many Values provided for Command '{s}'.", .{ cmd.name });
                try errReaction(parse_config.err_reaction, cmd, writer);
                return error.TooManyValues;
            }
            var cur_val: ?*const CommandT.ValueT = &vals[val_idx];
            while (cur_val) |val| : (cur_val = &vals[val_idx]) {
                val.set(arg) catch {
                    log.debug("Could not parse Argument '{s}' to Value '{s}'.", .{ arg, val.name() });
                    if (val_idx + 1 < vals.len and !cmd.vals_mandatory) {
                        val_idx += 1;
                        continue;
                    }
                    log.err("Could not parse Argument '{s}' to any Value for Command '{s}'.", .{ arg, cmd.name });
                    try errReaction(parse_config.err_reaction, cmd, writer);
                    log.err("", .{});
                    return error.CouldNotParseValue;
                };
                if (val.argIdx() == val.maxArgs()) val_idx += 1;

                try val.setArgIdx(parse_ctx.arg_idx);
                parse_ctx.*.arg_idx += 1;
                log.debug("Parsed Value '{?s}'.", .{ val.name() });
                continue :parseArg;
            }
        }

        // Check if the Command expected an Argument but didn't get a match.
        if (unmatched) {
            log.err("Unrecognized Argument '{s}' for Command '{s}'.", .{ arg, cmd.name });
            try errReaction(parse_config.err_reaction, cmd, writer);
            return error.UnrecognizedArgument;
        }
        // For Commands that expect no Arguments but are given one, fail to the Help message.
        else {
            log.err("Command '{s}' does not expect any arguments, but '{s}' was passed.", .{ cmd.name, arg });
            try errReaction(parse_config.err_reaction, cmd, writer);
            return error.UnexpectedArgument;
        }
    }
    // Check if a Sub Command has been set if it is Mandated for the current Command.
    if (cmd.sub_cmds_mandatory and cmd.sub_cmd == null and
        !(cmd.sub_cmds != null and cmd.sub_cmds.?.len == 2 and 
            (mem.eql(u8, cmd.sub_cmds.?[0].name, "usage") or mem.eql(u8, cmd.sub_cmds.?[0].name, "help"))) and
        !(cmd.checkFlag("help") or cmd.checkFlag("usage")) and
        !(mem.eql(u8, cmd.name, "help") or mem.eql(u8, cmd.name, "usage"))
    ) {
        log.err("Command '{s}' requires a Sub Command.", .{ cmd.name });
        try errReaction(parse_config.err_reaction, cmd, writer);
        return error.ExpectedSubCommand;
    }
    // Check that all Mandatory Options have been set.
    if (cmd.opts) |opts| manOpts: {
        if (!parse_ctx.usage_help_flag) parse_ctx.*.usage_help_flag = (cmd.checkFlag("help") or cmd.checkFlag("usage"));
        if (parse_ctx.usage_help_flag) break :manOpts;
        for (opts) |opt| {
            const group_man = groupMan: {
                const man_groups = cmd.mandatory_opt_groups orelse break :groupMan false;
                const group = opt.opt_group orelse break :groupMan false;
                break :groupMan utils.indexOfEql([]const u8, man_groups, group) != null;
            };
            if (
                (opt.mandatory or group_man) and 
                !(opt.val.isSet() or opt.val.hasDefault())
            ) {
                log.err("Option '{s}' is mandatory.", .{ opt.name });
                try errReaction(parse_config.err_reaction, cmd, writer);
                return error.ExpectedOption;
            }
        }
    }
    // Check for missing Values if they are Mandated for the current Command.
    if (!parse_ctx.usage_help_flag) parse_ctx.*.usage_help_flag = (cmd.checkFlag("help") or cmd.checkFlag("usage"));
    if (cmd.vals_mandatory and 
        cmd.vals != null and 
        val_idx < cmd.vals.?.len and
        !parse_ctx.usage_help_flag
    ) {
        log.err("Command '{s}' expects {d} Values, but only received {d}.", .{
            cmd.name,
            cmd.vals.?.len,
            val_idx,
        });
        try errReaction(parse_config.err_reaction, cmd, writer);
        return error.ExpectedMoreValues;
    }
    // Check for Usage/Help flags and run their respective methods.
    if (parse_config.auto_handle_usage_help and try cmd.checkUsageHelp(writer)) return error.UsageHelpCalled; 
}

/// Parse the provided `OptionType` (`opt`).
fn parseOpt(args: *ArgIteratorGeneric, comptime OptionType: type, opt: *const OptionType) !void {
    const peek_arg = args.peek();
    const set_arg = 
        if (peek_arg == null or peek_arg.?[0] == '-') setArg: {
            if (!(mem.eql(u8, opt.val.childType(), "bool") and !opt.val.hasCustomParseFn())) return error.EmptyArgumentProvidedToOption;
            _ = args.next();
            break :setArg "true";
        }
        else args.next().?;
    log.debug("Current Arg: {s}", .{ set_arg });
    try opt.val.set(set_arg);
}

/// React to Parsing Errors with the given Reaction (`reaction`) based on the provided Argument (`arg`) to the provided Writer (`writer`).
fn errReaction(reaction: ParseConfig.ParseErrorReaction, arg: anytype, writer: anytype) !void {
    return switch(reaction) {
        .Usage => arg.usage(writer),
        .Help => arg.help(writer),
        .None => {},
    };
}


// TESTING
const TestCommand = Command.Custom(.{ 
    .global_vals_mandatory = false,
    .global_sub_cmds_mandatory = false,
});
const TestValue = TestCommand.ValueT;
const test_setup_cmd: TestCommand = .{
    .name = "test-cmd",
    .description = "A Test Command.",
    .sub_cmds = &.{
        .{
            .name = "sub-test-cmd",
            .description = "A Test Sub Command.",
            .opts = &.{            
                .{
                    .name = "sub_string_opt",
                    .description = "A test sub string long option.",
                    .short_name = 'S',
                    .long_name = "sub-string",
                    .val = TestValue.ofType([]const u8, .{
                        .name = "sub_string_opt_val",
                        .description = "A test sub string opt value.",
                    }),
                },
                .{
                    .name = "sub_int_opt",
                    .description = "A test sub integer option.",
                    .short_name = 'I',
                    .long_name = "sub-int",
                    .val = TestValue.ofType(i16, .{
                        .name = "int_opt_val",
                        .description = "A test sub integer opt value.",
                    }),
                },
            },
        },
    },
    .opts = &.{
        .{
            .name = "string_opt",
            .description = "A test string long option.",
            .short_name = 's',
            .long_name = "string",
            .val = TestValue.ofType([]const u8, .{
                .name = "string_opt_val",
                .description = "A test string opt value.",
                .set_behavior = .Multi,
                .max_args = 6,
            }),
        },
        .{
            .name = "int_opt",
            .description = "A test integer option.",
            .short_name = 'i',
            .long_name = "int",
            .val = TestValue.ofType(i16, .{
                .name = "int_opt_val",
                .description = "A test integer opt value.",
                .valid_fn = struct{ fn valFn(int: i16, alloc: mem.Allocator) bool { _ = alloc; return int <= 666; } }.valFn,
                .set_behavior = .Multi,
                .max_args = 6,
            }),
        },
        .{
            .name = "float_opt",
            .description = "A test float option.",
            .short_name = 'f',
            .long_name = "float",
            .val = TestValue.ofType(f16, .{
                .name = "float_opt_val",
                .description = "An float opt value.",
                .valid_fn = struct{ fn valFn(float: f16, alloc: mem.Allocator) bool { _ = alloc; return float < 30000; } }.valFn,
                .set_behavior = .Multi,
                .max_args = 6,
            }),
        },
        .{
            .name = "toggle_opt",
            .description = "A test toggle/boolean option.",
            .short_name = 't',
            .long_name = "toggle",
            .val = TestValue.ofType(bool, .{
                .name = "toggle_opt_val",
                .description = "A test toggle/boolean option value.",
            }),
        },
        
    },
    .vals = &.{
        TestValue.ofType([]const u8, .{
            .name = "string_val",
            .description = "A test string value.",
            .default_val = "test",
        }),
    },
};

const TestCmdFromStruct = struct {
    pub const SubCmdFromStruct = struct {
        sub_bool: bool = false,
        sub_float: f32 = 0,
    };
    // Command
    @"sub-cmd": SubCmdFromStruct = .{
        .sub_bool = true,
        .sub_float = 0,
    },
    // Options
    int: ?i32 = 26,
    str: ?[]const u8 = "Opt string.",
    str2: ?[]const u8 = "Opt string 2.",
    flt: ?f16 = 0,
    int2: ?u16 = 0,
    multi_str: [5]?[]const u8,
    multi_int: [3]?u8,
    // Values
    struct_bool: bool = false,
    struct_str: []const u8 = "Val string.",
    struct_int: i64,
    multi_int_val: [2]u16,
    // Cova Command
    cova_cmd: TestCommand = .{
        .name = "test-struct-cova-cmd",
        .description = "A test cova Command within a struct.",
    },
    // Cova Option
    cova_opt: TestCommand.OptionT = .{
        .name = "test_struct_cova_opt",
        .description = "A test cova Option within a struct.",
    },
    // Cova Value
    cova_val: TestValue = TestValue.ofType(i8, .{
        .name = "test_struct_cova_val",
        .description = "A test cova Value within a struct.",
        .default_val = 50,
    }),
};
const test_setup_cmd_from_struct = TestCommand.from(TestCmdFromStruct, .{});

test "tokenize args" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    const arg_str = "cova struct-cmd --multi-str \"demo str\" -m 'a \"quoted string\"' -m \"A string using an 'apostrophe'\" 50";
    const test_args = try tokenizeArgs(arg_str, alloc, .{});
    const expect_args = [_][]const u8{ "cova", "struct-cmd", "--multi-str", "demo str", "-m", "a \"quoted string\"", "-m", "A string using an 'apostrophe'", "50" };
    for (test_args, expect_args[0..]) |t_arg, e_arg| try testing.expectEqualStrings(t_arg, e_arg);
}

test "command setup" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const test_cmd = try test_setup_cmd.init(alloc, .{});
    defer test_cmd.deinit();

    const test_cmd_from_struct = try test_setup_cmd_from_struct.init(alloc, .{
        .add_help_cmds = false,
        .add_help_opts = false,
    });
    defer test_cmd_from_struct.deinit();
}

test "argument parsing" {
    testing.log_level = .info;
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var writer_list = std.ArrayList(u8).init(alloc);
    defer writer_list.deinit();
    const writer = writer_list.writer();

    const test_args: []const []const [:0]const u8 = &.{
        &.{ "test-cmd", "sub_test_cmd", "sub-test-cmd", "--sub-string", "sub cmd string opt", "--sub-int=15984" },
        &.{ "test-cmd", "--string", "string opt 1", "--str", "string opt 2", "--string=string_opt_3", "-s", "string opt 4", "-s=string_opt_5", "-s_string_opt_6", "string value text" },
        &.{ "test-cmd", "--int", "11", "--in", "22", "--int=33", "-i", "444", "-i=555", "-i666", "string value text" },
        &.{ "test-cmd", "--float", "1111.12", "--flo", "2222.123", "--float=3333.1234", "-f", "4444.12345", "-f=5555.123456", "-f6666.1234567", "string value text" },
        &.{ "test-cmd", "--toggle", "-t", "string value text", },
        &.{ "test-cmd", "string value text", },
    };
    for (test_args) |tokens_list| {
        const test_cmd = &(try test_setup_cmd.init(alloc, .{}));
        defer test_cmd.deinit();
        const raw_iter = RawArgIterator{ .args = tokens_list };
        var test_iter = ArgIteratorGeneric.from(raw_iter);
        try parseArgs(&test_iter, TestCommand, test_cmd, writer, .{});
    }
}

test "argument analysis" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var writer_list = std.ArrayList(u8).init(alloc);
    defer writer_list.deinit();
    const writer = writer_list.writer();

    const test_cmd = &(try test_setup_cmd.init(alloc, .{}));
    defer test_cmd.deinit();
    const test_args: []const [:0]const u8 = &.{ "test-cmd", "--string", "opt string 1", "-s", "opt string 2", "--int=1,22,333,444,555,666", "--flo=5.1", "-f10.1,20.2,30.3", "-t", "val string", "sub-test-cmd", "--sub-s=sub_opt_str", "--sub-int", "21523", "help" }; 
    const raw_iter = RawArgIterator{ .args = test_args };
    var test_iter = ArgIteratorGeneric.from(raw_iter);
    parseArgs(&test_iter, TestCommand, test_cmd, writer, .{}) catch |err| {
        switch (err) {
            error.UsageHelpCalled => {},
            else => {
                try writer.print("Parsing Error during Testing: {!}\n", .{ err });
                return err;
            },
        }    
    };

    try utils.displayCmdInfo(TestCommand, test_cmd, alloc, writer);

    _ = test_setup_cmd.SubCommandsEnum();
}
