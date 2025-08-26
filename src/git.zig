const std = @import("std");
const indexOf = std.mem.indexOf;

pub const GitError = error{
    CommandFailed,
    OutOfMemory,

    InitFailed,

    ConfigKeyNotFound,

    BranchNotFound,
    BranchAlreadyExists,
    AlreadyOnBranch,

    CommitFailed,

    RemoteAlreadyExists,
    InvalidRemoteName,
    NotARepository,
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

pub fn config(
    allocator: std.mem.Allocator,
    key: []const u8,
    value: ?[]const u8,
) GitError![]const u8 {
    var argv = std.ArrayList([]const u8).init(allocator);
    defer argv.deinit();

    try argv.append("git");
    try argv.append("-C");
    try argv.append(".tix");
    try argv.append("config");
    try argv.append("--local");
    try argv.append(key);

    if (value) |val| {
        try argv.append(val);
    }

    const result = std.process.Child.run(.{ .allocator = allocator, .argv = argv.items }) catch {
        return GitError.CommandFailed;
    };
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    const err_output = result.stderr;

    const not_inside_git_repo = "inside a git repository";
    const not_a_repo = "not a git repository";
    const key_not_found = "key does not contain a section";

    if (indexOf(u8, err_output, not_inside_git_repo) != null) {
        return GitError.NotARepository;
    }

    if (indexOf(u8, err_output, not_a_repo) != null) {
        return GitError.NotARepository;
    }

    if (indexOf(u8, err_output, key_not_found) != null) {
        return GitError.ConfigKeyNotFound;
    }

    if (result.term.Exited != 0) {
        return GitError.CommandFailed;
    }

    const output = allocator.dupe(u8, result.stdout) catch {
        return GitError.OutOfMemory;
    };

    return output;
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

pub fn remote(
    allocator: std.mem.Allocator,
    verbose: bool,
) GitError![]const u8 {
    var argv = std.ArrayList([]const u8).init(allocator);
    defer argv.deinit();

    try argv.append("git");
    try argv.append("-C");
    try argv.append(".tix");
    try argv.append("remote");
    if (verbose) {
        try argv.append("-v");
    }

    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = argv.items,
    }) catch {
        return GitError.CommandFailed;
    };
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    const err_output = result.stderr;

    const not_a_repo = "not a git repository";

    if (indexOf(u8, err_output, not_a_repo) != null) {
        return GitError.NotARepository;
    }

    if (result.term.Exited != 0) {
        return GitError.CommandFailed;
    }

    const output = allocator.dupe(u8, result.stdout) catch {
        return GitError.OutOfMemory;
    };

    return output;
}

pub fn remoteAdd(
    allocator: std.mem.Allocator,
    name: []const u8,
    url: []const u8,
) GitError!void {
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{ "git", "-C", ".tix", "remote", "add", name, url },
    }) catch {
        return GitError.CommandFailed;
    };
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    const err_output = result.stderr;

    const not_a_repo = "not a git repository";
    const invalid_name = "is not a valid remote name";
    const already_exists = "already exists.";

    if (indexOf(u8, err_output, not_a_repo) != null) {
        return GitError.NotARepository;
    }

    if (indexOf(u8, err_output, invalid_name) != null) {
        return GitError.InvalidRemoteName;
    }

    if (indexOf(u8, err_output, already_exists) != null) {
        return GitError.RemoteAlreadyExists;
    }

    if (result.term.Exited != 0) {
        // Command failed but we don't recognize the error
        return GitError.CommandFailed;
    }
}
