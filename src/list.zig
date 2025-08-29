const std = @import("std");
const ulid = @import("ulid");
const Status = @import("status.zig").Status;
const Priority = @import("priority.zig").Priority;
const Ticket = @import("ticket.zig").Ticket;

const ListError = error{FileSystemError};

const Filters = struct {
    statuses: ?[]const Status = null,
    priorities: ?[]const Priority = null,
};

pub fn list(allocator: std.mem.Allocator, filters: Filters) ListError![]Ticket {
    var dir = std.fs.cwd().openDir(".tix", .{}) catch return ListError.FileSystemError;
    defer dir.close();

    var tickets = std.ArrayList(Ticket){};
    errdefer {
        for (tickets.items) |*t| {
            t.deinit(allocator);
        }
        tickets.deinit(allocator);
    }

    var it = dir.iterate();
    while (it.next() catch return ListError.FileSystemError) |entry| {
        // Skip non-ticket directories
        if (entry.kind != .directory) continue;

        if (!ulid.isValid(entry.name)) continue;

        const indexOfScalar = std.mem.indexOfScalar;

        var status: ?Status = null;
        if (filters.statuses) |sf| {
            status = try getStatus(entry.name, dir);
            if (indexOfScalar(Status, sf, status.?) == null)
                continue;
        }

        var priority: ?Priority = null;
        if (filters.priorities) |pf| {
            priority = try getPriority(entry.name, dir);
            if (indexOfScalar(Priority, pf, priority.?) == null)
                continue;
        }

        if (priority == null) {
            priority = getPriority(entry.name, dir) catch continue;
        }

        if (status == null) {
            status = getStatus(entry.name, dir) catch continue;
        }
        const ticket = Ticket.read(allocator, dir, entry.name, status.?, priority.?) catch return ListError.FileSystemError;

        tickets.append(allocator, ticket) catch return ListError.FileSystemError;
    }

    return tickets.toOwnedSlice(allocator) catch return ListError.FileSystemError;
}

fn getStatus(
    id: []const u8,
    dir: std.fs.Dir,
) !Status {
    for (std.enums.values(Status)) |s| {
        const status = s.toString();
        var status_buf: [256]u8 = undefined;
        const status_path = std.fmt.bufPrint(&status_buf, "{s}/{s}", .{ id, status }) catch continue;
        dir.access(status_path, .{}) catch continue;
        return s;
    }
    return ListError.FileSystemError;
}

fn getPriority(
    id: []const u8,
    dir: std.fs.Dir,
) !Priority {
    for (std.enums.values(Priority)) |p| {
        const priority = p.toString();
        var priority_buf: [256]u8 = undefined;
        const priority_path = std.fmt.bufPrint(&priority_buf, "{s}/{s}", .{ id, priority }) catch continue;
        dir.access(priority_path, .{}) catch continue;
        return p;
    }
    return ListError.FileSystemError;
}

test "list active tickets by default" {
    const init = @import("init.zig").init;
    const add = @import("add.zig").add;
    const move = @import("move.zig").move;
    const test_helper = @import("test_helper.zig");

    const allocator = std.testing.allocator;

    const original = try test_helper.setupTestDir(allocator, "list_test");
    defer test_helper.cleanupTestDir("list_test", original);

    _ = try init(allocator);

    // Create tickets with different statuses
    const todo_id = try add(allocator, "Todo Task", "This is todo", .A);
    defer allocator.free(todo_id);
    _ = try move(todo_id, .Todo);

    const doing_id = try add(allocator, "Doing Task", "This is doing", .B);
    defer allocator.free(doing_id);
    _ = try move(doing_id, .Doing);

    const done_id = try add(allocator, "Done Task", "This is done", .C);
    defer allocator.free(done_id);
    _ = try move(done_id, .Done);

    const backlog_id = try add(allocator, "Backlog Task", "This is backlog", .Z);
    defer allocator.free(backlog_id);

    // List with no filters (should get all tickets now)
    const tickets = try list(allocator, Filters{});
    defer {
        for (tickets) |*ticket| {
            ticket.deinit(allocator);
        }
        allocator.free(tickets);
    }

    try std.testing.expectEqual(@as(usize, 4), tickets.len);

    // Check we got tickets with all statuses
    var has_todo = false;
    var has_doing = false;
    var has_done = false;
    var has_backlog = false;
    for (tickets) |ticket| {
        if (ticket.status == .Todo) has_todo = true;
        if (ticket.status == .Doing) has_doing = true;
        if (ticket.status == .Done) has_done = true;
        if (ticket.status == .Backlog) has_backlog = true;
    }
    try std.testing.expect(has_todo);
    try std.testing.expect(has_doing);
    try std.testing.expect(has_done);
    try std.testing.expect(has_backlog);
}

test "list filter by status" {
    const init = @import("init.zig").init;
    const add = @import("add.zig").add;
    const move = @import("move.zig").move;
    const test_helper = @import("test_helper.zig");

    const allocator = std.testing.allocator;

    const original = try test_helper.setupTestDir(allocator, "list_status_test");
    defer test_helper.cleanupTestDir("list_status_test", original);

    _ = try init(allocator);

    // Create multiple todo tickets
    const todo1_id = try add(allocator, "Todo 1", "First todo", .A);
    defer allocator.free(todo1_id);
    _ = try move(todo1_id, .Todo);

    const todo2_id = try add(allocator, "Todo 2", "Second todo", .B);
    defer allocator.free(todo2_id);
    _ = try move(todo2_id, .Todo);

    const doing_id = try add(allocator, "Doing Task", "This is doing", .C);
    defer allocator.free(doing_id);
    _ = try move(doing_id, .Doing);

    const done_id = try add(allocator, "Done Task", "This is done", .Z);
    defer allocator.free(done_id);
    _ = try move(done_id, .Done);

    // Test 1: Filter for todo only
    {
        const filters = Filters{
            .statuses = &[_]Status{.Todo},
            .priorities = null,
        };

        const tickets = try list(allocator, filters);
        defer {
            for (tickets) |*ticket| {
                ticket.deinit(allocator);
            }
            allocator.free(tickets);
        }

        try std.testing.expectEqual(@as(usize, 2), tickets.len);
        for (tickets) |ticket| {
            try std.testing.expectEqual(Status.Todo, ticket.status);
        }
    }

    // Test 2: Filter for multiple statuses (Todo and Doing)
    {
        const filters = Filters{
            .statuses = &[_]Status{ .Todo, .Doing },
            .priorities = null,
        };

        const tickets = try list(allocator, filters);
        defer {
            for (tickets) |*ticket| {
                ticket.deinit(allocator);
            }
            allocator.free(tickets);
        }

        try std.testing.expectEqual(@as(usize, 3), tickets.len);
        for (tickets) |ticket| {
            try std.testing.expect(ticket.status == .Todo or ticket.status == .Doing);
            try std.testing.expect(ticket.status != .Done);
        }
    }
}

test "list filter by priority" {
    const init = @import("init.zig").init;
    const add = @import("add.zig").add;
    const move = @import("move.zig").move;
    const test_helper = @import("test_helper.zig");

    const allocator = std.testing.allocator;

    const original = try test_helper.setupTestDir(allocator, "list_priority_test");
    defer test_helper.cleanupTestDir("list_priority_test", original);

    _ = try init(allocator);

    // Create tickets with different priorities
    const high1_id = try add(allocator, "High Priority 1", "Important", .A);
    defer allocator.free(high1_id);
    _ = try move(high1_id, .Todo);

    const high2_id = try add(allocator, "High Priority 2", "Also important", .A);
    defer allocator.free(high2_id);
    _ = try move(high2_id, .Doing);

    const medium_id = try add(allocator, "Medium Priority", "Medium urgent", .B);
    defer allocator.free(medium_id);
    _ = try move(medium_id, .Todo);

    const low_id = try add(allocator, "Low Priority", "Not urgent", .Z);
    defer allocator.free(low_id);
    _ = try move(low_id, .Todo);

    // Test 1: Filter for priority A only (with default status filter)
    {
        const filters = Filters{
            .statuses = &[_]Status{ .Todo, .Doing },
            .priorities = &[_]Priority{.A},
        };

        const tickets = try list(allocator, filters);
        defer {
            for (tickets) |*ticket| {
                ticket.deinit(allocator);
            }
            allocator.free(tickets);
        }

        try std.testing.expectEqual(@as(usize, 2), tickets.len);
        for (tickets) |ticket| {
            try std.testing.expectEqual(Priority.A, ticket.priority);
        }
    }

    // Test 2: Filter for multiple priorities (A and B)
    {
        const filters = Filters{
            .statuses = &[_]Status{ .Todo, .Doing },
            .priorities = &[_]Priority{ .A, .B },
        };

        const tickets = try list(allocator, filters);
        defer {
            for (tickets) |*ticket| {
                ticket.deinit(allocator);
            }
            allocator.free(tickets);
        }

        try std.testing.expectEqual(@as(usize, 3), tickets.len);
        for (tickets) |ticket| {
            try std.testing.expect(ticket.priority == .A or ticket.priority == .B);
            try std.testing.expect(ticket.priority != .Z);
        }
    }
}

test "list combined filters" {
    const init = @import("init.zig").init;
    const add = @import("add.zig").add;
    const move = @import("move.zig").move;
    const test_helper = @import("test_helper.zig");

    const allocator = std.testing.allocator;

    const original = try test_helper.setupTestDir(allocator, "list_combined_test");
    defer test_helper.cleanupTestDir("list_combined_test", original);

    _ = try init(allocator);

    // Create tickets with various combinations
    const todo_a_id = try add(allocator, "Todo A", "High priority todo", .A);
    defer allocator.free(todo_a_id);
    _ = try move(todo_a_id, .Todo);

    const todo_b_id = try add(allocator, "Todo B", "Medium priority todo", .B);
    defer allocator.free(todo_b_id);
    _ = try move(todo_b_id, .Todo);

    const doing_a_id = try add(allocator, "Doing A", "High priority doing", .A);
    defer allocator.free(doing_a_id);
    _ = try move(doing_a_id, .Doing);

    // Filter for Todo status AND priority A
    const filters = Filters{
        .statuses = &[_]Status{.Todo},
        .priorities = &[_]Priority{.A},
    };

    const tickets = try list(allocator, filters);
    defer {
        for (tickets) |*ticket| {
            ticket.deinit(allocator);
        }
        allocator.free(tickets);
    }

    try std.testing.expectEqual(@as(usize, 1), tickets.len);
    try std.testing.expectEqual(Status.Todo, tickets[0].status);
    try std.testing.expectEqual(Priority.A, tickets[0].priority);
}
