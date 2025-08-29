const std = @import("std");
const amend_mod = @import("../amend.zig");
const ErrorCode = @import("../error.zig").ErrorCode;
const Status = @import("../status.zig").Status;
const Priority = @import("../priority.zig").Priority;
const ticket = @import("../ticket.zig");

pub fn tix_amend(ticket_id: [*:0]const u8, title: [*:0]const u8, body: [*:0]const u8, priority: u8) c_int {
    const ticket_id_slice = std.mem.span(ticket_id);

    const allocator = std.heap.c_allocator;

    const title_slice = std.mem.span(title);
    const body_slice = std.mem.span(body);

    // Convert empty strings to null for optional parameters
    const title_opt = if (title_slice.len == 0) null else title_slice;
    const body_opt = if (body_slice.len == 0) null else body_slice;

    // Convert u8 to optional enum (0 means no change)
    const priority_opt = if (priority == 0) null else std.meta.intToEnum(Priority, priority) catch {
        return @intFromEnum(ErrorCode.INVALID_PRIORITY);
    };

    amend_mod.amend(allocator, ticket_id_slice, title_opt, body_opt, priority_opt) catch |err| {
        return @intFromEnum(ErrorCode.fromError(err));
    };

    return 0;
}
