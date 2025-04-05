#include <iostream>

#include "wasm.h"
#include "binaryen-c.h"

using namespace wasm;

extern "C" bool _binaryenCloneFunction(Module* from, Module* to, char const* fromName, char const* toName) {
  auto fromFunc = from->getFunction(fromName);
  // FIXME: leaks!
  Function* copy = new Function;
  *copy = *fromFunc;
  copy->setExplicitName(toName);
  to->addFunction(copy);
  return true;
}

// can't print to stdout during zig tests
extern "C" void _BinaryenExpressionPrintStderr(BinaryenExpressionRef expr) {
  std::cerr << *(Expression*)expr << '\n';
}

// can't print to stdout during zig tests
extern "C" void _BinaryenModulePrintStderr(BinaryenModuleRef module) {
  std::cerr << *(Module*)module << '\n';
}
