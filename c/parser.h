#ifndef PARSER_H
#define PARSER_H

#include "thread_pool.h"
#include "dequeue.h"
#include <stddef.h>
#include <stdbool.h>

#ifdef TEST
#include <stdio.h>
#include "msg.h"
#define show(...) add_msg(__FILE__, __LINE__, true, __VA_ARGS__)
#define nshow(...) add_msg(__FILE__, __LINE__, false, __VA_ARGS__)
#else
#define show(...)
#define nshow(...)
#endif /* TEST */


typedef struct pair {
  const char *left;       /* left pair */
  const char *right;      /* right pair, may be NULL */
  const char *trip_pair;  /* triplet pair */
  int         priority;   /* priority of the parsing order */
  bool        triplet;    /* whether the triplet pair is defined */
  bool        cross_line; /* whether the pairs can cross lines */
  bool        balanced;   /* whether the left pair is equal to the right pairs */
} pair_t;

typedef struct context {
  thread_pool_t *tp;         /* thread pool */

  pair_t        *pair;       /* pair to be searched */
  const char   **ignore;     /* ignore patterns */
  const char   **lines;      /* lines to be parsed */
  pair_t       **pairs;      /* pairs to be parsed */
  size_t         num_ignore; /* number of ignore patterns */
  size_t         num_lines;  /* number of lines */
  size_t         num_pairs;  /* number of pairs */

  size_t         cur_line;   /* line index of current cursor */
  size_t         cur_col;    /* column index of current cursor */

  unsigned char  status;     /* 0 for no extra pairs, 1 for extra left pair, 2 for extra right pair */

  bool           only_find;  /* stop after left and/or right pair are found */
  bool           find_left;  /* whether to locate the left pair */
  bool           has_findl;  /* whether has found the left pair */
  size_t         lline;      /* line index of the left pair */
  size_t         lcol;       /* column index of the left pair */
  bool           find_right; /* whether to locate the right pair */
  bool           has_findr;  /* whether has found the right pair */
  size_t         rline;      /* line index of the left pair */
  size_t         rcol;       /* column index of the left pair */

  bool           stop;       /* whether to stop the parse process */
} context_t;

typedef struct pair_node {
  pair_t *pair;     /* pair definition */
  bool    on_left;  /* whether the pair is on the left of the cursor */
  bool    is_left;  /* left or right one */
  bool    is_trip;  /* whether is the triplet pair */
  size_t  line_idx; /* line index of current pair */
  size_t  col_idx;  /* column index of current pair */
} pair_node_t;

typedef dequeue_t      pairs_dqueue; /* dequeue whose nodes store the pair nodes */
typedef dequeue_node_t pairs_dnode;  /* dequeue node that stores the pair node */
typedef dequeue_t      nodes_dqueue; /* dequeue whose nodes store the pairs_dnode */
typedef dequeue_node_t nodes_dnode;  /* dequeue node that stores the pairs_dnode */

typedef struct line_node {
  pairs_dqueue *pairs; /* list of pair nodes */
  nodes_dqueue *cache; /* store the parsing result of pairs */
  bool          done;  /* whether all the prepare work of the current line is done */
} line_node_t;

typedef struct parse_arg {
  context_t    *ctx;   /* current context */
  line_node_t  *lines; /* array of line nodes */
  nodes_dqueue *res;   /* parsing result */
  size_t        start; /* start of the range of lines, [start, end) */
  size_t        end;   /* end of the range of lines [start, end) */
} parse_arg_t;

#ifdef TEST
parse_arg_t *
#else
void
#endif
parse(context_t *ctx);

#endif /* PARSER_H */
