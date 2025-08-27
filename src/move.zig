const std = @import("std");
const ulid = @import("ulid");
const Status = @import("status.zig").Status;

const MoveError = error{
    OutOfMemory,
    FileSystemError,
    InvalidTicketID,
    CommandFailed,
};

pub fn move(
    ticket_id: []const u8,
    status: Status,
) MoveError!i32 {
    if (!ulid.isValid(ticket_id)) return MoveError.InvalidTicketID;

    var ticket_path_buf: [256]u8 = undefined;
    const ticket_path = std.fmt.bufPrint(&ticket_path_buf, ".tix/{s}", .{ticket_id}) catch {
        return MoveError.OutOfMemory;
    };
    var dir = std.fs.cwd().openDir(ticket_path, .{}) catch {
        return MoveError.FileSystemError;
    };
    defer dir.close();

    const current_status = try getCurrentStatusFile(dir);

    dir.rename(current_status, status.toString()) catch {
        return MoveError.CommandFailed;
    };

    return 0;
}

fn getCurrentStatusFile(
    dir: std.fs.Dir,
) ![]const u8 {
    for (std.enums.values(Status)) |s| {
        const status = s.toString();
        dir.access(status, .{}) catch continue;
        return status;
    }
    return MoveError.FileSystemError;
}

test "move update ticket status" {
    const init = @import("init.zig").init;
    const add = @import("add.zig").add;
    const test_helper = @import("test_helper.zig");

    const allocator = std.testing.allocator;

    const original = try test_helper.setupTestDir(allocator, "config_test");
    defer test_helper.cleanupTestDir("config_test", original);

    _ = try init(allocator);

    const id = add(allocator, "Test Task", "This is a test task.", .Z) catch |err| {
        std.debug.print("Error moo: {any}\n", .{err});
        return err;
    };
    defer allocator.free(id);

    // Check initial status - should be Backlog (default from add)
    var ticket_path_buf: [256]u8 = undefined;
    const ticket_path = try std.fmt.bufPrint(&ticket_path_buf, ".tix/{s}", .{id});
    var dir = try std.fs.cwd().openDir(ticket_path, .{});
    defer dir.close();
    
    // Check that Backlog status file exists initially
    dir.access("s=b", .{}) catch |err| {
        std.debug.print("Expected s=b (backlog) file to exist, got error: {}\n", .{err});
        return err;
    };
    
    // Move to Doing status
    const result = try move(id, .Doing);
    try std.testing.expect(result == 0);
    
    // Check that old status file (backlog) no longer exists
    dir.access("s=b", .{}) catch |err| switch (err) {
        error.FileNotFound => {}, // Expected
        else => {
            std.debug.print("Expected s=b to be deleted, but got error: {}\n", .{err});
            return err;
        },
    };
    
    // Check that new status file (doing) exists
    dir.access("s=w", .{}) catch |err| {
        std.debug.print("Expected s=w (doing) file to exist after move, got error: {}\n", .{err});
        return err;
    };
}
