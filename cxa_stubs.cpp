// C++ ABI and libcxx stubs for WebAssembly
// These are needed when linking but not using full exception/iostream support

#include <cstddef>
#include <cstdlib>

extern "C" {

// Allocate exception object
void* __cxa_allocate_exception(size_t thrown_size) {
    // In a real implementation, this would allocate memory for the exception
    // For now, we just abort since we don't expect exceptions to be thrown
    (void)thrown_size;
    std::abort();
    return nullptr;
}

// Throw exception
void __cxa_throw(void* thrown, void* type_info, void (*destructor)(void*)) {
    // In a real implementation, this would initiate exception handling
    // For now, we just abort since we don't support exception throwing
    (void)thrown;
    (void)type_info;
    (void)destructor;
    std::abort();
}

} // extern "C"

// Stub implementations for std::basic_filebuf and related iostream classes
// These are no-op stubs since file I/O isn't supported in this WASM context

namespace std {
inline namespace __1 {

// Forward declarations
template<typename CharT, typename Traits> class basic_filebuf;
template<typename CharT, typename Traits> class basic_string;
template<typename T> class allocator;
class char_traits;

// Stub for basic_filebuf constructor
template<typename CharT, typename Traits>
void basic_filebuf_construct_stub() {
    // No-op stub
}

// Stub for basic_filebuf destructor
template<typename CharT, typename Traits>
void basic_filebuf_destruct_stub() {
    // No-op stub
}

// Export the stubs with the mangled names that the linker expects
extern "C" {

// basic_filebuf::basic_filebuf()
int _ZNSt3__113basic_filebufIcNS_11char_traitsIcEEEC1Ev(int this_ptr) {
    (void)this_ptr;
    basic_filebuf_construct_stub<char, char_traits>();
    return this_ptr;
}

// basic_filebuf::~basic_filebuf()
int _ZNSt3__113basic_filebufIcNS_11char_traitsIcEEED1Ev(int this_ptr) {
    (void)this_ptr;
    basic_filebuf_destruct_stub<char, char_traits>();
    return this_ptr;
}

// basic_filebuf::open(char const*, unsigned int)
void* _ZNSt3__113basic_filebufIcNS_11char_traitsIcEEE4openEPKcj(void* /* this */, const char* /* filename */, unsigned int /* mode */) {
    return nullptr; // Return null to indicate failure
}

// basic_filebuf::close()
void* _ZNSt3__113basic_filebufIcNS_11char_traitsIcEEE5closeEv(void* /* this */) {
    return nullptr;
}

// basic_ifstream::open(basic_string const&, unsigned int)
void _ZNSt3__114basic_ifstreamIcNS_11char_traitsIcEEE4openERKNS_12basic_stringIcS2_NS_9allocatorIcEEEEj(
    void* /* this */, const void* /* string */, unsigned int /* mode */) {
    // No-op
}

// basic_ofstream::open(basic_string const&, unsigned int)
void _ZNSt3__114basic_ofstreamIcNS_11char_traitsIcEEE4openERKNS_12basic_stringIcS2_NS_9allocatorIcEEEEj(
    void* /* this */, const void* /* string */, unsigned int /* mode */) {
    // No-op
}

} // extern "C"

} // namespace __1
} // namespace std

// Provide vtable and VTT stubs as weak symbols
// These will be used if the real symbols aren't available
extern "C" {

// vtable for std::__1::basic_ifstream<char, std::__1::char_traits<char>>
__attribute__((weak))
void* _ZTVNSt3__114basic_ifstreamIcNS_11char_traitsIcEEEE[16] = {nullptr};

// VTT for std::__1::basic_ifstream
__attribute__((weak))
void* _ZTTNSt3__114basic_ifstreamIcNS_11char_traitsIcEEEE[8] = {nullptr};

// vtable for std::__1::basic_ofstream<char, std::__1::char_traits<char>>
__attribute__((weak))
void* _ZTVNSt3__114basic_ofstreamIcNS_11char_traitsIcEEEE[16] = {nullptr};

// VTT for std::__1::basic_ofstream
__attribute__((weak))
void* _ZTTNSt3__114basic_ofstreamIcNS_11char_traitsIcEEEE[8] = {nullptr};

}
