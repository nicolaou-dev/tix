const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const static_lib = b.addStaticLibrary(.{
        .name = "tix",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    static_lib.linkLibC();

    b.installArtifact(static_lib);
    
    // Install the header file
    b.installFile("tix.h", "include/tix.h");

    const tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    tests.linkLibC();

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);

    // Add a release step to build for all platforms
    const release_step = b.step("release", "Build releases for all platforms");
    
    const platforms = [_][]const u8{
        "aarch64-macos",
        "x86_64-macos", 
        "x86_64-linux",
        "x86_64-windows",
    };
    
    for (platforms) |platform| {
        const target_query = std.Target.Query.parse(.{
            .arch_os_abi = platform,
        }) catch unreachable;
        
        const resolved_target = b.resolveTargetQuery(target_query);
        
        const lib = b.addStaticLibrary(.{
            .name = "tix",
            .root_source_file = b.path("src/root.zig"),
            .target = resolved_target,
            .optimize = .ReleaseSafe,
        });
        lib.linkLibC();
        
        const install = b.addInstallArtifact(lib, .{
            .dest_dir = .{ .override = .{ .custom = platform } },
        });
        
        // Also install header file for each platform
        const install_header = b.addInstallFile(b.path("tix.h"), b.fmt("{s}/tix.h", .{platform}));
        
        release_step.dependOn(&install.step);
        release_step.dependOn(&install_header.step);
    }
}
