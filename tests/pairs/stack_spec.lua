local Stack = require('pairs.stack')

describe('pairs.Stack', function()
  it('should have error when stack is empty', function()
    local st = Stack.new()
    assert.has.errors(function() st:pop() end)
    assert.has.errors(function() st:top() end)
  end)

  it('should create from a list', function()
    local st1 = Stack.new()
    st1:push('a')
    st1:push('b')
    local st2 = Stack.new{'a', 'b'}
    assert.is_true(st1 == st2)
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

  it('equality', function()
    local st1 = Stack.new()
    local st2 = Stack.new()
    st1:push('a')
    st1:push('b')
    st2:push('a')
    assert.is_not_true(st1 == st2)
    st2:push('b')
    assert.is_true(st1 == st2)
  end)

  it('equality', function()
    local st = Stack.new{'a', 'b'}
    st:clear()
    assert.is_true(st:empty())
  end)
end)
