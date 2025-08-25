const std = @import("std");

pub const GitError = error{
    CommandFailed,
    OutOfMemory,
};

/// Initialize a new git repository
pub fn init(
    allocator: std.mem.Allocator,
) GitError!void {
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{ "git", "-C", ".tix", "init" },
    }) catch {
        return GitError.CommandFailed;
    };
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    if (result.term.Exited != 0) {
        return GitError.CommandFailed;
    }
}
