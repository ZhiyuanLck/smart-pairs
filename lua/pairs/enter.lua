local M = {}
local u = require('pairs.utils')
local P = require('pairs')

local function type_aux()
  local left_line, right_line = u.get_cursor_lr()
  left_line = left_line:match('(.-)%s*$')
  right_line = right_line:match('^%s*(.-)%s*$')

  -- blank number of left and right part
  local has_left, has_right, feed_tab
  for _, pair in ipairs(P:get_pairs()) do
    local left_cross_line = pair.opts.cross_line and left_line:match(u.escape(pair.left) .. '$')
    has_left = (pair.left == pair.right and
      (
        (pair.opts.triplet and left_line:match(string.rep(u.escape(pair.left), 3) .. '$'))
        or left_cross_line
      )) or (pair.left ~= pair.right and left_cross_line)
    if has_left then
      if pair.left ~= pair.right or not pair.triplet then
        has_right = right_line:match('^' .. u.escape(pair.right)) ~= nil
      else
        has_right = right_line:match('^' .. string.rep(u.escape(pair.right), 3)) ~= nil
      end
      feed_tab = not pair.opts.triplet
      break
    end
  end

  local linenr = vim.fn.line('.')

  if has_left then
    local indent = left_line:match('^%s*')
    right_line = indent .. right_line
    if feed_tab then
      indent = indent .. (vim.bo.et and string.rep(' ', vim.bo.sw) or '\t')
    end
    vim.api.nvim_set_current_line(left_line)
    vim.fn.append(linenr, has_right and {indent, right_line} or right_line)
    u.set_cursor(linenr + 1, indent)
  else
    vim.api.nvim_set_current_line(left_line .. right_line)
    u.set_cursor(linenr, left_line)
    u.feedkeys('<cr>')
  end
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
