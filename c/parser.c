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

  pairs_dqueue *q;

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
 * @param ctx: context
 * @param lres: left parsing result
 * @param rres: right parsing result
 * @param start: start of the line index
 * @param end: end of the line index
 * @return arguments
 */
static parse_arg_t *new_arg(context_t *ctx) {
  parse_arg_t *arg;
  arg        = malloc(sizeof(*arg));
  arg->lines = new_lines(ctx->num_lines);
  arg->res   = new_dequeue();
  arg->ctx   = ctx;
  arg->start = 0;
  arg->end   = 0;
  return arg;
}

/**
 * @brief destroy the arguments
 *
 * @param arg: arguments
 */
static void destroy_arg(parse_arg_t *arg) {
  destroy_lines(arg->lines, arg->ctx->num_lines);
  destroy_dequeue(arg->res);
  free(arg);
}

/**
 * @brief remove single pair whose scope is the line scope
 *
 * @param q: pointer to the dequeue
 */
static void remove_single_pair(nodes_dqueue *q) {
  if (q == NULL) {
    return;
  }

  pairs_dnode *dn;
  pair_node_t *pn;

  while (q->tail != NULL) {
    dn = q->tail->data;
    pn = dn->data;
    if (!pn->is_left || pn->is_trip || pn->pair->cross_line) {
      break;
    }
    show("remove single pair %s\n", get_pair(pn));
    pop_right(q);
  }
}

/**
 * @brief parse the pair.
 * @detailed parse_pair_next decide how to handle the curren pair node, and if a pair is popped from the
 * stack, true is returned to indicate that we need keep handling the current pair node in terms
 * of the new stack. So we need a wrapper, i.e. parse_pair to check the return value of
 * parse_pair_next in a while loop until the current pair node is pushed or discarded.
 *
 * @param q: cache dequeue
 * @param dn: pairs dequeue node to be parsed
 * @param preprocess: whether is preprocessing
 * @return true if need to judge more otherwise false
 */
static bool parse_pair_next(nodes_dqueue *q, pairs_dnode *dn, bool preprocess) {
#ifdef TEST
  const char *pre = (preprocess ? "#fg[magenta]PREPROCESS#rs" : "#fg[magenta]PROCESS#rs");
#endif

  if (q->tail == NULL) {
    push_right(q, dn);
    show("%s: empty stack, PUSH\n", pre);
    return false;
  }

  pair_node_t *pn  = dn->data;
  pairs_dnode *tmp = q->tail->data;
  pair_node_t *top = tmp->data;

  /* first, do not handle balanced pairs if is in preprocess */
  if (preprocess && (top->pair->balanced || pn->pair->balanced)) {
    show("%s: IGNORE balanced pair in preprocess\n", pre);
    push_right(q, dn);
    return false;
  }

  /* handle cases when two pairs are equal */
  if (top->pair == pn->pair) {
    if (pn->pair->balanced || (top->is_left && !pn->is_left)) {
      show("%s: OFFSET the matched left pair: #fg[red]%s#rs\n", pre, get_pair(top));
      pop_right(q);
    } else {
      show("%s: PUSH the same pair: #fg[red]%s#rs\n", pre, get_pair(top));
      push_right(q, dn);
    }
  /* l1 > l2, l1 > r2: discard current pair if the top pair is a different left pair with a higher priority.
   * balanced pair is default to be left pair, so fit the current case if top is a balanced pair
   */
  } else if (top->is_left &&  top->pair->priority > pn->pair->priority) {
    show("%s: DISCARD the right part: top pair #fg[red]%s #fg[cyan]%d#rs, cur pair #fg[red]%s #fg[cyan]%d#rs\n",
        pre, get_pair(top), top->pair->priority, get_pair(pn), pn->pair->priority);
  /* l1 <= r2, r1 <= r2: discard the top pair if the current pair is a different right pair with a higher priority
   * balanced pair is default to be left pair, so fit the current case if pn is not a balanced pair
   */
  } else if (!pn->is_left && top->pair->priority <= pn->pair->priority) {
    show("%s: DISCARD the left part: top pair #fg[red]%s #fg[cyan]%d#rs, cur pair #fg[red]%s #fg[cyan]%d#rs\n",
        pre, get_pair(top), top->pair->priority, get_pair(pn), pn->pair->priority);
    pop_right(q);
    return true;
  /* l1 < l2, r1 > r2 or pn is a balanced pair */
  } else {
    show("%s: PUSH pair: top pair #fg[red]%s #fg[cyan]%d#rs, cur pair #fg[red]%s #fg[cyan]%d#rs\n",
        pre, get_pair(top), top->pair->priority, get_pair(pn), pn->pair->priority);
    push_right(q, dn);
  }

  return false;
}

/**
 * @brief parse the pair
 *
 * @param q: cache dequeue
 * @param dn: pairs dequeue node to be parsed
 * @param preprocess: whether is preprocessing
 */
static void parse_pair(nodes_dqueue *q, pairs_dnode *dn, bool preprocess) {
  while (parse_pair_next(q, dn, preprocess));
  pair_node_t *p = dn->data;
}

/**
 * @brief compare the pair with the line and return the updated index or 0 for no match
 *
 * @param arg: common arguments
 * @param pair: pair object
 * @param is_trip: if is the triplet pair
 * @param is_left: if is the left pair
 * @param line_idx: line index
 * @param col_idx: line column index
 */
static bool pair_cmp(parse_arg_t *arg, pair_t *pair, bool is_trip, bool is_left, size_t line_idx, size_t *col_idx) {
  const char *p = is_trip ? pair->trip_pair : (is_left ? pair->left : pair->right);
  /* incase the right pair is NULL */
  if (p == NULL) {
    return false;
  }

  context_t  *ctx  = arg->ctx;
  const char *line = ctx->lines[line_idx];
  size_t      save = *col_idx;
  size_t      col  = *col_idx;

  while (line[col] != '\0' && *p != '\0' && line[col] == *p) {
    ++col;
    ++p;
  }

  /* pair range [save, col),  | -> cur_col */
  if (*p == '\0' && (line_idx != ctx->cur_line || save >= ctx->cur_col || col <= ctx->cur_col)) {
    pair_node_t *pn;
    pn           = malloc(sizeof(*pn));
    pn->pair     = pair;
    pn->is_left  = is_left;
    pn->on_left  = line_idx < ctx->cur_line || (line_idx == ctx->cur_line && save < ctx->cur_col);
    pn->is_trip  = is_trip;
    pn->line_idx = line_idx;
    pn->col_idx  = save;
    line_node_t *cur_ln = arg->lines + line_idx;
    push_right(cur_ln->pairs, pn);
    show("#fg[green]FIND PAIR#rs: #fg[red]%s#rs\n", get_pair(pn));
    parse_pair(cur_ln->cache, cur_ln->pairs->tail, true);
    *col_idx = col;
    return true;
  }
  return false;
}

/**
 * @brief find and save the position of each pair and process them as possible as it can
 * @detailed find every pair and record then in the pairs dequeue, and the results of the
 * preprocess are cached.
 *
 * @param arg: arguments of type parse_arg_t
 */
static void find_pair(void *arg) {
  if (arg == NULL) {
    return;
  }

  parse_arg_t *parg = arg;
  context_t   *ctx  = parg->ctx;
  pair_t      *pair; /* current pair in the loop */
  const char  *line; /* current line */
  const char  *p;    /* pair string */
  size_t       save; /* index before cmp */
  size_t       col;  /* index of line */
  // size_t       c;    [> index after cmp <]

  for (int i = parg->start; i < parg->end; i++) {
    col         = 0;
    line        = ctx->lines[i];

    show("#fg[yellow]START SEARCH#rs line #fg[cyan]%d#rs: #fg[red]%s#rs\n", i, line);
    while (line[col] != '\0') {
      show("#fg[blue]CHECK COL #fg[cyan]%lu#rs: #fg[red]%c#rs\n", col, line[col]);
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
        if (pair->triplet && pair_cmp(arg, pair, true, true, i, &col)) {
          break;
        } else if (pair_cmp(arg, pair, false, true, i, &col)) {
          break;
        } else if (pair_cmp(arg, pair, false, false, i, &col)) {
          break;
        }
      }
      if (save == col) {
        ++col;
      }
    }

    remove_single_pair(parg->lines[i].cache);
    show("#fg[yellow]END SEARCH#rs\n\n");

    parg->lines[i].done = true;
  }
}

/**
 * @brief check if the current pair node has not reach the bound
 *
 * @param res global result dequeue
 * @param pdn pairs dequeue node
 * @param bound restrict bound pair
 * @return whether to continue to process
 */
static bool check_and_parse(nodes_dqueue *res, pairs_dnode *pdn, pair_t *bound) {
  pairs_dnode *pdn2;
  pair_node_t *pn = pdn->data;
  show("#fg[blue]CHECK BOUND AND PARSE PAIR #fg[red]%s#rs\n", get_pair(pn));
  if (pn->pair == bound && (!pn->is_left || pn->pair->balanced)) {
    if (res->tail == NULL) {
      return false;
    } else {
      pdn2 = res->tail->data;
      pn   = pdn2->data;
      /* if the pair of the top of the stack is the bound pair, it must be a left pair */
      if (pn->pair != bound) {
        return false;
      }
    }
  }
  parse_pair(res, pdn, false);
  return true;
}

/**
 * @brief merge the pairs dequeue to the result dequeue
 * @detailed if we find a left bound pair before the cursor, we need to reparse the line where the
 * bound pair locates.
 *
 * @param ctx: context
 * @param res: global result dequeue
 * @param pdn: pairs dequeue node which is the next node of the bound pair node
 * @param bound restrict bound pair
 * @return whether to cotinue the search
 */
static bool merge_pairs(context_t *ctx, nodes_dqueue *res, pairs_dnode *pdn, pair_t *bound) {
  /* end of the file */
  if (pdn == NULL) {
    return false;
  }
  pair_node_t *pn;  /* pair node */
  while (pdn != NULL) {
    pn = pdn->data;
    // show("merge pairs node %s\n", get_pair(pn));
    if (!check_and_parse(res, pdn, bound)) {
      show("#fg[green]REACH THE BOUND #fg[red]%s#rs\n", bound->right);
      return false;
    }
    pdn = pdn->next;
  }
  remove_single_pair(res);
  return true;
}

/**
 * @brief merge the cache dequeue to the result dequeue
 *
 * @param ctx: context
 * @param res: global result dequeue
 * @param cdn: cache dequeue node
 * @param bound restrict bound pair
 * @return whether to cotinue the search
 */
static bool merge_cache(context_t *ctx, nodes_dqueue *res, nodes_dnode *cdn, pair_t *bound) {
  /* empty cache */
  if (cdn == NULL) {
    return true;
  }
  pair_node_t *pn;  /* pair node */
  pairs_dnode *pdn; /* dequeue node that stores pair node */
  while (cdn != NULL) {
    pdn = cdn->data;
    pn  = pdn->data;
    parse_pair(res, pdn, false);
    cdn = cdn->next;
  }
  remove_single_pair(res);
  return true;
}

/**
 * @brief merge the cache dequeue of current line to the result dequeue
 *
 * @param pair: pair to be searched
 * @param res: global search result dequeue
 * @param cdn: cache dequeue node
 * @return bound pair node or NULL
 */
static pairs_dnode *merge_cur_line(pair_t *pair, nodes_dqueue *res, nodes_dnode *cdn) {
  pair_node_t *pn;  /* pair node */
  pairs_dnode *pdn; /* dequeue node that stores pair node */
  pairs_dnode *pdn2;

  bool on_left = true;
  while (cdn != NULL) {
    pdn = cdn->data;
    pn  = pdn->data;
    show("#fg[blue]MERGE PAIR #fg[red]%s#rs of current line\n", get_pair(pn));
    if (pair != NULL && on_left && !pn->on_left) {
      show("first bracket on the right of current line: %s\n", get_pair(pn));
      on_left = false;
      if (res->tail != NULL) {
        pdn2 = res->tail->data;
        pn   = pdn2->data;
        /* triplet is default left */
        if (pn->is_left && pn->pair != pair) {
          return pdn2;
        }
      }
    }
    parse_pair(res, pdn, false);
    cdn = cdn->next;
  }

  remove_single_pair(res);

  /* recheck in case such case: (' */
  if (pair != NULL && on_left && res->tail != NULL) {
    pdn2 = res->tail->data;
    pn   = pdn2->data;
    /* triplet is default left */
    if (pn->is_left && pn->pair != pair) {
      return pdn2;
    }
  }

  return NULL;
}

/**
 * @brief merge all results
 *
 * @param arg: arguments of type parse_arg_t
 */
static void merge_results(void *arg) {
  parse_arg_t *parg  = arg;
  context_t   *ctx   = parg->ctx;
  dequeue_t   *res   = parg->res;
  line_node_t *lines = parg->lines;

  if (ctx->stop) {
    return;
  }

  pair_node_t *pn;      /* pair node */
  pairs_dnode *restart; /* pair node to restart search */
  pairs_dnode *next;    /* next pair node of restart */
  nodes_dnode *cdn;     /* cache dequeue node */
  pair_t      *bound = NULL;

  show("#fg[yellow]START MERGING#rs results...\n");
  int i = 0;
  while (i < ctx->num_lines) {
    while (!lines[i > 0 ? i - 1 : 0].done);

    cdn  = lines[i].cache->head;
    next = lines[i].pairs->head;
    if (bound) {
      show("#fg[magenta]PARSE#rs [bounded] line #fg[cyan]%d/%d#rs: #fg[red]%s#rs\n",
          i + 1, ctx->num_lines, ctx->lines[i]);
      if (!merge_pairs(ctx, res, next, bound)) {
        break;
      }
    } else if (i != ctx->cur_line) {
      show("#fg[magenta]PARSE#rs [unbounded] line #fg[cyan]%d/%d#rs: #fg[red]%s#rs\n",
          i + 1, ctx->num_lines, ctx->lines[i]);
      merge_cache(ctx, res, cdn, bound);
    } else {
      show("#fg[magenta]PARSE#rs current line #fg[cyan]%d/%d#rs: #fg[red]%s#rs\n",
          i + 1, ctx->num_lines, ctx->lines[i]);
      restart = merge_cur_line(ctx->pair, res, cdn);
      if (restart != NULL) {
        pn    = restart->data;
        next  = restart->next;
        bound = pn->pair;
        i     = pn->line_idx;

        if (next == NULL && i < ctx->num_lines - 1) {
          next = lines[i + 1].pairs->head;
          ++i;
        }

        show("#fg[green]RESTART#rs at line: #fg[red]%s#rs, col: #fg[cyan]%d#rs, pair: #fg[red]%s#rs\n",
            ctx->lines[pn->line_idx], pn->col_idx, get_pair(pn));
        clear_dequeue(res);
      }
    }

    ++i;
  }
  show("#fg[yellow]END MERGE#rs\n\n");

  ctx->stop = true;
}

#ifdef TEST
parse_arg_t *
#else
void
#endif
parse(context_t *ctx) {
  parse_arg_t *arg = new_arg(ctx);
  size_t       sep = 1;
  size_t       i   = 0;

  while (i < ctx->num_lines) {
    arg->start = i;
    arg->end   = i + sep > ctx->num_lines ? ctx->num_lines : i + sep;
    find_pair(arg);
    i += sep;
  }

  merge_results(arg);
#ifdef TEST
  return arg;
#else
  destroy_arg(arg);
#endif
}
