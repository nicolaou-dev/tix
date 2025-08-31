const std = @import("std");
const git = @import("git.zig");

pub const RemoteError = error{
    RemoteAlreadyExists,
    InvalidRemoteName,
    NotARepository,
    CommandFailed,
};

pub fn remote(allocator: std.mem.Allocator, verbose: bool) RemoteError![]const u8 {
    const result = git.remote(allocator, verbose) catch |err| switch (err) {
        error.NotARepository => return RemoteError.NotARepository,
        else => return RemoteError.CommandFailed,
    };

    return result;
}

pub fn remoteAdd(allocator: std.mem.Allocator, url: []const u8) RemoteError!void {
    git.remoteAdd(allocator, url) catch |err| switch (err) {
        error.RemoteAlreadyExists => return RemoteError.RemoteAlreadyExists,
        error.InvalidRemoteName => return RemoteError.InvalidRemoteName,
        error.NotARepository => return RemoteError.NotARepository,
        else => return RemoteError.CommandFailed,
    };
}

test "test remote and remoteAdd functions" {
    const init = @import("init.zig").init;
    const test_helper = @import("test_helper.zig");
    const allocator = std.testing.allocator;

    // Setup isolated test directory
    const original = try test_helper.setupTestDir(allocator, "remote");
    defer test_helper.cleanupTestDir("remote", original);

    // Create .tix directory
    try std.fs.cwd().makeDir(".tix");

    // Test remote() when .tix is not a git repo
    const remote_err = remote(allocator, false);
    try std.testing.expectError(RemoteError.NotARepository, remote_err);

    // Test remoteAdd() when .tix is not a git repo
    const err = remoteAdd(allocator, "https://example.com/repo.git");
    try std.testing.expectError(RemoteError.NotARepository, err);

    _ = try init(allocator);

    try remoteAdd(allocator, "https://example.com/repo.git");

    // Test without verbose
    const remotes = try remote(allocator, false);
    defer allocator.free(remotes);

    // git remote returns "origin\n"
    try std.testing.expect(std.mem.eql(u8, std.mem.trim(u8, remotes, "\n"), "origin"));
    
    // Test with verbose
    const remotes_verbose = try remote(allocator, true);
    defer allocator.free(remotes_verbose);
    
    // git remote -v returns lines with origin and URL
    try std.testing.expect(std.mem.indexOf(u8, remotes_verbose, "origin") != null);
    try std.testing.expect(std.mem.indexOf(u8, remotes_verbose, "https://example.com/repo.git") != null);

    const err3 = remoteAdd(allocator, "https://example.com/repo.git");
    try std.testing.expectError(RemoteError.RemoteAlreadyExists, err3);
}
