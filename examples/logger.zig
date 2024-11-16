const std = @import("std");
const log = std.log;
const cova = @import("cova");

// We need to add any Enums we're using to our Value Config.
pub const CommandT = cova.Command.Custom(.{
    .val_config = .{
        .custom_types = &.{log.Level},
    },
});
pub const setup_cmd = CommandT{
    .name = "logger",
    .description = "A small demo of using the Log Level Enum as an Option.",
    .opts = &.{.{ .name = "log_level", .description = "An Option using the `log.Level` Enum.", .long_name = "log-level", .mandatory = true, .val = CommandT.ValueT.ofType(log.Level, .{ .name = "log_level_val", .description = " This Value will handle then Enum." }) }},
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer if (gpa.deinit() != .ok and gpa.detectLeaks()) log.err("Memory leak detected!", .{});
    const stdout = std.io.getStdOut().writer();

    var main_cmd = try setup_cmd.init(alloc, .{});
    defer main_cmd.deinit();
    var args_iter = try cova.ArgIteratorGeneric.init(alloc);
    defer args_iter.deinit();

    cova.parseArgs(&args_iter, CommandT, main_cmd, stdout, .{}) catch |err| switch (err) {
        error.UsageHelpCalled => {},
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
