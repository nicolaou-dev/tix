const std = @import("std");
const show_mod = @import("../show.zig");
pub const CTicket = @import("../ticket.zig").CTicket;
const ErrorCode = @import("../error.zig").ErrorCode;

pub fn tix_show(id: [*:0]const u8, output: *[*c]CTicket) c_int {
    const allocator = std.heap.c_allocator;

    const id_slice = std.mem.span(id);

    var ticket = show_mod.show(allocator, id_slice) catch |err| {
        return @intFromEnum(ErrorCode.fromError(err));
    };
    defer ticket.deinit(allocator);

    const c_ticket = ticket.toCTicket(allocator) catch return @intFromEnum(ErrorCode.OUT_OF_MEMORY);
    errdefer c_ticket.deinit(allocator);

    const ptr = allocator.create(CTicket) catch return @intFromEnum(ErrorCode.OUT_OF_MEMORY);

    ptr.* = c_ticket;

    output.* = ptr;

    return 0;
}

pub fn tix_show_free(ticket: ?*CTicket) void {
    const t = ticket orelse return;
    const allocator = std.heap.c_allocator;
    t.deinit(allocator);
    allocator.destroy(t);
}
