local Pairs = require('pairs')
local u = require('pairs.utils')
local api = vim.api

--- current context
---@class Context
---@field cur_line_idx number @0-based current line index
---@field line_idx number @0-based line index
---@field min_idx number @0-based minimum line index
---@field max_idx number @0-based maximum line index
---@field max_search_lines number @maximum lines to be searched
---@field searched_lines number @number of lines that have been searched
---@field cur_col_idx number @0-based column index
---@field cur_line string @current line
---@field cur_left string @the text to the left of the cursor
---@field cur_right string @the text to the right of the cursor
---@field left_ctn Counter @counter of the left bracket
---@field right_ctn Counter @counter of the right bracket
---@field last_ctn Counter @last status of the current counter
---@field search_up boolean @indicate the search direction, initially true
---@field pair Pair @pair to be searched
local Context = {}
Context.__index = Context

--- only for annotation
---@class CtxOpts
---@field mode string @operation mode: 'bracket', 'delete', 'enter'
---@field pair Pair @pair to be searched
local ctx_opts = {}

--- create the Context object
---@param opts CtxOpts
---@return Context
function Context.new(opts)
  opts = u.if_nil(opts, {})
  local ctx = setmetatable({}, Context)
  local cursor = u.get_cursor()
  ctx.cur_line_idx = cursor[1]
  ctx.line_idx = ctx.cur_line_idx
  ctx.min_idx = 0
  ctx.max_idx = api.nvim_buf_line_count(0) - 1
  ctx.max_search_lines = Pairs.max_search_lines
  ctx.searched_lines = 0
  ctx.cur_col_idx = cursor[2]
  ctx.cur_line = api.nvim_get_current_line()
  ctx.cur_left = ctx.cur_line:sub(1, ctx.cur_col_idx)
  ctx.cur_right = ctx.cur_line:sub(ctx.cur_col_idx + 1)
  ctx.left_ctn = ctx.new_counter()
  ctx.right_ctn = ctx.new_counter()
  ctx.search_up = true
  ctx.pair = opts.pair
  return ctx
end

--- bracket counters
---@class Counter
---@field real number @real amount
---@field valid number @valid amount with the minimum 0
local Counter = {}
Counter.__index = Counter

--- create a counter object
---@param ctn Counter @copy initialization
---@return Counter
function Context.new_counter(ctn)
  if ctn then return setmetatable({real = ctn.real, valid = ctn.valid}, Counter) end
  return setmetatable({real = 0, valid = 0}, Counter)
end

--- increase the counter
function Counter:incr()
  self.real  = self.real + 1
  self.valid = self.valid + 1
end

--- decrease the counter
function Counter:decr()
  self.real = self.real - 1
  self.valid = self.valid == 0 and 0 or self.valid - 1
end

--- check whether to stop the search progress
---@return boolean
function Context:stop()
  return self.line_idx < self.min_idx or self.line_idx > self.max_idx or self.searched_lines > self.max_search_lines
end

--- switch the search direction
function Context:switch()
  self.search_up = not self.search_up
  self.searched_lines = 0
  self.last_ctn = nil
  self.line_idx = self.cur_line_idx
end

function Context:get_line()
  local line
  if self.line_idx == self.cur_line_idx then
    line = self.search_up and self.cur_left or self.cur_right
  else
    line = u.get_line(self.line_idx)
  end
  self.searched_lines = self.searched_lines + 1
  self.line_idx = self.search_up and self.line_idx - 1 or self.line_idx + 1
  return line
end

--- calculate the amount of the left brackets relative to the right brackets
---@param str string @input text
---@param left string @left bracket
---@param right string @right bracket
---@param ctn Counter | nil @optional continuous counter
---@return Counter
function Context.count_left(str, left, right, ctn)
  local cur = 1
  local ln, rn, sn = #left, #right, #str
  ctn = ctn or Context.new_counter()
  while (cur <= sn) do
    if str:sub(cur, cur + ln - 1) == left then
      ctn:incr()
      cur = cur + ln
    elseif str:sub(cur, cur + rn - 1) == right then
      ctn:decr()
      cur = cur + rn
    else
      cur = cur + 1
    end
  end
  return ctn
end

--- calculate the amount of the right brackets relative to the left brackets
---@param str string @input text
---@param left string @left bracket
---@param right string @right bracket
---@param ctn Counter | nil @optional continuous counter
---@return Counter
function Context.count_right(str, left, right, ctn)
  local ln, rn, sn = #left, #right, #str
  local cur = sn
  ctn = ctn or Context.new_counter()
  while (cur > 0) do
    if str:sub(cur - rn + 1, cur) == right then
      ctn:incr()
      cur = cur - rn
    elseif str:sub(cur - ln + 1, cur) == left then
      ctn:decr()
      cur = cur - ln
    else
      cur = cur - 1
    end
  end
  return ctn
end

--- calculate the amount of the balanced bracket
---@param str string @input text
---@param bracket string @character
---@return number
function Context.count_bracket(str, bracket)
  local n = 0
  local cur = 1
  while (cur <= #str) do
    if str:sub(cur, cur + #bracket - 1) == bracket then
      n = n + 1
      cur = cur + #bracket
    else
      cur = cur + 1
    end
  end
  return n
end

return Context
