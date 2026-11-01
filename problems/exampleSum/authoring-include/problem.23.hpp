#pragma once
#include <cstdint>
#include <vector>

#include "cplib.hpp"

inline constexpr int kMaxN = 1000;
inline constexpr int kMaxValue = 1000000000;
inline constexpr std::int64_t kMaxSum = std::int64_t{kMaxN} * kMaxValue;

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
  std::int64_t sum;
  static auto read(cplib::var::Reader &in, const Input &) -> Output {
    return {in.read(cplib::var::i64("sum", -kMaxSum, kMaxSum))};
  }
  static auto evaluate(cplib::evaluate::Evaluator &ev, const Output &pans,
                       const Output &jans, const Input &)
      -> cplib::evaluate::Result {
    return ev.eq("sum", pans.sum, jans.sum);
  }
};

inline auto traits(const Input &) -> std::vector<cplib::validator::Trait> {
  return {};
}
