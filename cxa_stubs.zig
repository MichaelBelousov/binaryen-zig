const std = @import("std");
const builtin = @import("builtin");

const call_conv: std.builtin.CallingConvention = switch (builtin.target.cpu.arch) {
    .wasm32, .wasm64 => .{ .wasm_mvp = .{} },
    else => .c,
};

// https://refspecs.linuxfoundation.org/abi-eh-1.22.html#cxx-throw
//
fn __cxa_allocate_exception(_thrown_size: usize) callconv(call_conv) ?*anyopaque {
    _ = _thrown_size;
    @panic("__cxa_allocate_exception");
}

const StdCppTypeInfo = opaque {};

// should be: fn (?*anyopaque) void
const Destructor = opaque {};

fn __cxa_throw(_thrown: ?*anyopaque, _type_info: ?*StdCppTypeInfo, _destructor: ?*Destructor) callconv(call_conv) void {
    _ = _thrown;
    _ = _type_info;
    _ = _destructor;
    @panic("__cxa_throw");
}

comptime {
    // FIXME: these aren't being exported for some reason currently?
    if (builtin.cpu.arch.isWasm()) {
        @export(&__cxa_throw, .{ .name = "__cxa_throw" });
        @export(&__cxa_allocate_exception, .{ .name = "__cxa_allocate_exception" });
    }
}
