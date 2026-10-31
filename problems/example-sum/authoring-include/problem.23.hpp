#pragma once
#include <string>
#include <vector>

#include "cplib.hpp"
#include "normalized_text.23.hpp"

inline constexpr int kMaxN = 1000;
inline constexpr int kMaxValue = 1000000000;

struct Input {
  static auto read(cplib::var::Reader &in) -> Input {
    int n = in.read(cplib::var::i32("n", 1, kMaxN));
    in.read(cplib::var::eoln);
    for (int i = 0; i < n; ++i) {
      if (i != 0) {
        in.read(cplib::var::space);
      }
      in.read(cplib::var::i32("a", -kMaxValue, kMaxValue));
    }
    in.read(cplib::var::eoln);
    return {};
  }
};

struct Output {
  std::string normalized;
  static auto read(cplib::var::Reader &in, const Input &) -> Output {
    return {contest_template::read_normalized_text(in)};
  }
  static auto evaluate(cplib::evaluate::Evaluator &ev, const Output &pans,
                       const Output &jans, const Input &)
      -> cplib::evaluate::Result {
    return ev.eq("normalized_output", pans.normalized, jans.normalized);
  }
};

inline auto traits(const Input &) -> std::vector<cplib::validator::Trait> {
  return {};
}
