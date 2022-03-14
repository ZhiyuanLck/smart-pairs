local u = require('pairs.utils')

---@class Pair @pair
---@field left string @left pair
---@field right string @right pair
local Pair = {}

--- create a new pair object
---@param pair table
---@return table
function Pair.new(pair)
  u.check_type(pair, 'list')

  local item_count = #pair
  if item_count < 2 then
    error('pair list must have at least 2 items to specify the left and right pairs')
  end

  local obj = { left = pair[1], right = pair[2] }
  u.check_type(obj.left, 'string')
  u.check_type(obj.right, 'string')
  u.check_type(pair[3], 'table', true)

  for k, v in pairs(pair[3] or {}) do
    obj[k] = v
  end

  return setmetatable(obj, Pair)
end

return Pair
