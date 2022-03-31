#include "thread_pool.h"
#include <stddef.h>
#include <stdbool.h>
#include <stdlib.h>
#include "thread.h"

struct thread_pool_work {
  thread_func_t            func;
  void                    *arg;
  struct thread_pool_work *next;
};
typedef struct thread_pool_work thread_pool_work_t;

struct thread_pool {
  thread_pool_work_t *work_first;   /* queue head */
  thread_pool_work_t *work_last;    /* queue tail */
  pthread_mutex_t     work_mutex;   /* all locking */
  pthread_cond_t      work_cond;    /* signal the threads that there is work to processed */
  pthread_cond_t      working_cond; /* signal when there are no threads processing */
  size_t              working_cnt;  /* number of active work */
  size_t              thread_cnt;   /* number of alive threads */
  bool                stop;         /* whether to stop the threads */
};

/* create a new work */
static thread_pool_work_t *thread_pool_work_create(thread_func_t func, void *arg) {
  thread_pool_work_t *work;

  if (func == NULL) {
    return NULL;
  }

  work       = malloc(sizeof(*work));
  work->func = func;
  work->arg  = arg;
  work->next = NULL;
  return work;
}

/* destroy the work */
static void thread_pool_work_destroy(thread_pool_work_t *work) {
  if (work == NULL) {
    return;
  }
  free(work);
}

/* get a work from the head of the queue */
static thread_pool_work_t *thread_pool_work_get(thread_pool_t *tp) {
  thread_pool_work_t *work;

  if (tp == NULL) {
    return NULL;
  }

  work = tp->work_first;
  if (work == NULL) {
    return NULL;
  }

  if (work->next == NULL) {
    tp->work_first = NULL;
    tp->work_last  = NULL;
  } else {
    tp->work_first = work->next;
  }

  return work;
}

static void *thread_pool_worker(void *arg) {
  thread_pool_t      *tp = arg;
  thread_pool_work_t *work;

  while (1) {
    pthread_mutex_lock(&(tp->work_mutex));

    while (!tp->stop && tp->work_first == NULL) {
      pthread_cond_wait(&(tp->work_cond), &(tp->work_mutex));
    }

    if (tp->stop) {
      break;
    }

    work = thread_pool_work_get(tp);
    tp->working_cnt++;
    pthread_mutex_unlock(&(tp->work_mutex));

    if (work != NULL) {
      work->func(work->arg);
      thread_pool_work_destroy(work);
    }

    pthread_mutex_lock(&(tp->work_mutex));
    tp->working_cnt--;
    if (!tp->stop && tp->working_cnt == 0 && tp->work_first == NULL) {
      pthread_cond_signal(&(tp->working_cond));
    }
    pthread_mutex_unlock(&(tp->work_mutex));
  }

  tp->thread_cnt--;
  pthread_cond_signal(&(tp->working_cond));
  pthread_mutex_unlock(&(tp->work_mutex));
  return NULL;
}

thread_pool_t *thread_pool_create(size_t num) {
  thread_pool_t *tp;
  pthread_t      thread;
  size_t         i;

  if (num == 0) {
    num = pcthread_get_num_procs() + 1;
  }

  tp = calloc(1, sizeof(*tp));
  tp->thread_cnt = num;

  pthread_mutex_init(&(tp->work_mutex), NULL);
  pthread_cond_init(&(tp->work_cond), NULL);
  pthread_cond_init(&(tp->working_cond), NULL);

  tp->work_first = NULL;
  tp->work_last  = NULL;

  for (i = 0; i < num; i++) {
    pthread_create(&thread, NULL, thread_pool_worker, tp);
    pthread_detach(thread);
  }

  return tp;
}

void thread_pool_destroy(thread_pool_t *tp) {
  if (tp == NULL) {
    return;
  }

  thread_pool_work_t *work;
  thread_pool_work_t *work2;

  pthread_mutex_lock(&(tp->work_mutex));
  work = tp->work_first;
  while (work != NULL) {
    work2 = work->next;
    thread_pool_work_destroy(work);
    work = work2;
  }
  tp->stop = true;
  pthread_cond_broadcast(&(tp->work_cond));
  pthread_mutex_unlock(&(tp->work_mutex));

  thread_pool_wait(tp);

  pthread_mutex_destroy(&(tp->work_mutex));
  pthread_cond_destroy(&(tp->work_cond));
  pthread_cond_destroy(&(tp->working_cond));

  free(tp);
}

bool thread_pool_add_work(thread_pool_t *tp, thread_func_t func, void *arg) {
  if (tp == NULL) {
    return false;
  }

  thread_pool_work_t *work;
  work = thread_pool_work_create(func, arg);
  if (work == NULL) {
    return false;
  }

  pthread_mutex_lock(&(tp->work_mutex));
  if (tp->work_first == NULL) {
    tp->work_first = work;
    tp->work_last  = work;
  } else {
    tp->work_last->next = work;
    tp->work_last       = work;
  }

  pthread_cond_broadcast(&(tp->work_cond));
  pthread_mutex_unlock(&(tp->work_mutex));

  return true;
}

void thread_pool_add_work_loop(thread_pool_t *tp, thread_func_t func, void *arg) {
  while (!thread_pool_add_work(tp, func, arg));
}

/* wait until all work done or all thread exited */
void thread_pool_wait(thread_pool_t *tp) {
  if (tp == NULL) {
    return;
  }

  pthread_mutex_lock(&(tp->work_mutex));
  while (1) {
    if ((!tp->stop && tp->working_cnt != 0) || (tp->stop && tp->thread_cnt != 0)) {
      pthread_cond_wait(&(tp->working_cond), &(tp->work_mutex));
    } else {
      break;
    }
  }
  pthread_mutex_unlock(&(tp->work_mutex));
}
