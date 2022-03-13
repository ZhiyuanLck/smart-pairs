local u = require('pairs.utils')
local get_config = require('pairs.config').get_config

--- Pairs class
---@class Pairs
local Pairs = {}

--- setup configuration and keymap
---@vararg table @user configuration
function Pairs.setup(...)
  local arg = {...}
  local user_config

  if arg[1] == Pairs then
    u.warn([[`require('pairs'):setup()` is deprecated, use `require('pairs').setup()` instead]])
    user_config = arg[2] or {}
  else
    user_config = arg[1] or {}
  end

  u.check_type(user_config, 'table', true)

  local config = get_config(user_config)
  for k, v in pairs(config) do
    Pairs[k] = v
  end
end

return Pairs
