const std = @import("std");
const move_mod = @import("../move.zig");
const Status = @import("../status.zig").Status;
const ErrorCode = @import("../error.zig").ErrorCode;

pub export fn tix_move(ticket_id: [*:0]const u8, status: u8) c_int {
    const ticket_id_slice = std.mem.span(ticket_id);

    const status_enum = std.meta.intToEnum(Status, status) catch {
        return @intFromEnum(ErrorCode.INVALID_STATUS);
    };

    const result = move_mod.move(ticket_id_slice, status_enum) catch |err| {
        return @intFromEnum(ErrorCode.fromError(err));
    };

    return result;
}
