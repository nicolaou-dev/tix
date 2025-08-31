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
    var argv = std.ArrayList([]const u8){};
    defer argv.deinit(allocator);

    try argv.append(allocator, "git");
    try argv.append(allocator, "-C");
    try argv.append(allocator, ".tix");
    try argv.append(allocator, "config");
    try argv.append(allocator, "--local");
    try argv.append(allocator, key);

    if (value) |val| {
        try argv.append(allocator, val);
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
    branch_name: []const u8,
    create: bool,
) GitError!void {
    // Build argv with git switch command and all paths
    var argv = std.ArrayList([]const u8){};
    defer argv.deinit(allocator);

    try argv.append(allocator, "git");
    try argv.append(allocator, "-C");
    try argv.append(allocator, ".tix");
    try argv.append(allocator, "switch");
    if (create) {
        try argv.append(allocator, "-c");
    }
    try argv.append(allocator, branch_name);

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
    var argv = std.ArrayList([]const u8){};
    defer argv.deinit(allocator);

    try argv.append(allocator, "git");
    try argv.append(allocator, "-C");
    try argv.append(allocator, ".tix");
    try argv.append(allocator, "remote");
    if (verbose) {
        try argv.append(allocator, "-v");
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

pub fn add(
    allocator: std.mem.Allocator,
    paths: []const []const u8,
) GitError!void {
    var argv = std.ArrayList([]const u8){};
    defer argv.deinit(allocator);

    try argv.append(allocator, "git");
    try argv.append(allocator, "-C");
    try argv.append(allocator, ".tix");
    try argv.append(allocator, "add");

    for (paths) |path| {
        try argv.append(allocator, path);
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
}

pub fn commit(
    allocator: std.mem.Allocator,
    message: []const u8,
) GitError!void {
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{ "git", "-C", ".tix", "commit", "-m", message },
    }) catch {
        return GitError.CommitFailed;
    };
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    if (result.term.Exited != 0) {
        return GitError.CommandFailed;
    }
}

pub fn resetHard(
    allocator: std.mem.Allocator,
) GitError!void {
    const result = std.process.Child.run(.{ .allocator = allocator, .argv = &[_][]const u8{ "git", "-C", ".tix", "reset", "--hard" } }) catch {
        return GitError.CommandFailed;
    };
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    if (result.term.Exited != 0) {
        return GitError.CommandFailed;
    }
}

pub fn resetHardHead(
    allocator: std.mem.Allocator,
) GitError!void {
    const result = std.process.Child.run(.{ .allocator = allocator, .argv = &[_][]const u8{ "git", "-C", ".tix", "reset", "--hard", "HEAD^" } }) catch {
        return GitError.CommandFailed;
    };
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    if (result.term.Exited != 0) {
        return GitError.CommandFailed;
    }
}

pub fn resetHardReflog(
    allocator: std.mem.Allocator,
) GitError!void {
    const result = std.process.Child.run(.{ .allocator = allocator, .argv = &[_][]const u8{ "git", "-C", ".tix", "reset", "--hard", "HEAD@{1}" } }) catch {
        return GitError.CommandFailed;
    };
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    if (result.term.Exited != 0) {
        return GitError.CommandFailed;
    }
}

pub fn clean(
    allocator: std.mem.Allocator,
) GitError!void {
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{ "git", "-C", ".tix", "clean", "-fd" },
    }) catch {
        return GitError.CommandFailed;
    };
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    if (result.term.Exited != 0) {
        return GitError.CommandFailed;
    }
}

pub fn log(
    allocator: std.mem.Allocator,
    oneline: bool,
    limit: ?u32,
    since: ?[]const u8,
) GitError![]const u8 {
    var argv = std.ArrayList([]const u8){};
    defer argv.deinit(allocator);

    try argv.append(allocator, "git");
    try argv.append(allocator, "--no-pager");
    try argv.append(allocator, "-C");
    try argv.append(allocator, ".tix");
    try argv.append(allocator, "log");

    if (oneline) {
        try argv.append(allocator, "--oneline");
    } else {
        try argv.append(allocator, "--pretty=format:%h %ad %s");
        try argv.append(allocator, "--date=short");
    }

    var limit_str: ?[]u8 = null;
    defer if (limit_str) |s| allocator.free(s);
    if (limit) |n| {
        limit_str = std.fmt.allocPrint(allocator, "-{}", .{n}) catch return GitError.OutOfMemory;
        argv.append(allocator, limit_str.?) catch return GitError.OutOfMemory;
    }

    var since_str: ?[]u8 = null;
    defer if (since_str) |s| allocator.free(s);
    if (since) |s| {
        since_str = std.fmt.allocPrint(allocator, "--since={s}", .{s}) catch return GitError.OutOfMemory;
        argv.append(allocator, since_str.?) catch return GitError.OutOfMemory;
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

pub fn branch(
    allocator: std.mem.Allocator,
) GitError![]const u8 {
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{ "git", "-C", ".tix", "branch" },
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

pub fn pull(
    allocator: std.mem.Allocator,
) GitError!void {
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{ "git", "-C", ".tix", "pull" },
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

    return;
}

pub fn getCurrentBranch(
    allocator: std.mem.Allocator,
) GitError![]u8 {
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{ "git", "-C", ".tix", "branch", "--show-current" },
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

    const branch_name = std.mem.trim(u8, result.stdout, " \n\r\t");
    return allocator.dupe(u8, branch_name);
}

pub fn push(
    allocator: std.mem.Allocator,
) GitError!void {
    const current_branch = try getCurrentBranch(allocator);
    defer allocator.free(current_branch);

    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{ "git", "-C", ".tix", "push", "-u", "origin", current_branch },
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

    return;
}

pub fn clone(
    allocator: std.mem.Allocator,
    repo_url: []const u8,
) GitError!void {
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{ "git", "clone", repo_url, ".tix" },
    }) catch {
        return GitError.CommandFailed;
    };
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    if (result.term.Exited != 0) {
        return GitError.CommandFailed;
    }
}
