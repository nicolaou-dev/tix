const std = @import("std");

/// C-compatible error codes
pub const ErrorCode = enum(c_int) {
    INIT_WORKSPACE_CREATION_FAILED = -1,
    INIT_ACCESS_DENIED = -2,
    UNKNOWN_ERROR = -99,

    pub fn fromError(err: anyerror) ErrorCode {
        return switch (err) {
            error.InitWorkspaceCreationFailed => .INIT_WORKSPACE_CREATION_FAILED,
            error.InitAccessDenied => .INIT_ACCESS_DENIED,
            else => .UNKNOWN_ERROR,
        };
    }
};
