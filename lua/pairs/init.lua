local fmt = string.format
local u = require('pairs.utils')
local fb = require('pairs.fallback')

local Pairs = {
  pairs = {
    ['*'] = {
      {'(', ')'},
      {'[', ']'},
      {'{', '}'},
      {"'", "'"},
      {'"', '"'},
    },
    lua = {
      {'(', ')', {ignore = {'%(', '%)', '\\(', '\\)', '%%'}}},
      {'[', ']', {ignore = {'%[', '%]', '\\[', '\\]', '%%'}}},
      {'{', '}', {ignore = {'%{', '%}', '\\{', '\\}', '%%'}}},
    },
    python = {
      {"'", "'", {triplet = true}},
      {'"', '"', {triplet = true}},
    },
    markdown = {
      {'`', '`', {triplet = true}},
    },
    tex = {
      {'$', '$'}
    }
  },
  default_opts = {
    ['*'] = {
      ignore_pre = '\\\\', -- double backslash or [[\\]]
      ignore_after = '\\w', -- double backslash or [[\w]]
    },
    lua = {
      ignore_pre = '[%\\\\]' -- double backslash
    }
  },
  delete = {
    enable_mapping  = true,
    enable_cond     = true,
    enable_fallback = fb.delete,
    empty_line = {
      enable_cond      = true,
      enable_fallback  = fb.delete,
      enable_sub = {
        start                      = true,
        inside_brackets            = true,
        left_bracket               = true,
        text_multi_line            = true,
        text_delete_to_prev_indent = true,
      },
      trigger_indent_level = 1,
    },
    current_line = {
      enable_cond     = true,
      enable_fallback = fb.delete,
    }
  },
  space = {
    enable_mapping  = true,
    enable_cond     = true,
    enable_fallback = fb.space,
  },
  enter = {
    enable_mapping  = true,
    enable_cond     = true,
    enable_fallback = fb.enter,
  },
}

Pairs.__index = Pairs

-- Pair
local Pr = {}
Pr.__index = Pr

function Pr:new(pair)
  if type(pair) ~= 'table' then
    error('expect a pair table, but get a ' .. type(pair))
  end
  if #pair < 2 then
    error('expect length of pair table to greater than 1, bug the length is ' .. #pair)
  end
  return setmetatable({left = pair[1], right = pair[2], opts = pair[3] or {}}, Pr)
end

function Pairs:set_keymap()
  local map = function(lhs, rhs)
    vim.api.nvim_set_keymap('i', lhs, rhs, {silent = true})
  end
  for _, pair in pairs(self.lr['*']) do
    local l, r = pair.left, pair.right
    map(l, fmt([[<cmd>lua require('pairs.bracket').type_left("%s")<cr>]], l:gsub('"', '\\"')))
    map(r, fmt([[<cmd>lua require('pairs.bracket').type_right("%s")<cr>]], r:gsub('"', '\\"')))
  end
  if u.enable(self.delete.enable_mapping) then
    map('<bs>', [[<cmd>lua require('pairs.delete').type()<cr>]])
  end
  if u.enable(self.space.enable_mapping) then
    map('<space>', [[<cmd>lua require('pairs.space').type()<cr>]])
  end
  if u.enable(self.enter.enable_mapping) then
    map('<cr>', [[<cmd>lua require('pairs.enter').type()<cr>]])
  end
  self:set_buf_keymap()
end

function Pairs:set_buf_keymap()
  local ft = vim.o.filetype
  if not self.lr[ft] then return end
  local map = function(lhs, rhs)
    vim.api.nvim_buf_set_keymap(0, 'i', lhs, rhs, {silent = true})
  end
  for _, pair in pairs(self.lr[ft]) do
    local l, r = pair.left, pair.right
    map(l, fmt([[<cmd>lua require('pairs.bracket').type_left("%s")<cr>]], l:gsub('"', '\\"')))
    map(r, fmt([[<cmd>lua require('pairs.bracket').type_right("%s")<cr>]], r:gsub('"', '\\"')))
  end
end

-- set the default value of option if user not provide a value
-- @param ft string: file type
-- @param pair table
-- @param opt_key: option of the pair
function Pairs:set_default_opts(ft, pair, opt_key)
  if pair.opts[opt_key] then return end
  if self.default_opts[ft] and self.default_opts[ft][opt_key] then
    pair.opts[opt_key] = self.default_opts[ft][opt_key]
  elseif self.default_opts['*'] and self.default_opts['*'][opt_key] then
    pair.opts[opt_key] = self.default_opts['*'][opt_key]
  end
end

-- @field pairs table: custom pairs
function Pairs:setup(opts)
  opts = opts or {}

  u.check_opts(opts)
  u.merge(self.delete, opts.delete)
  u.merge(self.space, opts.space)
  u.merge(self.enter, opts.enter)

  for ft, pairs in pairs(opts.pairs or {}) do
    self.pairs[ft] = pairs
  end

  for ft, default_opts in pairs(opts.default_opts or {}) do
    self.default_opts[ft] = default_opts
  end

  -- init pair map
  self.lr, self.rl = {}, {}
  local new_pairs = {}

  for ft, pairs in pairs(self.pairs) do
    new_pairs[ft] = {}
    self.lr[ft], self.rl[ft] = {}, {}

    for _, pair in ipairs(pairs) do
      pair = Pr:new(pair)

      self:set_default_opts(ft, pair, 'ignore_pre')
      self:set_default_opts(ft, pair, 'ignore_after')
      self:set_default_opts(ft, pair, 'triplet')

      if not pair.opts.ignore then
        pair.opts.ignore = {'\\' .. pair.left, '\\' .. pair.right}
      end

      if not pair.opts.cross_line then
        if pair.left == pair.right then
          pair.opts.cross_line = pair.opts.triplet
        else
          pair.opts.cross_line = true
        end
      end

      if not pair.opts.enable_smart_space then
        pair.opts.enable_smart_space = pair.left ~= pair.right
      end

      table.insert(new_pairs[ft], pair)
      self.lr[ft][pair.left] = pair
      self.rl[ft][pair.right] = pair
    end
  end

  self.pairs = new_pairs

  -- merge global pairs to ft_pairs
  for ft, pairs in pairs(self.pairs) do
    if ft ~= '*' then
      for _, pair in ipairs(self.pairs['*']) do
        if not self.lr[ft][pair.left] then
          table.insert(pairs, pair)
        end
      end
    end
  end

  self:set_keymap()
  vim.cmd([[
    aug Pairs
      au!
      au BufRead,BufNew * lua require('pairs'):set_keymap()
    aug END
  ]])
end

-- given right bracket, get the left one
-- @param right string right bracket
function Pairs:get_left(right)
  local ft = vim.o.filetype
  if self.rl[ft] and self.rl[ft][right] then
    return self.rl[ft][right].left
  end
  if self.rl['*'] and self.rl['*'][right] then
    return self.rl['*'][right].left
  end
  error(fmt('the right bracket %s is not defined', right))
end

-- given left bracket, get the right one
-- @param left string left bracket
function Pairs:get_right(left)
  local ft = vim.o.filetype
  if self.lr[ft] and self.lr[ft][left] then
    return self.lr[ft][left].right
  end
  if self.lr['*'] and self.lr['*'][left] then
    return self.lr['*'][left].right
  end
  error(fmt('the left bracket %s is not defined', left))
end

function Pairs:get_opts(left)
  local ft = vim.o.filetype
  if self.lr[ft] and self.lr[ft][left] then
    return self.lr[ft][left].opts
  end
  if self.lr['*'] and self.lr['*'][left] then
    return self.lr['*'][left].opts
  end
  error(fmt('the left bracket %s is not defined', left))
end

-- get extra ignore pattern by left bracket
function Pairs:get_ignore(left)
  local ignore = self:get_opts(left).ignore or {}
  if type(ignore) == 'string' then
    return {ignore}
  end
  return ignore
end

-- test whether the left bracket exists
function Pairs:exists(left)
  local ft = vim.o.filetype
  if self.lr[ft] and self.lr[ft][left] then
    return true
  end
  if self.lr['*'] and self.lr['*'][left] then
    return true
  end
  return false
end

function Pairs:get_pairs()
  local ft = vim.o.filetype
  return self.pairs[ft] or self.pairs['*']
end

-- remove escaped brackets and ignore pattern
-- @param line string: line to be processed
-- @param left string: left bracket
-- @return string: clean line
function Pairs:clean(line, left)
  line = line:gsub('\\\\', '')
  line = line:gsub('\\' .. u.escape(left), '')
  local right = self:get_right(left)
  if right ~= left then
    line = line:gsub('\\' .. u.escape(right), '')
  end
  local ignore = self:get_ignore(left)
  for _, pattern in ipairs(ignore) do
    line = line:gsub(u.escape(pattern), '')
  end
  return line
end

-- test whether to ignore the current left bracket
-- @param left_line string: left part of current line separated by the cursor
-- @param left string: left bracket
-- @return boolean
function Pairs:ignore_pre(left_line, left)
  left_line = self:clean(left_line, left)
  local opts = self:get_opts(left)
  if not opts.ignore_pre then return false end
  local ignore_pre = opts.ignore_pre .. '$'
  return vim.fn.match(left_line, ignore_pre) ~= -1
end

-- test whether to completef the right bracket
-- @param right_line string: left part of current line separated by the cursor
-- @param left string: left bracket
-- @return boolean
function Pairs:ignore_after(right_line, left)
  right_line = self:clean(right_line, left)
  local opts = self:get_opts(left)
  if not opts.ignore_after then return false end
  local ignore_after = '^' .. opts.ignore_after
  -- exclude the right bracket or all right brackets will be better ?
  -- local right = self:get_right(left)
  -- if right_line:match('^' .. escape(right)) then return false end
  return ignore_after and vim.fn.match(right_line, ignore_after) ~= -1
end

-- get left bracket count on the left and the right bracket count on the right
function Pairs:get_count(left_line, right_line, left, right)
  local l = self:clean(left_line, left)
  local r = self:clean(right_line, left)
  local lc = u.count(l, left, right)
  local rc = u.count(r:reverse(), right:reverse(), left:reverse())
  return lc, rc
end

-- count occurrences of bracket, ignore escaped ones
-- @param line string: line to be searched
-- @param bracket: pattern
-- @return number
function Pairs:match_count(line, bracket)
  line = self:clean(line, bracket)
  local n = 0
  for _ in line:gmatch(u.escape(bracket)) do n = n + 1 end
  return n
end

return Pairs
