local u = require('pairs.utils')
local t = require('pairs.test')
local api = vim.api

describe('Test utils.check_type:', function()
  it("should have no error (string, string)", function()
    local var = 'string'
    assert.has_no.errors(function() u.check_type(var, 'string') end)
  end)

  it("should have no error (nil, nil)", function()
    local var = nil
    assert.has_no.errors(function() u.check_type(var, 'nil') end)
  end)

  it("should have no error (nil, table, true)", function()
    local var = nil
    assert.has_no.errors(function() u.check_type(var, 'table', true) end)
  end)

  it("should have no error ({}, list)", function()
    local var = {}
    assert.has_no.errors(function() u.check_type(var, 'list') end)
  end)

  it("should have no error (list, list)", function()
    local var = {1, 2}
    assert.has_no.errors(function() u.check_type(var, 'list') end)
  end)

  it("should have no error (table, table)", function()
    local var = { a = 2 }
    assert.has_no.errors(function() u.check_type(var, 'table') end)
  end)

  it("should have error (string, table)", function()
    local var = 'string'
    assert.has.errors(function() u.check_type(var, 'table') end)
  end)

  it("should have error (nil, table)", function()
    local var = nil
    assert.has.errors(function() u.check_type(var, 'table') end)
  end)

  it("should have error ({}, table)", function()
    local var = {}
    assert.has.errors(function() u.check_type(var, 'table') end)
  end)

  it("should have error (list, table)", function()
    local var = {1, 2}
    assert.has.errors(function() u.check_type(var, 'table') end)
  end)

  it("should have error (table, list)", function()
    local var = { a = 2 }
    assert.has.errors(function() u.check_type(var, 'list') end)
  end)
end)

describe('Test utils.get_cursor:', function()
  before_each(function()
    t.init_buf()
  end)

  after_each(function()
    api.nvim_buf_delete(0, {force = true})
  end)

  it("should set correct cursor", function()
    t.set_buf('test', 0, 2)
    assert.are.same({0, 2}, u.get_cursor())
    local text = [[
test
abc
    ]]
    t.set_buf(text, 1, 2)
    assert.are.same({1, 2}, u.get_cursor())
  end)
end)

describe('Test utils.set_default_val:', function()
  it("should set the default value", function()
    local tbl = {}
    u.set_default_val(tbl, 'a', 1)
    assert.are.same(1, tbl.a)
  end)

  it("should do nothing", function()
    local tbl = {a = 2}
    u.set_default_val(tbl, 'a', 1)
    assert.are.same(2, tbl.a)
  end)
end)
