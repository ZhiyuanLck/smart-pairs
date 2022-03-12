local t = require('pairs.test')
local d = require('pairs.delete')

describe('delete balanced pairs', function()
  before_each(function()
    t.init_buf()
    vim.bo.et = true
    vim.bo.sw = 2
    require('pairs'):setup()
  end)

  after_each(function()
    vim.cmd('bdelete')
  end)

  it("Should delete one char", function()
    t.set_buf('" "', 0, 1)
    d.type()
    t.check_buf('""', 0, 0)
  end)
end)
