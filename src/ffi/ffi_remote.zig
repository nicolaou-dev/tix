const std = @import("std");
const helper = @import("helper.zig");
const remote = @import("../remote.zig");
const ErrorCode = @import("../error.zig").ErrorCode;

/// Returns the remote name(s). If verbose is non-zero, includes URLs.
pub fn tix_remote(verbose: c_int, output: *[*c]u8) c_int {
    const allocator = std.heap.c_allocator;

    const remote_result = remote.remote(allocator, verbose != 0) catch |err| {
        return @intFromEnum(ErrorCode.fromError(err));
    };

    const c_str = allocator.dupeZ(u8, remote_result) catch {
        allocator.free(remote_result);
        return @intFromEnum(ErrorCode.OUT_OF_MEMORY);
    };
    defer allocator.free(remote_result);

    output.* = c_str.ptr;
    return 0;
}

pub fn tix_remote_free(str: [*c]u8) void {
    helper.free_string(str);
}

/// Adds a new remote with hardcoded name "origin" and the specified URL.
pub fn tix_remote_add(url: [*:0]const u8) c_int {
    const allocator = std.heap.c_allocator;

    // Convert C string to Zig slice
    const url_slice = std.mem.span(url);

    remote.remoteAdd(allocator, url_slice) catch |err| {
        return @intFromEnum(ErrorCode.fromError(err));
    };

    return 0;
}
