const std = @import("std");
const list = @import("../list.zig");
pub const CTicket = @import("../ticket.zig").CTicket;
const Priority = @import("../priority.zig").Priority;
const Status = @import("../status.zig").Status;
const ErrorCode = @import("../error.zig").ErrorCode;

pub fn tix_list(
    statuses: [*c]const u8,
    priorities: [*c]const u8,
    output: *[*c]CTicket,
    count: *usize,
) c_int {
    const allocator = std.heap.c_allocator;

    // Handle nullable C strings
    const status_slice = if (statuses) |s| std.mem.span(s) else "";
    const priority_slice = if (priorities) |p| std.mem.span(p) else "";

    var s_buffer: [4]Status = undefined;
    const status_filter = Status.fromSlice(status_slice, &s_buffer) catch |err| {
        return @intFromEnum(ErrorCode.fromError(err));
    };

    var p_buffer: [4]Priority = undefined;
    const priority_filter = Priority.fromSlice(priority_slice, &p_buffer) catch |err| {
        return @intFromEnum(ErrorCode.fromError(err));
    };

    const result = list.list(allocator, .{
        .statuses = if (status_filter.len == 0) null else status_filter,
        .priorities = if (priority_filter.len == 0) null else priority_filter,
    }) catch |err| {
        return @intFromEnum(ErrorCode.fromError(err));
    };

    defer {
        for (result) |*ticket| ticket.deinit(allocator);
        allocator.free(result);
    }

    if (result.len == 0) {
        output.* = null;
        count.* = 0;
        return 0;
    }

    const out = allocator.alloc(CTicket, result.len) catch return @intFromEnum(ErrorCode.OUT_OF_MEMORY);
    errdefer {
        for (out) |*ct| ct.deinit(allocator);
        allocator.free(out);
    }

    for (result, 0..) |ticket, i| {
        out[i] = ticket.toCTicket(allocator) catch {
            return @intFromEnum(ErrorCode.OUT_OF_MEMORY);
        };
    }

    output.* = out.ptr;
    count.* = result.len;

    return 0;
}

pub fn tix_list_free(tickets: [*c]CTicket, count: usize) void {
    if (tickets == null) return;
    const allocator = std.heap.c_allocator;
    const slice = tickets[0..count];
    for (slice) |*ticket| ticket.deinit(allocator);
    allocator.free(slice);
}
