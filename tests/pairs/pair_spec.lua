local Pair = require('pairs.pair')

describe("Test fields of class | Pair >", function()
  describe("is_pair |", function()
    it("should have default value true", function()
      assert.is_true(Pair.new{'[', ']'}.is_pair)
    end)

    it("should be set", function()
      assert.is_not_true(Pair.new{'[', ']', is_pair = false}.is_pair)
    end)

    it("should get error when is not boolean", function()
      assert.has.errors(function() Pair.new{'[', ']', is_pair = 2} end)
    end)
  end)

  describe("left |", function()
    it("should be set", function()
      assert.are.same('[', Pair.new{'[', ']'}.left)
      assert.are.same('[', Pair.new{left = '[', right = ']'}.left)
    end)

    it("should get error when is nil", function()
      assert.has.errors(function() Pair.new{nil, ']'} end)
    end)

    it("should get error when is not string", function()
      assert.has.errors(function() Pair.new{2, ']'} end)
    end)
  end)

  describe("right |", function()
    it("should be set", function()
      assert.are.same(']', Pair.new{'[', ']'}.right)
      assert.are.same(']', Pair.new{left = '[', right = ']'}.right)
    end)

    it("should get error when is nil and is_pair is true", function()
      assert.has.errors(function() Pair.new{'['} end)
    end)

    it("should be nil when is_pair is false", function()
      assert.is_nil(Pair.new{'[', is_pair = false}.right)
    end)

    it("should get error when is not string", function()
      assert.has.errors(function() Pair.new{'[', 2} end)
    end)
  end)

  describe("skip |", function()
    it("should have default value 0", function()
      assert.are.same(0, Pair.new{'[', ']'}.skip)
    end)

    it("should be set", function()
      assert.are.same(2, Pair.new{'[', ']', skip = 2}.skip)
    end)

    it("should get error when is not number", function()
      assert.has.errors(function() Pair.new{'[', ']', skip = ''} end)
    end)
  end)

  describe("is_skip |", function()
    it("should be true", function()
      assert.is_true(Pair.new{'[', ']', skip = 2}.is_skip)
    end)

    it("should be false", function()
      assert.is_not_true(Pair.new{'[', ']', skip = 0}.is_skip)
    end)
  end)

  describe("eleft, eright |", function()
    it("should set the escaped pair", function()
      local pair = Pair.new{ '(', ')' }
      assert.are.same('%(', pair.eleft)
      assert.are.same('%)', pair.eright)
    end)
  end)

  describe("ignore opts |", function()
    it("should have error when is not list", function()
      assert.has.errors(function()
        Pair.new{
          '[', ']', ignore = { a = 2 }
        }
      end)
      assert.has.errors(function()
        Pair.new{
          '[', ']', ignore_left = { a = 2 }
        }
      end)
      assert.has.errors(function()
        Pair.new{
          '[', ']', ignore_right = { a = 2 }
        }
      end)
    end)

    it("should be set", function()
      assert.are.same({'a', 'b'}, Pair.new{ '[', ']', ignore = { 'a', 'b' } }.ignore)
      assert.are.same({'a', 'b'}, Pair.new{ '[', ']', ignore_left = { 'a', 'b' } }.ignore_left)
      assert.are.same({'a', 'b'}, Pair.new{ '[', ']', ignore_right = { 'a', 'b' } }.ignore_right)
    end)
  end)
end)
