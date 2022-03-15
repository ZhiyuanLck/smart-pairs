local Pairs = require('pairs')

describe('Test Pairs method get_pair:', function()
  it("should have error when opts is not set", function()
    Pairs.setup()
    assert.has.errors(function() Pairs:get_pair() end)
  end)

  it("should have error when bracket not exists", function()
    Pairs.setup()
    assert.has.errors(function() Pairs:get_pair{left = '-'} end)
    assert.has.errors(function() Pairs:get_pair{right = '-'} end)
  end)

  it("should get correct pair", function()
    Pairs.setup()
    local pair = {'(', ')', left = '(', right = ')', eleft = '%(', eright = '%)'}
    assert.are.same(pair, Pairs:get_pair{left = '('})
    assert.are.same(pair, Pairs:get_pair{right = ')'})
    vim.bo.ft = 'markdown'
    pair = {'`', '`', left = '`', right = '`', eleft = '`', eright = '`', triplet = true}
    assert.are.same(pair, Pairs:get_pair{left = '`'})
    assert.are.same(pair, Pairs:get_pair{right = '`'})
  end)
end)
