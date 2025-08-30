const std = @import("std");
const helper = @import("helper.zig");
const projects_mod = @import("../projects.zig");
const ErrorCode = @import("../error.zig").ErrorCode;

pub fn tix_projects(output: *[*c][*c]u8, count: *usize) c_int {
    const allocator = std.heap.c_allocator;

    const result = projects_mod.projects(allocator) catch |err| {
        return @intFromEnum(ErrorCode.fromError(err));
    };
    defer {
        for (result) |branch| allocator.free(branch);
        allocator.free(result);
    }

    // Allocate array of C strings
    const c_strings = allocator.alloc([*c]u8, result.len) catch {
        return @intFromEnum(ErrorCode.OUT_OF_MEMORY);
    };

    // Convert each branch name to C string
    for (result, 0..) |branch, i| {
        const c_str = allocator.dupeZ(u8, branch) catch {
            // Free already allocated strings
            for (c_strings[0..i]) |str| {
                helper.free_string(str);
            }
            allocator.free(c_strings);
            return @intFromEnum(ErrorCode.OUT_OF_MEMORY);
        };
        c_strings[i] = c_str.ptr;
    }

    output.* = c_strings.ptr;
    count.* = result.len;
    return 0;
}

pub fn tix_projects_free(branches: [*c][*c]u8, count: usize) void {
    const allocator = std.heap.c_allocator;
    if (branches != null) {
        for (0..count) |i| {
            helper.free_string(branches[i]);
        }
        const slice = branches[0..count];
        allocator.free(slice);
    }
}
