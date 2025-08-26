const std = @import("std");
const init = @import("init.zig").init;
const config = @import("config.zig");
const remote = @import("remote.zig");
const switch_mod = @import("switch.zig");
const add_mod = @import("add.zig");
const error_types = @import("error.zig");

// Import error code mapping
const ErrorCode = error_types.ErrorCode;

/// Initializes a new Tix workspace at the given path.
pub export fn tix_init() c_int {
    const allocator = std.heap.c_allocator;

    const init_result = init(allocator) catch |err| {
        return @intFromEnum(ErrorCode.fromError(err));
    };

    return switch (init_result) {
        .initialized => 0,
        .reinitialized => 1,
    };
}

pub export fn tix_config_set(key: [*:0]const u8, value: [*:0]const u8) c_int {
    const allocator = std.heap.c_allocator;

    // Convert C strings to Zig slices
    const key_slice = std.mem.span(key);
    const value_slice = std.mem.span(value);

    config.configSetKey(allocator, key_slice, value_slice) catch |err| {
        return @intFromEnum(ErrorCode.fromError(err));
    };

    return 0;
}

pub export fn tix_config_get(key: [*:0]const u8, output: *[*c]u8) c_int {
    const allocator = std.heap.c_allocator;

    // Convert C string to Zig slice
    const key_slice = std.mem.span(key);

    const value = config.configGetKey(allocator, key_slice) catch |err| {
        return @intFromEnum(ErrorCode.fromError(err));
    };

    // Convert to null-terminated C string
    const c_str = allocator.dupeZ(u8, value) catch {
        return @intFromEnum(ErrorCode.OUT_OF_MEMORY);
    };
    allocator.free(value);
    output.* = c_str.ptr;

    return 0;
}

/// Returns the remote name(s). If verbose is non-zero, includes URLs.
pub export fn tix_remote(output: *[*c]u8, verbose: c_int) c_int {
    const allocator = std.heap.c_allocator;

    const remote_result = remote.remote(allocator, verbose != 0) catch |err| {
        return @intFromEnum(ErrorCode.fromError(err));
    };

    // Convert to null-terminated C string
    const c_str = allocator.dupeZ(u8, remote_result) catch {
        allocator.free(remote_result);
        return @intFromEnum(ErrorCode.OUT_OF_MEMORY);
    };
    allocator.free(remote_result);

    output.* = c_str.ptr;
    return 0;
}

/// Adds a new remote with the specified name and URL.
pub export fn tix_remote_add(name: [*:0]const u8, url: [*:0]const u8) c_int {
    const allocator = std.heap.c_allocator;

    // Convert C strings to Zig slices
    const name_slice = std.mem.span(name);
    const url_slice = std.mem.span(url);

    remote.remoteAdd(allocator, name_slice, url_slice) catch |err| {
        return @intFromEnum(ErrorCode.fromError(err));
    };

    return 0;
}

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

/// Adds a new ticket with the given title, body, and priority.
/// Priority: 'a', 'b', 'c', 'z', or 0 for default (z)
pub export fn tix_add(
    title: [*:0]const u8,
    body: [*:0]const u8,
    priority: u8,
    output: *[*c]u8,
) c_int {
    const allocator = std.heap.c_allocator;

    // Convert C strings to Zig slices
    const title_slice = std.mem.span(title);
    const body_slice = std.mem.span(body);

    // Parse priority: 0 means use default (null), otherwise parse the character
    const priority_enum = if (priority == 0)
        add_mod.Priority.Z
    else switch (priority) {
        'a', 'A' => add_mod.Priority.A,
        'b', 'B' => add_mod.Priority.B,
        'c', 'C' => add_mod.Priority.C,
        'z', 'Z' => add_mod.Priority.Z,
        else => return @intFromEnum(ErrorCode.INVALID_PRIORITY),
    };

    const result = add_mod.add(allocator, title_slice, body_slice, priority_enum) catch |err| {
        return @intFromEnum(ErrorCode.fromError(err));
    };

    const c_str = allocator.dupeZ(u8, result) catch {
        allocator.free(result);
        return @intFromEnum(ErrorCode.OUT_OF_MEMORY);
    };
    allocator.free(result);

    output.* = c_str.ptr;
    return 0;
}
