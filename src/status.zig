const std = @import("std");

pub const Status = enum(u8) {
    Backlog = 'b',
    Todo = 't',
    Doing = 'w',
    Done = 'd',


    pub fn toString(self: Status) []const u8 {
        return switch (self) {
            .Backlog => "s=b",
            .Todo => "s=t",
            .Doing => "s=w",
            .Done => "s=d",
        };
    }

    pub fn fromSlice(slice: []const u8, out: *[4]Status) ![]Status {
        if (slice.len > 4) return error.InvalidStatus;
        for (slice, 0..) |c, i| out[i] = std.meta.intToEnum(Status, c) catch return error.InvalidStatus;
        return out[0..slice.len];
    }
};
