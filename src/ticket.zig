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

    pub fn read(allocator: std.mem.Allocator, dir: std.fs.Dir, id: []const u8, status: Status, priority: Priority) TicketError!Ticket {
        var ticket_dir = dir.openDir(id, .{}) catch return TicketError.FileSystemError;
        defer ticket_dir.close();

        // read title.md contents and body.md contents
        const title = ticket_dir.readFileAlloc(allocator, "title.md", 1024) catch return TicketError.FileSystemError;
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
        return CTicket{
            .id = c_id.ptr,
            .title = c_title.ptr,
            .priority = @intFromEnum(self.priority),
            .status = @intFromEnum(self.status),
        };
    }

    pub fn deinit(self: *Ticket, allocator: std.mem.Allocator) void {
        allocator.free(self.id);
        allocator.free(self.title);
    }
};

pub const CTicket = extern struct {
    id: [*:0]const u8,
    title: [*:0]const u8,
    priority: u8,
    status: u8,

    pub fn deinit(self: *CTicket, allocator: std.mem.Allocator) void {
        allocator.free(self.id);
        allocator.free(self.title);
    }
};
