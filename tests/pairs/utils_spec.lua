local u = require('pairs.utils')

describe('Test utils.check_type:', function()
  it("should have no error", function()
    local var = 'string'
    assert.has_no.errors(function() u.check_type(var, 'string') end)
  end)

  it("should have no error", function()
    local var = nil
    assert.has_no.errors(function() u.check_type(var, 'nil') end)
  end)

  it("should have no error", function()
    local var = nil
    assert.has_no.errors(function() u.check_type(var, 'table', true) end)
  end)

  it("should have no error", function()
    local var = {}
    assert.has_no.errors(function() u.check_type(var, 'list') end)
  end)

  it("should have no error", function()
    local var = {1, 2}
    assert.has_no.errors(function() u.check_type(var, 'list') end)
  end)

  it("should have no error", function()
    local var = { a = 2 }
    assert.has_no.errors(function() u.check_type(var, 'table') end)
  end)

  it("should have error", function()
    local var = 'string'
    assert.has.errors(function() u.check_type(var, 'table') end)
  end)

  it("should have error", function()
    local var = nil
    assert.has.errors(function() u.check_type(var, 'table') end)
  end)

  it("should have error", function()
    local var = {}
    assert.has.errors(function() u.check_type(var, 'table') end)
  end)

  it("should have error", function()
    local var = {1, 2}
    assert.has.errors(function() u.check_type(var, 'table') end)
  end)

  it("should have error", function()
    local var = { a = 2 }
    assert.has.errors(function() u.check_type(var, 'list') end)
  end)
end)
