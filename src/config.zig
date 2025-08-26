const std = @import("std");
const git = @import("git.zig");

pub const ConfigError = error{
    NotARepository,
    CommandFailed,
    KeyNotFound,
};

pub fn configSetKey(
    allocator: std.mem.Allocator,
    key: []const u8,
    value: []const u8,
) ConfigError!void {
    _ = git.config(allocator, key, value) catch |err| {
        switch (err) {
            error.NotARepository => return ConfigError.NotARepository,
            error.ConfigKeyNotFound => return ConfigError.KeyNotFound,
            else => return ConfigError.CommandFailed,
        }
    };
}

pub fn configGetKey(
    allocator: std.mem.Allocator,
    key: []const u8,
) ConfigError![]const u8 {
    const value = git.config(allocator, key, null) catch |err| {
        switch (err) {
            error.NotARepository => return ConfigError.NotARepository,
            error.ConfigKeyNotFound => return ConfigError.KeyNotFound,
            else => return ConfigError.CommandFailed,
        }
    };

    return value;
}

test "configSetKey and configGetKey" {
    const init = @import("init.zig").init;
    const test_helper = @import("test_helper.zig");
    const allocator = std.testing.allocator;

    // Setup isolated test directory
    const original = try test_helper.setupTestDir(allocator, "config_test");
    defer test_helper.cleanupTestDir("config_test", original);

    // Create .tix directory
    try std.fs.cwd().makeDir(".tix");

    const not_a_repo = configGetKey(allocator, "user.name");
    try std.testing.expectError(ConfigError.NotARepository, not_a_repo);

    const set_not_a_repo = configSetKey(allocator, "user.name", "Test User");
    try std.testing.expectError(ConfigError.NotARepository, set_not_a_repo);

    _ = try init(allocator);

    const invalid_get_key = configGetKey(allocator, "invalid@key");
    try std.testing.expectError(ConfigError.KeyNotFound, invalid_get_key);

    const not_found_key = configGetKey(allocator, "not.found");
    try std.testing.expectError(ConfigError.CommandFailed, not_found_key);

    const invalid_set_key = configSetKey(allocator, "invalid@key", "value");
    try std.testing.expectError(ConfigError.KeyNotFound, invalid_set_key);

    try configSetKey(allocator, "user.name", "Test User");

    const name = try configGetKey(allocator, "user.name");
    defer allocator.free(name);
    try std.testing.expect(std.mem.eql(u8, std.mem.trim(u8, name, "\n"), "Test User"));
}
