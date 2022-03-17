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

--- only for annotation
---@class GetPairOpts
---@field left string @get the right bracket by the left
---@field right string @get the left bracket by the right
local get_pair_opts = {}

--- get the pair object by either bracket
---@param opts GetPairOpts
---@return Pair
function Pairs:get_pair(opts)
  local bmap = opts.left ~= nil and self.lr or (opts.right ~= nil and self.rl or nil)
  if bmap == nil then
    error('neither left or right bracket is known to get the other one')
  end
  local ft = vim.bo.ft
  local bracket = opts.left or opts.right
  local pair = bmap[ft] ~= nil and bmap[ft][bracket] or (bmap['*'] and bmap['*'][bracket])
  if pair == nil then
    local mode = opts.left and 'left' or 'right'
    error(fmt('Invalid %s bracket %s', mode, bracket))
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
