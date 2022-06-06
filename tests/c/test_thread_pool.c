#include "test.h"
#include <assert.h>
#include <thread_pool.h>
#include <stdio.h>
#include <stdlib.h>

void worker(void *arg) {
  int *val = arg;
  *val = 1;
}

int main() {
  thread_pool_t *tp = thread_pool_create(4);
  int vals[100];
  for (int i = 0; i < 100; ++i) {
    vals[i] = 0;
  }
  for (int i = 0; i < 100; ++i) {
    thread_pool_add_work(tp, worker, vals + i);
  }
  thread_pool_wait(tp);
  for (int i = 0; i < 100; ++i) {
    if (vals[i] != 1) {
      thread_pool_destroy(tp);
      exit(1);
    }
  }
  thread_pool_destroy(tp);
  return 0;
}
