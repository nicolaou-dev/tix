const std = @import("std");
const undo_mod = @import("../undo.zig");
const ErrorCode = @import("../error.zig").ErrorCode;

pub fn tix_undo() c_int {
    const allocator = std.heap.c_allocator;

    undo_mod.undo(allocator) catch |err| {
        return @intFromEnum(ErrorCode.fromError(err));
    };

    return 0;
}