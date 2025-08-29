const std = @import("std");
const show_mod = @import("../show.zig");
pub const CTicket = @import("../ticket.zig").CTicket;
const ErrorCode = @import("../error.zig").ErrorCode;
const helper = @import("helper.zig");

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

pub fn tix_show_title(id: [*:0]const u8, output: *[*c]u8) c_int {
    const allocator = std.heap.c_allocator;
    const id_slice = std.mem.span(id);

    const title = show_mod.showTitle(allocator, id_slice) catch |err| {
        return @intFromEnum(ErrorCode.fromError(err));
    };
    errdefer allocator.free(title);

    const c_title = allocator.dupeZ(u8, title) catch {
        allocator.free(title);
        return @intFromEnum(ErrorCode.OUT_OF_MEMORY);
    };
    allocator.free(title);

    output.* = c_title.ptr;
    return 0;
}

pub fn tix_show_title_free(str: [*c]u8) void {
    helper.free_string(str);
}

pub fn tix_show_body(id: [*:0]const u8, output: *[*c]u8) c_int {
    const allocator = std.heap.c_allocator;
    const id_slice = std.mem.span(id);

    const body = show_mod.showBody(allocator, id_slice) catch |err| {
        return @intFromEnum(ErrorCode.fromError(err));
    };
    errdefer allocator.free(body);

    const c_body = allocator.dupeZ(u8, body) catch {
        allocator.free(body);
        return @intFromEnum(ErrorCode.OUT_OF_MEMORY);
    };
    allocator.free(body);

    output.* = c_body.ptr;
    return 0;
}

pub fn tix_show_body_free(str: [*c]u8) void {
    helper.free_string(str);
}

pub fn tix_show_status(id: [*:0]const u8) c_int {
    const id_slice = std.mem.span(id);

    const status = show_mod.showStatus(id_slice) catch |err| {
        return @intFromEnum(ErrorCode.fromError(err));
    };

    return @intFromEnum(status);
}

pub fn tix_show_priority(id: [*:0]const u8) c_int {
    const id_slice = std.mem.span(id);

    const priority = show_mod.showPriority(id_slice) catch |err| {
        return @intFromEnum(ErrorCode.fromError(err));
    };

    return @intFromEnum(priority);
}
