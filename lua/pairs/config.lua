local u = require('pairs.utils')
local Pair = require('pairs.pair')
local push = table.insert
local sort = table.sort

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
      {"'", "'", skip = 20},
      {'"', '"', skip = 20},
    },
    lua = {
      {'(', ')', ignore = {'%(', '%)', '%%'}},
      {'[', ']', ignore = {'%[', '%]', '%%'}},
      {'{', '}', ignore = {'%{', '%}', '%%'}},
    },
    python = {
      {"'", "'", triplet = true, skip = 20},
      {'"', '"', triplet = true, skip = 20},
    },
    ruby = {
      {'|', '|'},
    },
    markdown = {
      {'`', '`', triplet = true},
    },
    html = {
      {'<', '>'}
    },
    xml = {
      {'<', '>'}
    },
    tex = {
      {'$', '$'},
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
      pair = Pair.new(pair)
      push(pairs_tbl[ft], pair)
      config.lr[ft][pair.left] = pair
      if pair.right then
        config.rl[ft][pair.right] = pair
      end
    end
  end
  config.pairs = pairs_tbl

  -- merge global pairs into filetype-specified pairs
  for ft, ft_pairs in pairs(config.pairs) do
    if ft ~= '*' then
      for _, pair in ipairs(config.pairs['*']) do
        if not config.lr[ft][pair.left] and not config.rl[ft][pair.right] then
          push(ft_pairs, pair)
        end
      end
    end
  end

  local normal_pairs = {}
  local skip_regions = {}
  for ft, ft_pairs in pairs(config.pairs) do
    normal_pairs[ft] = {}
    skip_regions[ft] = {}

    for _, pair in ipairs(ft_pairs) do
      if pair.is_pair then push(normal_pairs[ft], pair) end
      if pair.is_skip then push(skip_regions[ft], pair) end
    end

    sort(skip_regions[ft], function(l, r)
      return l.skip > r.skip
    end)
  end

  config.pairs = normal_pairs
  config.regions = skip_regions

  return config
end

return M
