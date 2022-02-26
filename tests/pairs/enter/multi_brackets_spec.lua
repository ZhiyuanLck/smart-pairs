local t = require('pairs.test')
local e = require('pairs.enter')

describe('enter with no indent', function()
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
{
  {
    {}}}
    ]]
    local expect = [[
{
  {
    {
      
    }}}
    ]]
    t.set_buf(input, 2, 5)
    e.type()
    t.check_buf(expect, 3, 6)
  end)

  it("Should break two lines", function()
    local input = [[
{
  {
    {}}}
    ]]
    local expect = [[
{
  {
    {}
    
  }}
    ]]
    t.set_buf(input, 2, 6)
    e.type()
    t.check_buf(expect, 3, 4)
  end)

  it("Should break two lines", function()
    local input = [[
{
  {
    {}}}
    ]]
    local expect = [[
{
  {
    {}}
  
}
    ]]
    t.set_buf(input, 2, 7)
    e.type()
    t.check_buf(expect, 3, 2)
  end)

  it("Should break two lines", function()
    local input = [[
{
  {
    {a}}}
    ]]
    local expect = [[
{
  {
    {a
      
    }}}
    ]]
    t.set_buf(input, 2, 6)
    e.type()
    t.check_buf(expect, 3, 6)
  end)
end)
