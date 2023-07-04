# Parsing
Parsing is handled by the `parseArgs()` function in cova.zig. It takes in an ArgIterator (`args`), a Command type (`CommandT`), an initialized Command (`cmd`), a Writer (`writer`), and a ParseConfig (`parse_config`), then parses each argument token sequentially. The results of a successful parse are stored in the provided Command (`cmd`) which can then be analyzed by the library user's project code.

## Basic Setup
```
pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    const stdout = std.io.getStdOut().writer();

    const main_cmd = &(try setup_cmd.init(alloc, .{})); 
    defer main_cmd.deinit();

    var args_iter = try cova.ArgIteratorGeneric.init(alloc);
    defer args_iter.deinit();
    try cova.parseArgs(&args_iter, CustomCommand, main_cmd, stdout, .{ 
        .vals_mandatory = false,
        .allow_abbreviated_long_opts = true, 
    });
    try stdout.print("\n", .{});
```
