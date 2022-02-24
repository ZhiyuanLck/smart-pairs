local P     = require('pairs')
local u     = require('pairs.utils')
local fn    = vim.fn
local api   = vim.api
local fmt   = string.format
local match = string.match

local Del = {}

Del.__index = Del

function Del:new()
  local del = {}
  del.line_idx = fn.line('.') - 1
  del.cur_line = api.nvim_get_current_line()
  del.left_line, del.right_line = u.get_cursor_lr()
  del.empty_line = match(del.cur_line, '^%s*$') ~= nil
  del.empty_pre = not del.empty_line and match(del.left_line, '^%s*$') ~= nil
  return setmetatable(del, Del)
end

--- search up the first nonempty line
function Del:search_up()
  local cur = self.line_idx - 1
  local end_idx = cur - P.max_search_lines
  if end_idx < 0 then end_idx = 0 end
  while cur >= end_idx do
    local line = u.get_line(cur)
    if match(line, '^%s*$') == nil then
      self.has_left = P:has_left_end(line, self.right) ~= nil
      self.above_idx = cur
      self.above_line = match(line, '^(.-)%s*$')
      return
    end
    cur = cur - 1
  end
  self.has_left = false
  self.above_idx = -1
  self.start_file = true
end

--- search down the first nonempty line
function Del:search_down()
  if self.empty_pre then
    self.has_right = P:has_right_start(self.cur_line) ~= nil
    self.below_idx = self.line_idx
    self.below_line = self.cur_line
    self.below_right_line = match(self.below_line, '^%s*(.-)%s*$')
    return
  end
  local cur =  self.line_idx + 1
  local end_nr = fn.line('$')
  local end_idx = cur + P.max_search_lines
  if end_idx >= end_nr then end_idx = end_nr - 1 end
  while cur <= end_idx do
    local line = u.get_line(cur)
    if match(line, '^%s*$') == nil then
      self.right = P:has_right_start(line)
      self.has_right = self.right ~= nil
      self.below_idx = cur
      self.below_line = line
      self.below_right_line = match(self.below_line, '^%s*(.-)%s*$')
      return
    end
    cur = cur + 1
  end
  --- end of file
  self.has_right = false
  self.below_idx = end_nr
  self.end_file = true
end

--- delete all blanks
function Del:del_all_blank()
  if self.start_file then
    u.del_lines(self.above_idx + 1, self.below_idx)
    if not self.end_file then
      u.set_cursor(self.above_idx + 1, u.get_indent(self.below_line))
    end
  elseif self.end_file then
    u.del_lines(self.above_idx + 1, self.below_idx)
    u.set_line(self.above_idx, self.above_line)
    u.set_cursor(self.above_idx + 1, self.above_line)
  else
    u.del_lines(self.above_idx + 1, self.below_idx + 1)
    u.set_line(self.above_idx, self.above_line .. self.below_right_line)
    u.set_cursor(self.above_idx + 1, self.above_line)
  end
end

--- delete all but one empty lines
---@param line string: empty line will be set to line
---@param col number or string: set the cursor column to col, default at the empty line
---@param line_offset number: offset of linenr of the cursor, used for option 'one_above' and 'one_below'
function Del:leave_one(line, col, line_offset)
  u.del_lines(self.above_idx + 2, self.below_idx)
  if not self.start_file then
    u.set_line(self.above_idx, self.above_line)
  end
  u.set_line(self.above_idx + 1, line)
  u.set_cursor(self.above_idx + 2 + (line_offset or 0), col)
end

function Del:leave_zero_above()
  if self.start_file then
    self:leave_one(self.left_line, self.left_line)
  else
    u.del_lines(self.above_idx + 1, self.below_idx)
    u.set_cursor(self.above_idx + 1, self.above_line)
  end
end

function Del:leave_zero_below()
  if self.end_file then
    self:leave_one(self.left_line, self.left_line)
  else
    u.del_lines(self.above_idx + 1, self.below_idx)
    u.set_cursor(self.above_idx + 2, u.get_indent(self.below_line))
  end
end

function Del:do_multiline_action(opts)
  local actions = {
    delete_all = function() self:del_all_blank() end,
    leave_one_start = function() self:leave_one('', 0) end,
    leave_one_indent = function()
      local indent = u.get_indent(self.above_line) .. P:get_indent()
      self:leave_one(indent, indent)
    end,
    leave_one_cur = function() self:leave_one(self.left_line, self.left_line) end,
    leave_one_below = function() self:leave_one('', u.get_indent(self.below_line), 1) end,
    leave_one_above = function() self:leave_one('', self.above_line, -1) end,
    leave_zero_above = function() self:leave_zero_above() end,
    leave_zero_below = function() self:leave_zero_below() end,
  }
  local func = actions[opts.strategy] or opts.fallback
  func()
end

function Del:smart_del_one(opts)
  local indent1
  if self.has_right then
    local cur = self.above_idx
    local min_idx = cur - P.max_search_lines
    min_idx = min_idx < 0 and 0 or min_idx
    local ctn = {}
    while cur >= min_idx do
      local line = u.get_line(cur)
      local pair = P:has_left(line, ctn, self.right)
      if pair then
        indent1 = u.get_indent_level(line)
        break
      end
      cur = cur - 1
    end
  else
    indent1 = u.get_indent_level(self.above_line)
  end
  local indent2 = u.get_indent_level(self.cur_line)
  if indent2 - indent1 <= opts.trigger_indent_level then
    self:del_all_blank()
  else
    opts.fallback()
  end
end

function Del:do_oneline_action(opts)
  local actions = {
    delete_all = function() self:del_all_blank() end,
    leave_zero_above = function() self:leave_zero_above() end,
    leave_zero_below = function() self:leave_zero_below() end,
    smart = function() self:smart_del_one(opts) end,
  }
  local func = actions[opts.strategy] or opts.fallback
  func()
end

function Del:del_blank()
  local opts = self.empty_pre and P.delete.empty_pre or P.delete.empty_line
  self:search_down()
  self:search_up()
  if self.has_left or self.has_right then
    self.gap = self.below_idx - self.above_idx - 1
  elseif self.empty_pre then
    self.gap = self.line_idx - self.above_idx - 1
  else
    self.gap = self.line_idx - self.above_idx
  end

  if self.has_left then
    opts = self.has_right and opts.bracket_bracket or opts.bracket_text
  else
    opts = self.has_right and opts.text_bracket or opts.text_text
  end

  if self.gap > 1 then
    self:do_multiline_action(opts.multi)
  elseif self.gap == 1 then
    self:do_oneline_action(opts.one)
  else
    opts.fallback()
  end
end

local function del_current_line()
  local left_line, right_line = u.get_cursor_lr()

  --- number of chars to be delete on the lef and right
  local del_l, del_r
  for _, pair in ipairs(P:get_pairs()) do
    --- local left_blank = left_line:match(u.escape(pair.left) .. '(%s*)$')
    local left_part, left_blank = left_line:match(fmt('(%s)(%%s*)$', u.escape(pair.left)))
    if not left_blank then goto continue end
    del_l = #left_blank
    local right_blank, right_part = right_line:match(fmt('^(%%s*)(%s)', u.escape(pair.right)))
    del_r = right_blank and #right_blank or #right_line:match('^%s*')
    if (del_l > 0 and del_r == 0) or (del_l == 1 and del_r == 1) then --- delete all blanks
    --- leave two blank if has right bracke, otherwise delete all blanks
    elseif del_l >= 1 and del_r >= 1 then
      del_l = right_blank and del_l - 1 or del_l
      del_r = right_blank and del_r - 1 or del_r
    elseif right_blank then --- del_l == 0, del bracket
      --- local lc, rc = P:get_count(left_line, right_line, pair.left, pair.right)
      local lc, rc = P:get_cross_count(pair.left, pair.right)
      del_l = #left_part
      --- respect balanced pair
      if (pair.opts.balanced and lc % 2 == 1 and rc % 2 == 1) or (not pair.opts.balanced and lc <= rc) then
        del_r = del_r + #right_part
      end
    else --- del_l == 0, del single bracket
      del_l = #left_part
      del_r = del_r - 1
    end
    goto finish
    ::continue::
  end

  if not del_l or (del_l == 1 and del_r == 0) then
    u.feedkeys('<bs>')
    return
  end

  ::finish::
  if del_l > 0 then left_line = left_line:sub(1, #left_line - del_l) end
  if del_r > 0 then right_line = right_line:sub(del_r + 1) end
  local idx = fn.line('.') - 1
  api.nvim_buf_set_text(0, idx, fn.strlen(left_line), idx, fn.col('$') - fn.strlen(right_line) - 1, {''})
  u.set_cursor(0, left_line)
  u.remove_trailing_spaces()
end

function Del.type()
  if not u.enable(P.delete.enable_cond) then
    return P.delete.enable_fallback() or ''
  end

  u.call(P.delete.before_hook)
  local del = Del:new()
  if del.empty_line or del.empty_pre then
    local opts = del.empty_line and P.delete.empty_pre or P.delete.empty_line
    if not u.enable(opts.enable_cond) then
      return opts.enable_fallback() or ''
    end
    u.call(opts.before_hook)
    del:del_blank()
    u.call(opts.after_hook)
  elseif not u.enable(P.delete.current_line.enable_cond) then
    return P.delete.current_line.enable_fallback() or ''
  else
    u.call(P.delete.current_line.before_hook)
    del_current_line()
    u.call(P.delete.current_line.after_hook)
  end
  u.call(P.delete.after_hook)
  return ''
end

return Del
