local conf = require('pairs.config')

describe('Test configuration:', function()
  it("should use the default html pairs", function()
    local config = conf.get_config()
    assert.are.same('<', config.pairs.html[1].left)
    assert.are.same('>', config.pairs.html[1].right)
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
  end)
end)
