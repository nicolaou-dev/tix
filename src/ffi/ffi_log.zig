const std = @import("std");
const helper = @import("helper.zig");
const log_mod = @import("../log.zig");
const ErrorCode = @import("../error.zig").ErrorCode;

pub fn tix_log(output: *[*c]u8, oneline: c_int, limit: c_int, since: [*c]const u8) c_int {
    const allocator = std.heap.c_allocator;

    const since_slice = if (since) |s| std.mem.span(s) else null;
    const limit_val = if (limit > 0) @as(u32, @intCast(limit)) else null;

    const result = log_mod.log(allocator, oneline != 0, limit_val, since_slice) catch |err| {
        return @intFromEnum(ErrorCode.fromError(err));
    };

    const c_str = allocator.dupeZ(u8, result) catch {
        allocator.free(result);
        return @intFromEnum(ErrorCode.OUT_OF_MEMORY);
    };
    defer allocator.free(result);

    output.* = c_str.ptr;
    return 0;
}

pub fn tix_log_free(str: [*c]u8) void {
    helper.free_string(str);
}