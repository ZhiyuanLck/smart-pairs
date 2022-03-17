local u = require('pairs.utils')

---@class Pair @pair
---@field left string @left pair
---@field eleft string @escaped left pair
---@field right string @right pair
---@field eright string @escaped right pair
---@field ignore string[] @lua patterns to be ignored when parse the line
---@field ignore_left string[] @lua patterns to the left of the cursor to be concerned
---@field ignore_right string[] @lua patterns to the right of the cursor to be concerned
---@field skip number @skip priority, 0 for no skip, default 0
---@field is_skip boolean @whehter to skip the region
---@field is_pair boolean @if false, the pair only serves as the region, default true
---@field cross_line boolean @whether the pair or region can spread across multiple lines
local Pair = {}

--- create a new pair object
---@param pair table
---@return Pair
function Pair.new(pair)
  pair.is_pair = u.if_nil(pair.is_pair, true)
  u.check_type(pair.is_pair, 'boolean')

  pair.left = u.if_nil(pair.left, pair[1])
  u.check_type(pair.left, 'string')

  pair.right = u.if_nil(pair.right, pair[2])
  u.check_type(pair.right, 'string', not pair.is_pair)

  pair.skip = u.if_nil(pair.skip, 0)
  u.check_type(pair.skip, 'number')

  pair.is_skip = not pair.is_pair or pair.skip > 0

  pair.eleft = u.escape(pair.left)
  if pair.right then
    pair.eright = u.escape(pair.right)
  end

  pair.cross_line = u.if_nil(pair.cross_line, pair.right ~= nil and pair.left ~= pair.right)

  pair.ignore = u.if_nil(pair.ignore, {})
  u.check_type(pair.ignore, 'list')

  pair.ignore_left = u.if_nil(pair.ignore_left, {})
  u.check_type(pair.ignore_left, 'list')

  pair.ignore_right = u.if_nil(pair.ignore_right, {})
  u.check_type(pair.ignore_right, 'list')

  return setmetatable(pair, Pair)
end

return Pair
