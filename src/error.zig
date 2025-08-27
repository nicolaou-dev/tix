const std = @import("std");

/// C-compatible error codes
pub const ErrorCode = enum(c_int) {
    // General errors (common across modules)
    OUT_OF_MEMORY = -1,
    NOT_A_REPOSITORY = -2,
    COMMAND_FAILED = -3,
    FILE_SYSTEM_ERROR = -4,
    INVALID_TICKET_ID = -5,
    UNKNOWN_ERROR = -99,

    // Init-specific errors
    INIT_WORKSPACE_CREATION_FAILED = -10,
    INIT_ACCESS_DENIED = -11,

    // Config-specific errors
    CONFIG_INVALID_KEY = -20,

    // Remote-specific errors
    REMOTE_ALREADY_EXISTS = -30,
    REMOTE_INVALID_NAME = -31,

    // Switch-specific errors
    SWITCH_PROJECT_NOT_FOUND = -40,
    SWITCH_PROJECT_ALREADY_EXISTS = -41,
    SWITCH_ALREADY_ON_PROJECT = -42,

    // Add-specific errors
    INVALID_PRIORITY = -50,
    INVALID_TITLE = -51,

    // Move-specific errors
    INVALID_STATUS = -60,

    pub fn fromError(err: anyerror) ErrorCode {
        return switch (err) {
            // General errors (used across modules)
            error.OutOfMemory => .OUT_OF_MEMORY,
            error.NotARepository => .NOT_A_REPOSITORY,
            error.CommandFailed => .COMMAND_FAILED,
            error.FileSystemError => .FILE_SYSTEM_ERROR,
            error.InvalidTicketID => .INVALID_TICKET_ID,

            // Init-specific
            error.InitWorkspaceCreationFailed => .INIT_WORKSPACE_CREATION_FAILED,
            error.InitAccessDenied => .INIT_ACCESS_DENIED,

            // Config-specific
            error.ConfigKeyNotFound, error.KeyNotFound => .CONFIG_INVALID_KEY,

            // Remote-specific
            error.RemoteAlreadyExists => .REMOTE_ALREADY_EXISTS,
            error.InvalidRemoteName => .REMOTE_INVALID_NAME,

            // Switch-specific
            error.ProjectNotFound => .SWITCH_PROJECT_NOT_FOUND,
            error.ProjectAlreadyExists => .SWITCH_PROJECT_ALREADY_EXISTS,
            error.AlreadyOnProject => .SWITCH_ALREADY_ON_PROJECT,

            // Add-specific
            error.InvalidPriority => .INVALID_PRIORITY,
            error.InvalidTitle => .INVALID_TITLE,

            // Move-specific
            error.InvalidStatus => .INVALID_STATUS,

            else => .UNKNOWN_ERROR,
        };
    }
};
