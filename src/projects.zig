const std = @import("std");
const git = @import("git.zig");

pub const ProjectsError = error{
    CommandFailed,
    OutOfMemory,
    NotARepository,
};

pub fn projects(allocator: std.mem.Allocator) ProjectsError![][]const u8 {
    const branch_output = git.branch(allocator) catch |err| switch (err) {
        git.GitError.NotARepository => return ProjectsError.NotARepository,
        git.GitError.CommandFailed => return ProjectsError.CommandFailed,
        git.GitError.OutOfMemory => return ProjectsError.OutOfMemory,
        else => return ProjectsError.CommandFailed,
    };
    defer allocator.free(branch_output);

    var branches = std.ArrayList([]const u8){};
    defer branches.deinit(allocator);

    var current_branch: ?[]const u8 = null;
    
    var lines = std.mem.tokenizeScalar(u8, branch_output, '\n');
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t\r");
        if (trimmed.len == 0) continue;

        if (std.mem.startsWith(u8, trimmed, "* ")) {
            // Current branch - will be inserted at index 0
            const branch_name = trimmed[2..];
            current_branch = allocator.dupe(u8, branch_name) catch return ProjectsError.OutOfMemory;
        } else {
            // Other branches
            const branch_name = allocator.dupe(u8, trimmed) catch return ProjectsError.OutOfMemory;
            branches.append(allocator, branch_name) catch return ProjectsError.OutOfMemory;
        }
    }

    // Put current branch first
    if (current_branch) |curr| {
        branches.insert(allocator, 0, curr) catch return ProjectsError.OutOfMemory;
    }

    return branches.toOwnedSlice(allocator) catch return ProjectsError.OutOfMemory;
}

test "projects lists branches" {
    const test_helper = @import("test_helper.zig");
    const init = @import("init.zig").init;
    const switch_mod = @import("switch.zig");

    const allocator = std.testing.allocator;

    const original = try test_helper.setupTestDir(allocator, "test_projects");
    defer test_helper.cleanupTestDir("test_projects", original);

    // Create .tix directory
    try std.fs.cwd().makeDir(".tix");

    _ = try init(allocator);

    // List projects - should have main/master by default
    const result1 = try projects(allocator);
    defer {
        for (result1) |branch| allocator.free(branch);
        allocator.free(result1);
    }
    try std.testing.expect(result1.len > 0);
    // First element should be current branch (main)
    try std.testing.expect(std.mem.eql(u8, result1[0], "main"));

    // Create a new project
    _ = try switch_mod.switchProject(allocator, "backend", true);

    // List projects again
    const result2 = try projects(allocator);
    defer {
        for (result2) |branch| allocator.free(branch);
        allocator.free(result2);
    }
    try std.testing.expect(result2.len >= 2);
    // First element should be current project (backend)
    try std.testing.expect(std.mem.eql(u8, result2[0], "backend"));

    // Switch back to main
    _ = try switch_mod.switchProject(allocator, "main", false);

    // List projects again
    const result3 = try projects(allocator);
    defer {
        for (result3) |branch| allocator.free(branch);
        allocator.free(result3);
    }
    // First element should be current project (main)
    try std.testing.expect(std.mem.eql(u8, result3[0], "main"));
    // Should contain backend project
    var has_backend = false;
    for (result3) |branch| {
        if (std.mem.eql(u8, branch, "backend")) {
            has_backend = true;
            break;
        }
    }
    try std.testing.expect(has_backend);
}

test "projects returns error when not a repository" {
    const test_helper = @import("test_helper.zig");
    
    const allocator = std.testing.allocator;

    const original = try test_helper.setupTestDir(allocator, "test_projects_no_repo");
    defer test_helper.cleanupTestDir("test_projects_no_repo", original);

    // Create .tix directory but don't init
    try std.fs.cwd().makeDir(".tix");

    const result = projects(allocator);
    try std.testing.expectError(ProjectsError.NotARepository, result);
}