const std = @import("std");

pub const Priority = enum(u8) {
    A = 'a', // High
    B = 'b', // Medium
    C = 'c', // Low
    Z = 'z', // Default


    pub fn toString(self: Priority) []const u8 {
        return switch (self) {
            .A => "p=a",
            .B => "p=b",
            .C => "p=c",
            .Z => "p=z",
        };
    }

    pub fn fromSlice(slice: []const u8, out: *[4]Priority) ![]Priority {
        if (slice.len > 4) return error.InvalidPriority;
        for (slice, 0..) |c, i| out[i] = std.meta.intToEnum(Priority, c) catch return error.InvalidPriority;
        return out[0..slice.len];
    }
};
