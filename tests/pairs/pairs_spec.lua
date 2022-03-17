local Pairs = require('pairs')

describe('Pairs.get_pair', function()
  it("should have error when bracket is not string", function()
    Pairs.setup()
    assert.has.errors(function() Pairs:get_pair(2) end)
  end)

  it("should have error when bracket not exists", function()
    Pairs.setup()
    assert.has.errors(function() Pairs:get_pair('a') end)
  end)

  it("should get correct pair", function()
    Pairs.setup{
      pairs = {
        c = {
          {'//'},
          {'(', ')'},
          {'[', ']'}
        }
      }
    }
    vim.bo.ft = 'c'
    assert.are.same(')', Pairs:get_pair('(').right)
    assert.are.same('[', Pairs:get_pair(']').left)
    assert.are.same('//', Pairs:get_pair('//').left)
  end)
end)
