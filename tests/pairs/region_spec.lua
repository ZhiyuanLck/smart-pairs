local Region = require('pairs.region')

describe("Test class 'Region':", function()
  it("should have error when start is nil", function()
    assert.has.errors(function() Region.new({}) end)
  end)

  it("should have error when start is not string", function()
    assert.has.errors(function() Region.new{start = 2} end)
  end)

  it("should have error when finish is not string", function()
    assert.has.errors(function() Region.new{start = '', finish = {}} end)
  end)

  it("should have error when cross_line is not boolean", function()
    assert.has.errors(function() Region.new{start = '', cross_line = 2} end)
  end)

  it("should have error when priority is not number", function()
    assert.has.errors(function() Region.new{start = '', priority = ''} end)
  end)

  it("cross_line should be false if finish is nil", function()
    assert.is_not_true(Region.new{start = ''}.cross_line)
  end)

  it("cross_line should be false if start is equal to finish", function()
    assert.is_not_true(Region.new{start = 'a', finish = 'a'}.cross_line)
  end)

  it("cross_line should be true if start is not equal to finish", function()
    assert.is_true(Region.new{start = 'a', finish = 'b'}.cross_line)
  end)

  it("priority should be 0", function()
    assert.are.same(0, Region.new{start = ''}.priority)
  end)

  it("explicit options should be set", function()
    local region = {
      start = '(',
      finish = ')',
      cross_line = false,
      priority = 10
    }
    local expected = vim.deepcopy(region)
    expected.estart = '%('
    expected.efinish = '%)'
    assert.are.same(expected, Region.new(region))
  end)
end)
