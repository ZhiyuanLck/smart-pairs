local Pair = require('pairs.pair')

describe('Test class Pair:', function()
  it("should have error when pair has only one item", function()
    local pair = { 'a' }
    assert.has.errors(function() Pair.new(pair) end)
  end)

  it("should have error when pair's first item is not string", function()
    local pair = { 2, 'b' }
    assert.has.errors(function() Pair.new(pair) end)
  end)

  it("should have error when pair's second item is not string", function()
    local pair = { 'a', 2 }
    assert.has.errors(function() Pair.new(pair) end)
  end)

  it("should have no error when pair has no option", function()
    local pair = { 'a', 'b' }
    assert.has_no.errors(function() Pair.new(pair) end)
    pair = { left = 'a', right = 'b' }
    assert.has_no.errors(function() Pair.new(pair) end)
  end)

  it("should set the escaped pair", function()
    local pair = Pair.new{ '(', ')' }
    assert.are.same('%(', pair.eleft)
    assert.are.same('%)', pair.eright)
  end)

  it("should copy the options", function()
    local pair = { 'a', 'b', ignore_pre = 'test' }
    pair = Pair.new(pair)
    assert.are.same('test', pair.ignore_pre)
  end)
end)
