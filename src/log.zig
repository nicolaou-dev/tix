const std = @import("std");
const git = @import("git.zig");

pub const LogError = error{
    CommandFailed,
    OutOfMemory,
    NotARepository,
};

pub fn log(allocator: std.mem.Allocator, oneline: bool, limit: ?u32, since: ?[]const u8) LogError![]const u8 {
    return git.log(allocator, oneline, limit, since) catch |err| switch (err) {
        git.GitError.NotARepository => return LogError.NotARepository,
        git.GitError.CommandFailed => return LogError.CommandFailed,
        git.GitError.OutOfMemory => return LogError.OutOfMemory,
        else => return LogError.CommandFailed,
    };
}

test "log returns commit history" {
    const test_helper = @import("test_helper.zig");
    const init = @import("init.zig").init;
    const add = @import("add.zig").add;
    const Priority = @import("priority.zig").Priority;

    const allocator = std.testing.allocator;

    const original = try test_helper.setupTestDir(allocator, "test_log");
    defer test_helper.cleanupTestDir("test_log", original);

    // Create .tix directory
    try std.fs.cwd().makeDir(".tix");

    _ = try init(allocator);

    // Create a ticket to generate some history
    const id = try add(allocator, "Test ticket", "Test body", Priority.B);
    defer allocator.free(id);

    // Test basic log
    const result1 = try log(allocator, false, null, null);
    defer allocator.free(result1);
    try std.testing.expect(result1.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, result1, "Test ticket") != null);

    // Test oneline format
    const result2 = try log(allocator, true, null, null);
    defer allocator.free(result2);
    try std.testing.expect(result2.len > 0);

    // Test with limit
    const result3 = try log(allocator, true, 1, null);
    defer allocator.free(result3);
    const newlines = std.mem.count(u8, result3, "\n");
    try std.testing.expect(newlines == 0 or newlines == 1); // Only 1 commit or no newline at end
}