local u = require('pairs.utils')
local t = require('pairs.test')
local api = vim.api
local fmt = string.format

describe('Test utils.check_type:', function()
  it("should have no error (string, string)", function()
    assert.has_no.errors(function() u.check_type('', 'string') end)
  end)

  it("should have no error (nil, nil)", function()
    assert.has_no.errors(function() u.check_type(nil, 'nil') end)
  end)

  it("should have no error (nil, table, true)", function()
    assert.has_no.errors(function() u.check_type(nil, 'table', true) end)
  end)

  it("should have no error ({}, list)", function()
    assert.has_no.errors(function() u.check_type({}, 'list') end)
  end)

  it("should have no error (list, list)", function()
    assert.has_no.errors(function() u.check_type({1, 2}, 'list') end)
  end)

  it("should have no error (table, table)", function()
    assert.has_no.errors(function() u.check_type({a = 2}, 'table') end)
  end)

  it("should have error (string, table)", function()
    assert.has.errors(function() u.check_type('', 'table') end)
  end)

  it("should have error (nil, table)", function()
    assert.has.errors(function() u.check_type(nil, 'table') end)
  end)

  it("should have error ({}, table)", function()
    assert.has.errors(function() u.check_type({}, 'table') end)
  end)

  it("should have error (list, table)", function()
    assert.has.errors(function() u.check_type({1, 2}, 'table') end)
  end)

  it("should have error (table, list)", function()
    assert.has.errors(function() u.check_type({ a = 2}, 'list') end)
  end)

  it("should have error (string, number, true)", function()
    assert.has.errors(function() u.check_type('', 'number', true) end)
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

describe([[Test 'utils.if_nil':]], function()
  it("should return the original value", function()
    assert.are.same(2, u.if_nil(2, 1))
  end)

  it("should return the default value", function()
    assert.are.same(1, u.if_nil(nil, 1))
  end)
end)

describe("Test 'utils.escape':", function()
  it("should escape special chars", function()
    local text = '%()[].*+-?{}^$'
    assert.are.same(text, text:match(u.escape(text)))
  end)
end)
