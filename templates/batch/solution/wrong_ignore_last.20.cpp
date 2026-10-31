#include <iostream>

int main() {
  int n;
  std::cin >> n;
  long long sum = 0;
  for (int i = 0; i < n; ++i) {
    long long value;
    std::cin >> value;
    if (i + 1 < n) {
      sum += value;
    }
  }
  std::cout << sum << '\n';
}
