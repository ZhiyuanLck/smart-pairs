#include "test.h"
#ifdef THREADS
#include "threads.h"
#endif /* THREADS */
#include <stdlib.h>
#include <stdio.h>

thread_pool_t *tp = NULL;

/* create a new pair struct for test */
static pair_t *new_pair(const char* left, const char *right, const char *trip_pair, int priority, bool triplet, bool cross_line, bool balanced) {
  pair_t *pair = malloc(sizeof(pair_t));
  pair->left       = left;
  pair->right      = right;
  pair->trip_pair  = trip_pair;
  pair->priority   = priority;
  pair->triplet    = triplet;
  pair->cross_line = cross_line;
  pair->balanced   = balanced;
  return pair;
}

/* create a new context for test */
context_t *new_context(const char **lines, size_t num_lines, size_t pair_idx) {
  context_t *ctx;

  pair_t **pairs = malloc(8 * sizeof(pair_t*));
  pairs[0] = new_pair("\"", "\"", "\"\"\"", 20, true,  false, true);
  pairs[1] = new_pair("'",  "'",  "'''",    20, true,  false, true);
  pairs[2] = new_pair("/*", "*/", NULL,     10, false, true,  false);
  pairs[3] = new_pair("//", NULL, NULL,     5,  false, false, false);
  pairs[4] = new_pair("(",  ")",  NULL,     0,  false, true,  false);
  pairs[5] = new_pair("[",  "]",  NULL,     0,  false, true,  false);
  pairs[6] = new_pair("{",  "}",  NULL,     0,  false, true,  false);
  pairs[7] = new_pair("$",  "$",  NULL,     0,  false, true,  true);

  ctx = malloc(sizeof(*ctx));
#ifdef THREADS
  tp = tp ? tp : thread_pool_create(5);
#endif /* THREADS */
  ctx->tp         = tp;
  ctx->ignore     = NULL;
  ctx->lines      = lines;
  ctx->pair       = pairs[pair_idx];
  ctx->pairs      = pairs;
  ctx->num_ignore = 0;
  ctx->num_lines  = num_lines;
  ctx->num_pairs  = 8;
  ctx->cur_line   = 0;
  ctx->cur_col    = 0;
  ctx->stop       = false;

  ctx->pairs = pairs;
  return ctx;
}

/* destroy the context */
void destroy_context(context_t *ctx) {
  for (int i = 0; i < ctx->num_pairs; i++) {
    free(ctx->pairs[i]);
  }
  free(ctx->pairs);
  free(ctx);
}

void destroy_tp() {
#ifdef THREADS
  thread_pool_destroy(tp);
#endif /* THREADS */
}

/**
 * @brief convert the dequeue to string by concat the pairs saved in the nodes
 *
 * @param q pointer to the dequeue
 * @param s where the result string is saved
 * @param is_pair whether is the pair list or dequeue node stack
 */
void to_string(dequeue_t *q, char *s, bool is_pair) {
  if (q == NULL) {
    *s = '\0';
    return;
  }
  dequeue_node_t *dn1;
  dequeue_node_t *dn2;
  pair_node_t    *pn;
  const char     *c;

  dn1 = q->head;
  while (dn1 != NULL) {
    if (is_pair) {
      pn = dn1->data;
    } else {
      dn2 = dn1->data;
      pn  = dn2->data;
    }
    c  = pn->is_trip ? pn->pair->trip_pair : (pn->is_left ? pn->pair->left : pn->pair->right);
    while (c != NULL && *c != '\0') {
      *s = *c;
      s++;
      c++;
    }
    dn1 = dn1->next;
  }
  *s = '\0';
}

/**
 * @brief show specific line of the source file
 *
 * @param file file name
 * @param lineno line index
 */
void show_line(const char *file, int lineno) {
  FILE *fp   = fopen(file, "r");
  int   line = 1;
  if (fp == NULL) {
    fprintf(stderr, "cannot open file %s\n", file);
  } else {
    char s[1000];
    while (fgets(s, 1000, fp) != NULL) {
      if (line == lineno) {
        fprintf(stderr, "%s\n", s);
        break;
      }
      ++line;
    }
  }
}
