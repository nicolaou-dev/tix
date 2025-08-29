const std = @import("std");
const Status = @import("status.zig").Status;
const Priority = @import("priority.zig").Priority;

pub const TicketError = error{
    FileSystemError,
};

pub const Ticket = struct {
    id: []const u8,
    title: []const u8,
    status: Status,
    priority: Priority,
    body: []const u8 = "",

    pub fn read(allocator: std.mem.Allocator, dir: std.fs.Dir, id: []const u8, status: Status, priority: Priority) TicketError!Ticket {
        var ticket_dir = dir.openDir(id, .{}) catch return TicketError.FileSystemError;
        defer ticket_dir.close();

        // read title.md contents
        const title = getTitle(ticket_dir, allocator) catch return TicketError.FileSystemError;

        const duplicated_id = allocator.dupe(u8, id) catch {
            allocator.free(title);
            return TicketError.FileSystemError;
        };
        const ticket = Ticket{
            .id = duplicated_id,
            .title = title,
            .status = status,
            .priority = priority,
        };

        return ticket;
    }

    pub fn toCTicket(self: *const Ticket, allocator: std.mem.Allocator) TicketError!CTicket {
        const c_id = allocator.dupeZ(u8, self.id) catch return TicketError.FileSystemError;
        const c_title = allocator.dupeZ(u8, self.title) catch {
            allocator.free(c_id);
            return TicketError.FileSystemError;
        };
        const c_body = allocator.dupeZ(u8, self.body) catch {
            allocator.free(c_id);
            allocator.free(c_title);
            return TicketError.FileSystemError;
        };
        return CTicket{
            .id = c_id.ptr,
            .title = c_title.ptr,
            .body = c_body.ptr,
            .priority = @intFromEnum(self.priority),
            .status = @intFromEnum(self.status),
        };
    }

    pub fn deinit(self: *const Ticket, allocator: std.mem.Allocator) void {
        allocator.free(self.id);
        allocator.free(self.title);
        if (self.body.len > 0) allocator.free(self.body);
    }
};

pub fn getStatus(
    dir: std.fs.Dir,
) !Status {
    for (std.enums.values(Status)) |s| {
        const status = s.toString();
        dir.access(status, .{}) catch continue;
        return s;
    }
    return TicketError.FileSystemError;
}

pub fn getPriority(
    dir: std.fs.Dir,
) !Priority {
    for (std.enums.values(Priority)) |p| {
        const priority = p.toString();
        dir.access(priority, .{}) catch continue;
        return p;
    }
    return TicketError.FileSystemError;
}

pub fn getTitle(
    dir: std.fs.Dir,
    allocator: std.mem.Allocator,
) ![]const u8 {
    const title = dir.readFileAlloc(allocator, "title.md", 1024) catch return TicketError.FileSystemError;
    errdefer allocator.free(title);
    return title;
}

pub fn getBody(
    dir: std.fs.Dir,
    allocator: std.mem.Allocator,
) ![]const u8 {
    const body = dir.readFileAlloc(allocator, "body.md", 4096) catch return TicketError.FileSystemError;
    errdefer allocator.free(body);
    return body;
}

pub const CTicket = extern struct {
    id: [*:0]const u8,
    title: [*:0]const u8,
    body: [*:0]const u8,
    priority: u8,
    status: u8,

    pub fn deinit(self: *const CTicket, allocator: std.mem.Allocator) void {
        allocator.free(std.mem.span(self.id));
        allocator.free(std.mem.span(self.title));
        allocator.free(std.mem.span(self.body));
    }
};
