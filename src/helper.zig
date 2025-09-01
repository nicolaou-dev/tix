const std = @import("std");

pub fn addTixToGitIgnore(allocator: std.mem.Allocator) !void {
    const gitignore_path = ".gitignore";

    if (std.fs.cwd().access(gitignore_path, .{})) |_| {} else |_| {
        const file = try std.fs.cwd().createFile(gitignore_path, .{});
        file.close();
    }

    const contents = try std.fs.cwd().readFileAlloc(allocator, gitignore_path, 1024 * 1024);
    defer allocator.free(contents);

    if (std.mem.indexOf(u8, contents, ".tix") != null) return;

    const file = try std.fs.cwd().openFile(gitignore_path, .{ .mode = .write_only });
    defer file.close();
    try file.seekFromEnd(0);

    if (contents.len > 0 and contents[contents.len - 1] != '\n') {
        try file.writeAll("\n");
    }

    try file.writeAll(".tix\n");
}