const std = @import("std");
const git = @import("git.zig");

pub const PushError = error{
    CommandFailed,
    OutOfMemory,
    NotARepository,
};

pub fn push(allocator: std.mem.Allocator) PushError!void {
    git.push(allocator) catch |err| switch (err) {
        git.GitError.NotARepository => return PushError.NotARepository,
        git.GitError.OutOfMemory => return PushError.OutOfMemory,
        else => return PushError.CommandFailed,
    };

    return;
}
