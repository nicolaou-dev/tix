const std = @import("std");

pub const TestContext = struct {
    original_dir: [1024]u8,
    original_len: usize,
};

/// Creates an isolated test directory and manages cleanup
pub fn setupTestDir(allocator: std.mem.Allocator, test_name: []const u8) !TestContext {
    var buf: [1024]u8 = undefined;
    const original = try std.fs.cwd().realpath(".", &buf);

    // Create isolated test directory
    const test_path = try std.fmt.allocPrint(allocator, "/tmp/{s}", .{test_name});
    defer allocator.free(test_path);

    // Delete if exists from previous run, then create fresh
    std.fs.cwd().deleteTree(test_path) catch {};
    try std.fs.cwd().makePath(test_path);
    try std.process.changeCurDir(test_path);

    var result = TestContext{
        .original_dir = undefined,
        .original_len = original.len,
    };
    @memcpy(result.original_dir[0..original.len], original);

    return result;
}

/// Cleans up test directory and returns to original
pub fn cleanupTestDir(test_name: []const u8, original: TestContext) void {
    // Return to original directory
    const original_path = original.original_dir[0..original.original_len];
    std.process.changeCurDir(original_path) catch {};

    // Clean up test directory
    var buf: [256]u8 = undefined;
    const test_path = std.fmt.bufPrint(&buf, "/tmp/{s}", .{test_name}) catch return;
    std.fs.cwd().deleteTree(test_path) catch {};
}
