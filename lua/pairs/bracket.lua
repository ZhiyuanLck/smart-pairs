local M = {}
local u = require('pairs.utils')
local P = require('pairs')

-- action when typeset the left bracket
local function type_left_neq(left, right)
  local left_line, right_line = u.get_cursor_lr()
  local ignore_pre = P:ignore_pre(left_line, left)
  local ignore_after = P:ignore_after(right_line, left)

  if not ignore_pre and not ignore_after then
    local lc, rc = P:get_count(left_line, right_line, left, right)
    if lc >= rc then
      right_line = right .. right_line
    end
  end

  left_line = left_line .. left
  vim.api.nvim_set_current_line(left_line .. right_line)
  local pos = vim.api.nvim_win_get_cursor(0)
  pos[2] = vim.fn.strlen(left_line)
  vim.api.nvim_win_set_cursor(0, pos)
end

-- action when typeset the right bracket
-- @param right bracket
local function type_right_neq(left, right)
  local left_line, right_line = u.get_cursor_lr()

  local ignore_pre = P:ignore_pre(left_line, left)
  if ignore_pre then
    u.feedkeys(right)
    return
  end

  local lc, rc = P:get_count(left_line, right_line, left, right)
  local pos = vim.api.nvim_win_get_cursor(0)
  -- lots of left brackets more than right, we need the right one
  -- or the first right bracket is to be typeset after revoming the counterbalances on the right
  if lc > rc or rc == 0 then
    left_line = left_line .. right
    pos[2] = vim.fn.strlen(left_line)
  -- now we have at least one right bracket on the right and then jump to it
  else
    local _, end_idx = right_line:find(right)
    pos[2] = pos[2] + vim.fn.strlen(right_line:sub(1, end_idx))
  end
  vim.api.nvim_set_current_line(left_line .. right_line)
  vim.api.nvim_win_set_cursor(0, pos)
end

-- action when two brackets are equal
-- @param bracket string
local function type_eq(bracket)
  local left_line, right_line = u.get_cursor_lr()
  local left_count = P:match_count(left_line, bracket)
  local right_count = P:match_count(right_line, bracket)
  local pos = vim.api.nvim_win_get_cursor(0)

  -- process triplet bracket
  if P:get_opts(bracket).triplet then
    local pattern = u.escape(bracket)
    local l = left_line
    local n = 0
    repeat
      local i, _ = l:find(pattern .. '$')
      if i then
        n = n + 1
        l = l:sub(1, i - 1)
      end
    until (n > 2 or i == nil)
    local valid = n == 2 and not right_line:match('^' .. pattern)
    if valid then
      left_line = left_line .. bracket
      right_line = string.rep(bracket, 3) .. right_line
      pos[2] = vim.fn.strlen(left_line)
      vim.api.nvim_set_current_line(left_line .. right_line)
      vim.api.nvim_win_set_cursor(0, pos)
      return
    end
  end

  -- complete anothor bracket
  local complete = function()
    left_line = left_line .. bracket
    pos[2] = vim.fn.strlen(left_line)
  end
  -- typeset two brackets
  local typeset = function()
    right_line = bracket .. right_line
    complete()
  end

  local ignore_pre = P:ignore_pre(left_line, bracket)
  -- not consider ignore_after
  -- local ignore_after = self:ignore_after(right_line, bracket)

  -- number of brackets of current line is odd, always complete
  if ignore_pre or (left_count + right_count) % 2 == 1 then
    complete()
  -- number of brackets of current line is even
  -- number of brackets of left side is even, which means the right side is also even
  -- typeset two brackets
  elseif left_count % 2 == 0 then -- typeset all
    typeset()
  -- left side is odd and right side is odd, which means you are inside the bracket scope
  else
    local i, j = right_line:find(bracket)
    -- jump only if the right bracket is next to the cursor
    if i == 1 then
      pos[2] = pos[2] + vim.fn.strlen(right_line:sub(1, j))
    else -- typeset two brackets
      typeset()
    end
  end

  vim.api.nvim_set_current_line(left_line .. right_line)
  vim.api.nvim_win_set_cursor(0, pos)
end

function M.type_left(left)
  local right = P:get_right(left)
  if left == right then
    type_eq(left)
  else
    type_left_neq(left, right)
  end
end

function M.type_right(right)
  local left = P:get_left(right)
  if left == right then
    type_eq(right)
  else
    type_right_neq(left, right)
  end
end

return M
