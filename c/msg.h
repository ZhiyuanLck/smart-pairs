#ifndef MSG_QUEUE_H
#define MSG_QUEUE_H
#include <stdbool.h>

typedef struct msg_node {
  struct msg_node *next;
  char            *msg;
} msg_node_t;

typedef struct msg_queue {
  msg_node_t *head;
  msg_node_t *tail;
} msg_queue_t;

/* extern msg_queue_t *msgq; */

void add_msg(const char *file, int lineno, bool verbose, const char* format, ...);
void destroy_msg();
void clear_msg();
void show_msg();
const char* trunc_file(const char* file);

#endif /* MSG_QUEUE_H */
