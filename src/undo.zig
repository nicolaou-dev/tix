const std = @import("std");
const git = @import("git.zig");

pub const UndoError = error{
    CommandFailed,
    OutOfMemory,
    NotARepository,
};

pub fn undo(allocator: std.mem.Allocator) UndoError!void {
    git.resetHardHead(allocator) catch |err| switch (err) {
        git.GitError.NotARepository => return UndoError.NotARepository,
        git.GitError.CommandFailed => return UndoError.CommandFailed,
        git.GitError.OutOfMemory => return UndoError.OutOfMemory,
        else => return UndoError.CommandFailed,
    };
}

test "undo reverts last commit" {
    const test_helper = @import("test_helper.zig");
    const add = @import("add.zig").add;
    const log = @import("log.zig");
    const Priority = @import("priority.zig").Priority;
    const init = @import("init.zig").init;

    const allocator = std.testing.allocator;

    const original = try test_helper.setupTestDir(allocator, "test_undo");
    defer test_helper.cleanupTestDir("test_undo", original);

    _ = try init(allocator);

    const title = "Test ticket";
    const ticket_id = try add(allocator, title, "Test body", Priority.B);
    defer allocator.free(ticket_id);

    var dir = try std.fs.cwd().openDir(".tix", .{});
    defer dir.close();
    try dir.access(ticket_id, .{});

    const log_before = try log.log(allocator, false, null, null);
    defer allocator.free(log_before);

    try std.testing.expect(log_before.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, log_before, title) != null);

    try undo(allocator);

    const log_after_undo = try log.log(allocator, false, null, null);
    defer allocator.free(log_after_undo);
    try std.testing.expect(std.mem.indexOf(u8, log_after_undo, title) == null);

    // ticket shouldn't exist anymore
    var dir_after = try std.fs.cwd().openDir(".tix", .{});
    defer dir_after.close();
    const access_err = dir_after.access(ticket_id, .{});
    try std.testing.expectError(error.FileNotFound, access_err);
}
