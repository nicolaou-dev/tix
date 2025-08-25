const std = @import("std");
const init = @import("init.zig").init;
const error_types = @import("error.zig");

// Import error code mapping
const ErrorCode = error_types.ErrorCode;

/// Initializes a new Tix workspace at the given path.
pub export fn tix_init() c_int {
    const allocator = std.heap.c_allocator;

    const init_result = init(allocator) catch |err| {
        return @intFromEnum(ErrorCode.fromError(err));
    };

    return switch (init_result) {
        .initialized => 0,
        .reinitialized => 1,
    };
}
