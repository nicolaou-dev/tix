const std = @import("std");
const ticket = @import("ticket.zig");
const Status = @import("status.zig").Status;
const Priority = @import("priority.zig").Priority;

pub const ShowError = error{
    TicketNotFound,
    FileSystemError,
};

pub fn show(allocator: std.mem.Allocator, id: []const u8) ShowError!ticket.Ticket {
    var dir = std.fs.cwd().openDir(".tix", .{}) catch return ShowError.FileSystemError;
    defer dir.close();

    var ticket_dir = dir.openDir(id, .{}) catch return ShowError.TicketNotFound;
    defer ticket_dir.close();

    const title = ticket.getTitle(ticket_dir, allocator) catch return ShowError.FileSystemError;
    errdefer allocator.free(title);

    const body = ticket.getBody(ticket_dir, allocator) catch return ShowError.FileSystemError;
    errdefer allocator.free(body);

    const status = ticket.getStatus(ticket_dir) catch return ShowError.FileSystemError;
    const priority = ticket.getPriority(ticket_dir) catch return ShowError.FileSystemError;

    const duplicated_id = allocator.dupe(u8, id) catch return ShowError.FileSystemError;
    errdefer allocator.free(duplicated_id);

    return ticket.Ticket{
        .id = duplicated_id,
        .title = title,
        .body = body,
        .status = status,
        .priority = priority,
    };
}

pub fn showTitle(allocator: std.mem.Allocator, id: []const u8) ShowError![]const u8 {
    var dir = std.fs.cwd().openDir(".tix", .{}) catch return ShowError.FileSystemError;
    defer dir.close();

    var ticket_dir = dir.openDir(id, .{}) catch return ShowError.TicketNotFound;
    defer ticket_dir.close();

    return ticket.getTitle(ticket_dir, allocator) catch return ShowError.FileSystemError;
}

pub fn showBody(allocator: std.mem.Allocator, id: []const u8) ShowError![]const u8 {
    var dir = std.fs.cwd().openDir(".tix", .{}) catch return ShowError.FileSystemError;
    defer dir.close();

    var ticket_dir = dir.openDir(id, .{}) catch return ShowError.TicketNotFound;
    defer ticket_dir.close();

    return ticket.getBody(ticket_dir, allocator) catch return ShowError.FileSystemError;
}

pub fn showStatus(id: []const u8) ShowError!Status {
    var dir = std.fs.cwd().openDir(".tix", .{}) catch return ShowError.FileSystemError;
    defer dir.close();

    var ticket_dir = dir.openDir(id, .{}) catch return ShowError.TicketNotFound;
    defer ticket_dir.close();

    return ticket.getStatus(ticket_dir) catch return ShowError.FileSystemError;
}

pub fn showPriority(id: []const u8) ShowError!Priority {
    var dir = std.fs.cwd().openDir(".tix", .{}) catch return ShowError.FileSystemError;
    defer dir.close();

    var ticket_dir = dir.openDir(id, .{}) catch return ShowError.TicketNotFound;
    defer ticket_dir.close();

    return ticket.getPriority(ticket_dir) catch return ShowError.FileSystemError;
}

test "show full ticket details" {
    const init = @import("init.zig").init;
    const add = @import("add.zig").add;
    const move = @import("move.zig").move;
    const test_helper = @import("test_helper.zig");

    const allocator = std.testing.allocator;

    const original = try test_helper.setupTestDir(allocator, "show_test");
    defer test_helper.cleanupTestDir("show_test", original);

    _ = try init(allocator);

    // Create a test ticket
    const ticket_id = try add(allocator, "Test Title", "Test body content\nWith multiple lines", .A, null);
    defer allocator.free(ticket_id);

    // Move it to Todo status
    _ = try move(allocator, ticket_id, .Todo);

    // Show the ticket
    var t = try show(allocator, ticket_id);
    defer t.deinit(allocator);

    try std.testing.expectEqualStrings(ticket_id, t.id);
    try std.testing.expectEqualStrings("Test Title", t.title);
    try std.testing.expectEqualStrings("Test body content\nWith multiple lines", t.body);
    try std.testing.expectEqual(Status.Todo, t.status);
    try std.testing.expectEqual(Priority.A, t.priority);
}

test "show individual fields" {
    const init = @import("init.zig").init;
    const add = @import("add.zig").add;
    const move = @import("move.zig").move;
    const test_helper = @import("test_helper.zig");

    const allocator = std.testing.allocator;

    const original = try test_helper.setupTestDir(allocator, "show_fields_test");
    defer test_helper.cleanupTestDir("show_fields_test", original);

    _ = try init(allocator);

    const ticket_id = try add(allocator, "Field Test Title", "Field test body", .B, null);
    defer allocator.free(ticket_id);

    _ = try move(allocator, ticket_id, .Doing);

    // Test showTitle
    const title = try showTitle(allocator, ticket_id);
    defer allocator.free(title);
    try std.testing.expectEqualStrings("Field Test Title", title);

    // Test showBody
    const body = try showBody(allocator, ticket_id);
    defer allocator.free(body);
    try std.testing.expectEqualStrings("Field test body", body);

    // Test showStatus
    const status = try showStatus(ticket_id);
    try std.testing.expectEqual(Status.Doing, status);

    // Test showPriority
    const priority = try showPriority(ticket_id);
    try std.testing.expectEqual(Priority.B, priority);
}

test "show nonexistent ticket" {
    const init = @import("init.zig").init;
    const test_helper = @import("test_helper.zig");

    const allocator = std.testing.allocator;

    const original = try test_helper.setupTestDir(allocator, "show_error_test");
    defer test_helper.cleanupTestDir("show_error_test", original);

    _ = try init(allocator);

    // Try to show a ticket that doesn't exist
    const result = show(allocator, "01K3NONEXISTENTTICKETID");
    try std.testing.expectError(ShowError.TicketNotFound, result);

    // Try to show title of nonexistent ticket
    const title_result = showTitle(allocator, "01K3NONEXISTENTTICKETID");
    try std.testing.expectError(ShowError.TicketNotFound, title_result);

    // Try to show body of nonexistent ticket
    const body_result = showBody(allocator, "01K3NONEXISTENTTICKETID");
    try std.testing.expectError(ShowError.TicketNotFound, body_result);

    // Try to show status of nonexistent ticket
    const status_result = showStatus("01K3NONEXISTENTTICKETID");
    try std.testing.expectError(ShowError.TicketNotFound, status_result);

    // Try to show priority of nonexistent ticket
    const priority_result = showPriority("01K3NONEXISTENTTICKETID");
    try std.testing.expectError(ShowError.TicketNotFound, priority_result);
}

test "show ticket with empty body" {
    const init = @import("init.zig").init;
    const add = @import("add.zig").add;
    const test_helper = @import("test_helper.zig");

    const allocator = std.testing.allocator;

    const original = try test_helper.setupTestDir(allocator, "show_empty_body_test");
    defer test_helper.cleanupTestDir("show_empty_body_test", original);

    _ = try init(allocator);

    // Create ticket with empty body
    const ticket_id = try add(allocator, "No Body Title", "", .Z, null);
    defer allocator.free(ticket_id);

    var t = try show(allocator, ticket_id);
    defer t.deinit(allocator);

    try std.testing.expectEqualStrings("No Body Title", t.title);
    try std.testing.expectEqualStrings("", t.body);
    try std.testing.expectEqual(Status.Backlog, t.status);
    try std.testing.expectEqual(Priority.Z, t.priority);
}
