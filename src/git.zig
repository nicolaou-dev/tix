const std = @import("std");
const indexOf = std.mem.indexOf;

pub const GitError = error{
    CommandFailed,
    OutOfMemory,

    InitFailed,

    BranchNotFound,
    BranchAlreadyExists,
    AlreadyOnBranch,

    CommitFailed,
};

/// Initialize a new git repository
pub fn init(
    allocator: std.mem.Allocator,
) GitError!void {
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{ "git", "-C", ".tix", "init" },
    }) catch {
        return GitError.InitFailed;
    };
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    if (result.term.Exited != 0) {
        return GitError.InitFailed;
    }
}

pub fn switchBranch(
    allocator: std.mem.Allocator,
    branch: []const u8,
    create: bool,
) GitError!void {
    // Build argv with git switch command and all paths
    var argv = std.ArrayList([]const u8).init(allocator);
    defer argv.deinit();

    try argv.append("git");
    try argv.append("-C");
    try argv.append(".tix");
    try argv.append("switch");
    if (create) {
        try argv.append("-c");
    }
    try argv.append(branch);

    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = argv.items,
    }) catch {
        return GitError.CommandFailed;
    };
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    // Check for specific conditions in output
    const err_output = result.stderr;

    const already_on = "Already on";
    const not_found = "invalid reference";
    const already_exists = "already exists";

    if (indexOf(u8, err_output, already_on) != null) {
        return GitError.AlreadyOnBranch;
    }

    if (indexOf(u8, err_output, not_found) != null) {
        return GitError.BranchNotFound;
    }

    if (indexOf(u8, err_output, already_exists) != null) {
        return GitError.BranchAlreadyExists;
    }

    // If command failed but we don't recognize the error
    if (result.term.Exited != 0) {
        return GitError.CommandFailed;
    }
}

pub fn commitEmpty(
    allocator: std.mem.Allocator,
    message: []const u8,
) GitError!void {
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{ "git", "-C", ".tix", "commit", "--allow-empty", "-m", message },
    }) catch {
        return GitError.CommitFailed;
    };
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    if (result.term.Exited != 0) {
        return GitError.CommandFailed;
    }
}
