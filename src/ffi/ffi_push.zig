const std = @import("std");
const push_mod = @import("../push.zig");
const ErrorCode = @import("../error.zig").ErrorCode;

pub fn tix_push() c_int {
    const allocator = std.heap.c_allocator;

    push_mod.push(allocator) catch |err| {
        return @intFromEnum(ErrorCode.fromError(err));
    };

    return 0;
}