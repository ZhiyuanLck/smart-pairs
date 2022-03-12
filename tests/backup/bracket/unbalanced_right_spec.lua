local t = require('pairs.test')
local b = require('pairs.bracket')
local P = require('pairs')

describe('unbalanced right bracket', function()
  before_each(function()
    t.init_buf()
    require('pairs'):setup()
  end)

  after_each(function()
    vim.cmd('bdelete')
  end)

  it("Should typeset the right bracket", function()
    t.set_buf('(', 0, 1)
    b.type_right(')')
    t.check_buf('()', 0, 2)
  end)

  it("Should typeset the right bracket [M]", function()
    local input = [[
(

    ]]
    local expect = [[
(
)
    ]]
    t.set_buf(input, 1, 0)
    b.type_right(')')
    t.check_buf(expect, 1, 1)
  end)

  it("Should typeset the right bracket", function()
    t.set_buf('()(', 0, nil)
    b.type_right(')')
    t.check_buf('()()', 0, nil)
  end)

  it("Should typeset the right bracket [M]", function()
    local input = [[
()(

    ]]
    local expect = [[
()(
)
    ]]
    t.set_buf(input, 1, 0)
    b.type_right(')')
    t.check_buf(expect, 1, 1)
  end)

  it("Should ignore escaped right bracket and typeset the right bracket", function()
    t.set_buf('(\\)', 0, 1)
    b.type_right(')')
    t.check_buf('()\\)', 0, 2)
  end)

  it("Should ignore prefix pattern and typeset the right bracket", function()
    t.set_buf('(\\)', 0, 2)
    b.type_right(')')
    t.check_buf('(\\))', 0, 3)
  end)

  it("Should typeset the right bracket with unknown strategy", function()
    P.autojump_strategy.unbalanced = "none"
    t.set_buf('()', 0, 1)
    b.type_right(')')
    t.check_buf('())', 0, 2)
  end)

  it("Should typeset the right bracket with nil strategy", function()
    P.autojump_strategy.unbalanced = nil
    t.set_buf('()', 0, 1)
    b.type_right(')')
    t.check_buf('())', 0, 2)
  end)

  it("Should jump with 'right' strategy", function()
    P.autojump_strategy.unbalanced = "right"
    t.set_buf('()', 0, 1)
    b.type_right(')')
    t.check_buf('()', 0, 2)
  end)

  it("Should jump with 'right' strategy [M]", function()
    P.autojump_strategy.unbalanced = "right"
    local input = [[
(
)
    ]]
    local expect = [[
(
)
    ]]
    t.set_buf(input, 1, 0)
    b.type_right(')')
    t.check_buf(expect, 1, 1)
  end)

  it("Should ignore escaped left bracket and jump with 'right' strategy", function()
    P.autojump_strategy.unbalanced = "right"
    t.set_buf('(\\()', 0, 3)
    b.type_right(')')
    t.check_buf('(\\()', 0, 4)
  end)

  it("Should ignore escaped left bracket and jump with 'right' strategy [M]", function()
    local input = [[
(\(
)
    ]]
    local expect = [[
(\(
)
    ]]
    t.set_buf(input, 1, 0)
    b.type_right(')')
    t.check_buf(expect, 1, 1)
  end)

  it("Should jump with 'all' strategy", function()
    P.autojump_strategy.unbalanced = "all"
    t.set_buf('()', 0, 1)
    b.type_right(')')
    t.check_buf('()', 0, 2)
  end)

  it("Should jump with 'all' strategy", function()
    P.autojump_strategy.unbalanced = "all"
    t.set_buf('(text)', 0, 2)
    b.type_right(')')
    t.check_buf('(text)', 0, nil)
  end)

  it("Should jump with 'all' strategy [M]", function()
    P.autojump_strategy.unbalanced = "all"
    local input = [[
(
)
    ]]
    local expect = [[
(
)
    ]]
    t.set_buf(input, 0, 1)
    b.type_right(')')
    t.check_buf(expect, 1, 1)
  end)

  -- do not jump in custom scope region
end)
