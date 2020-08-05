#include <functional>
#include <iostream>
#include <string>

template <class T, bool (*PRED)(T const &)> struct validator : T {
  validator(T value) : T(value) {
    if (!PRED(value))
      throw "Invalid Value.";
  }
};

constexpr auto non_empty_string_validator = [](std::string const &s) {
  return s != "";
};
typedef validator<std::string, +non_empty_string_validator> non_empty_string;

int main() {
  non_empty_string str{"cats"};
  non_empty_string strtwo = str;
  std::cout << str << " also " << strtwo << std::endl;
  return 0;
}
