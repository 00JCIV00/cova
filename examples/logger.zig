const std = @import("std");
const log = std.log;
const cova = @import("cova");

pub const CommandT = cova.Command.Custom(.{
    .val_config = .{
        .custom_types = &.{log.Level},
    },
});
pub const setup_cmd = CommandT{
    .name = "logger",
    .description = "A small demo of using the Log Level Enum as an Option.",
    .opts = &.{
        .{
            .name = "log_level",
            .description = "An Option using the `log.Level` Enum.",
            .long_name = "log-level",
            .mandatory = true,
            .val = CommandT.ValueT.ofType(log.Level, .{
                .name = "log_level_val",
                .description = " This Value will handle then Enum.",
            }),
        },
    },
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const alloc = init.gpa;
    var stdout_file = std.Io.File.stdout();
    var stdout_buf: [4096]u8 = undefined;
    var stdout_writer = stdout_file.writer(io, &stdout_buf);
    const stdout = &stdout_writer.interface;

    var main_cmd = try setup_cmd.init(alloc, .{});
    defer main_cmd.deinit();
    var args_iter: cova.ArgIteratorGeneric = try .init(init.minimal.args);
    defer args_iter.deinit();

    cova.parseArgs(&args_iter, CommandT, main_cmd, stdout, .{ .io = io }) catch |err| switch (err) {
        error.UsageHelpCalled => return,
        else => return err,
    };

    const main_opts = try main_cmd.getOpts(.{});
    const log_lvl_opt = main_opts.get("log_level").?;
    const log_lvl = log_lvl_opt.val.getAs(log.Level) catch {
        log.err("The provided Log Level was invalid.", .{});
        return;
    };
    log.info("Provided Log Level: {s}", .{@tagName(log_lvl)});
}
