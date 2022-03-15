local u = require('pairs.utils')

---@class Pair @pair
---@field left string @left pair
---@field eleft string @escaped left pair
---@field right string @right pair
---@field eright string @escaped right pair
local Pair = {}

--- create a new pair object
---@param pair table
---@return table
function Pair.new(pair)
  pair.left = u.if_nil(pair.left, pair[1])
  pair.right = u.if_nil(pair.right, pair[2])
  u.check_type(pair.left, 'string')
  u.check_type(pair.right, 'string')

  pair.eleft = u.escape(pair.left)
  pair.eright = u.escape(pair.right)

  return setmetatable(pair, Pair)
end

return Pair
