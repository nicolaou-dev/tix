const std = @import("std");

/// C-compatible error codes
pub const ErrorCode = enum(c_int) {
    INIT_WORKSPACE_CREATION_FAILED = -1,
    INIT_ACCESS_DENIED = -2,
    SWITCH_PROJECT_NOT_FOUND = -3,
    SWITCH_PROJECT_ALREADY_EXISTS = -4,
    SWITCH_ALREADY_ON_PROJECT = -5,
    SWITCH_FAILED = -6,
    UNKNOWN_ERROR = -99,

    pub fn fromError(err: anyerror) ErrorCode {
        return switch (err) {
            error.InitWorkspaceCreationFailed => .INIT_WORKSPACE_CREATION_FAILED,
            error.InitAccessDenied => .INIT_ACCESS_DENIED,
            error.ProjectNotFound => .SWITCH_PROJECT_NOT_FOUND,
            error.ProjectAlreadyExists => .SWITCH_PROJECT_ALREADY_EXISTS,
            error.AlreadyOnProject => .SWITCH_ALREADY_ON_PROJECT,
            error.SwitchFailed => .SWITCH_FAILED,
            else => .UNKNOWN_ERROR,
        };
    }
};
