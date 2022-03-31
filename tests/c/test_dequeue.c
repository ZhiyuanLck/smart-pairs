#include "dequeue.h"
#include <stdlib.h>
#include <assert.h>

int main() {
  int l[5] = {1, 2, 3, 4, 5};
  int *x;
  dequeue_t *q = new_dequeue();
  assert(q->head == NULL);
  assert(q->tail == NULL);

  push_left(q, l);
  assert(q->head->prev == NULL);
  assert(q->head->data == (void*)l);
  assert(q->tail->data == (void*)l);
  assert(q->tail->next == NULL);

  push_right(q, l + 1);
  assert(q->head->prev == NULL);
  assert(q->head->next == q->tail);
  assert(q->head->data == (void*)l);
  assert(q->tail->data == (void*)(l + 1));
  assert(q->tail->prev == q->head);
  assert(q->tail->next == NULL);

  x = pop_left(q);
  assert(x == l);
  assert(q->head->prev == NULL);
  assert(q->head->data == (void*)(l + 1));
  assert(q->tail->data == (void*)(l + 1));
  assert(q->tail->next == NULL);

  x = pop_right(q);
  assert(x == l + 1);
  assert(q->head == NULL);
  assert(q->tail == NULL);

  x = pop_right(q);
  assert(x == NULL);
  assert(q->head == NULL);
  assert(q->tail == NULL);

  destroy_dequeue(q);
}
