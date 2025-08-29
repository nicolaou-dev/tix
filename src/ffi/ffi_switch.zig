const std = @import("std");
const switch_mod = @import("../switch.zig");
const ErrorCode = @import("../error.zig").ErrorCode;

/// Switches to the specified project. If `create` is non-zero, creates the project if it doesn't exist.
pub export fn tix_switch_project(project: [*:0]const u8, create: c_int) c_int {
    const allocator = std.heap.c_allocator;

    // Convert C string to Zig slice
    const project_slice = std.mem.span(project);

    // Convert c_int to bool
    const should_create = create != 0;

    const switch_result = switch_mod.switchProject(allocator, project_slice, should_create) catch |err| {
        return @intFromEnum(ErrorCode.fromError(err));
    };

    return switch (switch_result) {
        .switched => 0,
        .created => 1,
    };
}
