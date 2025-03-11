pub usingnamespace @import("./cxa_stubs.zig");
// FIXME: if I need this, add it to the build as an import
export const _wasm_intrinsics_wat = @embedFile("binaryen-wat-intrinsics").*;
