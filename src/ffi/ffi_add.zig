const std = @import("std");
const helper = @import("helper.zig");
const add_mod = @import("../add.zig");
const Priority = @import("../priority.zig").Priority;
const ErrorCode = @import("../error.zig").ErrorCode;

/// Adds a new ticket with the given title, body, and priority.
/// Priority: 'a', 'b', 'c', 'z', or 0 for default (z)
pub export fn tix_add(
    title: [*:0]const u8,
    body: [*:0]const u8,
    priority: u8,
    output: *[*c]u8,
) c_int {
    const allocator = std.heap.c_allocator;

    const title_slice = std.mem.span(title);
    const body_slice = std.mem.span(body);

    // Parse priority: 0 means use default (null), otherwise parse the character
    const priority_enum = if (priority == 0) .Z else std.meta.intToEnum(Priority, priority) catch {
        return @intFromEnum(ErrorCode.INVALID_PRIORITY);
    };

    const result = add_mod.add(allocator, title_slice, body_slice, priority_enum) catch |err| return @intFromEnum(ErrorCode.fromError(err));
    defer allocator.free(result);

    const c_str = allocator.dupeZ(u8, result) catch
        return @intFromEnum(ErrorCode.OUT_OF_MEMORY);

    output.* = c_str.ptr;
    return 0;
}

pub export fn tix_add_free(str: [*c]u8) void {
    helper.free_string(str);
}
