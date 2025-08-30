const std = @import("std");
const redo_mod = @import("../redo.zig");
const ErrorCode = @import("../error.zig").ErrorCode;

pub fn tix_redo() c_int {
    const allocator = std.heap.c_allocator;

    redo_mod.redo(allocator) catch |err| {
        return @intFromEnum(ErrorCode.fromError(err));
    };

    return 0;
}