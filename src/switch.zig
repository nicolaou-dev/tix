const std = @import("std");
const git = @import("git.zig");

pub const SwitchError = error{
    ProjectNotFound,
    ProjectAlreadyExists,
    AlreadyOnProject,
    NotARepository,
    CommandFailed,
};

pub const SwitchResult = enum {
    switched,
    created,
};

/// Switch project, creating it if necessary
pub fn switchProject(allocator: std.mem.Allocator, project: []const u8, create: bool) SwitchError!SwitchResult {
    git.switchBranch(allocator, project, create) catch |err| switch (err) {
        error.BranchNotFound => return SwitchError.ProjectNotFound,
        error.BranchAlreadyExists => return SwitchError.ProjectAlreadyExists,
        error.AlreadyOnBranch => return SwitchError.AlreadyOnProject,
        error.NotARepository => return SwitchError.NotARepository,
        else => return SwitchError.CommandFailed,
    };

    return if (create) .created else .switched;
}

test "switchProject handles all switch scenarios" {
    const init = @import("init.zig").init;
    const test_helper = @import("test_helper.zig");
    const allocator = std.testing.allocator;

    // Setup isolated test directory
    const original = try test_helper.setupTestDir(allocator, "switch_test");
    defer test_helper.cleanupTestDir("switch_test", original);

    _ = try init(allocator);

    const err = switchProject(allocator, "my-project", false);
    try std.testing.expectError(SwitchError.ProjectNotFound, err);

    const result = try switchProject(allocator, "my-project", true);
    try std.testing.expect(result == .created);

    // try to switch to the same project - should fail
    const err2 = switchProject(allocator, "my-project", false);
    try std.testing.expectError(SwitchError.AlreadyOnProject, err2);

    // Try to create the same project again while in that project - should fail
    const err3 = switchProject(allocator, "my-project", true);
    try std.testing.expectError(SwitchError.ProjectAlreadyExists, err3);

    // Create another project
    const result2 = try switchProject(allocator, "another-project", true);
    try std.testing.expect(result2 == .created);

    // Now switch back to first project
    const result3 = try switchProject(allocator, "my-project", false);
    try std.testing.expect(result3 == .switched);

    // Try to create the same project again - should fail
    const err4 = switchProject(allocator, "another-project", true);
    try std.testing.expectError(SwitchError.ProjectAlreadyExists, err4);
}
