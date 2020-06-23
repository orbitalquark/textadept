#include "foo.h"

void bar() {
  printf("bar\n");
}

int main(int argc, char **argv) {
  foo(FOO);
  bar();
  return 0;
}
