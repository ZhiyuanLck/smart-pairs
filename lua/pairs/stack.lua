---@class Stack
---@filed size
local Stack = {}
Stack.__index = Stack

--- creat a new stack
---@return Stack
function Stack.new()
  return setmetatable({size = 0}, Stack)
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

return Stack
