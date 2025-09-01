const std = @import("std");
const push_mod = @import("../push.zig");
const ErrorCode = @import("../error.zig").ErrorCode;

pub fn tix_push(force: c_int, force_with_lease: c_int) c_int {
    const allocator = std.heap.c_allocator;

    push_mod.push(allocator, force != 0, force_with_lease != 0) catch |err| {
        return @intFromEnum(ErrorCode.fromError(err));
    };

    return 0;
}