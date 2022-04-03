#include "msg.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>

msg_queue_t *msgq = NULL;

/**
 * @brief add a message to the queue
 *
 * @param file source file name
 * @param lineno line index of the source file
 * @param format message
 */
void add_msg(const char *file, int lineno, const char* format, ...) {
  int     l1;
  int     l2;
  va_list args;
  char   *msg;

  file = trunc_file(file);
  l1 = snprintf(NULL, 0, "%s:%d: ", file, lineno);

  va_start(args, format);
  l2 = vsnprintf(NULL, 0, format, args);
  va_end(args);

  msg = malloc((l1 + l2 + 1) * sizeof(char));
  sprintf(msg, "%s:%d: ", file, lineno);

  va_start(args, format);
  vsprintf(msg + l1, format, args);
  va_end(args);

  msg_node_t *node = malloc(sizeof(msg_node_t));
  node->next = NULL;
  node->msg  = msg;
  /* show message in time */
  // fprintf(stdout, "%s", msg);

  if (msgq == NULL) {
    msgq       = malloc(sizeof(*msgq));
    msgq->head = NULL;
    msgq->tail = NULL;
  }

  if (msgq->tail == NULL) {
    msgq->head = node;
    msgq->tail = node;
  } else {
    msgq->tail->next = node;
    msgq->tail       = node;
  }
}

static char *pop_msg() {
  if (msgq == NULL || msgq->head == NULL) {
    return NULL;
  }

  msg_node_t *node = msgq->head;
  char       *msg  = node->msg;
  msgq->head       = node->next;

  if (msgq->head == NULL) {
    msgq->tail = NULL;
  }

  free(node);
  return msg;
}

void clear_msg() {
  if (msgq == NULL) {
    return;
  }

  while (msgq->head != NULL) {
    free(pop_msg());
  }
}

void destroy_msg() {
  clear_msg();
  free(msgq);
}

void show_msg() {
  if (msgq == NULL) {
    return;
  }

  while (msgq->head != NULL) {
    char *msg = pop_msg();
    fprintf(stderr, "%s", msg);
    free(msg);
  }
}

/**
 * @brief get truncated file name
 *
 * @param file file name
 * @return name
 */
const char* trunc_file(const char* file) {
  const char* cur = file;
  while (*cur != '\0') {
    cur++;
  }
  while (cur != file && *cur != '/') {
    cur--;
  }
  return cur + 1;
}
