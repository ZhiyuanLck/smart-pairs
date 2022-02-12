local M = {}
local u = require('pairs.utils')
local P = require('pairs')

local function type_aux()
  local left_line, right_line = u.get_cursor_lr()

  local bnl, bnr, has_right
  for _, pair in ipairs(P:get_pairs()) do
    local left_blank = left_line:match(u.escape(pair.left) .. '(%s*)$')
    local right_blank = right_line:match('^(%s*)' .. u.escape(pair.right))

    if pair.opts.triplet then
      has_right = right_line:match('^%s*' .. string.rep(u.escape(pair.right), 3))
    else
      has_right = pair.opts.cross_line and right_blank
    end

    if left_blank or right_blank then
      bnl = left_blank and #left_blank or #left_line:match('%s*$')
      bnr = right_blank and #right_blank or #right_line:match('^%s*')
      break
    end
  end

  if not bnl and not bnr then
    bnl = #left_line:match('%s*$')
    bnr = #right_line:match('^%s*')
  end

  left_line = bnl == 0 and left_line or left_line:sub(1, #left_line - bnl)
  right_line = bnr == 0 and right_line or right_line:sub(bnr + 1)
  vim.api.nvim_set_current_line(left_line .. right_line)
  u.set_cursor(0, left_line)

  u.feedkeys(has_right and "<cr><esc>O" or "<cr>")
end

function M.type()
  if not u.enable(P.enter.enable_cond) then
    return P.enter.enable_fallback() or ''
  end

  u.call(P.enter.before_hook)
  type_aux()
  u.call(P.enter.after_hook)
  return ''
end

return M
