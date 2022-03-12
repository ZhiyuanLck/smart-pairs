local M = {}
local fn = vim.fn
local api = vim.api
local u = require('pairs.utils')

--- get the col index
---@param col number | string
---@return number
function M.get_col(col)
  if type(col) == 'string' then
    return fn.strlen(col)
  end
  return col < 0 and fn.col('.') - 1 or col
end

--- initialize the buffer
function M.init_buf()
  local buf = api.nvim_create_buf(false, true)
  api.nvim_command('buffer ' .. buf)
  api.nvim_command('startinsert')
end

--- set the buffer with the input and the cursor
---@param input string
---@param line number @0-based line index
---@param col string | number @0-based column index
function M.set_buf(input, line, col)
  api.nvim_buf_set_lines(0, 0, -1, true, vim.split(input, '\n'))
  u.set_cursor(line + 1, M.get_col(col or input))
end

--- check the buffer with the expected string and the cursor
---@param expect string
---@param line number @0-based line index
---@param col string | number
function M.check_buf(expect, line, col)
  col = col or expect
  expect = vim.split(expect, '\n')
  local buf_lines = M.get_buf_lines()
  assert.are.same(expect, buf_lines)
  assert.are.same(line, fn.line('.') - 1)
  assert.are.same(M.get_col(col), fn.col('.') - 1)
end

function M.get_buf_lines()
  return api.nvim_buf_get_lines(0, 0, api.nvim_buf_line_count(0), false)
end

function M.feedkeys(keys)
  u.feedkeys(keys, 'xt')
end

return M
