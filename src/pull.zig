const std = @import("std");
const git = @import("git.zig");

pub const PullError = error{
    CommandFailed,
    OutOfMemory,
    NotARepository,
};

pub fn pull(allocator: std.mem.Allocator) PullError!void {
    git.pull(allocator) catch |err| switch (err) {
        git.GitError.NotARepository => return PullError.NotARepository,
        git.GitError.CommandFailed => return PullError.CommandFailed,
        git.GitError.OutOfMemory => return PullError.OutOfMemory,
        else => return PullError.CommandFailed,
    };

    return;
}

test "pull fetches new changes from remote" {
    const init = @import("init.zig").init;
    const clone = @import("clone.zig").clone;
    const add = @import("add.zig");
    const log = @import("log.zig");
    const undo = @import("undo.zig");
    const test_helper = @import("test_helper.zig");

    const allocator = std.testing.allocator;

    const original = try test_helper.setupTestDir(allocator, "pull_test");
    defer test_helper.cleanupTestDir("pull_test", original);

    var ticket_id_buf: [26]u8 = undefined;
    var ticket_id: []const u8 = undefined;

    // Create repo_1 with a ticket
    {
        try std.fs.cwd().makeDir("repo_1");
        try std.process.changeCurDir("repo_1");
        defer std.process.changeCurDir("..") catch {};
        _ = try init(allocator);

        const title = "Test ticket";
        const id = try add.add(allocator, title, "Test body", .Z, null);
        defer allocator.free(id);

        // Save ticket ID for later use
        @memcpy(&ticket_id_buf, id);
        ticket_id = ticket_id_buf[0..];

        const log_tix_1 = try log.log(allocator, false, null, null);
        defer allocator.free(log_tix_1);

        try std.testing.expect(log_tix_1.len > 0);
        try std.testing.expect(std.mem.indexOf(u8, log_tix_1, title) != null);
    }

    try std.fs.cwd().makeDir("repo_2");
    try std.process.changeCurDir("repo_2");

    // Clone repo_1 to get the ticket
    _ = try clone(allocator, "../repo_1/.tix");

    // Verify we have the ticket after clone
    const log_after_clone = try log.log(allocator, false, null, null);
    defer allocator.free(log_after_clone);
    try std.testing.expect(std.mem.indexOf(u8, log_after_clone, "Test ticket") != null);

    // Verify ticket directory exists before undo
    var tix_dir_before = try std.fs.cwd().openDir(".tix", .{});
    defer tix_dir_before.close();
    try tix_dir_before.access(ticket_id, .{});

    // Undo to go back before the ticket
    try undo.undo(allocator);

    // Verify ticket is gone after undo (both log and directory)
    const log_after_undo = try log.log(allocator, false, null, null);
    defer allocator.free(log_after_undo);
    try std.testing.expect(std.mem.indexOf(u8, log_after_undo, "Test ticket") == null);

    // Verify ticket directory doesn't exist after undo
    var tix_dir_after_undo = try std.fs.cwd().openDir(".tix", .{});
    defer tix_dir_after_undo.close();
    const access_result = tix_dir_after_undo.access(ticket_id, .{});
    try std.testing.expectError(error.FileNotFound, access_result);

    // Pull to bring the ticket back
    try pull(allocator);

    // Verify ticket is back after pull (both log and directory)
    const log_after_pull = try log.log(allocator, false, null, null);
    defer allocator.free(log_after_pull);
    try std.testing.expect(std.mem.indexOf(u8, log_after_pull, "Test ticket") != null);

    // Verify ticket directory exists again after pull
    var tix_dir_after_pull = try std.fs.cwd().openDir(".tix", .{});
    defer tix_dir_after_pull.close();
    try tix_dir_after_pull.access(ticket_id, .{});

    // Verify ticket files exist after pull
    var ticket_dir = try tix_dir_after_pull.openDir(ticket_id, .{});
    defer ticket_dir.close();
    try ticket_dir.access("title.md", .{});
    try ticket_dir.access("body.md", .{});
    try ticket_dir.access("s=b", .{});
    try ticket_dir.access("p=z", .{});
}
