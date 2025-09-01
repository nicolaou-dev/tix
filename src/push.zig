const std = @import("std");
const git = @import("git.zig");

pub const PushError = error{
    CommandFailed,
    OutOfMemory,
    NotARepository,
    RejectedNeedsForce,
};

pub fn push(allocator: std.mem.Allocator, force: bool, force_with_lease: bool) PushError!void {
    git.push(allocator, force, force_with_lease) catch |err| switch (err) {
        git.GitError.NotARepository => return PushError.NotARepository,
        git.GitError.OutOfMemory => return PushError.OutOfMemory,
        git.GitError.PushRejectedNeedsForce => return PushError.RejectedNeedsForce,
        else => return PushError.CommandFailed,
    };

    return;
}
