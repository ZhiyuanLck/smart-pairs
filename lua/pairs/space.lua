local M = {}
local u = require('pairs.utils')
local P = require('pairs')

function M.type()
  local left_line, right_line = u.get_cursor_lr()

  for _, pair in ipairs(P:get_pairs()) do
    local pl = u.escape(pair.left) .. '$'
    local pr = '^' .. u.escape(pair.right)
    if left_line:match(pl) and right_line:match(pr) then
      right_line = ' ' .. right_line
      break
    end
  end

  left_line = left_line .. ' '
  vim.api.nvim_set_current_line(left_line .. right_line)
  u.set_cursor(0, left_line)
end

return M
