local u = require('pairs.utils')
local get_config = require('pairs.config').get_config
local fmt = string.format

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

  if #user_config > 0 then
    u.check_type(user_config, 'table', 'user_config', true)
  end

  local config = get_config(user_config)
  for k, v in pairs(config) do
    Pairs[k] = v
  end
end

--- get the pair object by either bracket
---@param bracket string
---@return Pair
function Pairs:get_pair(bracket)
  u.check_type(bracket, 'string', 'bracket')
  local ft = vim.bo.ft
  local pair = self.lr[ft] and self.lr[ft][bracket]
  pair = pair or (self.lr['*'] and self.lr['*'][bracket])
  pair = pair or (self.rl[ft] and self.rl[ft][bracket])
  pair = pair or (self.rl['*'] and self.rl['*'][bracket])
  if pair == nil then
    error(fmt("pair '%s' does not exist", bracket))
  end
  return pair
end

--- collect pairs of current file type
---@return Pair[]
function Pairs:get_pairs()
  local ft = vim.bo.ft
  return self.pairs[ft] or self.pairs['*']
end

return Pairs
