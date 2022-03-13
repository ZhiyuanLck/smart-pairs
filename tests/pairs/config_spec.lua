local conf = require('pairs.config')
local Pairs = require('pairs')

describe('Test configuration of pairs:', function()
  it("should use the default html pairs", function()
    local config = conf.get_config()
    assert.are.same('<', config.pairs.html[1].left)
    assert.are.same('>', config.pairs.html[1].right)

    Pairs.setup()
    assert.are.same('<', Pairs.pairs.html[1].left)
    assert.are.same('>', Pairs.pairs.html[1].right)
  end)

  it("custom html pairs should overwrite the default", function()
    local user_config = {
      pairs = {
        html = { {'a', 'b'} }
      }
    }
    local config = conf.get_config(user_config)
    assert.are.same('a', config.pairs.html[1].left)
    assert.are.same('b', config.pairs.html[1].right)

    Pairs.setup(user_config)
    assert.are.same('a', Pairs.pairs.html[1].left)
    assert.are.same('b', Pairs.pairs.html[1].right)
  end)

  it("custom html pairs should be added", function()
    local user_config = {
      pairs = {
        rust = { {'a', 'b'} }
      }
    }
    local config = conf.get_config(user_config)
    assert.are.same('a', config.pairs.rust[1].left)
    assert.are.same('b', config.pairs.rust[1].right)

    Pairs.setup(user_config)
    assert.are.same('a', Pairs.pairs.rust[1].left)
    assert.are.same('b', Pairs.pairs.rust[1].right)
  end)

  it("global pairs should be merged into the pairs of current file type", function()
    local user_config = {
      pairs = {
        ['*'] = { {'a', 'b'} },
        lua = { {'+', '+'} }
      }
    }
    local config = conf.get_config(user_config)
    assert.are.same('a', config.pairs.lua[2].left)
    assert.are.same('b', config.pairs.lua[2].right)

    Pairs.setup(user_config)
    assert.are.same('a', Pairs.pairs.lua[2].left)
    assert.are.same('b', Pairs.pairs.lua[2].right)
  end)

  it("global pairs should not overwrite the local one when left pairs are same", function()
    local user_config = {
      pairs = {
        ['*'] = { {'a', 'b'} },
        lua = { {'a', '+'} }
      }
    }
    local config = conf.get_config(user_config)
    assert.are.same('a', config.pairs.lua[1].left)
    assert.are.same('+', config.pairs.lua[1].right)

    Pairs.setup(user_config)
    assert.are.same('a', Pairs.pairs.lua[1].left)
    assert.are.same('+', Pairs.pairs.lua[1].right)
  end)

  it("global pairs should not overwrite the local one when right pairs are same", function()
    local user_config = {
      pairs = {
        ['*'] = { {'a', 'b'} },
        lua = { {'+', 'b'} }
      }
    }
    local config = conf.get_config(user_config)
    assert.are.same('+', config.pairs.lua[1].left)
    assert.are.same('b', config.pairs.lua[1].right)

    Pairs.setup(user_config)
    assert.are.same('+', Pairs.pairs.lua[1].left)
    assert.are.same('b', Pairs.pairs.lua[1].right)
  end)
end)
