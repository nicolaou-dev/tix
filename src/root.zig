const std = @import("std");

// Import FFI modules
const ffi_init = @import("ffi/ffi_init.zig");
const ffi_config = @import("ffi/ffi_config.zig");
const ffi_remote = @import("ffi/ffi_remote.zig");
const ffi_switch = @import("ffi/ffi_switch.zig");
const ffi_add = @import("ffi/ffi_add.zig");
const ffi_move = @import("ffi/ffi_move.zig");
const ffi_list = @import("ffi/ffi_list.zig");
const ffi_show = @import("ffi/ffi_show.zig");
const ffi_amend = @import("ffi/ffi_amend.zig");

// Export all FFI functions for C
pub export fn tix_init() c_int {
    return ffi_init.tix_init();
}

pub export fn tix_config_set(key: [*:0]const u8, value: [*:0]const u8) c_int {
    return ffi_config.tix_config_set(key, value);
}

pub export fn tix_config_get(key: [*:0]const u8, output: *[*c]u8) c_int {
    return ffi_config.tix_config_get(key, output);
}

pub export fn tix_config_get_free(str: [*c]u8) void {
    ffi_config.tix_config_get_free(str);
}

pub export fn tix_remote(verbose: c_int, output: *[*c]u8) c_int {
    return ffi_remote.tix_remote(verbose, output);
}

pub export fn tix_remote_free(str: [*c]u8) void {
    ffi_remote.tix_remote_free(str);
}

pub export fn tix_remote_add(name: [*:0]const u8, url: [*:0]const u8) c_int {
    return ffi_remote.tix_remote_add(name, url);
}

pub export fn tix_switch_project(project: [*:0]const u8, create: c_int) c_int {
    return ffi_switch.tix_switch_project(project, create);
}

pub export fn tix_add(title: [*:0]const u8, body: [*:0]const u8, priority: u8, output: *[*c]u8) c_int {
    return ffi_add.tix_add(title, body, priority, output);
}

pub export fn tix_add_free(str: [*c]u8) void {
    ffi_add.tix_add_free(str);
}

pub export fn tix_move(ticket_id: [*:0]const u8, status: u8) c_int {
    return ffi_move.tix_move(ticket_id, status);
}

pub export fn tix_list(statuses: [*c]const u8, priorities: [*c]const u8, output: *[*c]ffi_list.CTicket, count: *usize) c_int {
    return ffi_list.tix_list(statuses, priorities, output, count);
}

pub export fn tix_list_free(tickets: [*c]ffi_list.CTicket, count: usize) void {
    ffi_list.tix_list_free(tickets, count);
}

pub export fn tix_show(id: [*:0]const u8, output: *[*c]ffi_show.CTicket) c_int {
    return ffi_show.tix_show(id, output);
}

pub export fn tix_show_free(ticket: ?*ffi_show.CTicket) void {
    ffi_show.tix_show_free(ticket);
}

pub export fn tix_show_title(id: [*:0]const u8, output: *[*c]u8) c_int {
    return ffi_show.tix_show_title(id, output);
}

pub export fn tix_show_title_free(str: [*c]u8) void {
    ffi_show.tix_show_title_free(str);
}

pub export fn tix_show_body(id: [*:0]const u8, output: *[*c]u8) c_int {
    return ffi_show.tix_show_body(id, output);
}

pub export fn tix_show_body_free(str: [*c]u8) void {
    ffi_show.tix_show_body_free(str);
}

pub export fn tix_show_status(id: [*:0]const u8) c_int {
    return ffi_show.tix_show_status(id);
}

pub export fn tix_show_priority(id: [*:0]const u8) c_int {
    return ffi_show.tix_show_priority(id);
}

pub export fn tix_amend(ticket_id: [*:0]const u8, title: [*:0]const u8, body: [*:0]const u8, priority: u8) c_int {
    return ffi_amend.tix_amend(ticket_id, title, body, priority);
}
