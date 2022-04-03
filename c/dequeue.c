#include "dequeue.h"
#include <stdlib.h>


/**
 * @brief create a new dequeue node
 *
 * @param data data to be stored in the node
 * @return dequeue node
 */
static dequeue_node_t *new_dequeue_node(void *data) {
  dequeue_node_t *node;
  node       = malloc(sizeof(*node));
  node->data = data;
  node->next = NULL;
  node->prev = NULL;
  return node;
}

/**
 * @brief create a new dequeue
 *
 * @return new dequeue
 */
dequeue_t *new_dequeue() {
  dequeue_t *q;
  q = malloc(sizeof(*q));
  q->head = NULL;
  q->tail = NULL;
  return q;
}

/**
 * @brief clear the elements
 *
 * @param q pointer to the dequeue
 */
void clear_dequeue(dequeue_t *q) {
  if (q == NULL) {
    return;
  }

  while (q->head != NULL) {
    pop_left(q);
  }
}

/**
 * @brief destroy all nodes of the dequeue and the dequeue itself
 *
 * @param q pointer to the dequeue
 */
void destroy_dequeue(dequeue_t *q) {
  if (q == NULL) {
    return;
  }

  while (q->head != NULL) {
    pop_left(q);
  }

  free(q);
}

/**
 * @brief push the element to the left side
 *
 * @param q pointer to dequeue
 * @param data
 */
void push_left(dequeue_t *q, void *data) {
  if (q == NULL) {
    return;
  }

  dequeue_node_t *node = new_dequeue_node(data);

  if (q->head == NULL) {
    q->head = node;
    q->tail = node;
  } else {
    node->next    = q->head;
    q->head->prev = node;
    q->head       = node;
  }
}

/**
 * @brief push the element to the right side
 *
 * @param q pointer to dequeue
 * @param data
 */
void push_right(dequeue_t *q, void *data) {
  if (q == NULL) {
    return;
  }

  dequeue_node_t *node = new_dequeue_node(data);

  if (q->tail == NULL) {
    q->head = node;
    q->tail = node;
  } else {
    node->prev    = q->tail;
    q->tail->next = node;
    q->tail       = node;
  }
}

/**
 * @brief pop the left element
 *
 * @param q pointer to dequeue
 * @return data of deleted node
 */
void *pop_left(dequeue_t *q) {
  if (q == NULL || q->head == NULL) {
    return NULL;
  }

  dequeue_node_t *node = q->head;
  void           *data = node->data;
  q->head              = node->next;

  if (q->head == NULL) {
    q->tail = NULL;
  } else {
    q->head->prev = NULL;
  }

  free(node);
  return data;
}

/**
 * @brief pop the right element
 *
 * @param q pointer to dequeue
 * @return data of deleted node
 */
void *pop_right(dequeue_t *q) {
  if (q == NULL || q->tail == NULL) {
    return NULL;
  }

  dequeue_node_t *node = q->tail;
  void           *data = node->data;
  q->tail              = node->prev;

  if (q->tail == NULL) {
    q->head = NULL;
  } else {
    q->tail->next = NULL;
  }

  free(node);
  return data;
}
