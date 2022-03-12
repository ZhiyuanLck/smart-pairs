local t = require('pairs.test')
local s = require('pairs.space')
local P = require('pairs')

describe('unbalanced right bracket', function()
  before_each(function()
    t.init_buf()
    require('pairs'):setup()
  end)

  after_each(function()
    vim.cmd('bdelete')
  end)

  it("Should typeset one space", function()
    t.set_buf('', 0, 0)
    s.type()
    t.check_buf(' ', 0, 1)
  end)

  it("Should typeset one space inside bracket", function()
    t.set_buf('( )', 0, 1)
    s.type()
    t.check_buf('(  )', 0, 2)
  end)

  it("Should typeset one space inside string", function()
    t.set_buf('""', 0, 1)
    s.type()
    t.check_buf('" "', 0, 2)
  end)

  it("Should typeset one space with 'enable_smart_space' disabled", function()
    P:setup{
      pairs = {
        ['*'] = {
          {'(', ')', {enable_smart_space = false}}
        }
      }
    }
    t.set_buf('()', 0, 1)
    s.type()
    t.check_buf('( )', 0, 2)
  end)

  it("Should typeset two space inside bracket", function()
    t.set_buf('()', 0, 1)
    s.type()
    t.check_buf('(  )', 0, 2)
  end)
end)
