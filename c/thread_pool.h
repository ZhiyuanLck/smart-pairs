#ifndef THREAD_POOL_H
#define THREAD_POOL_H

#include <stdbool.h>
#include <stddef.h>

struct thread_pool;
typedef struct thread_pool thread_pool_t;

typedef void (*thread_func_t)(void *arg);

thread_pool_t *thread_pool_create(size_t num);
void thread_pool_destroy(thread_pool_t *tp);

bool thread_pool_add_work(thread_pool_t *tp, thread_func_t func, void *arg);
void thread_pool_add_work_loop(thread_pool_t *tp, thread_func_t func, void *arg);
void thread_pool_wait(thread_pool_t *tp);

#endif /* THREAD_POOL_H */
