local t = require('pairs.test')
local b = require('pairs.bracket')

describe('unbalanced left bracket', function()
  before_each(function()
    require('pairs'):setup()
  end)

  after_each(function()
    vim.cmd('bdelete')
  end)

  it("Should complete the right bracket", function()
    t.init_buf('', 0, 0)
    b.type_left('(')
    t.check_buf('()', 0, 1)
  end)

  it("Should complete the right bracket", function()
    t.init_buf(')', 0, 1)
    b.type_left('(')
    t.check_buf(')()', 0, 2)
  end)

  it("Should complete the right bracket [M]", function()
    local input = [[
)

    ]]
    local expect = [[
)
()
    ]]
    t.init_buf(input, 1, 0)
    b.type_left('(')
    t.check_buf(expect, 1, 1)
  end)

  it("Should ignore escaped right bracket and complete the right bracket", function()
    t.init_buf('\\)', 0, 0)
    b.type_left('(')
    t.check_buf('()\\)', 0, 1)
  end)

  it("Should ignore escaped right bracket and complete the right bracket [M]", function()
    local input = [[

\)
    ]]
    local expect = [[
()
\)
    ]]
    t.init_buf(input, 0, 0)
    b.type_left('(')
    t.check_buf(expect, 0, 1)
  end)

  it("Should ignore right bracket in single quoted string and complete the right bracket", function()
    t.init_buf("')'", 0, 0)
    b.type_left('(')
    t.check_buf("()')'", 0, 1)
  end)

  it("Should ignore right bracket in single quoted string and complete the right bracket [M]", function()
    local input = [[

')'
    ]]
    local expect = [[
()
')'
    ]]
    t.init_buf(input, 0, 0)
    b.type_left('(')
    t.check_buf(expect, 0, 1)
  end)

  it("Should ignore right bracket in double quoted string and complete the right bracket", function()
    t.init_buf('")"', 0, 0)
    b.type_left('(')
    t.check_buf('()")"', 0, 1)
  end)

  it("Should ignore right bracket in double quoted string and complete the right bracket [M]", function()
    local input = [[

")"
    ]]
    local expect = [[
()
")"
    ]]
    t.init_buf(input, 0, 0)
    b.type_left('(')
    t.check_buf(expect, 0, 1)
  end)

  it("Should ignore custom pattern in lua and complete the right bracket", function()
    t.init_buf('%)', 0, 0, 'lua')
    b.type_left('(')
    t.check_buf('()%)', 0, 1)
  end)

  it("Should ignore custom pattern in lua and complete the right bracket [M]", function()
    local input = [[

%)
    ]]
    local expect = [[
()
%)
    ]]
    t.init_buf(input, 0, 0, 'lua')
    b.type_left('(')
    t.check_buf(expect, 0, 1)
  end)

  it("Should just typeset the left bracket", function()
    t.init_buf(')', 0, 0)
    b.type_left('(')
    t.check_buf('()', 0, 1)
  end)

  it("Should just typeset the left bracket [M]", function()
    local input = [[

)
    ]]
    local expect = [[
(
)
    ]]
    t.init_buf(input, 0, 0)
    b.type_left('(')
    t.check_buf(expect, 0, 1)
  end)

  it("Should ignore escaped left bracket and just typeset the left bracket", function()
    t.init_buf('\\()', 0, 0)
    b.type_left('(')
    t.check_buf('(\\()', 0, 1)
  end)

  it("Should ignore escaped left bracket and just typeset the left bracket [M]", function()
    local input = [[

\()
    ]]
    local expect = [[
(
\()
    ]]
    t.init_buf(input, 0, 0)
    b.type_left('(')
    t.check_buf(expect, 0, 1)
  end)

  it("Should ignore left bracket in single quoted string and just typeset the left bracket", function()
    t.init_buf("'(')", 0, 0)
    b.type_left('(')
    t.check_buf("('(')", 0, 1)
  end)

  it("Should ignore left bracket in single quoted string and just typeset the left bracket [M]", function()
    local input = [[

'(')
    ]]
    local expect = [[
(
'(')
    ]]
    t.init_buf(input, 0, 0)
    b.type_left('(')
    t.check_buf(expect, 0, 1)
  end)

  it("Should ignore left bracket in double quoted string and just typeset the left bracket", function()
    t.init_buf('"(")', 0, 0)
    b.type_left('(')
    t.check_buf('("(")', 0, 1)
  end)

  it("Should ignore left bracket in double quoted string and just typeset the left bracket [M]", function()
    local input = [[

"(")
    ]]
    local expect = [[
(
"(")
    ]]
    t.init_buf(input, 0, 0)
    b.type_left('(')
    t.check_buf(expect, 0, 1)
  end)

  it("Should ignore custom pattern in lua and just typeset the left bracket", function()
    t.init_buf('%))', 0, 0, 'lua')
    b.type_left('(')
    t.check_buf('(%))', 0, 1)
  end)

  it("Should ignore custom pattern in lua and just typeset theleft bracket [M]", function()
    local input = [[

%))
    ]]
    local expect = [[
(
%))
    ]]
    t.init_buf(input, 0, 0, 'lua')
    b.type_left('(')
    t.check_buf(expect, 0, 1)
  end)

  it("Should ignore prefix pattern and just typeset the left bracket", function()
    t.init_buf('\\', 0, 1, 'lua')
    b.type_left('(')
    t.check_buf('\\(', 0, 2)
  end)

  it("Should ignore custom prefix pattern and just typeset the left bracket", function()
    require('pairs'):setup{ default_opts = { ['*'] = { ignore_pre = '+' } } }
    t.init_buf('+', 0, 1)
    b.type_left('(')
    t.check_buf('+(', 0, 2)
  end)

  it("Should ignore custom postfix pattern and just typeset the left bracket", function()
    require('pairs'):setup{ default_opts = { ['*'] = { ignore_after = '+' } } }
    t.init_buf('+', 0, 0)
    b.type_left('(')
    t.check_buf('(+', 0, 1)
  end)
end)
