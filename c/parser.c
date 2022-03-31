#include "parser.h"
#include <stdlib.h>
#include <stdio.h>

#ifdef TEST
static const char *get_pair(pair_node_t *pn) {
  return pn->is_trip ? pn->pair->trip_pair : (pn->is_left ? pn->pair->left : pn->pair->right);
}
#endif

/**
 * @brief create a list of line nodes according to the number of lines
 *
 * @param num: number of the lines
 * @return list of line nodes
 */
static line_node_t *new_lines(size_t num) {
  if (num == 0) {
    return NULL;
  }

  line_node_t *lines;
  lines = malloc(num * sizeof(*lines));

  for (int i = 0; i < num; i++) {
    lines[i].pairs = new_dequeue();
    lines[i].cache = new_dequeue();
    lines[i].done  = false;
  }

  return lines;
}

/**
 * @brief destroy all line nodes
 *
 * @param lines: array of line nodes
 * @param num: number of lines
 */
static void destroy_lines(line_node_t *lines, int num) {
  if (lines == NULL) {
    return;
  }

  dequeue_node_t *qn;
  dequeue_t *q;

  for (int i = 0; i < num; i++) {
    q = lines[i].pairs;
    while (q->head != NULL) {
      free((pair_node_t*)pop_left(q));
    }
    free(q);
    destroy_dequeue(lines[i].cache);
  }

  free(lines);
}

/**
 * @brief create the arguments struct
 *
 * @param ctx context
 * @param start start of the line index
 * @param end end of the line index
 * @return arguments
 */
static parse_arg_t *new_arg(context_t *ctx, size_t start, size_t end) {
  parse_arg_t *arg;
  arg        = malloc(sizeof(*arg));
  arg->lines = new_lines(ctx->num_lines);
  arg->ctx   = ctx;
  arg->start = start;
  arg->end   = end;
  return arg;
}

/**
 * @brief destroy the arguments
 *
 * @param arg argumnets
 */
static void destroy_arg(parse_arg_t *arg) {
  destroy_lines(arg->lines, arg->ctx->num_lines);
  free(arg);
}

/**
 * @brief remove single pair whose scope is the line scope
 *
 * @param q pointer to the dequeue
 */
static void remove_single_pair(dequeue_t *q) {
  if (q == NULL) {
    return;
  }

  dequeue_node_t *dn;
  pair_node_t    *pn;

  while (q->tail != NULL) {
    dn = q->tail->data;
    pn = dn->data;
    if (!pn->is_left || pn->pair->right != NULL) {
      break;
    }
    pop_right(q);
  }
}

/**
 * @brief parse the pair
 *
 * @param q dequeue of pair nodes
 * @param pn pair node to be parsed
 * @return true if need to judge more otherwise false
 */
static bool parse_pair_next(dequeue_t *q, dequeue_node_t *dn) {
  if (q->tail == NULL) {
    push_right(q, dn);
    show("empty stack\n");
    return false;
  }

  pair_node_t    *pn  = dn->data;
  dequeue_node_t *tmp = q->tail->data;
  pair_node_t    *top = tmp->data;

  /* first, do not handle balanced pairs now */
  if (top->pair->balanced || pn->pair->balanced) {
    show("ignore balanced pair\n");
    push_right(q, dn);
  /* then, handle cases when two pairs are equal */
  } else if (top->pair == pn->pair) {
    if (top->is_left && !pn->is_left) {
      show("offset the matched left pair: %s\n", get_pair(top));
      pop_right(q);
    } else {
      show("push the same pair: %s\n", get_pair(top));
      push_right(q, dn);
    }
  /* l1 >= l2, l1 >= r2: discard current pair if the top pair is a different left pair with a higher or equal priority */
  } else if (top->is_left &&  top->pair->priority >= pn->pair->priority) {
    show("discard the right part: top pair %s %d, cur pair %s %d\n", get_pair(top), top->pair->priority, get_pair(pn), pn->pair->priority);
  /* l1 < r2, r1 < r2: discard the top pair if the current pair is a different right pair with a higher priority */
  } else if (!pn->is_left && top->pair->priority < pn->pair->priority) {
    show("discard the left part: top pair %s %d, cur pair %s %d\n", get_pair(top), top->pair->priority, get_pair(pn), pn->pair->priority);
    pop_right(q);
    return true;
  } else {
    show("push pair: top pair %s %d, cur pair %s %d\n", get_pair(top), top->pair->priority, get_pair(pn), pn->pair->priority);
    push_right(q, dn);
  }

  return false;
}

/**
 * @brief parse the pair
 *
 * @param q dequeue of pair nodes
 * @param pn pair node to be parsed
 */
static void parse_pair(dequeue_t *q, dequeue_node_t *dn) {
  while (parse_pair_next(q, dn));
  pair_node_t *p = dn->data;
  /* fprintf(stderr, "parse pair %s %d times\n", p->is_left ? p->pair->left : p->pair->right, i); */
}

/**
 * @brief handle when a new pair is found
 *
 * @param ln: line node
 * @param pair: pointer to the pair
 * @param is_left: left or right pair
 * @param is_trip: whether is the triplet pair
 * @param line_idx: line index of the pair
 * @param col_idx: column index of the pair
 */
static void handle_pair(line_node_t *ln, pair_t *pair, bool is_trip, bool is_left, size_t line_idx, size_t col_idx) {
  if (ln == NULL) {
    return;
  }

  pair_node_t *pn;
  pn           = malloc(sizeof(*pn));
  pn->pair     = pair;
  pn->is_left  = is_left;
  pn->is_trip  = is_trip;
  pn->line_idx = line_idx;
  pn->col_idx  = col_idx;

  push_right(ln->pairs, pn);
  parse_pair(ln->cache, ln->pairs->tail);
}

/**
 * @brief compare the pair with the line and return the shifted index
 *
 * @param p pair string
 * @param line line string
 * @param col line column index
 * @return 0 for no match and shifted index for match
 */
static size_t pair_cmp(const char *p, const char *line, size_t col) {
  if (p == NULL) {
    return 0;
  }

  while (line[col] != '\0' && *p != '\0' && line[col] == *p) {
    ++col;
    ++p;
  }

  return *p == '\0' ? col : 0;
}

/**
 * @brief find and save the position of each pair and process them as possible as it can
 *
 * @param arg arguments
 */
static void find_pair(void *arg) {
  if (arg == NULL) {
    return;
  }

  parse_arg_t *parg = arg;
  context_t   *ctx  = parg->ctx;
  pair_t      *pair;
  const char  *line; /* current line */
  const char  *p;    /* pair string */
  size_t       save; /* index before cmp */
  size_t       col;  /* index of line */
  size_t       c;    /* index after cmp */

  for (int i = parg->start; i < parg->end; i++) {
    col = 0;
    line = ctx->lines[i];
    while (line[col] != '\0') {
      show("search col %lu\n", col);
      /* ignore escaped pattern */
      if (line[col] == '\\') {
        ++col;
        if (line[col] != '\0') {
          ++col;
        }
        continue;
      }

      save = col;
      for (int j = 0; j < ctx->num_pairs; j++) {
        pair = ctx->pairs[j];

        /* check if is the triplet pair */
        if (pair->triplet) {
          c = pair_cmp(pair->trip_pair, line, col);
          if (c != 0) {
            show("line: %s, char: %c, find triplet %s\n", line, line[col], pair->trip_pair);
            handle_pair(parg->lines + i, pair, true, true, i, c);
            col = c;
            break;
          }
        }

        /* check if is the left pair */
        c = pair_cmp(pair->left, line, col);
        if (c != 0) {
          show("line: %s, char: %c, find left %s\n", line, line[col], pair->left);
          handle_pair(parg->lines + i, pair, false, true, i, c);
          col = c;
          break;
        }

        /* check if is the right pair */
        c = pair_cmp(pair->right, line, col);
        if (c != 0) {
          show("line: %s, char: %c, find right %s\n", line, line[col], pair->right);
          handle_pair(parg->lines + i, pair, false, false, i, c);
          col = c;
          break;
        }
      }
      if (save == col) {
        ++col;
      }
    }

    remove_single_pair(parg->lines[i].cache);
    parg->lines[i].done = true;
    show("search end\n");
  }
}
