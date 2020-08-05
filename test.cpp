#include <iostream>

#include "uni.hpp"

using std::cout;
using std::endl;

struct lifecycle {
  lifecycle() { cout << "created\n"; }
  lifecycle(lifecycle &) { cout << "copied\n"; }
  lifecycle(lifecycle &&) { cout << "moved\n"; }
  ~lifecycle() { cout << "destroyed\n"; }
  void thing() { cout << "used\n"; }
};

void foo1(lifecycle l) {
  cout << "enter foo1\n";
  l.thing();
  cout << "leaving foo1\n";
}

void example1() {
  cout << "start e1\n";
  lifecycle l;
  cout << "in e1\n";
  foo1(l);
  cout << "leaving e1\n";
}

void foo2(lifecycle *l) {
  cout << "enter foo2\n";
  l->thing();
  cout << "leaving foo2\n";
}

void example2() {
  cout << "start e2\n";
  lifecycle *l = new lifecycle;
  cout << "in e2\n";
  foo2(l);
  cout << "leaving e2\n";
  delete l;
}

void foo3(uni<lifecycle> l) {
  cout << "enter foo3\n";
  l->thing();
  cout << "leaving foo3\n";
}

void example3() {
  cout << "start e3\n";
  uni l(new lifecycle);
  cout << "in e3\n";
  foo3(std::move(l));
  cout << "leaving e3\n";
}

int main() {
  example1();
  cout << "\n\nseperator\n\n";
  example2();
  cout << "\n\nseperator\n\n";
  example3();
}
