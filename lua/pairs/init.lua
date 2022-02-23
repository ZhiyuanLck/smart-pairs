local fmt = string.format
local u = require('pairs.utils')
local fb = require('pairs.fallback')
local push = table.insert

local config = {
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
    tex = {
      {'$', '$', {cross_line = true}},
      --- Chinese pairs
      {'（', '）'},
      {'【', '】'},
      {'‘', '’'},
      {'“', '”'},
    }
  },
  default_opts = {
    ['*'] = {
      ignore_pre = '\\\\', --- double backslash or [[\\]]
      ignore_after = '\\w', --- double backslash or [[\w]]
    },
    lua = {
      ignore_pre = '[%\\\\]' --- double backslash
    }
  },
  indent = {
    ['*'] = 1,
    python = 2,
  },
  delete = {
    enable_mapping  = true,
    enable_cond     = true,
    enable_fallback = fb.delete,
    empty_line = {
      enable_cond     = true,
      enable_fallback = fb.delete,
      bracket_bracket = {
        fallback = fb.delete_indent,
        multi = {
          strategy = 'leave_one_indent',
          fallback = fb.delete_indent,
        },
        one = {
          strategy = 'smart',
          trigger_indent_level = 0,
          fallback = fb.delete,
        },
      },
      bracket_text = {
        fallback = fb.delete_indent,
        multi = {
          strategy = 'leave_zero_above',
          fallback = fb.delete_indent,
        },
        one = {
          strategy = 'smart',
          trigger_indent_level = 0,
          fallback = fb.delete,
        },
      },
      text_bracket = {
        fallback = fb.delete_indent,
        multi = {
          strategy = 'leave_one_cur',
          fallback = fb.delete_indent,
        },
        one = {
          strategy = 'leave_zero_above',
          trigger_indent_level = 0,
          fallback = fb.delete,
        },
      },
      text_text = {
        fallback = fb.delete_indent,
        multi = {
          strategy = 'leave_one_above',
          fallback = fb.delete_indent,
        },
        one = {
          strategy = nil,
          trigger_indent_level = 0,
          fallback = fb.delete_indent,
        },
      },
    },
    empty_pre = {
      enable_cond     = true,
      enable_fallback = fb.delete,
      bracket_bracket = {
        fallback = fb.delete_indent,
        multi = {
          strategy = 'leave_one_indent',
          fallback = fb.delete_indent,
        },
        one = {
          strategy = 'delete_all',
          trigger_indent_level = 0,
          fallback = fb.delete,
        },
      },
      bracket_text = {
        fallback = fb.delete_indent,
        multi = {
          strategy = 'leave_zero_below',
          fallback = fb.delete_indent,
        },
        one = {
          strategy = 'leave_zero_below',
          trigger_indent_level = 0,
          fallback = fb.delete,
        },
      },
      text_bracket = {
        fallback = fb.delete_indent,
        multi = {
          strategy = 'leave_one_indent',
          fallback = fb.delete_indent,
        },
        one = {
          strategy = 'leave_zero_above',
          trigger_indent_level = 0,
          fallback = fb.delete,
        },
      },
      text_text = {
        fallback = fb.delete_indent,
        multi = {
          strategy = 'leave_one_cur',
          fallback = fb.delete_indent,
        },
        one = {
          strategy = nil,
          trigger_indent_level = 0,
          fallback = fb.delete,
        },
      },
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
  autojump_strategy = {
    unbalanced = 'right', --- all, right, none
  },
  mapping = {
    jump_left_in_any   = '<m-[>',
    jump_right_out_any = '<m-]>',
    jump_left_out_any  = '<m-{>',
    jump_right_in_any  = '<m-}>',
  },
  max_search_lines = 500,
}

local Pairs = {}
setmetatable(Pairs, {__index=config})

--- Pair
local Pr = {}

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
  local map_jump = function(left, out)
    local direction = left and 'left' or 'right'
    local side = out and 'out' or 'in'
    local key = self.mapping[fmt('jump_%s_%s_any', direction, side)]
    if not key then return false end
    out = out and 'true' or 'false'
    map(key, fmt([[<cmd>lua require('pairs.bracket').jump_%s{out = %s}<cr>]], direction, out))
  end
  map_jump(true, true)
  map_jump(true, false)
  map_jump(false, false)
  map_jump(false, true)
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

--- set the default value of option if user not provide a value
---@param ft string: file type
---@param pair table
---@param opt_key table: option of the pair
function Pairs:set_default_opts(ft, pair, opt_key)
  if pair.opts[opt_key] ~= nil then return end
  if self.default_opts[ft] ~= nil and self.default_opts[ft][opt_key] ~= nil then
    pair.opts[opt_key] = self.default_opts[ft][opt_key]
  elseif self.default_opts['*'] ~= nil and self.default_opts['*'][opt_key] ~= nil then
    pair.opts[opt_key] = self.default_opts['*'][opt_key]
  end
end

---@field pairs table: custom pairs
function Pairs:setup(opts)
  opts = opts or {}

  u.check_opts(opts)
  u.merge(self.delete, opts.delete)
  u.merge(self.space, opts.space)
  u.merge(self.enter, opts.enter)
  u.merge(self.indent, opts.indent)
  u.merge(self.autojump_strategy, opts.autojump_strategy)

  for ft, pairs in pairs(opts.pairs or {}) do
    self.pairs[ft] = pairs
  end

  for ft, default_opts in pairs(opts.default_opts or {}) do
    self.default_opts[ft] = default_opts
  end

  --- init pair map
  self.lr, self.rl = {}, {}
  local new_pairs = {}

  for ft, pairs in pairs(config.pairs) do
    new_pairs[ft] = {}
    self.lr[ft], self.rl[ft] = {}, {}

    for _, pair in ipairs(pairs) do
      pair = Pr:new(pair)

      self:set_default_opts(ft, pair, 'ignore_pre')
      self:set_default_opts(ft, pair, 'ignore_after')
      self:set_default_opts(ft, pair, 'triplet')

      if pair.opts.ignore == nil then
        pair.opts.ignore = {'\\' .. pair.left, '\\' .. pair.right}
      end

      if pair.opts.cross_line == nil then
        pair.opts.cross_line = pair.left ~= pair.right
      end

      if pair.opts.enable_smart_space == nil then
        pair.opts.enable_smart_space = pair.left ~= pair.right
      end

      pair.opts.balanced = pair.left == pair.right

      push(new_pairs[ft], pair)
      self.lr[ft][pair.left] = pair
      self.rl[ft][pair.right] = pair
    end
  end

  self.pairs = new_pairs

  --- merge global pairs to ft_pairs
  for ft, pairs in pairs(self.pairs) do
    if ft ~= '*' then
      for _, pair in ipairs(self.pairs['*']) do
        if not self.lr[ft][pair.left] then
          push(pairs, pair)
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

--- given right bracket, get the left one
---@param right string right bracket
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

--- given left bracket, get the right one
---@param left string left bracket
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

--- get extra ignore pattern by left bracket
function Pairs:get_ignore(left)
  local ignore = self:get_opts(left).ignore or {}
  if type(ignore) == 'string' then
    return {ignore}
  end
  return ignore
end

--- test whether the left bracket exists
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

--- remove escaped brackets and ignore pattern
---@param line string: line to be processed
---@param left string: left bracket
---@param remove_triplet boolean: whether to remove possible triplet pair, default true
---@return string: clean line
function Pairs:clean(line, left, remove_triplet)
  --- ignore \\
  line = line:gsub('\\\\', '')
  --- ignore escaped pair
  line = line:gsub('\\' .. u.escape(left), '')
  local right = self:get_right(left)
  if right ~= left then
    line = line:gsub('\\' .. u.escape(right), '')
  end
  --- ignore extra pattern
  local ignore = self:get_ignore(left)
  for _, pattern in ipairs(ignore) do
    line = line:gsub(u.escape(pattern), '')
  end
  --- ignore string
  line = line:gsub("\\'", ''):gsub('\\"', '')
  line = line:gsub("'.-'", ''):gsub('".-"', '')
  --- remove possible triplet
  if remove_triplet or true then
    line = line:gsub('"""', ''):gsub("'''", '')
  end
  return line
end

--- remove all escaped brackets and ignore pattern
function Pairs:clean_all(line)
  line = line:gsub('\\\\', '')
  for _, pair in ipairs(self:get_pairs()) do
    line = line:gsub('\\' .. u.escape(pair.left), '')
    if pair.right ~= pair.left then
      line = line:gsub('\\' .. u.escape(pair.right), '')
    end
    for _, pattern in ipairs(self:get_ignore(pair.left)) do
      line = line:gsub(u.escape(pattern), '')
    end
  end
  line = line:gsub("\\'", ''):gsub('\\"', '')
  line = line:gsub("'.-'", ''):gsub('".-"', '')
  return line
end

--- check if line has extra left bracket by counting the number of left brackets in line
---@param line string: line to be counted
---@param ctn table: counter table
---@param pair table: pair obj
function Pairs:has_left(line, ctn, pair)
  if not line then return false end
  local _line = self:clean_all(line)
  ctn = ctn or {}

  local _count = function(p)
    ctn[p.left] = ctn[p.left] or 0
    if p.opts.triplet then
      ctn[p.left] = ctn[p.left] + u.match_count(self:clean(line, p.left, false), u.triplet(p.left))
      return ctn[p.left] % 2 == 1 and p
    elseif p.opts.cross_line then
      local count = u.count(_line, p.left, p.right)
      if ctn[p.left] + count.n > 0 then return p end
      ctn[p.left] = ctn[p.left] +  count.m
    end
  end

  if pair then return _count(pair) end
  for _, _pair in ipairs(self:get_pairs()) do
    if _count(_pair) then return _pair end
  end
end

--- check if line has left bracket at end
---@param line string: line to be searched
---@param pair table: pair obj
function Pairs:has_left_end(line, pair)
  if not line then return nil end
  local _line = self:clean_all(line)
  local _has = function(p)
    if (p.opts.triplet and self:clean(line, p.left, false):match(u.triplet(p.left) .. '%s*$')) or
      (p.opts.cross_line and _line:match(u.escape(p.left) .. '%s*$')) then
      return p
    end
  end

  if pair then return _has(pair) end
  for _, _pair in ipairs(self:get_pairs()) do
    local ret = _has(_pair)
    if ret then return ret end
  end
end

--- check if line has right bracket at start
function Pairs:has_right_start(line)
  if not line then return false end
  local _line = self:clean_all(line)
  for _, pair in ipairs(self:get_pairs()) do
    if (pair.opts.triplet and self:clean(line, pair.left, false):match('^%s*' .. u.triplet(pair.left))) or
      (pair.opts.cross_line and _line:match('^%s*' .. u.escape(pair.right))) then
      return pair
    end
  end
end

--- test whether to ignore the current left bracket
---@param left_line string: left part of current line separated by the cursor
---@param left string: left bracket
---@return boolean
function Pairs:ignore_pre(left_line, left)
  left_line = self:clean(left_line, left)
  local opts = self:get_opts(left)
  if not opts.ignore_pre then return false end
  local ignore_pre = opts.ignore_pre .. '$'
  return vim.fn.match(left_line, ignore_pre) ~= -1
end

--- test whether to completef the right bracket
---@param right_line string: left part of current line separated by the cursor
---@param left string: left bracket
---@return boolean
function Pairs:ignore_after(right_line, left)
  right_line = self:clean(right_line, left)
  local opts = self:get_opts(left)
  if not opts.ignore_after then return false end
  local ignore_after = '^' .. opts.ignore_after
  --- exclude the right bracket or all right brackets will be better ?
  --- local right = self:get_right(left)
  --- if right_line:match('^' .. escape(right)) then return false end
  return ignore_after and vim.fn.match(right_line, ignore_after) ~= -1
end

--- get left bracket count on the left and above (limited by max_search_lines)
function Pairs:get_cross_count(left, right, cache)
  local line_idx = vim.fn.line('.') - 1
  local l_idx = line_idx - (self.max_search_lines or 0)
  l_idx = l_idx < 0 and 0 or l_idx
  local end_nr = vim.api.nvim_buf_line_count(0)
  local r_idx = line_idx + (self.max_search_lines or 1)
  r_idx = r_idx > end_nr and end_nr or r_idx
  local l = l_idx < line_idx and vim.api.nvim_buf_get_lines(0, l_idx, line_idx, true) or {}
  local r = r_idx > line_idx + 1 and vim.api.nvim_buf_get_lines(0, line_idx + 1, r_idx, true) or {}
  local left_line, right_line = u.get_cursor_lr()
  local ln = #l
  local rn = #r
  local lc = 0
  local rc = 0

  local count = function(line, reverse)
    if reverse then
      return u.count(self:clean(line, left, right):reverse(), right:reverse(), left:reverse())
    end
    return u.count(self:clean(line, left, right), left, right)
  end

  if ln == 0 then
    lc = count(left_line).n
  else
    lc = lc + count(left_line).m
    for i = 1, ln do
      lc = lc + (i == 1 and count(l[i]).n or count(l[i]).m)
    end
  end

  if rn == 0 then
    rc = count(right_line, true).n
  else
    rc = rc + count(right_line, true).m
    for i = 1, rn do
      rc = rc + (i == rn and count(r[i], true).n or count(r[i], true).m)
    end
  end
  return lc < 0 and 0 or lc, rc < 0 and 0 or rc
end

--- NOTE: to be removed
--- get left bracket count on the left and the right bracket count on the right
function Pairs:get_count(left_line, right_line, left, right)
  local l = self:clean(left_line, left)
  local r = self:clean(right_line, left)
  local lc = u.count(l, left, right).n
  local rc = u.count(r:reverse(), right:reverse(), left:reverse()).n
  return lc, rc
end

--- count occurrences of bracket, ignore escaped ones
---@param line string: line to be searched
---@param bracket: pattern
---@return number
function Pairs:match_count(line, bracket)
  line = self:clean(line, bracket)
  return u.match_count(line, u.escape(bracket))
end

function Pairs:get_indent()
  local ft = vim.bo.ft
  local level = self.indent[ft] or self.indent['*'] or 1
  return u.get_indent(level)
end

return Pairs
