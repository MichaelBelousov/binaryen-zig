// Stub implementations of file.h functions for WebAssembly
// File I/O is not supported in WASM, so these functions either abort or return failure

#include "support/file.h"
#include "support/utilities.h"
#include <iostream>

namespace wasm {

// read_stdin still works since it uses cin
// (implementation from original file.cpp)
std::vector<char> read_stdin() {
  std::vector<char> input;
  char c;
  while (std::cin.get(c) && !std::cin.eof()) {
    input.push_back(c);
  }
  return input;
}

// File reading not supported - abort if called
template<typename T>
T read_file(const std::string& filename, Flags::BinaryOption binary) {
  (void)filename;
  (void)binary;
  Fatal() << "File I/O not supported in WebAssembly build";
  return T(); // unreachable
}

// Explicit instantiations
template std::string read_file<>(const std::string&, Flags::BinaryOption);
template std::vector<char> read_file<>(const std::string&, Flags::BinaryOption);

std::string read_possible_response_file(const std::string& input) {
  if (input.size() == 0 || input[0] != '@') {
    return input;
  }
  Fatal() << "Response files not supported in WebAssembly build";
  return ""; // unreachable
}

// Output class that only supports stdout
Output::Output(const std::string& filename, Flags::BinaryOption binary)
  : out(std::cout.rdbuf()) {
  (void)binary;
  if (!filename.empty() && filename != "-") {
    Fatal() << "File output not supported in WebAssembly build: '" << filename << "'";
  }
}

void copy_file(std::string input, std::string output) {
  (void)input;
  (void)output;
  Fatal() << "File operations not supported in WebAssembly build";
}

size_t file_size(std::string filename) {
  (void)filename;
  Fatal() << "File operations not supported in WebAssembly build";
  return 0; // unreachable
}

} // namespace wasm
