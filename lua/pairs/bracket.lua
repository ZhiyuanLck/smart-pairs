local M = {}
local fmt = string.format
local u = require('pairs.utils')
local P = require('pairs')

--- action when typeset the left bracket
---@param left string: left bracket
---@param right string: right bracket
local function type_left_neq(left, right)
  local left_line, right_line = u.get_cursor_lr()
  local ignore_pre = P:ignore_pre(left_line, left)
  local ignore_after = P:ignore_after(right_line, left)
  local insert_text = left

  if not ignore_pre and not ignore_after then
    --- local lc, rc = P:get_count(left_line, right_line, left, right)
    local lc, rc = P:get_cross_count(left, right)
    if lc >= rc then
      insert_text = insert_text .. right
    end
  end

  u.insert(-1, -1, insert_text)
  u.advance_cursor(left)
end

--- action when typeset the right bracket
---@param left string
---@param right string
local function type_right_neq(left, right)
  local left_line, right_line = u.get_cursor_lr()

  local do_nothing = function()
    u.insert(-1, -1, right)
    u.advance_cursor(right)
  end

  local ignore_pre = P:ignore_pre(left_line, left)
  if ignore_pre then
    do_nothing()
    return
  end

  --- local lc, rc = P:get_count(left_line, right_line, left, right)
  local lc, rc = P:get_cross_count(left, right)
  --- lots of left brackets more than right, we need the right one
  --- or the first right bracket is to be typeset after revoming the counterbalances on the right
  if lc > rc or rc == 0 then
    do_nothing()
    return
  end

  local strategy = P.autojump_strategy.unbalanced

  local _right = u.escape(right)
  if strategy == 'right' then
    local m = right_line:match('^' .. _right)
    if m then
      u.advance_cursor(m)
    else
      do_nothing()
    end
  elseif strategy == 'all' then
    local line_idx = vim.fn.line('.') - 1
    local cur = line_idx
    local end_nr = vim.api.nvim_buf_line_count(0)
    local end_idx = line_idx + P.max_search_lines
    if end_idx >= end_nr then end_idx = end_nr - 1 end

    local n = 0
    while (cur <= end_idx) do
      local line = cur == line_idx and right_line or u.get_line(cur)
      local count = u.count(line:reverse(), right:reverse(), left:reverse())
      if n + count.n > 0 then
        local m = line:match('^.-' .. _right)
        if cur == line_idx then
          u.advance_cursor(m)
        else
          u.set_cursor(cur + 1, m)
        end
        return
      else
        n = n + count.m
      end
      cur = cur + 1
    end
  else
    do_nothing()
  end
end

--- action when two brackets are equal
---@param bracket string
local function type_eq(bracket)
  local left_line, right_line = u.get_cursor_lr()

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
      u.insert(-1, -1, string.rep(bracket, 4))
      u.advance_cursor(bracket)
      return
    end
  end

  local left_count = P:match_count(left_line, bracket)
  local right_count = P:match_count(right_line, bracket)

  -- complete anothor bracket
  local complete = function()
    u.insert(-1, -1, bracket)
    u.advance_cursor(bracket)
  end
  -- typeset two brackets
  local typeset = function()
    u.insert(-1, -1, bracket .. bracket)
    u.advance_cursor(bracket)
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
    -- jump only if the right bracket is next to the cursor
    if right_line:match('^' .. u.escape(bracket)) then
      u.advance_cursor(bracket)
    else -- typeset two brackets
      typeset()
    end
  end
end

function M.type_left(left)
  local right = P:get_right(left)
  if left == right then
    type_eq(left)
  else
    type_left_neq(left, right)
  end
  return ''
end

function M.type_right(right)
  local left = P:get_left(right)
  if left == right then
    type_eq(right)
  else
    type_right_neq(left, right)
  end
  return ''
end

--- test whether line contain key and return match cursor col
---@param line string
---@param format string: detail search pattern
---@param key string: key to be searched
---@param left_line string: left line to be concated to get the cursor col
local function match_col(line, format, key, left_line)
  local m = line:match(fmt(format, u.escape(key)))
  if not m then return end
  m = left_line and left_line .. m or m
  return vim.fn.strlen(m)
end

--- jump to the key
---@param opts table
---@field key string: search key
---@field out boolean: if jump outside the key
function M.jump_left(opts)
  opts = opts or {}
  local line_idx = vim.fn.line('.') - 1
  local cur = line_idx
  local format = opts.out and '^(.*)%s.-$' or '^(.*%s).-$'

  while (cur >= 0 and line_idx - cur <= P.max_search_lines) do
    local line = cur == line_idx and u.get_cursor_l() or u.get_line(cur)
    local trim = function(key)
      if cur ~= line_idx or opts.out then return line end
      local m = line:match(fmt('^(.*)%s$', u.escape(key)))
      return m or line
    end
    if opts.key then
      local tmp_line = trim(opts.key)
      local col = match_col(tmp_line, format, opts.key)
      if col then u.set_cursor(cur + 1, col) return end
    else
      local max
      for _, pair in ipairs(P:get_pairs()) do
        local tmp_line = trim(pair.left)
        local col = match_col(tmp_line, format, pair.left)
        if col and (not max or col > max) then max = col end
      end
      if max then u.set_cursor(cur + 1, max) end
    end
    cur = cur - 1
  end
end

--- jump to the key
---@param opts table
---@field key string: search key
---@field out boolean: if jump outside the key
function M.jump_right(opts)
  opts = opts or {}
  local line_idx = vim.fn.line('.') - 1
  local cur = line_idx
  local format = opts.out and '^(.-%s)' or '^(.-)%s'
  local end_nr = vim.api.nvim_buf_line_count(0)

  while (cur < end_nr and cur - line_idx <= P.max_search_lines) do
    local line, left_line
    if cur == line_idx then
      left_line, line = u.get_cursor_lr()
    else
      line = u.get_line(cur)
    end

    local trim = function(key)
      if cur ~= line_idx or opts.out then return line, left_line end
      local m = line:match(fmt('^%s(.*)$', u.escape(key)))
      return m and m or line, m and left_line .. key or left_line
    end

    if opts.key then
      local tmp_line, tmp_left_line = trim(opts.key)
      local col = match_col(tmp_line, format, opts.key, tmp_left_line)
      if col then u.set_cursor(cur + 1, col) return end
    else
      local min
      for _, pair in ipairs(P:get_pairs()) do
        local tmp_line, tmp_left_line = trim(pair.right)
        local col = match_col(tmp_line, format, pair.right, tmp_left_line)
        if col and (not min or col < min) then min = col end
      end
      if min then u.set_cursor(cur + 1, min) return end
    end
    cur = cur + 1
  end
end

return M
