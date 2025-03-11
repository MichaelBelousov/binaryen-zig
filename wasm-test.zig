const std = @import("std");
const binaryen = @import("binaryen");

pub fn main() !void {}

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
    const mod = binaryen.Module.parseText(src);
    defer mod.deinit();
    //const out = mod.emitText();
    const emitted = mod.emitBinary("./module.map");
    //defer binaryen.freeEmit(emitted.binary);
    //defer binaryen.freeEmit(emitted.sourceMap);
    return emitted.binary.ptr;
}
