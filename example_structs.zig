//! Example structs for covademo

pub const add_user = struct {
    fname: ?[]const u8 = "(First)",
    lname: ?[]const u8 = "(Last)",
    age: ?u8 = 30,
    id: u16 = 12345,
    admin: ?bool = false,
    ref_ids: [3]?u8 = .{ 10, 58, 62 },
};

pub const rem_user = struct {
    id: u16,
};

pub const fav_list = struct {
    cities: ?[5][]const u8,
    foods: ?[3][]const u8 = .{ "ramen", "chicken parm", "tangerines" },
};
