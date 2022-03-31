#ifndef TEST_H
#define TEST_H

#include "parser.h"
#include "dequeue.h"

context_t *new_context(const char **lines, size_t num_lines);
void destroy_context(context_t *ctx);
void to_string(dequeue_t *q, char *s, bool is_pair);
bool cmp_pos(dequeue_t *q, const char *s);
bool cmp_stack(dequeue_t *q, const char *s);
void show_line(const char *file, int lineno);

#endif /* TEST_H */
