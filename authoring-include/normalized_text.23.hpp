#pragma once

#include <cstddef>
#include <string>

#include "cplib.hpp"

namespace contest_template {

// Match Hydro's non-strict default checker (compareSh / process_file).
// Source:
// https://github.com/hydro-dev/Hydro/blob/master/packages/hydrojudge/src/checkers.ts
// Strip trailing CRs, per-line trailing space/tab/CR, and final empty lines.
// Leading/internal whitespace and line breaks remain significant. A
// whitespace-only line is NOT an empty line in Hydro's AWK pipeline, even at
// the end of the file.
inline auto read_normalized_text(cplib::var::Reader &in,
                                 bool fold_ascii_case = false) -> std::string {
  std::string normalized;
  std::size_t pending_empty_lines = 0;
  while (auto line = in.inner().read_line()) {
    while (!line->empty() && line->back() == '\r') line->pop_back();
    if (line->empty()) {
      ++pending_empty_lines;
      continue;
    }
    normalized.append(pending_empty_lines, '\n');
    pending_empty_lines = 0;
    while (!line->empty() && (line->back() == ' ' || line->back() == '\t' ||
                              line->back() == '\r')) {
      line->pop_back();
    }
    if (fold_ascii_case) {
      for (char &c : *line)
        if (c >= 'a' && c <= 'z') c -= 'a' - 'A';
    }
    normalized += *line;
    normalized += '\n';
  }
  return normalized;
}

}  // namespace contest_template
