#include "parser.c"
#include "test.h"
#include "msg.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>

/**
 * @brief test if the parse result is correct
 *
 * @param file source file name
 * @param lineno line index of the source file
 * @param s line to be parsed
 * @param pos string representation of position queue
 * @param st string representation of stack
 */
void test_one_line_helper(const char *file, int lineno, const char *line, const char *pos, const char *st) {
  char         str1[100];
  char         str2[100];
  const char  *s[] = {line};
  context_t   *ctx = new_context(s, 1);
  parse_arg_t *arg = new_arg(ctx, 0, 1);
  find_pair(arg);

  to_string(arg->lines->pairs, str1, true);
  bool pos_cond = strcmp(pos, str1) == 0;

  to_string(arg->lines->cache, str2, false);
  bool st_cond = strcmp(st, str2) == 0;

  file = trunc_file(file);
  if (pos_cond && st_cond) {
    clear_msg();
  } else {
    show_msg();
    fprintf(stderr, "%s:%d: ", file, lineno);
  }

  if (!pos_cond) {
    fprintf(stderr, "%s expect \"%s\", but get \"%s\"\n", "position", pos, str1);
    show_line(file, lineno);
    exit(1);
  }
  if (!st_cond) {
    fprintf(stderr, "%s expect \"%s\", but get \"%s\"\n", "stack", st, str2);
    show_line(file, lineno);
    exit(1);
  }

  destroy_arg(arg);
  destroy_context(ctx);
}

#define test_one_line(...) test_one_line_helper(__FILE__, __LINE__, __VA_ARGS__)

int main() {
  /* normal tests */
  test_one_line("(",       "(",   "(");
  test_one_line("((",      "((",  "((");
  test_one_line(")",       ")",   ")");
  test_one_line("))",      "))",  "))");
  test_one_line("()",      "()",  "");
  test_one_line("(text))", "())", ")");
  test_one_line("((text)", "(()", "(");

  /* brackets with comments */
  test_one_line("(//)",    "(//)",    "(");
  test_one_line("(//()",   "(//()",   "(");
  test_one_line("(/*)*/",  "(/*)*/",  "(");
  test_one_line("(/*)*/)", "(/*)*/)", "");

  /* brackets with string */
  test_one_line("'(",  "'(",  "'(");
  test_one_line("(')", "(')", "(')");

  /* triplet pair */
  test_one_line("'''",   "'''",   "'''");
  test_one_line("''''",  "''''",  "''''");
  test_one_line("(''')", "(''')", "(''')");

  /* escape patterns */
  test_one_line("\\(",   "",   "");
  test_one_line("\\()",  ")",  ")");
  test_one_line("(\\)",  "(",  "(");
  test_one_line("(\\))", "()", "");

  destroy_msg();
}
