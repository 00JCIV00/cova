const builtin = @import("builtin");
const std = @import("std");
const ArrayList = std.ArrayList;
const MultiArrayList = std.MultiArrayList;

const cova = @import("cova");

pub const CommandT = cova.Command.Custom(.{
    .global_help_prefix = "Basic User Management App",
});
pub const OptionT = CommandT.OptionT;
pub const ValueT = CommandT.ValueT;

pub const setup_cmd: CommandT = .{
    .name = "basic-app",
    .description = "A basic user management application designed to highlight key features of the Cova library.",
    .cmd_groups = &.{ "INTERACT", "VIEW" },
    .sub_cmds = &.{
        CommandT.from(User, .{
            .cmd_name = "new",
            .cmd_description = "Add a new user.",
            .cmd_examples = &.{"basic-app new -f Bruce -l Wayne -a 40 -p \"555 555 5555\" -A \" 1007 Mountain Drive, Gotham\" true"},
            .cmd_group = "INTERACT",
            .sub_descriptions = &.{
                .{ "is_admin", "Add this user as an admin?" },
                .{ "first_name", "User's First Name." },
                .{ "last_name", "User's Last Name." },
                .{ "age", "User's Age." },
                .{ "phone", "User's Phone #." },
                .{ "address", "User's Address." },
            },
        }),
        CommandT.from(@TypeOf(open), .{
            .cmd_name = "open",
            .cmd_description = "Open or create a users file.",
            .cmd_examples = &.{"basic-app open users.csv"},
            .cmd_group = "INTERACT",
            .ignore_first = true,
        }),
        CommandT{
            .name = "list",
            .description = "List all current users.",
            .cmd_group = "VIEW",
            .sub_cmds_mandatory = false,
            .sub_cmds = &.{
                CommandT.from(Filter, .{
                    .cmd_name = "filter",
                    .cmd_description = "List all current users matching the provided filter. Filters can be exactly ONE of any user field.",
                }),
            },
        },
        CommandT{
            .name = "clean",
            .description = "Clean (delete) the default users file (users.csv) and persistent variable file (.ba_persist).",
            .examples = &.{ "basic-app clean", "basic-app delete --file users.csv" },
            .alias_names = &.{"delete"},
            .cmd_group = "INTERACT",
            .opts = &.{
                OptionT{
                    .name = "clean_file",
                    .description = "Specify a single file to be cleaned (deleted) instead of the defaults.",
                    .alias_long_names = &.{"delete_file"},
                    .short_name = 'f',
                    .long_name = "file",
                    .val = ValueT.ofType([]const u8, .{
                        .name = "clean_file",
                        .description = "The file to be cleaned.",
                        .alias_child_type = "filepath",
                        .valid_fn_io = cova.Value.ValidationFns.validFilepath,
                    }),
                },
            },
        },
        CommandT{
            .name = "view-lists",
            .description = "View all lists (csv files) in the current directory.",
            .cmd_group = "VIEW",
        },
    },
};

pub const User = struct {
    _id: u16 = 0,
    is_admin: bool = false,

    first_name: ?[]const u8,
    last_name: ?[]const u8,
    age: ?u8,
    phone: ?[]const u8 = "not provided",
    address: ?[]const u8 = "not provided",

    pub fn from(line: []const u8) !@This() {
        var field_iter = std.mem.splitAny(u8, line, ",");
        var out: @This() = undefined;
        var idx: u3 = 0;
        const user_id = field_iter.first();
        if (user_id.len == 0) return error.NotUserString;
        std.log.debug("User: {s}", .{user_id});
        field_iter.reset();
        while (field_iter.next()) |field| : (idx += 1) {
            const trimmed_field = std.mem.trim(u8, field, " ");
            std.log.debug("Field: {s}", .{trimmed_field});
            switch (idx) {
                0 => out._id = std.fmt.parseInt(u16, trimmed_field, 10) catch |err| {
                    std.log.err("ID error: {s}", .{trimmed_field});
                    return err;
                },
                1 => out.is_admin = std.mem.eql(u8, trimmed_field, "true"),
                2 => out.first_name = trimmed_field,
                3 => out.last_name = trimmed_field,
                4 => out.age = std.fmt.parseInt(u8, trimmed_field, 10) catch |err| {
                    std.log.err("Age error: {s}", .{trimmed_field});
                    return err;
                },
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

    pub fn format(value: @This(), writer: anytype) !void {
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
            value.last_name,
            value.first_name,
            value.age,
            value.phone,
            value.address,
        });
    }
};

pub const Filter = union(enum) {
    id: ?u16,
    admin: ?bool,
    age: ?u8,
    first_name: ?[]const u8,
    last_name: ?[]const u8,
    phone: ?[]const u8,
    address: ?[]const u8,
};

pub fn open(io: std.Io, filename: []const u8) !std.Io.File {
    const filename_checked =
        if (std.mem.eql(u8, filename[(filename.len - 4)..], ".csv")) filename else filenameChecked: {
            var fnc_buf: [100]u8 = .{0} ** 100;
            break :filenameChecked (try std.fmt.bufPrint(fnc_buf[0..], "{s}.csv", .{filename}))[0..(filename.len + 4)];
        };
    const open_file = try std.Io.Dir.cwd().createFile(io, filename_checked, .{ .read = true, .truncate = false });
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = ".ba_persist", .data = filename_checked });
    return open_file;
}

pub fn delete(io: std.Io, filename: []const u8) !void {
    std.Io.Dir.cwd().deleteFile(io, filename) catch std.log.err("There was an issue deleting the '{s}' file!", .{filename});
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const alloc = init.gpa;

    const main_cmd = try setup_cmd.init(alloc, .{});
    defer main_cmd.deinit();

    var args_iter = try cova.ArgIteratorGeneric.init(init.minimal.args);
    defer args_iter.deinit();
    var stdout_file = std.Io.File.stdout();
    var stdout_buf: [4096]u8 = undefined;
    var stdout_writer = stdout_file.writer(io, &stdout_buf);
    const stdout = &stdout_writer.interface;

    cova.parseArgs(&args_iter, CommandT, main_cmd, stdout, .{ .io = io }) catch |err| switch (err) {
        error.UsageHelpCalled, error.TooManyValues, error.UnrecognizedArgument, error.UnexpectedArgument, error.CouldNotParseOption => {},
        else => return err,
    };

    if (builtin.mode == .Debug) try cova.utils.displayCmdInfo(CommandT, main_cmd, alloc, stdout, true);

    var user_filename_buf: [100]u8 = .{0} ** 100;
    _ = std.Io.Dir.cwd().readFile(io, ".ba_persist", user_filename_buf[0..]) catch {
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = ".ba_persist", .data = "users.csv" });
        for (user_filename_buf[0..9], "users.csv") |*u, c| u.* = c;
    };
    const ufb_end = std.mem.indexOfScalar(u8, user_filename_buf[0..], 0) orelse 9;
    const user_filename = user_filename_buf[0..ufb_end];
    std.log.debug("User File Name: '{s}'", .{user_filename});

    var user_file = try open(io, user_filename);
    defer std.Io.File.close(user_file, io);
    var user_file_reader_buf: [4096]u8 = undefined;
    var user_file_reader = user_file.reader(io, &user_file_reader_buf);
    var user_file_writer_buf: [4096]u8 = undefined;
    var user_file_writer = user_file.writer(io, &user_file_writer_buf);
    defer user_file_writer.interface.flush() catch {};
    const user_file_buf = try user_file_reader.interface.allocRemaining(alloc, .unlimited);
    var users: ArrayList(User) = .empty;
    defer users.deinit(alloc);
    var users_mal: MultiArrayList(User) = .empty;
    defer users_mal.deinit(alloc);
    var users_iter = std.mem.splitAny(u8, user_file_buf, "\n");
    while (users_iter.next()) |user_ln| {
        const user = User.from(user_ln) catch break;
        try users.append(alloc, user);
        try users_mal.append(alloc, user);
    }

    if (main_cmd.matchSubCmd("new")) |new_cmd| {
        var new_user = try new_cmd.to(User, .{});
        const seed: u64 = @truncate(@as(u128, @intCast(std.Io.Clock.real.now(io).nanoseconds)));
        var rand = std.Random.DefaultPrng.init(seed);
        var user_id = rand.random().int(u16);
        while (std.mem.indexOfScalar(u16, users_mal.items(._id), user_id)) |_|
            user_id = rand.random().int(u16);
        new_user._id = user_id;
        try users.append(alloc, new_user);
        try users_mal.append(alloc, new_user);
        var user_buf: [512]u8 = .{0} ** 512;
        try user_file_writer.interface.print("{s}\n", .{try new_user.to(user_buf[0..])});
        try stdout.print("Added:\n{f}\n", .{new_user});
    }
    if (main_cmd.matchSubCmd("open")) |open_cmd| {
        user_file = try open_cmd.callAs(open, io, std.Io.File);
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
            if (print_user) try stdout.print("{f}\n", .{user});
        }
    }
    if (main_cmd.matchSubCmd("clean")) |clean_cmd| cleanCmd: {
        if ((try clean_cmd.getOpts(.{})).get("clean_file")) |clean_opt| {
            if (clean_opt.val.isSet()) {
                const filename = try clean_opt.val.getAs([]const u8);
                try delete(io, filename);
                break :cleanCmd;
            }
        }
        try delete(io, "users.csv");
        try delete(io, ".ba_persist");
    }
    if (main_cmd.checkSubCmd("view-lists")) {
        try stdout.print("Available Lists:\n", .{});
        var dir = try std.Io.Dir.cwd().openDir(io, ".", .{ .iterate = true });
        defer dir.close(io);
        var dir_walker = try dir.walk(alloc);
        defer dir_walker.deinit();
        var found_list = false;
        while (try dir_walker.next(io)) |entry| {
            const filename = entry.basename;
            if (filename.len <= 4) continue;
            if (std.mem.eql(u8, filename[(filename.len - 4)..], ".csv")) {
                found_list = true;
                try stdout.print("- {s}\n", .{filename});
            }
        }
        if (!found_list) try stdout.print("- None Found!\n", .{});
    }
}
