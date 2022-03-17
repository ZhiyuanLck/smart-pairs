local Pairs = require('pairs')

describe('Pairs.get_pair', function()
  it("should have error when opts is not set", function()
    Pairs.setup()
    assert.has.errors(function() Pairs:get_pair() end)
  end)

  it("should have error when bracket not exists", function()
    Pairs.setup()
    assert.has.errors(function() Pairs:get_pair{left = '-'} end)
    assert.has.errors(function() Pairs:get_pair{right = '-'} end)
  end)
end)
