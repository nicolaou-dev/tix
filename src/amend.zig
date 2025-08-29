const std = @import("std");
const git = @import("git.zig");
const ulid = @import("ulid");
const ticket = @import("ticket.zig");
const Status = @import("status.zig").Status;
const Priority = @import("priority.zig").Priority;

const AmendError = error{
    NotARepository,
    OutOfMemory,
    FileSystemError,
    CommandFailed,
    InvalidTicketID,
};

pub fn amend(allocator: std.mem.Allocator, ticket_id: []const u8, title: ?[]const u8, body: ?[]const u8, priority: ?Priority) AmendError!void {
    errdefer {
        git.resetHard(allocator) catch {};
        git.clean(allocator) catch {};
    }

    if (!ulid.isValid(ticket_id)) return AmendError.InvalidTicketID;

    var ticket_path_buf: [256]u8 = undefined;
    const ticket_path = std.fmt.bufPrint(&ticket_path_buf, ".tix/{s}", .{ticket_id}) catch {
        return AmendError.OutOfMemory;
    };
    var dir = std.fs.cwd().openDir(ticket_path, .{}) catch {
        return AmendError.FileSystemError;
    };
    defer dir.close();

    // Track changes for commit message (max 4 changes)
    var changes: [4][64]u8 = std.mem.zeroes([4][64]u8);
    var change_count: u8 = 0;

    if (title) |t| {
        dir.writeFile(.{
            .sub_path = "title.md",
            .data = t,
        }) catch {
            return AmendError.FileSystemError;
        };

        _ = std.fmt.bufPrint(&changes[change_count], "title: updated", .{}) catch {
            return AmendError.OutOfMemory;
        };
        change_count += 1;
    }

    if (body) |b| {
        dir.writeFile(.{
            .sub_path = "body.md",
            .data = b,
        }) catch {
            return AmendError.FileSystemError;
        };

        _ = std.fmt.bufPrint(&changes[change_count], "body: updated", .{}) catch {
            return AmendError.OutOfMemory;
        };
        change_count += 1;
    }


    if (priority) |p| {
        const current_priority = ticket.getPriority(dir) catch {
            return AmendError.FileSystemError;
        };

        dir.rename(current_priority.toString(), p.toString()) catch {
            return AmendError.CommandFailed;
        };

        _ = std.fmt.bufPrint(&changes[change_count], "priority: {s} -> {s}", .{ @tagName(current_priority), @tagName(p) }) catch {
            return AmendError.OutOfMemory;
        };
        change_count += 1;
    }

    // Only commit if there were changes
    if (change_count > 0) {
        const paths = [_][]const u8{ticket_id};

        git.add(allocator, &paths) catch |err| switch (err) {
            error.NotARepository => return AmendError.NotARepository,
            error.OutOfMemory => return AmendError.OutOfMemory,
            else => return AmendError.CommandFailed,
        };

        // Build commit message from tracked changes
        var commit_message_buf: [512]u8 = undefined;
        const header = std.fmt.bufPrint(&commit_message_buf, "{s}: Amended\n", .{ticket_id}) catch {
            return AmendError.OutOfMemory;
        };
        var pos: usize = header.len;

        for (0..change_count) |i| {
            const remaining = commit_message_buf[pos..];
            const line = std.fmt.bufPrint(remaining, "{s}\n", .{std.mem.sliceTo(&changes[i], 0)}) catch {
                return AmendError.OutOfMemory;
            };
            pos += line.len;
        }

        const final_message = commit_message_buf[0..pos];
        git.commit(allocator, final_message) catch |err| switch (err) {
            error.OutOfMemory => return AmendError.OutOfMemory,
            else => return AmendError.CommandFailed,
        };
    }
}

test "amend updates ticket title" {
    const init = @import("init.zig").init;
    const add = @import("add.zig").add;
    const test_helper = @import("test_helper.zig");
    const allocator = std.testing.allocator;

    const original = try test_helper.setupTestDir(allocator, "amend_title_test");
    defer test_helper.cleanupTestDir("amend_title_test", original);

    _ = try init(allocator);

    const id = try add(allocator, "Original Title", "Original body", .Z);
    defer allocator.free(id);

    // Amend only the title
    try amend(allocator, id, "New Title", null, null);

    // Verify title was updated
    const ticket_path = try std.fmt.allocPrint(allocator, ".tix/{s}", .{id});
    defer allocator.free(ticket_path);

    var ticket_dir = try std.fs.cwd().openDir(ticket_path, .{});
    defer ticket_dir.close();

    const title_content = try ticket_dir.readFileAlloc(allocator, "title.md", 1024);
    defer allocator.free(title_content);
    try std.testing.expect(std.mem.eql(u8, title_content, "New Title"));

    // Verify body was not changed
    const body_content = try ticket_dir.readFileAlloc(allocator, "body.md", 1024);
    defer allocator.free(body_content);
    try std.testing.expect(std.mem.eql(u8, body_content, "Original body"));
}

test "amend updates ticket priority" {
    const init = @import("init.zig").init;
    const add = @import("add.zig").add;
    const test_helper = @import("test_helper.zig");
    const allocator = std.testing.allocator;

    const original = try test_helper.setupTestDir(allocator, "amend_status_test");
    defer test_helper.cleanupTestDir("amend_status_test", original);

    _ = try init(allocator);

    const id = try add(allocator, "Test Title", "Test body", .Z);
    defer allocator.free(id);

    // Amend priority only
    try amend(allocator, id, null, null, .A);

    // Verify priority file was updated
    const ticket_path = try std.fmt.allocPrint(allocator, ".tix/{s}", .{id});
    defer allocator.free(ticket_path);

    var ticket_dir = try std.fs.cwd().openDir(ticket_path, .{});
    defer ticket_dir.close();

    // Check new priority file exists  
    try ticket_dir.access("p=a", .{});
    // Check old priority file is gone
    try std.testing.expectError(error.FileNotFound, ticket_dir.access("p=z", .{}));
}

test "amend with no changes does not commit" {
    const init = @import("init.zig").init;
    const add = @import("add.zig").add;
    const test_helper = @import("test_helper.zig");
    const allocator = std.testing.allocator;

    const original = try test_helper.setupTestDir(allocator, "amend_no_changes_test");
    defer test_helper.cleanupTestDir("amend_no_changes_test", original);

    _ = try init(allocator);

    const id = try add(allocator, "Test Title", "Test body", .Z);
    defer allocator.free(id);

    // Get initial commit count
    const log_before = try git.log(allocator);
    defer allocator.free(log_before);
    const commits_before = std.mem.count(u8, log_before, "commit");

    // Amend with no actual changes
    try amend(allocator, id, null, null, null);

    // Verify no new commit was created
    const log_after = try git.log(allocator);
    defer allocator.free(log_after);
    const commits_after = std.mem.count(u8, log_after, "commit");

    try std.testing.expect(commits_before == commits_after);
}

test "amend with invalid ticket id fails" {
    const init = @import("init.zig").init;
    const test_helper = @import("test_helper.zig");
    const allocator = std.testing.allocator;

    const original = try test_helper.setupTestDir(allocator, "amend_invalid_id_test");
    defer test_helper.cleanupTestDir("amend_invalid_id_test", original);

    _ = try init(allocator);

    // Try to amend non-existent ticket
    const result = amend(allocator, "invalid_id", "New Title", null, null);
    try std.testing.expectError(AmendError.InvalidTicketID, result);
}

test "amend commit message format is clean" {
    const init = @import("init.zig").init;
    const add = @import("add.zig").add;
    const test_helper = @import("test_helper.zig");
    const allocator = std.testing.allocator;

    const original = try test_helper.setupTestDir(allocator, "amend_commit_msg_test");
    defer test_helper.cleanupTestDir("amend_commit_msg_test", original);

    _ = try init(allocator);

    const id = try add(allocator, "Original Title", "Original body", .Z);
    defer allocator.free(id);

    // Amend multiple fields to test commit message formatting
    try amend(allocator, id, "New Title", "New body", .A);

    // Check that the commit message is properly formatted (no corruption)
    const log = try git.log(allocator);
    defer allocator.free(log);

    // Verify commit message contains expected format
    try std.testing.expect(std.mem.indexOf(u8, log, "Amended") != null);
    try std.testing.expect(std.mem.indexOf(u8, log, "title: updated") != null);
    try std.testing.expect(std.mem.indexOf(u8, log, "body: updated") != null);
    try std.testing.expect(std.mem.indexOf(u8, log, "priority: Z -> A") != null);
    
    // Verify no corruption characters
    try std.testing.expect(std.mem.indexOf(u8, log, "ªªª") == null);
    try std.testing.expect(std.mem.indexOf(u8, log, "\u{00}") == null);
}
