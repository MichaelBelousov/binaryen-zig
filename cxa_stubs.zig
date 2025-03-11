// https://refspecs.linuxfoundation.org/abi-eh-1.22.html#cxx-throw
//
export fn __cxa_allocate_exception(_thrown_size: usize) ?*anyopaque {
    _ = _thrown_size;
    @panic("__cxa_allocate_exception");
}

const StdCppTypeInfo = opaque {};

// should be: fn (?*anyopaque) void
const Destructor = opaque {};

export fn __cxa_throw(_thrown: ?*anyopaque, _type_info: ?*StdCppTypeInfo, _destructor: ?*Destructor) void {
    _ = _thrown;
    _ = _type_info;
    _ = _destructor;
    @panic("__cxa_throw");
}
