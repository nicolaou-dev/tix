const std = @import("std");
const git = @import("git.zig");

pub const CloneError = error{
    CommandFailed,
    OutOfMemory,
    WorkspaceAlreadyExists,
};
pub fn clone(
    allocator: std.mem.Allocator,
    repo_url: []const u8,
) CloneError!void {
    // Check if .tix already exists - if so, fail
    std.fs.cwd().access(".tix", .{}) catch |err| switch (err) {
        error.FileNotFound => {}, // Good, doesn't exist
        else => return CloneError.WorkspaceAlreadyExists,
    };

    git.clone(allocator, repo_url) catch |err| switch (err) {
        git.GitError.OutOfMemory => return CloneError.OutOfMemory,
        else => return CloneError.CommandFailed,
    };
}

test "clone fetches workspace from remote" {
    const init = @import("init.zig").init;
    const add = @import("add.zig");
    const log = @import("log.zig");
    const test_helper = @import("test_helper.zig");

    const allocator = std.testing.allocator;

    const original = try test_helper.setupTestDir(allocator, "clone_test");
    defer test_helper.cleanupTestDir("clone_test", original);

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

        const log_repo1 = try log.log(allocator, false, null, null);
        defer allocator.free(log_repo1);

        try std.testing.expect(log_repo1.len > 0);
        try std.testing.expect(std.mem.indexOf(u8, log_repo1, title) != null);
    }

    try std.fs.cwd().makeDir("repo_2");
    try std.process.changeCurDir("repo_2");

    // Clone repo_1 to get the ticket
    _ = try clone(allocator, "../repo_1/.tix");
    
    // Verify we have the ticket after clone (log)
    const log_after_clone = try log.log(allocator, false, null, null);
    defer allocator.free(log_after_clone);
    try std.testing.expect(std.mem.indexOf(u8, log_after_clone, "Test ticket") != null);

    // Verify ticket directory and files exist
    var tix_dir = try std.fs.cwd().openDir(".tix", .{});
    defer tix_dir.close();
    try tix_dir.access(ticket_id, .{});

    var ticket_dir = try tix_dir.openDir(ticket_id, .{});
    defer ticket_dir.close();
    
    try ticket_dir.access("title.md", .{});
    try ticket_dir.access("body.md", .{});
    try ticket_dir.access("s=b", .{});
    try ticket_dir.access("p=z", .{});
}
