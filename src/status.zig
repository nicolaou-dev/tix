pub const Status = enum {
    Backlog,
    Todo,
    Doing,
    Done,

    pub fn fromString(s: u8) ?Status {
        return switch (s) {
            'b' => .Backlog,
            't' => .Todo,
            'w' => .Doing,
            'd' => .Done,
            else => null,
        };
    }

    pub fn toString(self: Status) []const u8 {
        return switch (self) {
            .Backlog => "s=b",
            .Todo => "s=t",
            .Doing => "s=w",
            .Done => "s=d",
        };
    }
};
