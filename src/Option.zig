//! Optional Argument Structures

const Val = @import("Value.zig");

pub const In = struct {
    short_name: ?u8,
    long_name: ?[]u8,

    val: Val = Val,

    description: []u8 = "",

    pub fn getAsToggle(self: *@This()) Out {
        return Out {
            .long_name = self.long_name,
            .val = self.val,
        };
    }

    pub fn help(self: *@This(), writer: anytype) !void {
        _ = self;
        _ = writer;
    }
};

pub const Out = struct {
    name: ?[]u8,

    val: Val,
};
