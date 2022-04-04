#include "test.h"
#include "msg.h"
#include "parser.c"
#include <assert.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

/**
 * @brief test if the parse result is correct
 *
 * @param file: source file name
 * @param lineno: line index of the source file
 * @param expect: expected string representation of the stack
 * @param test_left: whethe to test the lres
 * @param ...: lines to be parsed
 */
void test_helper(const char *file, int lineno, const char *expect, size_t line_idx, size_t col_idx, int num, ...) {
  char        str[10];
  const char *s[10];

  context_t   *ctx = new_context(s, num, 4);
  ctx->cur_line    = line_idx;
  ctx->cur_col     = col_idx;

  va_list args;
  va_start(args, num);
  for (int i = 0; i < num; ++i) {
    s[i] = va_arg(args, const char*);
  }
  va_end(args);

  parse_arg_t *arg = parse(ctx);

  to_string(arg->res, str, false);
  file = trunc_file(file);
  if (strcmp(expect, str) == 0) {
    clear_msg();
  } else {
    show_msg();
    fprintf(stderr, "%s:%d: ", file, lineno);
    fprintf(stderr, "%s expect \"%s\", but get \"%s\"\n", "result", expect, str);
    show_line(file, lineno);
    exit(1);
  }

  destroy_arg(arg);
  destroy_context(ctx);
}

#define test_lines(...) test_helper(__FILE__, __LINE__, __VA_ARGS__)

int main() {
  /* normal merge */
  test_lines("",    0, 0, 2, "(",     ")");
  test_lines(")",   0, 0, 2, "(",     "))");
  test_lines("(/*", 0, 0, 2, "(/*",   ")");
  test_lines("*/)", 0, 0, 2, "(",     "*/)");
  test_lines("",    0, 0, 2, "(/*",   ")*/)");
  test_lines("",    0, 0, 2, "(/*",   ")//*/)");
  test_lines("(",   0, 0, 1, "(')'");
  test_lines("",    0, 0, 2, "('",    ")");
  test_lines("(",   0, 0, 2, "(",     "')");
  test_lines("(",   0, 0, 2, "(",     "')'')");
  test_lines("",    0, 0, 2, "(''')", "''')");
  test_lines("",    0, 0, 2, "(''')", "//''')");
  test_lines("(",   0, 0, 2, "(",     "//')')");
  test_lines("$",   0, 0, 1, "$");
  test_lines("",    0, 0, 2, "$",     "$");
  test_lines("$",   0, 0, 2, "$",     "'$'");

  /* scoped merge */
  test_lines("(",   0, 3, 2, "/*(",   "*/)");

  destroy_msg();
}
