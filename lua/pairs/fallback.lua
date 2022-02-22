local M = {
  delete = {
    empty_line = {},
    current_line = {}
  },
}

local u = require('pairs.utils')

function M.enter()
  u.feedkeys('<cr>')
end

function M.space()
  local left_line, right_line = u.get_cursor_lr()
  left_line = left_line .. ' '
  vim.api.nvim_set_current_line(left_line .. right_line)
  u.set_cursor(0, left_line)
end

function M.delete()
  u.feedkeys('<bs>')
end

function M.delete_indent()
  local cur_line = vim.api.nvim_get_current_line()
  local cur_wd = vim.fn.strdisplaywidth(cur_line:match('^%s*'))
  if cur_wd == 0 then u.feedkeys('<bs>') return end
  local cur = vim.fn.line('.') - 2
  while (cur >= 0) do
    local indent = u.get_line(cur):match('^%s*')
    if vim.fn.strdisplaywidth(indent) < cur_wd then
      --- why need extra ()?
      vim.api.nvim_set_current_line((cur_line:gsub('^%s*', indent)))
      u.set_cursor(0, indent)
      return
    end
    cur = cur - 1
  end
  u.feedkeys('<bs>')
end

return M
