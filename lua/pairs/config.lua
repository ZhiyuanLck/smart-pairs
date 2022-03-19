local u = require('pairs.utils')
local Pair = require('pairs.pair')
local push = table.insert
local sort = table.sort

local M = {}

---@class Pairs
---@field pairs table<string, table> @pairs specification of different file types, '*' for all types
---@field lr table<string, Pair> @map from left pair string to Pr object
---@field rl table<string, Pair> @map from right pair string to Pr object
---@field ignore table<string, string[]> @extra ignore patterns, '*' for all types
---@field max_search_lines number @maximum lines to be searched
M.default_config = {
  pairs = {
    ['*'] = {
      {'(', ')'},
      {'[', ']'},
      {'{', '}'},
      {"'", "'", priority = 20},
      {'"', '"', priority = 20},
    },
    python = {
      {"'", "'", triplet = true, priority = 20},
      {'"', '"', triplet = true, priority = 20},
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
  ignore = {
    lua = {'%%', '%(', '%)', '%['}
  },
  max_search_lines = 500
}

--- merge user config into the copy of default config
---@param user_config table @user configuration
---@param not_sort boolean @used for test, default false
---@return table
function M.get_config(user_config, not_sort)
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

  -- merge global ignore patterns into filetype patterns
  u.check_type(config.ignore, 'table', 'config.ignore')
  for ft, ft_ignore in pairs(config.ignore) do
    if ft ~= '*' then
      local ignore = vim.deepcopy(config.ignore['*'] or {})
      vim.list_extend(ignore, ft_ignore)
      config.ignore[ft] = ignore
    end
  end

  u.check_type(config.max_search_lines, 'number')

  if u.if_nil(not_sort, false) then return config end

  for _, ft_pairs in pairs(config.pairs) do
    sort(ft_pairs, function(l, r)
      if l.priority > r.priority then return true end
      if l.priority < r.priority then return false end
      return l.is_priority and not r.is_priority
    end)
  end

  return config
end

return M
