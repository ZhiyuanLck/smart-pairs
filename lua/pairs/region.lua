local u = require('pairs.utils')

---@class Region
---@field start string @start of the region
---@field estart string @escaped start of the region
---@field finish string @end of the region
---@field efinish string @escaped end of the region
---@field ignore string[] @patterns to be ignored before processing the line
---@field cross_line boolean @whether the region can cross lines
---@field priority number @default 0
local Region = {}

--- create a region object
---@param region Region
---@return Region
function Region.new(region)
  u.check_type(region, 'table')
  u.check_type(region.start, 'string')
  u.check_type(region.finish, 'string', true)
  u.check_type(region.ignore, 'list', true)
  u.check_type(region.cross_line, 'boolean', true)
  u.check_type(region.priority, 'number', true)

  region.estart = u.escape(region.start)
  if region.finish == nil then
    region.cross_line = false
  else
    region.efinish = u.escape(region.finish)
    region.cross_line = u.if_nil(region.cross_line, region.start ~= region.finish)
  end

  region.ignore = region.ignore or {}
  region.priority = u.if_nil(region.priority, 0)

  return setmetatable(region, Region)
end

return Region
