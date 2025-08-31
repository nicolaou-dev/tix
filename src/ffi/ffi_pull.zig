const std = @import("std");
const pull_mod = @import("../pull.zig");
const ErrorCode = @import("../error.zig").ErrorCode;

pub fn tix_pull() c_int {
    const allocator = std.heap.c_allocator;

    pull_mod.pull(allocator) catch |err| {
        return @intFromEnum(ErrorCode.fromError(err));
    };

    return 0;
}