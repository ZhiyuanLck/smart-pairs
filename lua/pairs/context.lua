local u = require('pairs.utils')
local api = vim.api

--- region status
---@class Status
---@field region Region
---@field ctx Context
---@field line_idx number
---@field input_line string
---@field output_line string
---@field inside boolean @whether is inside the region, default false
---@field search_up boolean @whether the search direction is up, default true
local Status = {}
Status.__index = Status

--- current context
---@class Context
---@field cur_line_idx number @0-based line index
---@field cur_col_idx number @0-based column index
---@field cur_line string @current line
---@field cur_left string @the text to the left of the cursor
---@field cur_right string @the text to the right of the cursor
local Context = {}
Context.__index = Context

--- only for annotation
---@class CtxOpts
---@field mode string @operation mode: 'bracket', 'delete', 'enter'
local ctx_opts = {}

--- create the Context object
---@param opts CtxOpts
---@return Context
function Context.new(opts)
  local ctx = setmetatable({}, Context)
  ctx:init(opts)
  return ctx
end

--- initialization code when a new Context object is created
---@param opts CtxOpts
function Context:init(opts)
  local cursor = u.get_cursor()
  self.cur_line_idx = cursor[1]
  self.cur_col_idx = cursor[2]
  self.cur_line = api.nvim_get_current_line()
  self.cur_left = self.cur_line:sub(1, self.cur_col_idx)
  self.cur_right = self.cur_line:sub(self.cur_col_idx + 1)
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
