#include "msg.h"
#include <unistd.h>
#include <sys/syscall.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <stdbool.h>

static bool match(const char *s1, const char *s2) {
  while (*s1 != '\0' && *s2 != '\0') {
    if (*s1 != *s2) return false;
    ++s1;
    ++s2;
  }
  return true;
}

static char *format_text(const char *format) {
  int n = 0;
  const char *ch = format;

  char *s = malloc((5 * strlen(format) + 1) * sizeof(char));
  char *p = s;
  while (*ch != '\0') {
    if (*ch == '#') {
      ++ch;
      if (match(ch, "fg")) {
        if (match(ch + 2, "[black]")) {
          sprintf(p, "\x1B[30m");
          ch += 9;
        } else if (match(ch + 2, "[red]")) {
          sprintf(p, "\x1B[31m");
          ch += 7;
        } else if (match(ch + 2, "[green]")) {
          sprintf(p, "\x1B[32m");
          ch += 9;
        } else if (match(ch + 2, "[yellow]")) {
          sprintf(p, "\x1B[33m");
          ch += 10;
        } else if (match(ch + 2, "[blue]")) {
          sprintf(p, "\x1B[34m");
          ch += 8;
        } else if (match(ch + 2, "[magenta]")) {
          sprintf(p, "\x1B[35m");
          ch += 11;
        } else if (match(ch + 2, "[cyan]")) {
          sprintf(p, "\x1B[36m");
          ch += 8;
        } else if (match(ch + 2, "[white]")) {
          sprintf(p, "\x1B[37m");
          ch += 9;
        }
        p += 5;
      } else if (match(ch, "bg")) {
        if (match(ch + 2, "[black]")) {
          sprintf(p, "\x1B[40m");
          ch += 9;
        } else if (match(ch + 2, "[red]")) {
          sprintf(p, "\x1B[41m");
          ch += 7;
        } else if (match(ch + 2, "[green]")) {
          sprintf(p, "\x1B[42m");
          ch += 9;
        } else if (match(ch + 2, "[yellow]")) {
          sprintf(p, "\x1B[43m");
          ch += 10;
        } else if (match(ch + 2, "[blue]")) {
          sprintf(p, "\x1B[44m");
          ch += 8;
        } else if (match(ch + 2, "[magenta]")) {
          sprintf(p, "\x1B[45m");
          ch += 11;
        } else if (match(ch + 2, "[cyan]")) {
          sprintf(p, "\x1B[46m");
          ch += 8;
        } else if (match(ch + 2, "[white]")) {
          sprintf(p, "\x1B[47m");
          ch += 9;
        }
        p += 5;
      } else if (match(ch, "bf")) {
        sprintf(p, "\x1B[1m");
        ch += 2;
        p += 4;
      } else if (match(ch, "ul")) {
        sprintf(p, "\x1B[4m");
        ch += 2;
        p += 4;
      } else if (match(ch, "rs")) {
        sprintf(p, "\x1B[0m");
        ch += 2;
        p += 4;
      } else if (*ch == '#') {
        sprintf(p, "#");
        ch += 1;
        p += 1;
      } else if (*ch == '\0') {
        sprintf(p, "#");
        break;
      } else {
        sprintf(p, "#%c", *ch);
        ch += 1;
        p += 2;
      }
    } else { /* normal char */
      sprintf(p, "%c", *ch);
      ++ch;
      ++p;
    }
    *p = '\0';
  }
  return s;
}

msg_queue_t *msgq = NULL;

/**
 * @brief add a message to the queue
 *
 * @param file source file name
 * @param lineno line index of the source file
 * @param verbose whether to print file and line number
 * @param format message
 */
void add_msg(const char *file, int lineno, bool verbose, const char *format, ...) {
  int     l1; /* length of file info */
  int     l2; /* length of format */
  va_list args;
  char   *msg;

  if (verbose) {
    file = trunc_file(file);
    l1 = snprintf(NULL, 0, "%s:%d [thread %ld]: ", file, lineno, syscall(SYS_gettid));
  } else {
    l1 = 0;
  }

  va_start(args, format);
  l2 = vsnprintf(NULL, 0, format, args);
  va_end(args);

  char *new_fm = malloc((l2 + 1) * sizeof(char));
  va_start(args, format);
  vsprintf(new_fm, format, args);
  va_end(args);
  char *tmp = new_fm;
  new_fm = format_text(new_fm);
  free(tmp);
  tmp = NULL;

  va_start(args, format);
  l2 = vsnprintf(NULL, 0, new_fm, args);
  va_end(args);

  msg = malloc((l1 + l2 + 1) * sizeof(char));
  if (verbose) {
    sprintf(msg, "%s:%d [thread %ld]: ", file, lineno, syscall(SYS_gettid));
    // sprintf(msg, "%s:%d: ", file, lineno);
  }

  va_start(args, format);
  vsprintf(msg + l1, new_fm, args);
  va_end(args);

  free(new_fm);
  new_fm = NULL;

  msg_node_t *node = malloc(sizeof(msg_node_t));
  node->next = NULL;
  node->msg  = msg;
  /* show message in time */
  /* fprintf(stdout, "%s", msg); */

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
