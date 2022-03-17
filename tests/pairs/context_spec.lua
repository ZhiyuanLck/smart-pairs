local Pairs = require('pairs')
local Context = require('pairs.context')
local t = require('pairs.test')
local api = vim.api

describe('Context.new', function()
  before_each(function()
    t.init_buf()
  end)

  after_each(function()
    api.nvim_buf_delete(0, {force = true})
  end)

  it("should set correct value of general member", function()
    t.set_buf('test', 0, 2)
    Pairs.setup()
    local ctx = Context.new()
    assert.are.same(0, ctx.cur_line_idx)
    assert.are.same(0, ctx.line_idx)
    assert.are.same(0, ctx.min_idx)
    assert.are.same(0, ctx.max_idx)
    assert.are.same(Pairs.max_search_lines, ctx.max_search_lines)
    assert.are.same(0, ctx.searched_lines)
    assert.is_true(ctx.search_up)
    assert.are.same(2, ctx.cur_col_idx)
    assert.are.same('test', ctx.cur_line)
    assert.are.same('te', ctx.cur_left)
    assert.are.same('st', ctx.cur_right)
  end)

  it("should set correct value of general member [Chinese character]", function()
    -- strlen('【') = 3
    t.set_buf('【】', 0, 3)
    local ctx = Context.new()
    assert.are.same(0, ctx.cur_line_idx)
    assert.are.same(3, ctx.cur_col_idx)
    assert.are.same('【】', ctx.cur_line)
    assert.are.same('【', ctx.cur_left)
    assert.are.same('】', ctx.cur_right)
  end)
end)

describe('Counter', function()
  it("should create a new counter", function()
    local ctn = Context.new_counter()
    assert.are.same(0, ctn.real)
    assert.are.same(0, ctn.valid)
  end)

  it("should create a new counter from another counter", function()
    local other = Context.new_counter{real = 2, valid = 3}
    local ctn = Context.new_counter(other)
    assert.are.same(2, ctn.real)
    assert.are.same(3, ctn.valid)
  end)

  it("should increase the value", function()
    local ctn = Context.new_counter{real = 1, valid = 2}
    ctn:incr()
    assert.are.same(2, ctn.real)
    assert.are.same(3, ctn.valid)
  end)

  it("should decrease the value", function()
    local ctn = Context.new_counter{real = 0, valid = 1}
    ctn:decr()
    assert.are.same(-1, ctn.real)
    assert.are.same(0, ctn.valid)
    ctn:decr()
    assert.are.same(-2, ctn.real)
    assert.are.same(0, ctn.valid)
  end)
end)

describe('Context:stop', function()
  before_each(function()
    t.init_buf()
    t.set_buf('a\nb\nc', 1, 1)
    Pairs.setup()
  end)

  after_each(function()
    api.nvim_buf_delete(0, {force = true})
  end)

  it("should stop", function()
    local ctx = Context.new()
    ctx.line_idx = 5
    assert.is_true(ctx:stop())
    ctx.line_idx = -1
    assert.is_true(ctx:stop())
    ctx.searched_lines = 600
    assert.is_true(ctx:stop())
  end)

  it("should not stop", function()
    local ctx = Context.new()
    ctx.line_idx = 0
    assert.is_not_true(ctx:stop())
    ctx.line_idx = 2
    assert.is_not_true(ctx:stop())
    ctx.searched_lines = 400
    assert.is_not_true(ctx:stop())
  end)
end)

describe('Context:switch', function()
  before_each(function()
    t.init_buf()
    t.set_buf('a\nb\nc', 1, 1)
    Pairs.setup()
  end)

  after_each(function()
    api.nvim_buf_delete(0, {force = true})
  end)

  it("should switch the direction", function()
    local ctx = Context.new()
    ctx.line_idx = 0
    ctx.searched_lines = 1
    ctx:switch()
    assert.are.same(1, ctx.line_idx)
    assert.are.same(0, ctx.searched_lines)
    assert.is_not_true(ctx.search_up)
    assert.is_nil(ctx.last_ctn)
  end)
end)

describe('Context:get_line', function()
  before_each(function()
    t.init_buf()
    t.set_buf('a\nbc\nd', 1, 1)
    Pairs.setup()
  end)

  after_each(function()
    api.nvim_buf_delete(0, {force = true})
  end)

  it("should get correct lines", function()
    local ctx = Context.new()

    assert.are.same('b', ctx:get_line())
    assert.are.same(0, ctx.line_idx)
    assert.are.same(1, ctx.searched_lines)

    assert.are.same('a', ctx:get_line())
    assert.are.same(-1, ctx.line_idx)
    assert.are.same(2, ctx.searched_lines)

    ctx:switch()

    assert.are.same('c', ctx:get_line())
    assert.are.same(2, ctx.line_idx)
    assert.are.same(1, ctx.searched_lines)

    assert.are.same('d', ctx:get_line())
    assert.are.same(3, ctx.line_idx)
    assert.are.same(2, ctx.searched_lines)
  end)
end)

-- describe('Context.count_left', function()
--   it("should get zero count", function()
--     local text = '[text]'
--     local ctn = Context.count_left(text, '[', ']')
--     assert.are.same(0, ctn.real)
--     assert.are.same(0, ctn.valid)
--     text = '【测试】'
--     ctn = Context.count_left(text, '【', '】')
--     assert.are.same(0, ctn.real)
--     assert.are.same(0, ctn.valid)
--   end)

--   it("should get positive count", function()
--     local text = '[[text]'
--     local ctn = Context.count_left(text, '[', ']')
--     assert.are.same(1, ctn.real)
--     assert.are.same(1, ctn.valid)
--     text = '【【测试】'
--     ctn = Context.count_left(text, '【', '】')
--     assert.are.same(1, ctn.real)
--     assert.are.same(1, ctn.valid)
--   end)

--   it("should get negative count", function()
--     local text = '[text]]'
--     local ctn = Context.count_left(text, '[', ']')
--     assert.are.same(-1, ctn.real)
--     assert.are.same(0, ctn.valid)
--     text = '【测试】】'
--     ctn = Context.count_left(text, '【', '】')
--     assert.are.same(-1, ctn.real)
--     assert.are.same(0, ctn.valid)
--   end)

--   it("should get continuous count", function()
--     local ctn = Context.count_left('', '[', ']')
--     ctn = Context.count_left('[', '[', ']', ctn)
--     assert.are.same(1, ctn.real)
--     assert.are.same(1, ctn.valid)
--     ctn = Context.count_left('text]', '[', ']', ctn)
--     assert.are.same(0, ctn.real)
--     assert.are.same(0, ctn.valid)
--     ctn = Context.count_left('text]', '[', ']', ctn)
--     assert.are.same(-1, ctn.real)
--     assert.are.same(0, ctn.valid)

--     ctn = Context.count_left('', '【', '】')
--     ctn = Context.count_left('【', '【', '】', ctn)
--     assert.are.same(1, ctn.real)
--     assert.are.same(1, ctn.valid)
--     ctn = Context.count_left('测试】', '【', '】', ctn)
--     assert.are.same(0, ctn.real)
--     assert.are.same(0, ctn.valid)
--     ctn = Context.count_left('测试】', '【', '】', ctn)
--     assert.are.same(-1, ctn.real)
--     assert.are.same(0, ctn.valid)
--   end)
-- end)

-- describe('Context.count_right', function()
--   it("should get zero count", function()
--     local text = '[text]'
--     local ctn = Context.count_right(text, '[', ']')
--     assert.are.same(0, ctn.real)
--     assert.are.same(0, ctn.valid)
--     text = '【测试】'
--     ctn = Context.count_right(text, '【', '】')
--     assert.are.same(0, ctn.real)
--     assert.are.same(0, ctn.valid)
--   end)

--   it("should get positive count", function()
--     local text = '[text]]'
--     local ctn = Context.count_right(text, '[', ']')
--     assert.are.same(1, ctn.real)
--     assert.are.same(1, ctn.valid)
--     text = '【测试】】'
--     ctn = Context.count_right(text, '【', '】')
--     assert.are.same(1, ctn.real)
--     assert.are.same(1, ctn.valid)
--   end)

--   it("should get negative count", function()
--     local text = '[[text]'
--     local ctn = Context.count_right(text, '[', ']')
--     assert.are.same(-1, ctn.real)
--     assert.are.same(0, ctn.valid)
--     text = '【【测试】'
--     ctn = Context.count_right(text, '【', '】')
--     assert.are.same(-1, ctn.real)
--     assert.are.same(0, ctn.valid)
--   end)

--   it("should get continuous count", function()
--     local ctn = Context.count_right('', '[', ']')
--     ctn = Context.count_right(']', '[', ']', ctn)
--     assert.are.same(1, ctn.real)
--     assert.are.same(1, ctn.valid)
--     ctn = Context.count_right('[text', '[', ']', ctn)
--     assert.are.same(0, ctn.real)
--     assert.are.same(0, ctn.valid)
--     ctn = Context.count_right('[text', '[', ']', ctn)
--     assert.are.same(-1, ctn.real)
--     assert.are.same(0, ctn.valid)

--     ctn = Context.count_right('', '【', '】')
--     ctn = Context.count_right('】', '【', '】', ctn)
--     assert.are.same(1, ctn.real)
--     assert.are.same(1, ctn.valid)
--     ctn = Context.count_right('【测试', '【', '】', ctn)
--     assert.are.same(0, ctn.real)
--     assert.are.same(0, ctn.valid)
--     ctn = Context.count_right('【测试', '【', '】', ctn)
--     assert.are.same(-1, ctn.real)
--     assert.are.same(0, ctn.valid)
--   end)
-- end)

-- describe('Context.count_bracket', function()
--   it("should get correct count of single char", function()
--     assert.are.same(0, Context.count_bracket('', '"'))
--     assert.are.same(0, Context.count_bracket('text', '"'))
--     assert.are.same(2, Context.count_bracket('"text"', '"'))
--     assert.are.same(2, Context.count_bracket('"测试"', '"'))
--   end)

--   it("should get correct count of multiple char", function()
--     assert.are.same(0, Context.count_bracket('', '""""'))
--     assert.are.same(1, Context.count_bracket('"""', '"""'))
--     assert.are.same(1, Context.count_bracket('""""', '"""'))
--     assert.are.same(2, Context.count_bracket('""""""', '"""'))
--   end)
-- end)
