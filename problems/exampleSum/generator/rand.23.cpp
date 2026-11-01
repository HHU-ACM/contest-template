#include <print>
#include <string>

#include "cplib.hpp"
#include "problem.23.hpp"

CPLIB_REGISTER_GENERATOR(gen, args, n = Var<cplib::var::i32>("n", 1, kMaxN),
                         bound = Var<cplib::var::i32>("bound", 0, kMaxValue),
                         mode = Var<cplib::var::String>("mode"),
                         salt = Var<cplib::var::String>("salt"));

void generator_main() {
  int n = args::n, bound = args::bound;
  std::string mode = args::mode;
  if (mode != "random" && mode != "max") {
    cplib::panic("Unknown mode");
  }
  std::println("{}", n);
  for (int i = 0; i < n; ++i) {
    int value = mode == "max" ? bound : gen.rnd.next(-bound, bound);
    std::print("{}{}", i == 0 ? "" : " ", value);
  }
  std::println("");
  gen.quit_ok();
}
