#include <iostream>
#include <numeric>
#include <vector>

int main() {
  int n;
  std::cin >> n;
  std::vector<long long> a(n);
  for (auto &value : a) {
    std::cin >> value;
  }
  std::cout << std::accumulate(a.begin(), a.end(), 0LL) << '\n';
}
