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

return M
