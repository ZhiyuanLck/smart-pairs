#ifndef DEQUEUE_H
#define DEQUEUE_H

typedef struct dequeue_node {
  struct dequeue_node *next;
  struct dequeue_node *prev;
  void                *data;
} dequeue_node_t;

typedef struct dequeue {
  dequeue_node_t *head;
  dequeue_node_t *tail;
} dequeue_t;

dequeue_t *new_dequeue();
void clear_dequeue(dequeue_t *q);
void destroy_dequeue(dequeue_t *q);
void push_left(dequeue_t *q, void *data);
void push_right(dequeue_t *q, void *data);
void *pop_left(dequeue_t *q);
void *pop_right(dequeue_t *q);

#endif /* DEQUEUE_H */
