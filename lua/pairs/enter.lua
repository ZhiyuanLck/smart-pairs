local M = {}
local u = require('pairs.utils')
local P = require('pairs')

local function type_aux()
  local left_line, right_line = u.get_cursor_lr()
  left_line = left_line:match('(.-)%s*$')
  right_line = right_line:match('^%s*(.-)%s*$')

  -- blank number of left and right part
  local has_left, has_right, has_indent
  local loose_match
  for _, pair in ipairs(P:get_pairs()) do
    if not pair.opts.cross_line and not pair.opts.triplet then goto continue end
    local _left_line = P:clean(left_line, pair.left, false)

    local check = function(loose)
      local _end = loose and '.-$' or '$'
      local left_cross_line = not pair.balanced and _left_line:match(u.escape(pair.left) .. _end)
      local triplet = pair.opts.triplet and _left_line:match(string.rep(u.escape(pair.left), 3) .. _end)
      has_left = left_cross_line or triplet
      if has_left then
        if pair.triplet then
          has_right = right_line:match('^' .. string.rep(u.escape(pair.right), 3)) ~= nil
        else
          has_right = right_line:match('^' .. u.escape(pair.right)) ~= nil
        end
        has_indent = not pair.opts.triplet
      end
      loose_match = loose
      return has_left
    end

    if check(false) or check(true) then break end
    ::continue::
  end

  local linenr = vim.fn.line('.')

  if has_left then
    local indent = left_line:match('^%s*')
    if not loose_match then right_line = indent .. right_line end
    if has_indent then
      indent = indent .. P:get_indent()
    end
    if loose_match then right_line = indent .. right_line end

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
