const std = @import("std");
const git = @import("git.zig");
const ulid = @import("ulid");
const Status = @import("status.zig").Status;
const Priority = @import("priority.zig").Priority;

const AddError = error{
    NotARepository,
    CommandFailed,
    OutOfMemory,
    FileSystemError,
    InvalidTitle,
};

pub fn add(
    allocator: std.mem.Allocator,
    title: []const u8,
    body: []const u8,
    priority: Priority,
) AddError![]const u8 {
    errdefer {
        git.resetHard(allocator) catch {};
        git.clean(allocator) catch {};
    }

    // Error if title is empty
    if (title.len == 0) {
        return AddError.InvalidTitle;
    }

    const id = ulid.newString();

    var ticket_path_buf: [256]u8 = undefined;
    const ticket_path = std.fmt.bufPrint(&ticket_path_buf, ".tix/{s}", .{id}) catch {
        return AddError.OutOfMemory;
    };

    std.fs.cwd().makePath(ticket_path) catch {
        return AddError.FileSystemError;
    };

    var dir = std.fs.cwd().openDir(ticket_path, .{}) catch {
        return AddError.FileSystemError;
    };
    defer dir.close();

    dir.writeFile(.{
        .sub_path = "title.md",
        .data = title,
    }) catch {
        return AddError.FileSystemError;
    };

    dir.writeFile(.{
        .sub_path = "body.md",
        .data = body,
    }) catch {
        return AddError.FileSystemError;
    };

    const status_file = dir.createFile(Status.Backlog.toString(), .{}) catch {
        return AddError.FileSystemError;
    };
    status_file.close();

    const priority_file = dir.createFile(priority.toString(), .{}) catch {
        return AddError.FileSystemError;
    };
    priority_file.close();

    const paths = [_][]const u8{&id};

    git.add(allocator, &paths) catch |err| switch (err) {
        error.NotARepository => return AddError.NotARepository,
        error.OutOfMemory => return AddError.OutOfMemory,
        else => return AddError.CommandFailed,
    };

    var commit_message_buf: [256]u8 = undefined;
    const commit_message = std.fmt.bufPrint(&commit_message_buf, "{s} New: {s}", .{ id, title }) catch {
        return AddError.OutOfMemory;
    };

    git.commit(allocator, commit_message) catch |err| switch (err) {
        error.OutOfMemory => return AddError.OutOfMemory,
        else => return AddError.CommandFailed,
    };

    const output = allocator.dupe(u8, &id) catch {
        return AddError.OutOfMemory;
    };

    return output;
}

test "add task" {
    const init = @import("init.zig").init;
    const test_helper = @import("test_helper.zig");

    const allocator = std.testing.allocator;

    const original = try test_helper.setupTestDir(allocator, "config_test");
    defer test_helper.cleanupTestDir("config_test", original);

    // Create .tix directory
    try std.fs.cwd().makeDir(".tix");

    const not_a_repo = add(allocator, "Test Task", "This is a test task.", Priority.A);

    try std.testing.expectError(AddError.NotARepository, not_a_repo);

    _ = try init(allocator);

    const id = add(allocator, "Test Task", "This is a test task.", Priority.A) catch |err| {
        std.debug.print("Error moo: {any}\n", .{err});
        return err;
    };
    defer allocator.free(id);
    _ = try ulid.parse(id);

    const ticket_path = std.fmt.allocPrint(allocator, ".tix/{s}", .{id}) catch {
        return;
    };
    defer allocator.free(ticket_path);

    // Verify ticket directory and files created
    var ticket_dir = try std.fs.cwd().openDir(ticket_path, .{});
    defer ticket_dir.close();

    const title_content = try ticket_dir.readFileAlloc(allocator, "title.md", 1024);
    defer allocator.free(title_content);
    try std.testing.expect(std.mem.eql(u8, title_content, "Test Task"));

    const body_content = try ticket_dir.readFileAlloc(allocator, "body.md", 1024);
    defer allocator.free(body_content);
    try std.testing.expect(std.mem.eql(u8, body_content, "This is a test task."));

    try ticket_dir.access("s=b", .{});
    try ticket_dir.access("p=a", .{});

    const log = try git.log(allocator, false, null, null);
    defer allocator.free(log);

    try std.testing.expect(std.mem.indexOf(u8, log, id) != null);
}

test "add task with empty title fails" {
    const init = @import("init.zig").init;
    const test_helper = @import("test_helper.zig");

    const allocator = std.testing.allocator;

    const original = try test_helper.setupTestDir(allocator, "add_empty_title_test");
    defer test_helper.cleanupTestDir("add_empty_title_test", original);

    // Create .tix directory
    try std.fs.cwd().makeDir(".tix");

    _ = try init(allocator);

    const result = add(allocator, "", "This is a test task with empty title.", Priority.B);
    try std.testing.expectError(AddError.InvalidTitle, result);
}

test "set priority to z (default)" {
    const init = @import("init.zig").init;
    const test_helper = @import("test_helper.zig");

    const allocator = std.testing.allocator;

    const original = try test_helper.setupTestDir(allocator, "add_default_priority_test");
    defer test_helper.cleanupTestDir("add_default_priority_test", original);

    // Create .tix directory
    try std.fs.cwd().makeDir(".tix");

    _ = try init(allocator);

    const id = add(allocator, "Task with Default Priority", "This task should have priority Z.", Priority.Z) catch {
        return;
    };
    defer allocator.free(id);

    const ticket_path = std.fmt.allocPrint(allocator, ".tix/{s}", .{id}) catch {
        return;
    };
    defer allocator.free(ticket_path);

    // Verify ticket directory and files created
    var ticket_dir = try std.fs.cwd().openDir(ticket_path, .{});
    defer ticket_dir.close();

    try ticket_dir.access("p=z", .{});
}
