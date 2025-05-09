const std = @import("std");
const binaryen = @import("binaryen");

pub fn main() !void {
    // std.debug.print("{} ?= {}\n", .{ @intFromEnum(binaryen.Type.stringref), binaryen.c.BinaryenTypeStringref() });
    // if (binaryen.Type.stringref != @as(binaryen.Type, @enumFromInt(binaryen.c.BinaryenTypeStringref()))) {
    //     std.debug.panic("{} != {}\n", .{ @intFromEnum(binaryen.Type.stringref), binaryen.c.BinaryenTypeStringref() });
    // }
}

export var length_transfer_buf: usize = 0;

pub export fn run() [*]u8 {
    const src =
        \\(module
        \\ (type $i32_i32_=>_i32 (func (param i32 i32) (result i32)))
        \\ (type $i32_=>_i32 (func (param i32) (result i32)))
        \\ (export "add" (func $add))
        \\ (export "add2" (func $add2))
        \\ (func $add (param $0 i32) (param $1 i32) (result i32)
        \\  (i32.add
        \\   (local.get $0)
        \\   (local.get $1)
        \\  )
        \\ )
        \\ (func $add2 (param $0 i32) (result i32)
        \\  (call $add
        \\   (local.get $0)
        \\   (i32.const 2)
        \\  )
        \\ )
        \\)
        \\
    ;
    // wtf: why does it exit in most cases...
    //std.debug.print("about to parse...\n", .{});
    const mod = binaryen.Module.parseText(src);
    //std.debug.print("parsed!\n", .{});
    defer mod.deinit();
    //const out = mod.emitText();
    //std.debug.print("going to emit...\n", .{});
    //const emitted = mod.emitBinary("./module.map");
    const emitted = mod.emitBinary(null);
    //std.debug.print("emitted!\n", .{});
    //defer binaryen.freeEmit(emitted.binary);
    //defer binaryen.freeEmit(emitted.sourceMap);
    length_transfer_buf = emitted.binary.len;
    return emitted.binary.ptr;
}
