const std = @import("std");
const helper = @import("helper.zig");
const config = @import("../config.zig");
const ErrorCode = @import("../error.zig").ErrorCode;

pub export fn tix_config_set(key: [*:0]const u8, value: [*:0]const u8) c_int {
    const allocator = std.heap.c_allocator;

    const key_slice = std.mem.span(key);
    const value_slice = std.mem.span(value);

    config.configSetKey(allocator, key_slice, value_slice) catch |err| {
        return @intFromEnum(ErrorCode.fromError(err));
    };

    return 0;
}

pub export fn tix_config_get(key: [*:0]const u8, output: *[*c]u8) c_int {
    const allocator = std.heap.c_allocator;

    const key_slice = std.mem.span(key);

    const value = config.configGetKey(allocator, key_slice) catch |err| {
        return @intFromEnum(ErrorCode.fromError(err));
    };
    defer allocator.free(value);

    const out = allocator.dupeZ(u8, value) catch {
        return @intFromEnum(ErrorCode.OUT_OF_MEMORY);
    };

    output.* = out.ptr;

    return 0;
}

pub export fn tix_config_get_free(str: [*c]u8) void {
    helper.free_string(str);
}
