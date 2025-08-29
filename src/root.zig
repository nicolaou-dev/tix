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

// Re-export all FFI functions
pub const tix_init = ffi_init.tix_init;

pub const tix_config_get = ffi_config.tix_config_get;
pub const tix_config_set = ffi_config.tix_config_set;
pub const tix_config_get_free = ffi_config.tix_config_get_free;

pub const tix_remote = ffi_remote.tix_remote;
pub const tix_remote_free = ffi_remote.tix_remote_free;

pub const tix_switch = ffi_switch.tix_switch;

pub const tix_add = ffi_add.tix_add;
pub const tix_add_free = ffi_add.tix_add_free;

pub const tix_move = ffi_move.tix_move;

pub const tix_list = ffi_list.tix_list;
pub const tix_list_free = ffi_list.tix_list_free;

pub const tix_show = ffi_show.tix_show;
pub const tix_show_free = ffi_show.tix_show_free;