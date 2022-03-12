local M = {}
local u = require('pairs.utils')
local P = require('pairs')
local fb = require('pairs.fallback')

local function type_aux()
  local left_line, right_line = u.get_cursor_lr()
  for _, pair in ipairs(P:get_pairs()) do
    if pair.opts.enable_smart_space and
      left_line:match(u.escape(pair.left) .. '$') and
      right_line:match('^' .. u.escape(pair.right)) then
      u.insert(-1, -1, '  ')
      u.advance_cursor(' ')
      return
    end
  end
  fb.space()
end

function M.type()
  if not u.enable(P.space.enable_cond) then
    return P.space.enable_fallback() or ''
  end

  u.call(P.space.before_hook)
  type_aux()
  u.call(P.space.after_hook)
  return ''
end

return M
