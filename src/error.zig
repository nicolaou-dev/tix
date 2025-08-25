const std = @import("std");

/// C-compatible error codes
pub const ErrorCode = enum(c_int) {
    // General errors
    OUT_OF_MEMORY = -1,
    UNKNOWN_ERROR = -99,

    // Init errors
    INIT_WORKSPACE_CREATION_FAILED = -10,
    INIT_ACCESS_DENIED = -11,

    // Remote errors
    REMOTE_ALREADY_EXISTS = -20,
    REMOTE_INVALID_NAME = -21,
    REMOTE_NOT_A_REPOSITORY = -22,
    REMOTE_FAILED = -23,

    // Switch errors
    SWITCH_PROJECT_NOT_FOUND = -30,
    SWITCH_PROJECT_ALREADY_EXISTS = -31,
    SWITCH_ALREADY_ON_PROJECT = -32,
    SWITCH_FAILED = -33,

    pub fn fromError(err: anyerror) ErrorCode {
        return switch (err) {
            // General
            error.OutOfMemory => .OUT_OF_MEMORY,

            // Init
            error.InitWorkspaceCreationFailed => .INIT_WORKSPACE_CREATION_FAILED,
            error.InitAccessDenied => .INIT_ACCESS_DENIED,

            // Remote
            error.RemoteAlreadyExists => .REMOTE_ALREADY_EXISTS,
            error.InvalidRemoteName => .REMOTE_INVALID_NAME,
            error.NotARepository => .REMOTE_NOT_A_REPOSITORY,
            error.RemoteFailed, error.RemoteAddFailed => .REMOTE_FAILED,

            // Switch
            error.ProjectNotFound => .SWITCH_PROJECT_NOT_FOUND,
            error.ProjectAlreadyExists => .SWITCH_PROJECT_ALREADY_EXISTS,
            error.AlreadyOnProject => .SWITCH_ALREADY_ON_PROJECT,
            error.SwitchFailed => .SWITCH_FAILED,

            else => .UNKNOWN_ERROR,
        };
    }
};
