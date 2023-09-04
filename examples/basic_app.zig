//! This is a basic user management application designed to highlight key features of the Cova library.

const std = @import("std");
const builtin = @import("builtin");
const cova = @import("cova");

// Setup
// - Types
// A custom Command Type should be set up for any project using Cova. The easiest way to do this
// is to simply use `cova.Command.BaseCommand()` which will provide a Command Type with default
// values. However, customization via `cova.Command.Custom()` and configuring the provided
// `cova.Command.Config` will create a Command Type that's more tailored to a project.
// The most basic example of this is simply adding a title to the help page as seen below.
pub const CommandT = cova.Command.Custom(.{ 
    .global_help_prefix = "Basic User Management App", // This will appear at the top of Usage/Help.
}); 
// Customized Option and Value Types can also be created via their respective `from()` functions
// and `Config` structs. The `Config` structs can be provided directly to the `cova.Command.Config`
// that's configured above so that the Types are created with the Command Type. This is the 
// preferred way to set up these Argument Types and allows them to be referenced as seen below.
pub const OptionT = CommandT.OptionT;
pub const ValueT = CommandT.ValueT;

// - Main Command
// Cova is designed on the principle of 'Comptime Setup. Runtime Use.' All this means is that 
// Commands and their corresponding Options and Values will be declared and set up during Comptime,
// then initialized with an allocator for parsing and analysis during Runtime.
//
// For Comptime Setup, a `setup_cmd` should be created. This is the Comptime version of the main
// command for the app, which can be thought of as the main menu. The example below is also an
// example of how Commands are declared when they aren't created by converting from a Struct, 
// Union, or Function. Notably, Commands can easily be nested via the `sub_cmds` field.
pub const setup_cmd: CommandT = .{
    .name = "basic-app",
    .description = "A basic user management application designed to highlight key features of the Cova library.",
    .sub_cmds = &.{
        // A Command created from a Struct. (Details below).
        CommandT.from(User, .{
            .cmd_name = "new",
            .cmd_description = "Add a new user.",
            .sub_descriptions = &.{
                .{ "is_admin", "Add this user as an admin?" },
                .{ "first_name", "User's First Name." }, 
                .{ "last_name", "User's Last Name." },
                .{ "age", "User's Age." },
                .{ "phone", "User's Phone #." },
                .{ "address", "User's Address." },
            },
        }),
        // A Command created from a Function. (Details below).
        CommandT.from(@TypeOf(open), .{
            .cmd_name = "open",
            .cmd_description = "Open or create a users file.",
        }),
        // A "raw" Command, same as the parent `setup_cmd`.
        CommandT{
            .name = "list",
            .description = "List all current users.",
            .sub_cmds_mandatory = false,
            .sub_cmds = &.{
                // A Command created from a Union. (Details below).
                CommandT.from(Filter, .{
                    .cmd_name = "filter",
                    .cmd_description = "List all current users matching the provided filter. Filters can be exactly ONE of any user field.",
                }),
            },
        },
        // Another "raw" Command example.
        CommandT{
            .name = "clean",
            .description = "Clean (delete) the default users file (users.csv) and persistent variable file (.ba_persist).",
        }
    },
};

// Commands can be created from Structs using the `cova.Command.Custom.from()` function. The rules
// for how they're converted can be configured by customizing the `cova.Command.Custom.FromConfig`
// that is provided to the `from()` function. The rules shown below are the defaults.
pub const User = struct {
    // Values
    //
    // Values are created from valid, non-Optional primitive fields such as:
    // - Booleans `bool`
    // - Integers `u8` / `i32`
    // - Floats `f32`
    // - Strings `[]const u8`
    // 
    // If a field begins with an underscore `_` it will be considered private and not converted
    // to a Value.
    // If a default value is provided for a field, the corresponding Value will inherit it as a
    // default value as well.
    _id: u16 = 0,
    is_admin: bool = false,

    // Options
    //
    // Options are created from valid, Optional primitive fields (i.e. `?bool`, `?u8`, etc).
    // Each Option wraps a Value, so the above conversion rules for Values apply to them as well.
    //
    // Additionally, Options will generate a short and long name from each field by default.
    // Short name generation will take the first free lower then upper case character of a field 
    // name, sequentially working through the name from the first to last character. 
    // Underscores `_` will also be converted to dashes `-`. End users can also abbreviate 
    // long names as long as the abbreviation is unique.
    first_name: ?[]const u8, // `-f` or `--first-name` (`--first` abbreviation would work)
    last_name: ?[]const u8, // `-l` or `--last-name` (`--last` abbreviation would work)
    age: ?u8, // -a or --age
    phone: ?[]const u8 = "not provided", // -p or --phone
    address: ?[]const u8 = "not provided", // -A or --address (`--addr` abbreviation would work) 

    pub fn from(line: []const u8) !@This() {
        var field_iter = std.mem.splitAny(u8, line, ",");
        var out: @This() = undefined;
        var idx: u3 = 0;
        const user_id = field_iter.first();
        if (user_id.len == 0) return error.NotUserString;
        std.log.debug("User: {s}", .{ user_id });
        field_iter.reset();
        while (field_iter.next()) |field| : (idx += 1) {
            const trimmed_field = std.mem.trim(u8, field, " ");
            std.log.debug("Field: {s}", .{ trimmed_field });
            switch (idx) {
                0 => out._id = std.fmt.parseInt(u16, trimmed_field, 10) catch |err| { std.log.err("ID error: {s}", .{ trimmed_field }); return err; },
                1 => out.is_admin = std.mem.eql(u8, trimmed_field, "true"),
                2 => out.first_name = trimmed_field,
                3 => out.last_name = trimmed_field,
                4 => out.age = std.fmt.parseInt(u8, trimmed_field, 10) catch |err| { std.log.err("Age error: {s}", .{ trimmed_field }); return err; },
                5 => out.phone = trimmed_field,
                6 => out.address = trimmed_field,
                else => return error.TooManyTokens, 
            }
        }
        return out;
    }
    pub fn to(self: @This(), str_buf: []u8) ![]const u8 {
        return try std.fmt.bufPrint(str_buf, "{d}, {any}, {?s}, {?s}, {?d}, {?s}, {?s}", .{
            self._id,
            self.is_admin,
            self.first_name,
            self.last_name,
            self.age,
            self.phone,
            self.address,
        });
    }

    pub fn format(value: @This(), comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print(
            \\User: {d}
            \\ - Admin: {any}
            \\ - Name: {?s}, {?s}
            \\ - Age: {?d}
            \\ - Phone #: {?s}
            \\ - Address: {?s}
            \\
            , .{
                value._id,
                value.is_admin,
                value.last_name, value.first_name,
                value.age,
                value.phone,
                value.address,
            }
        );
    }
};

// Commands can be created from Unions same as with Structs.
pub const Filter = union(enum){
    id: ?u16,
    admin: ?bool,
    age: ?u8,
    first_name: ?[]const u8,
    last_name: ?[]const u8,
    phone: ?[]const u8,
    address: ?[]const u8,
};

// Commands can also be created from Functions. Similar to Struct and Union Types, the 
// `cova.Command.Custom.from()` and `cova.Command.Custom.FromConfig` are used configure and convert
// the Function into a Command. Due to a lack of parameter names in a Function's Type Info,
// Function Parameters can only be converted to Values (not Options).
pub fn open(filename: []const u8) !std.fs.File {
    const filename_checked = 
        if (std.mem.eql(u8, filename[(filename.len - 4)..], ".csv")) filename
        else filenameChecked: {
            var fnc_buf: [100]u8 = .{ 0 } ** 100;
            break :filenameChecked (try std.fmt.bufPrint(fnc_buf[0..], "{s}.csv", .{ filename }))[0..(filename.len + 4)];
        };
    const open_file = try std.fs.cwd().createFile(filename_checked, .{ .read = true, .truncate = false });
    try std.fs.cwd().writeFile(".ba_persist", filename_checked);
    return open_file;
}

pub fn delete(filename: []const u8) !void {
    std.fs.cwd().deleteFile(filename) catch std.log.err("There was an issue deleting the '{s}' file!", .{ filename });
}

pub fn main() !void {
    // While technicaally any Allocator can be used, Cova is designed to be used with an
    // Arena Allocator. That said, any backing allocator can be used for the Arena Allocator.
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    // Initializing the `setup_cmd` with an allocator will make it available for Runtime use.
    // Wrapping the `init()` call in a reference `&(...)` makes it easier to use.
    const main_cmd = &(try setup_cmd.init(alloc, .{})); 
    defer main_cmd.deinit();

    // Parsing
    // - Arg Iterator
    // Cova requries an Argument Iterator in order to parse arguments. The easiest way to obtain
    // one is simply using `cova.ArgIteratorGeneric.init()` as seen below. This will provide Zig's
    // cross-platform `std.process.ArgIterator`, which will iterate through the arguments provided
    // to this application. Cova also provides `cova.RawArgIterator` which can be used for testing
    // or providing arguments from an alternate source.
    var args_iter = try cova.ArgIteratorGeneric.init(alloc);
    defer args_iter.deinit();
    // - Writer
    // Any valid Zig Writer can be used during parsing. Stdout is the easiest option here.
    const stdout = std.io.getStdOut().writer();

    // Using `cova.parseArgs()` will parse args from the provided ArgIterator and populate provided
    // Command. It's important to note that, by default, if the user calls for `usage` or `help` it
    // will trigger an error. This allow's that specific case to be handled specially if needed. If
    // there's no need to handle it specially, the below example will simply bypass the error.
    cova.parseArgs(&args_iter, CommandT, main_cmd, stdout, .{}) catch |err| switch (err) {
        error.UsageHelpCalled => {},
        else => return err,
    };

    // Analysis
    // - Debug Output of Commands after Parsing.
    // The `cova.utils.displayCmdInfo()` function is useful for seeing the results of a parsed 
    // Command. This is done recursively for any sub Argument Types within the Command and can be
    // used to debug said Command.
    if (builtin.mode == .Debug) try cova.utils.displayCmdInfo(CommandT, main_cmd, alloc, &stdout);

    // - App Vars
    var user_filename_buf: [100]u8 = .{ 0 } ** 100;
    _ = std.fs.cwd().readFile(".ba_persist", user_filename_buf[0..]) catch {
        try std.fs.cwd().writeFile(".ba_persist", "users.csv");
        for (user_filename_buf[0..9], "users.csv") |*u, c| u.* = c;
    };
    const ufb_end = std.mem.indexOfScalar(u8, user_filename_buf[0..], 0) orelse 9;
    const user_filename = user_filename_buf[0..ufb_end];
    std.log.debug("User File Name: '{s}'", .{ user_filename });

    // TODO: Figure out wonkiness with the filename
    var user_file: std.fs.File = try open(user_filename);
    defer user_file.close();
    var user_file_buf: []const u8 = try user_file.readToEndAlloc(alloc, 8192);
    var users = std.ArrayList(User).init(alloc);
    defer users.deinit();
    var users_mal = std.MultiArrayList(User){};
    defer users_mal.deinit(alloc);
    var users_iter = std.mem.splitAny(u8, user_file_buf, "\n");
    while (users_iter.next()) |user_ln| {
        const user = User.from(user_ln) catch break;
        try users.append(user);
        try users_mal.append(alloc, user);
    }

    // - Handle Parsed Commands
    // Commands have two primary methods for analysis.
    //
    // `cova.Command.Custom.matchSubCmd()` will return the Active Sub Command of a Command if it's
    // name matches the provided string. Otherwise, it returns null. This fits nicely with Zig's syntax
    // for handling nullable returns as seen below.
    if (main_cmd.matchSubCmd("new")) |new_cmd| {
        var new_user = try new_cmd.to(User, .{});
        var rand = std.rand.DefaultPrng.init(@as(u64, @truncate(@as(u128, @bitCast(std.time.nanoTimestamp())))));
        var user_id = rand.random().int(u16);
        while (std.mem.indexOfScalar(u16, users_mal.items(._id), user_id)) |_|
            user_id = rand.random().int(u16);
        new_user._id = user_id;
        try users.append(new_user);
        try users_mal.append(alloc, new_user);
        var user_buf: [512]u8 = .{ 0 } ** 512;
        try user_file.writer().print("{s}\n", .{ try new_user.to(user_buf[0..]) });
        try stdout.print("Added:\n{s}\n", .{ new_user });
    }
    if (main_cmd.matchSubCmd("open")) |open_cmd| {
        user_file = try open_cmd.callAs(open, null, std.fs.File);
    }
    if (main_cmd.matchSubCmd("list")) |list_cmd| {
        const filter = if (list_cmd.matchSubCmd("filter")) |filter_cmd| try filter_cmd.to(Filter, .{}) else null;
        for (users.items) |user| {
            const print_user: bool = if (filter) |fil| switch (fil) {
                .id => |id| id.? == user._id,
                .admin => |admin| admin.? == user.is_admin,
                .first_name => |first| if (user.first_name) |u_first| std.mem.eql(u8, first.?, u_first) else false,
                .last_name => |last| if (user.last_name) |u_last| std.mem.eql(u8, last.?, u_last) else false,
                .age => |age| if (user.age) |u_age| age == u_age else false,
                .phone => |phone| if (user.phone) |u_phone| std.mem.eql(u8, phone.?, u_phone) else false,
                .address => |addr| if (user.address) |u_addr| std.mem.eql(u8, addr.?, u_addr) else false,
            } else true;
            if (print_user) try stdout.print("{s}\n", .{ user });
        }
    }
    // Conversely, if the Command doesn't need to be returned, using the method 
    // `cova.Command.Custom.checkSubCmd()` will simply return a boolean check on whether or not 
    // the provided string is the same Active Sub Command's name.
    if (main_cmd.checkSubCmd("clean")) {
        try delete("users.csv");
        try delete(".ba_persist");
    }
}
