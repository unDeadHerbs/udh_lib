// Bad C++ unique ptr hax
template <typename T> struct uni {
  // explicit uni(T* from) { this = (uni*)from; }
  uni(uni &) = delete;
  uni(uni &&rhs) {
    this = &rhs;
    &rhs = 0;
  }
  // T operator*() { return this; }
  T *operator->() { return (T *)this; }
  ~uni() { delete (T *)this; }
};
#define new_uni()

// I don't think this is possible because I can't assign to ~this~.
