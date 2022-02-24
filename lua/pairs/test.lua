local M = {}
local fn = vim.fn
local api = vim.api
local u = require('pairs.utils')

--- get the col index
---@param col number or string
---@return number
function M.get_col(col)
  if type(col) == 'string' then
    return fn.strlen(col)
  end
  return col < 0 and fn.col('.') - 1 or col
end

--- initialize the buffer with the input and the cursor
---@param input string
---@param line number: 0-based line index
---@param col string or number
---@param ft string
function M.init_buf(input, line, col, ft)
  local buf = api.nvim_create_buf(false, true)
  col = col or input
  api.nvim_command('buffer ' .. buf)
  if ft then
    api.nvim_buf_set_option(buf, 'filetype', ft)
  end
  api.nvim_command('startinsert')
  api.nvim_buf_set_lines(0, 0, -1, true, vim.split(input, '\n'))
  u.set_cursor(line + 1, M.get_col(col))
end

--- check the buffer with the expected string and the cursor
---@param expect string
---@param line number: 0-based line index
---@param col string or number
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
