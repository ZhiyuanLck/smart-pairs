local fmt = string.format

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
    }
  },
  default_opts = {
    ['*'] = {
      ignore_pre = '\\\\', -- double backslash
      ignore_after = '\\S', -- double backslash
    },
    lua = {
      ignore_pre = '[%\\\\]' -- double backslash
    }
  },
  delete = {
    enable = true,
    empty_line = {
      enable       = true,
      enable_start = true,
      enable_end   = true,
      enable_text  = true,
      bracket = {
        enable = true,
        indent_level = 1
      }
    }
  },
  cache = {}
}

-- get the indent level of str in vim
-- @param str string
local function get_indent_level(str)
  local indent = vim.api.nvim_strwidth('\\t')
  local pre_space = str:match('^%s*'):gsub('\t', '\\t')
  local cur_indent = vim.api.nvim_strwidth(pre_space)
  return (cur_indent - cur_indent % indent) / indent
end

local function feedkeys(keys)
  keys = vim.api.nvim_replace_termcodes(keys, true, false, true)
  vim.api.nvim_feedkeys(keys, 'n', true)
end

local function set_cursor(line, col)
  line = line == 0 and vim.fn.line('.') or line
  if type(col) == 'string' then col = vim.fn.strlen(col) end
  vim.api.nvim_win_set_cursor(0, {line, col})
end

-- merge two opts table
local function merge(opts1, opts2)
  if not opts2 then return end
  for k, v in pairs(opts2) do
    if type(v) == 'table' and opts1[k] then
      merge(opts1[k], opts2[k])
    else
      opts1[k] = v
    end
  end
end

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
    map(l, fmt([[<cmd>lua require('pairs'):type_left("%s")<cr>]], l:gsub('"', '\\"')))
    map(r, fmt([[<cmd>lua require('pairs'):type_right("%s")<cr>]], r:gsub('"', '\\"')))
  end
  map('<space>', [[<cmd>lua require('pairs'):type_space()<cr>]])
  if self.delete.enable then
    map('<bs>', [[<cmd>lua require('pairs'):type_del()<cr>]])
  end
  map('<cr>', [[<cmd>lua require('pairs'):type_enter()<cr>]])
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
    map(l, fmt([[<cmd>lua require('pairs'):type_left("%s")<cr>]], l:gsub('"', '\\"')))
    map(r, fmt([[<cmd>lua require('pairs'):type_right("%s")<cr>]], r:gsub('"', '\\"')))
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

  merge(self.delete, opts.delete)

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
    local ft_pairs = {}
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

      table.insert(ft_pairs, pair)
      self.lr[ft][pair.left] = pair
      self.rl[ft][pair.right] = pair
    end

    new_pairs[ft] = ft_pairs
  end

  self.pairs = new_pairs
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
  if self.cache[ft] and self.cache[ft].pairs then
    return self.cache[ft].pairs
  end
  local lr = {}
  local _pairs = {}
  for _, pair in pairs(self.lr['*'] or {}) do
    lr[pair.left] = pair
  end
  for _, pair in pairs(self.lr[ft] or {}) do
    lr[pair.left] = pair
  end
  for _, pair in pairs(lr) do
    table.insert(_pairs, pair)
  end
  self.cache[ft] = self.cache[ft] or {}
  self.cache[ft].pairs = _pairs
  return _pairs
end

local function escape(str)
  local e = {'%', '(', ')', '[', '.', '*', '+', '-', '?', '^', '$'}
  for _, ch in ipairs(e) do
    str = str:gsub('%' .. ch, '%%%' .. ch)
  end
  return str
end

-- remove escaped brackets and ignore pattern
-- @param line string: line to be processed
-- @param left string: left bracket
-- @return string: clean line
local function clean(line, left)
  line = line:gsub('\\\\', '')
  line = line:gsub('\\' .. escape(left), '')
  local right = Pairs:get_right(left)
  if right ~= left then
    line = line:gsub('\\' .. escape(right), '')
  end
  local ignore = Pairs:get_ignore(left)
  for _, pattern in ipairs(ignore) do
    line = line:gsub(escape(pattern), '')
  end
  return line
end

-- count the number of left brackets with remove of corresponding pairs
-- @param str string
-- @param left string: left bracket
-- @param right string: right bracket
local function count(str, left, right)
  local cur = 1
  local n = 0
  local ln, rn, sn = #left, #right, #str
  repeat
    if str:sub(cur, cur + ln - 1) == left then
      n = n + 1
      cur = cur + #left
    elseif str:sub(cur, cur + rn - 1) == right then
      n = n > 0 and n - 1 or n
      cur = cur + #right
    else
      cur = cur + 1
    end
  until (cur > sn)
  return n
end

-- @return left and right part of line separated by cursor
local function get_line()
  local col = vim.fn.col('.') - 1
  local line = vim.api.nvim_get_current_line()
  local left_line = vim.fn.strpart(line, 0, col)
  local right_line = vim.fn.strpart(line, col)
  return left_line, right_line
end

-- test whether to ignore the current left bracket
-- @param left_line string: left part of current line separated by the cursor
-- @param left string: left bracket
-- @return boolean
function Pairs:ignore_pre(left_line, left)
  left_line = clean(left_line, left)
  local opts = self:get_opts(left)
  local ignore_pre = opts.ignore_pre
  return ignore_pre and vim.fn.match(left_line, ignore_pre .. '$') ~= -1
end

-- test whether to completef the right bracket
-- @param right_line string: left part of current line separated by the cursor
-- @param left string: left bracket
-- @return boolean
function Pairs:ignore_after(right_line, left)
  right_line = clean(right_line, left)
  local opts = self:get_opts(left)
  local ignore_after = opts.ignore_after
  local right = self:get_right(left)
  if right_line:match('^' .. escape(right)) then return false end
  return ignore_after and vim.fn.match(right_line, '^' .. ignore_after) ~= -1
end

-- get left bracket count on the left and the right bracket count on the right
local function get_count(left_line, right_line, left, right)
  local l = clean(left_line, left)
  local r = clean(right_line, left)
  local lc = count(l, left, right)
  local rc = count(r:reverse(), right:reverse(), left:reverse())
  return lc, rc
end

-- action when typeset the left bracket
function Pairs:type_left_neq(left, right)
  local left_line, right_line = get_line()
  local ignore_pre = self:ignore_pre(left_line, left)
  local ignore_after = self:ignore_after(right_line, left)

  if not ignore_pre and not ignore_after then
    local lc, rc = get_count(left_line, right_line, left, right)
    if lc >= rc then
      right_line = right .. right_line
    end
  end

  left_line = left_line .. left
  vim.api.nvim_set_current_line(left_line .. right_line)
  local pos = vim.api.nvim_win_get_cursor(0)
  pos[2] = vim.fn.strlen(left_line)
  vim.api.nvim_win_set_cursor(0, pos)
end

-- action when typeset the right bracket
-- @param right bracket
function Pairs:type_right_neq(left, right)
  local left_line, right_line = get_line()
  local lc, rc = get_count(left_line, right_line, left, right)
  local pos = vim.api.nvim_win_get_cursor(0)
  -- lots of left brackets more than right, we need the right one
  -- or the first right bracket is to be typeset after revoming the counterbalances on the right
  if lc > rc or rc == 0 then
    left_line = left_line .. right
    pos[2] = vim.fn.strlen(left_line)
  -- now we have at least one right bracket on the right and then jump to it
  else
    local _, end_idx = right_line:find(right)
    pos[2] = pos[2] + vim.fn.strlen(right_line:sub(1, end_idx))
  end
  vim.api.nvim_set_current_line(left_line .. right_line)
  vim.api.nvim_win_set_cursor(0, pos)
end

-- count occurrences of bracket, ignore escaped ones
-- @param line string: line to be searched
-- @param bracket: pattern
-- @return number
local function match_count(line, bracket)
  line = clean(line, bracket)
  local n = 0
  for _ in line:gmatch(escape(bracket)) do n = n + 1 end
  return n
end

-- action when two brackets are equal
-- @param bracket string
function Pairs:type_eq(bracket)
  local left_line, right_line = get_line()
  local left_count = match_count(left_line, bracket)
  local right_count = match_count(right_line, bracket)
  local pos = vim.api.nvim_win_get_cursor(0)

  -- process triplet bracket
  if self:get_opts(bracket).triplet then
    local pattern = escape(bracket)
    local l = left_line
    local n = 0
    repeat
      local i, _ = l:find(pattern .. '$')
      if i then
        n = n + 1
        l = l:sub(1, i - 1)
      end
    until (n > 2 or i == nil)
    local valid = n == 2 and not right_line:match('^' .. pattern)
    if valid then
      left_line = left_line .. bracket
      right_line = string.rep(bracket, 3) .. right_line
      pos[2] = vim.fn.strlen(left_line)
      vim.api.nvim_set_current_line(left_line .. right_line)
      vim.api.nvim_win_set_cursor(0, pos)
      return
    end
  end

  -- complete anothor bracket
  local complete = function()
    left_line = left_line .. bracket
    pos[2] = vim.fn.strlen(left_line)
  end
  -- typeset two brackets
  local typeset = function()
    right_line = bracket .. right_line
    complete()
  end

  local ignore_pre = self:ignore_pre(left_line, bracket)
  -- not consider ignore_after
  -- local ignore_after = self:ignore_after(right_line, bracket)

  -- number of brackets of current line is odd, always complete
  if ignore_pre or (left_count + right_count) % 2 == 1 then
    complete()
  -- number of brackets of current line is even
  -- number of brackets of left side is even, which means the right side is also even
  -- typeset two brackets
  elseif left_count % 2 == 0 then -- typeset all
    typeset()
  -- left side is odd and right side is odd, which means you are inside the bracket scope
  else
    local i, j = right_line:find(bracket)
    -- jump only if the right bracket is next to the cursor
    if i == 1 then
      pos[2] = pos[2] + vim.fn.strlen(right_line:sub(1, j))
    else -- typeset two brackets
      typeset()
    end
  end

  vim.api.nvim_set_current_line(left_line .. right_line)
  vim.api.nvim_win_set_cursor(0, pos)
end

function Pairs:type_left(left)
  local right = self:get_right(left)
  if left == right then
    self:type_eq(left)
  else
    self:type_left_neq(left, right)
  end
end

function Pairs:type_right(right)
  local left = self:get_left(right)
  if left == right then
    self:type_eq(right)
  else
    self:type_right_neq(left, right)
  end
end

function Pairs:type_space()
  local left_line, right_line = get_line()

  for _, pair in ipairs(self:get_pairs()) do
    local pl = escape(pair.left) .. '$'
    local pr = '^' .. escape(pair.right)
    if left_line:match(pl) and right_line:match(pr) then
      right_line = ' ' .. right_line
      break
    end
  end

  left_line = left_line .. ' '
  vim.api.nvim_set_current_line(left_line .. right_line)
  set_cursor(0, left_line)
end

function Pairs:del_empty_lines()
  local cur_line = vim.api.nvim_get_current_line()
  local empty_line = cur_line:match('^%s*$') ~= nil
  local empty_pre

  if not empty_line then
    local left_line, _ = get_line()
    empty_pre = left_line:match('^%s*$') ~= nil
    if not empty_pre then return false end
  end

  if not self.delete.empty_line.enable then
    feedkeys('<bs>')
    return true
  end

  local linenr = vim.fn.line('.')
  local cur = linenr - 2

  local line
  while (cur >= 0) do
    line = vim.api.nvim_buf_get_lines(0, cur, cur + 1, true)[1]
    if not line:match('^%s*$') then break end
    cur = cur - 1
  end

  local left
  if line then
    for _, pair in ipairs(Pairs:get_pairs()) do
      left = line:match(fmt('(%s)%%s*$', escape(pair.left)))
      if left then break end
    end
  end

  -- 0-indexed line index of first nonempty line when searching up
  local above_nr = cur

  cur =  empty_pre and linenr - 1 or linenr -- handle empty pre
  local end_nr = vim.fn.line('$')
  while (cur < end_nr) do
    line = vim.api.nvim_buf_get_lines(0, cur, cur + 1, true)[1]
    if not line:match('^%s*$') then break end
    cur = cur + 1
  end

  local right
  if left and line then
    right = line:match(fmt('^%%s*(%s)', escape(self:get_right(left))))
  end

  -- 0-indexed line index of first nonempty line when searching below
  local below_nr = cur

  if empty_pre then
    if below_nr - above_nr == 1 then
      feedkeys('<bs>')
      return true
    else
      set_cursor(vim.fn.line('.') - 1, 1)
    end
  end

  -- empty lines in the start of file
  if above_nr < 0 then
    if self.delete.empty_line.enable_start then
      vim.cmd(fmt('silent 1,%dd', below_nr))
      vim.api.nvim_win_set_cursor(0, {1, 1})
      feedkeys('<esc>I')
    else
      feedkeys('<bs>')
    end
    return true
  end

  local line1 = vim.api.nvim_buf_get_lines(0, above_nr, above_nr + 1, true)[1]:match('^(.-)%s*$')

  -- empty lines in the end of file
  if below_nr == end_nr then
    -- normal deletion when only one empty line
    if self.delete.empty_line.enable_end and below_nr - above_nr > 2 then
      vim.cmd(fmt('silent %d,%dd', above_nr + 2, end_nr))
      vim.api.nvim_buf_set_lines(0, above_nr, above_nr + 1, true, {line1})
      -- cannot set col to 1, which will cause indent problem
      vim.api.nvim_win_set_cursor(0, {above_nr + 1, vim.fn.strwidth(line1)})
      feedkeys('<esc>o')
    else
      feedkeys('<bs>')
    end
    return true
  end

  local line2 = vim.api.nvim_buf_get_lines(0, below_nr, below_nr + 1, true)[1]:match('^%s*(.-)$')
  -- delete all blanks and merge lines
  if left and right then
    if self.delete.empty_line.bracket.enable then
      local indent1 = get_indent_level(line1)
      local indent2 = get_indent_level(cur_line)
      if indent2 - indent1 <= self.delete.empty_line.bracket.indent_level then
        vim.cmd(fmt('silent %d,%dd', above_nr + 2, below_nr + 1))
        vim.api.nvim_buf_set_lines(0, above_nr, above_nr + 1, true, {line1 .. line2})
        vim.api.nvim_win_set_cursor(0, {above_nr + 1, vim.fn.strlen(line1)})
      else
        feedkeys('<bs>')
      end
    else
      feedkeys('<bs>')
    end
  -- normal deletion for only one empty line
  elseif above_nr + 2 == below_nr then
    feedkeys('<bs>')
  elseif self.delete.empty_line.enable_text then -- leave an empty line between text
    vim.cmd(fmt('silent %d,%dd', above_nr + 2, below_nr))
    vim.api.nvim_buf_set_lines(0, above_nr, above_nr + 1, true, {line1})
    -- cannot set col to 1, which will cause indent problem
    vim.api.nvim_win_set_cursor(0, {above_nr + 1, vim.fn.strlen(line1)})
    feedkeys('<esc>o')
  else
    feedkeys('<bs>')
  end
  return true
end

function Pairs:type_del()
  if self:del_empty_lines() then return end

  local left_line, right_line = get_line()

  local del_l, del_r
  for _, pair in ipairs(Pairs:get_pairs()) do
    local left_blank = left_line:match(escape(pair.left) .. '(%s*)$')
    if not left_blank then goto continue end
    del_l = #left_blank
    -- local right_part, right_blank = right_line:match('^(%s*)' .. escape(pair.right))
    local right_blank, right_part = right_line:match(fmt('^(%%s*)(%s)', escape(pair.right)))
    del_r = right_blank and #right_blank or #right_line:match('^%s*')
    if (del_l > 0 and del_r == 0) or (del_l == 1 and del_r == 1) then -- delete all blanks
    -- leave two blank if has right bracke, otherwise delete all blanks
    elseif del_l >= 1 and del_r >= 1 then
      del_l = right_blank and del_l - 1 or del_l
      del_r = right_blank and del_r - 1 or del_r
    elseif right_blank then -- del_l == 0, del bracket
      local lc, rc = get_count(left_line, right_line, pair.left, pair.right)
      del_l = 1
      del_r = lc > rc and del_r or del_r + #right_part
    else -- del_l == 0, del single bracket
      del_l = 1
      del_r = del_r - 1
    end
    goto finish
    ::continue::
  end

  if not del_l or (del_l == 1 and del_r == 0) then
    feedkeys('<bs>')
    return
  end

  ::finish::
  if del_l > 0 then left_line = left_line:sub(1, #left_line - del_l) end
  if del_r > 0 then right_line = right_line:sub(del_r + 1) end
  vim.api.nvim_set_current_line(left_line .. right_line)
  set_cursor(0, left_line)
end

function Pairs:type_enter()
  local left_line, right_line = get_line()

  local bnl, bnr, has_right
  for _, pair in ipairs(Pairs:get_pairs()) do
    local left_blank = left_line:match(escape(pair.left) .. '(%s*)$')
    local right_blank = right_line:match('^(%s*)' .. escape(pair.right))

    if pair.opts.triplet then
      has_right = right_line:match('^%s*' .. string.rep(escape(pair.right), 3))
    else
      has_right = pair.opts.cross_line and right_blank
    end

    if left_blank or right_blank then
      bnl = left_blank and #left_blank or #left_line:match('%s*$')
      bnr = right_blank and #right_blank or #right_line:match('^%s*')
      break
    end
  end

  if not bnl and not bnr then
    bnl = #left_line:match('%s*$')
    bnr = #right_line:match('^%s*')
  end

  left_line = bnl == 0 and left_line or left_line:sub(1, #left_line - bnl)
  right_line = bnr == 0 and right_line or right_line:sub(bnr + 1)
  vim.api.nvim_set_current_line(left_line .. right_line)
  set_cursor(0, left_line)

  feedkeys(has_right and "<cr><esc>O" or "<cr>")
end

return Pairs
