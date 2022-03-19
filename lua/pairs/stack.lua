---@class Stack
---@field size number
local Stack = {}
Stack.__index = Stack

--- creat a new stack
---@param list any[]
---@return Stack
function Stack.new(list)
  list = list or {}
  list.size = #list
  return setmetatable(list, Stack)
end

--- push data to stack
---@param data any
function Stack:push(data)
  self.size = self.size + 1
  self[self.size] = data
end

--- pop the top item and return it
---@return any
function Stack:pop()
  if self.size == 0 then
    error('cannot pop from an empty stack')
  end
  local item = self[self.size]
  self.size = self.size - 1
  return item
end

--- get the top item of the stack
---@return any
function Stack:top()
  if self.size == 0 then
    error('cannot get the top item from an empty stack')
  end
  return self[self.size]
end

--- test whether the stack is empty
---@return boolean
function Stack:empty()
  return self.size == 0
end

--- clear the stack
function Stack:clear()
  self.size = 0
end

function Stack.__eq(st1, st2)
  if st1.size ~= st2.size then return false end
  for i = 1, st1.size do
    if st1[i] ~= st2[i] then return false end
  end
  return true
end

return Stack
