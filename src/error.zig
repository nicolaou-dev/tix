const std = @import("std");

/// C-compatible error codes
pub const ErrorCode = enum(c_int) {
    // General errors
    OUT_OF_MEMORY = -1,
    UNKNOWN_ERROR = -99,

    // Init errors
    INIT_WORKSPACE_CREATION_FAILED = -10,
    INIT_ACCESS_DENIED = -11,

    // Config errors
    CONFIG_KEY_NOT_FOUND = -20,

    // Remote errors
    REMOTE_ALREADY_EXISTS = -30,
    REMOTE_INVALID_NAME = -31,
    REMOTE_NOT_A_REPOSITORY = -32,
    REMOTE_FAILED = -33,

    // Switch errors
    SWITCH_PROJECT_NOT_FOUND = -40,
    SWITCH_PROJECT_ALREADY_EXISTS = -41,
    SWITCH_ALREADY_ON_PROJECT = -42,
    SWITCH_FAILED = -43,

    pub fn fromError(err: anyerror) ErrorCode {
        return switch (err) {
            // General
            error.OutOfMemory => .OUT_OF_MEMORY,

            // Init
            error.InitWorkspaceCreationFailed => .INIT_WORKSPACE_CREATION_FAILED,
            error.InitAccessDenied => .INIT_ACCESS_DENIED,

            // Config
            error.ConfigKeyNotFound => .CONFIG_KEY_NOT_FOUND,

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
