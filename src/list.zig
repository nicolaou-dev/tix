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

    const indexOfScalar = std.mem.indexOfScalar;
    var it = dir.iterate();
    while (it.next() catch return ListError.FileSystemError) |entry| {
        // Skip non-ticket directories
        if (entry.kind != .directory) continue;

        if (!ulid.isValid(entry.name)) continue;

        var td = dir.openDir(entry.name, .{}) catch return ListError.FileSystemError;
        defer td.close();

        var status: ?Status = null;
        var priority: ?Priority = null;
        var td_it = td.iterate();
        while (td_it.next() catch return ListError.FileSystemError) |sub_entry| {
            if (sub_entry.kind != .file) continue;

            switch (sub_entry.name[0]) {
                'p' => priority = std.meta.intToEnum(Priority, sub_entry.name[2]) catch continue,
                's' => status = std.meta.intToEnum(Status, sub_entry.name[2]) catch continue,

                else => continue,
            }

            if (status != null and priority != null) break;
        }
        if (filters.statuses) |sf| {
            if (indexOfScalar(Status, sf, status.?) == null) continue;
        }
        if (filters.priorities) |pf| {
            if (indexOfScalar(Priority, pf, priority.?) == null) continue;
        }
        const title = td.readFileAlloc(allocator, "title.md", 1024) catch return ListError.FileSystemError;

        tickets.append(allocator, .{
            .id = allocator.dupe(u8, entry.name) catch return ListError.FileSystemError,
            .title = title,
            .status = status.?,
            .priority = priority.?,
        }) catch return ListError.FileSystemError;
    }

    return tickets.toOwnedSlice(allocator) catch return ListError.FileSystemError;
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
    _ = try move(allocator, todo_id, .Todo);

    const doing_id = try add(allocator, "Doing Task", "This is doing", .B);
    defer allocator.free(doing_id);
    _ = try move(allocator, doing_id, .Doing);

    const done_id = try add(allocator, "Done Task", "This is done", .C);
    defer allocator.free(done_id);
    _ = try move(allocator, done_id, .Done);

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
    _ = try move(allocator, todo1_id, .Todo);

    const todo2_id = try add(allocator, "Todo 2", "Second todo", .B);
    defer allocator.free(todo2_id);
    _ = try move(allocator, todo2_id, .Todo);

    const doing_id = try add(allocator, "Doing Task", "This is doing", .C);
    defer allocator.free(doing_id);
    _ = try move(allocator, doing_id, .Doing);

    const done_id = try add(allocator, "Done Task", "This is done", .Z);
    defer allocator.free(done_id);
    _ = try move(allocator, done_id, .Done);

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
    _ = try move(allocator, high1_id, .Todo);

    const high2_id = try add(allocator, "High Priority 2", "Also important", .A);
    defer allocator.free(high2_id);
    _ = try move(allocator, high2_id, .Doing);

    const medium_id = try add(allocator, "Medium Priority", "Medium urgent", .B);
    defer allocator.free(medium_id);
    _ = try move(allocator, medium_id, .Todo);

    const low_id = try add(allocator, "Low Priority", "Not urgent", .Z);
    defer allocator.free(low_id);
    _ = try move(allocator, low_id, .Todo);

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
    _ = try move(allocator, todo_a_id, .Todo);

    const todo_b_id = try add(allocator, "Todo B", "Medium priority todo", .B);
    defer allocator.free(todo_b_id);
    _ = try move(allocator, todo_b_id, .Todo);

    const doing_a_id = try add(allocator, "Doing A", "High priority doing", .A);
    defer allocator.free(doing_a_id);
    _ = try move(allocator, doing_a_id, .Doing);

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
