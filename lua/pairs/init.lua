local u = require("pairs.utils")

--- Pairs class
---@class Pairs
local Pairs = {}

--- setup configuration
---@vararg table @user configuration
function Pairs.setup(...)
  local arg = {...}
  local user_config

  if arg[1] == Pairs then
    u.warn([[`require("pairs"):setup()` is deprecated, use `require("pairs").setup()` instead]])
    user_config = arg[2] or {}
  else
    user_config = arg[1] or {}
  end

end

return Pairs
