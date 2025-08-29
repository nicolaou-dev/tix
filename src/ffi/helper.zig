const std = @import("std");

pub fn free_string(str: [*c]u8) void {
    if (str == null) return;
    const allocator = std.heap.c_allocator;
    const slice = std.mem.span(str);
    allocator.free(slice);
}
