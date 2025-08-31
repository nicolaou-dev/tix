const std = @import("std");
const clone_mod = @import("../clone.zig");
const ErrorCode = @import("../error.zig").ErrorCode;

pub fn tix_clone(repo_url: [*:0]const u8) c_int {
    const allocator = std.heap.c_allocator;

    const repo_url_slice = std.mem.span(repo_url);

    clone_mod.clone(allocator, repo_url_slice) catch |err| {
        return @intFromEnum(ErrorCode.fromError(err));
    };

    return 0;
}
