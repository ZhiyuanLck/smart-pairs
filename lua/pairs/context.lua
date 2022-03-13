local u = require('pairs.utils')
local api = vim.api
local fn = vim.fn

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
function Context:new(opts)
  local ctx = setmetatable({}, Context)
  ctx:init()
  return ctx
end

--- initialization code when a new Context object is created
function Context:init()
  local cursor = u.get_cursor()
  self.cur_line_idx = cursor[1]
  self.cur_col_idx = cursor[2]
  self.cur_line = api.nvim_get_current_line()
  self.cur_left = fn.strpart(self.cur_line, 0, self.cur_col_idx)
  self.cur_right = fn.strpart(self.cur_line, self.cur_col_idx)
end

return Context
