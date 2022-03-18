local Stack = require('pairs.stack')

describe('pairs.Stack', function()
  it('should have error when stack is empty', function()
    local st = Stack.new()
    assert.has.errors(function() st:pop() end)
    assert.has.errors(function() st:top() end)
  end)

  it('should work well', function()
    local st = Stack.new()
    assert.is_true(st:empty())

    st:push(1)
    assert.is_not_true(st:empty())
    assert.are.same(1, st[1])
    assert.are.same(1, st:top())

    st:push('a')
    assert.is_not_true(st:empty())
    assert.are.same('a', st[2])
    assert.are.same('a', st:top())

    assert.are.same('a', st:pop())
    assert.is_not_true(st:empty())
    assert.are.same(1, st:top())

    assert.are.same(1, st:pop())
    assert.is_true(st:empty())
  end)
end)
