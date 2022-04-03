local u = require('pairs.utils')
local t = require('pairs.test')
local api = vim.api

describe('utils.check_type', function()
  it("should have no error (string, string)", function()
    assert.has_no.errors(function() u.check_type('', 'string') end)
  end)

  it("should have no error (nil, nil)", function()
    assert.has_no.errors(function() u.check_type(nil, 'nil') end)
  end)

  it("should have no error (nil, table, true)", function()
    assert.has_no.errors(function() u.check_type(nil, 'table', '', true) end)
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
    assert.has.errors(function() u.check_type('', 'number', '', true) end)
  end)

  it("should have correct error message", function()
    assert.has_error(function()
      u.check_type('', 'number', 'n')
    end, "expect n to have type number, but get type string of value ")
    assert.has_error(function()
      u.check_type(2, 'string', '')
    end, "expect type string, but get type number of value 2")
  end)
end)

describe('utils.get_cursor', function()
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

describe('utils.set_default_val', function()
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

describe('utils.if_nil', function()
  it("should return the original value", function()
    assert.are.same(2, u.if_nil(2, 1))
  end)

  it("should return the default value", function()
    assert.are.same(1, u.if_nil(nil, 1))
    assert.is_true(u.if_nil(nil, true))
    assert.is_not_true(u.if_nil(nil, false))
  end)
end)

describe('utils.escape', function()
  it("should escape special chars", function()
    local text = '%()[].*+-?{}^$'
    assert.are.same(text, text:match(u.escape(text)))
  end)
end)

describe('utils.get_line', function()
  t.init_buf()
  t.set_buf([[
first line
second line
  ]], 0, 0)

  it("should escape special chars", function()
    assert.are.same('first line', u.get_line(0))
    assert.are.same('second line', u.get_line(1))
  end)

  api.nvim_buf_delete(0, {force = true})
end)