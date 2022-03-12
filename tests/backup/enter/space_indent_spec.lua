local t = require('pairs.test')
local e = require('pairs.enter')

describe('enter with space indent', function()
  before_each(function()
    t.init_buf()
    vim.bo.et = true
    vim.bo.sw = 2
    require('pairs'):setup()
  end)

  after_each(function()
    vim.cmd('bdelete')
  end)

  it("Should break two lines", function()
    local input = [[
{}
    ]]
    local expect = [[
{
  
}
    ]]
    t.set_buf(input, 0, 1)
    e.type()
    t.check_buf(expect, 1, 2)
  end)

  it("Should break two lines without extra spaces", function()
    local input = [[
{  }
    ]]
    local expect = [[
{
  
}
    ]]
    t.set_buf(input, 0, 2)
    e.type()
    t.check_buf(expect, 1, 2)
  end)

  it("Should break two lines", function()
    local input = [[
  {}
    ]]
    local expect = [[
  {
    
  }
    ]]
    t.set_buf(input, 0, 3)
    e.type()
    t.check_buf(expect, 1, 4)
  end)

  it("Should break two lines without extra spaces", function()
    local input = [[
  {  }
    ]]
    local expect = [[
  {
    
  }
    ]]
    t.set_buf(input, 0, 4)
    e.type()
    t.check_buf(expect, 1, 4)
  end)

  it("Should break two lines", function()
    local input = [[
{text}
    ]]
    local expect = [[
{text
  
}
    ]]
    t.set_buf(input, 0, 5)
    e.type()
    t.check_buf(expect, 1, 2)
  end)

  it("Should break two lines without extra spaces", function()
    local input = [[
{text  }
    ]]
    local expect = [[
{text
  
}
    ]]
    t.set_buf(input, 0, 6)
    e.type()
    t.check_buf(expect, 1, 2)
  end)

  it("Should break two lines", function()
    local input = [[
  {text}
    ]]
    local expect = [[
  {text
    
  }
    ]]
    t.set_buf(input, 0, 7)
    e.type()
    t.check_buf(expect, 1, 4)
  end)

  it("Should break two lines without extra spaces", function()
    local input = [[
  {text  }
    ]]
    local expect = [[
  {text
    
  }
    ]]
    t.set_buf(input, 0, 8)
    e.type()
    t.check_buf(expect, 1, 4)
  end)

  it("Should break one line", function()
    local input = [[
{
    ]]
    local expect = [[
{
  
    ]]
    t.set_buf(input, 0, 1)
    e.type()
    t.check_buf(expect, 1, 2)
  end)

  it("Should break one line without extra spaces", function()
    local input = [[
{ 
    ]]
    local expect = [[
{
  
    ]]
    t.set_buf(input, 0, 2)
    e.type()
    t.check_buf(expect, 1, 2)
  end)

  it("Should break one line", function()
    local input = [[
  {
    ]]
    local expect = [[
  {
    
    ]]
    t.set_buf(input, 0, 3)
    e.type()
    t.check_buf(expect, 1, 4)
  end)

  it("Should break one line without extra spaces", function()
    local input = [[
  { 
    ]]
    local expect = [[
  {
    
    ]]
    t.set_buf(input, 0, 4)
    e.type()
    t.check_buf(expect, 1, 4)
  end)

  it("Should break one line", function()
    local input = [[
{text
    ]]
    local expect = [[
{text
  
    ]]
    t.set_buf(input, 0, 5)
    e.type()
    t.check_buf(expect, 1, 2)
  end)

  it("Should break one line", function()
    local input = [[
  {text
    ]]
    local expect = [[
  {text
    
    ]]
    t.set_buf(input, 0, 7)
    e.type()
    t.check_buf(expect, 1, 4)
  end)

  it("Should break one line without extra spaces", function()
    local input = [[
{text 
    ]]
    local expect = [[
{text
  
    ]]
    t.set_buf(input, 0, 6)
    e.type()
    t.check_buf(expect, 1, 2)
  end)

  it("Should break one line without extra spaces", function()
    local input = [[
  {text 
    ]]
    local expect = [[
  {text
    
    ]]
    t.set_buf(input, 0, 8)
    e.type()
    t.check_buf(expect, 1, 4)
  end)

  it("Should break one line", function()
    local input = [[
{ab}
    ]]
    local expect = [[
{a
  b}
    ]]
    t.set_buf(input, 0, 2)
    e.type()
    t.check_buf(expect, 1, 2)
  end)

  it("Should break one line", function()
    local input = [[
  {ab}
    ]]
    local expect = [[
  {a
    b}
    ]]
    t.set_buf(input, 0, 4)
    e.type()
    t.check_buf(expect, 1, 4)
  end)

  it("Should break one line without extra spaces", function()
    local input = [[
{a  b}
    ]]
    local expect = [[
{a
  b}
    ]]
    t.set_buf(input, 0, 3)
    e.type()
    t.check_buf(expect, 1, 2)
  end)

  it("Should break one line without extra spaces", function()
    local input = [[
  {a  b}
    ]]
    local expect = [[
  {a
    b}
    ]]
    t.set_buf(input, 0, 5)
    e.type()
    t.check_buf(expect, 1, 4)
  end)
end)
