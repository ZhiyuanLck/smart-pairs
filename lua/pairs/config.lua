local u = require('pairs.utils')
local Pair = require('pairs.pair')
local push = table.insert

local M = {}

---@class Pairs
---@field pairs table<string, table> @pairs specification of different file types, '*' for all types
---@field lr table<string, Pair> @map from left pair string to Pr object
---@field rl table<string, Pair> @map from right pair string to Pr object
M.default_config = {
  pairs = {
    ['*'] = {
      {'(', ')'},
      {'[', ']'},
      {'{', '}'},
      {"'", "'"},
      {'"', '"'},
    },
    lua = {
      {'(', ')', {ignore = {'%(', '%)', '%%'}}},
      {'[', ']', {ignore = {'%[', '%]', '%%'}}},
      {'{', '}', {ignore = {'%{', '%}', '%%'}}},
    },
    python = {
      {"'", "'", {triplet = true}},
      {'"', '"', {triplet = true}},
    },
    ruby = {
      {'|', '|'},
    },
    markdown = {
      {'`', '`', {triplet = true}},
    },
    html = {
      {'<', '>'}
    },
    xml = {
      {'<', '>'}
    },
    tex = {
      {'$', '$', {cross_line = true}},
      --- Chinese pairs
      {'（', '）'},
      {'【', '】'},
      {'‘', '’'},
      {'“', '”'},
      {'《', '》'},
    }
  },
}

--- merge user config into the copy of default config
---@param user_config table @user configuration
---@return table
function M.get_config(user_config)
  user_config = user_config or {}
  ---@class Pairs
  local config = vim.deepcopy(M.default_config)
  config.lr = {}
  config.rl = {}

  for ft, pairs in pairs(user_config.pairs or {}) do
    config.pairs[ft] = pairs
  end

  local pairs_tbl = {}
  for ft, ft_pairs in pairs(config.pairs) do
    pairs_tbl[ft] = {}
    config.lr[ft] = {}
    config.rl[ft] = {}

    for _, pair in ipairs(ft_pairs) do
      pair = Pair:new(pair)
      push(pairs_tbl[ft], pair)
      config.lr[ft][pair.left] = pair
      config.rl[ft][pair.right] = pair
    end
  end
  config.pairs = pairs_tbl

  return config
end

return M
