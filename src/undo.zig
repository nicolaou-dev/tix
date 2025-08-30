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
    const move = @import("move.zig").move;
    const Status = @import("status.zig").Status;
    const Priority = @import("priority.zig").Priority;
    const init = @import("init.zig").init;

    const allocator = std.testing.allocator;

    const original = try test_helper.setupTestDir(allocator, "test_undo");
    defer test_helper.cleanupTestDir("test_undo", original);

    // Create .tix directory
    try std.fs.cwd().makeDir(".tix");

    _ = try init(allocator);

    const title = "Test ticket";
    const ticket_id = try add(allocator, title, "Test body", Priority.B);
    defer allocator.free(ticket_id);

    const log_before = try git.log(allocator, false, null, null);
    defer allocator.free(log_before);
    const commits_before = std.mem.count(u8, log_before, "commit ");

    _ = try move(allocator, ticket_id, Status.Todo);

    const log_after_move = try git.log(allocator, false, null, null);
    defer allocator.free(log_after_move);
    const commits_after_move = std.mem.count(u8, log_after_move, "commit ");
    try std.testing.expect(commits_after_move == commits_before + 1);

    try undo(allocator);

    const log_after_undo = try git.log(allocator, false, null, null);
    defer allocator.free(log_after_undo);
    const commits_after_undo = std.mem.count(u8, log_after_undo, "commit ");
    try std.testing.expect(commits_after_undo == commits_before);

    var dir = try std.fs.cwd().openDir(".tix", .{});
    defer dir.close();

    var ticket_dir = try dir.openDir(ticket_id, .{ .iterate = true });
    defer ticket_dir.close();

    var has_todo_status = false;
    var it = ticket_dir.iterate();
    while (try it.next()) |entry| {
        if (entry.kind != .file) continue;
        if (std.mem.eql(u8, entry.name, "s=t")) {
            has_todo_status = true;
            break;
        }
    }

    try std.testing.expect(!has_todo_status);
}