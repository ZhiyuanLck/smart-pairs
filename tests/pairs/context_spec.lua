local Contex = require('pairs.context')
local t = require('pairs.test')
local api = vim.api

describe('Test class Contex/init:', function()
  before_each(function()
    t.init_buf()
  end)

  after_each(function()
    api.nvim_buf_delete(0, {force = true})
  end)

  it("should set correct value of general member", function()
    t.set_buf('test', 0, 2)
    local ctx = Contex:new()
    assert.are.same(0, ctx.cur_line_idx)
    assert.are.same(2, ctx.cur_col_idx)
    assert.are.same('test', ctx.cur_line)
    assert.are.same('te', ctx.cur_left)
    assert.are.same('st', ctx.cur_right)
  end)
end)
