
#include "ece2400-stdlib.h"
#include <stdio.h>
#include <stdlib.h>

int avg(int x, int y) {
  int sum = x + y;
  return sum / 2;
}

void test_case_1_basic() {
  printf("\n%s\n", __func__);
  ECE2400_CHECK_INT_EQ(avg(10, 20), 15);
}

int main(int argc, char* argv[]) {
  __n = (argc == 1) ? 0 : atoi(argv[1]);

  if ((__n <= 0) || (__n == 1))
    test_case_1_basic();

  printf("\n");
  return __failed;
}
