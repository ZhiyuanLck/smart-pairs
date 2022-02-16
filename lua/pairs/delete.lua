local M = {}
local fmt = string.format
local u = require('pairs.utils')
local P = require('pairs')

-- delete to less indent
local function delete_less_indent()
  local cur_line = vim.api.nvim_get_current_line()
  local cur_wd = vim.fn.strdisplaywidth(cur_line:match('^%s*'))
  if cur_wd == 0 then u.feedkeys('<bs>') return end
  local cur = vim.fn.line('.') - 2
  while (cur >= 0) do
    local indent = u.get_line(cur):match('^%s*')
    if vim.fn.strdisplaywidth(indent) < cur_wd then
      -- why need extra ()?
      vim.api.nvim_set_current_line((cur_line:gsub('^%s*', indent)))
      u.set_cursor(0, indent)
      return
    end
    cur = cur - 1
  end
  u.feedkeys('<bs>')
end

local function del_empty_lines()
  local cur_line = vim.api.nvim_get_current_line()
  local left_line = u.get_cursor_l()
  local empty_line = cur_line:match('^%s*$') ~= nil
  local empty_pre

  if not empty_line then
    empty_pre = left_line:match('^%s*$') ~= nil
    if not empty_pre then return false end
  end

  local opts = P.delete.empty_line

  if not u.enable(opts.enable_cond) then
    opts.enable_fallback()
    return true
  end

  -- search up the first nonempty line
  local linenr = vim.fn.line('.')
  local cur = linenr - 2

  local line
  while (cur >= 0) do
    line = u.get_line(cur)
    if not line:match('^%s*$') then break end
    cur = cur - 1
  end

  local has_left = P:has_left(line)

  -- 0-indexed line index of first nonempty line when searching up
  local above_idx = cur

  -- search down the first nonempty line
  cur =  empty_pre and linenr - 1 or linenr -- handle empty pre
  local end_nr = vim.fn.line('$')
  while (cur < end_nr) do
    line = u.get_line(cur)
    if not line:match('^%s*$') then break end
    cur = cur + 1
  end

  local has_right = P:has_right(line)

  -- 0-indexed line index of first nonempty line when searching below
  local below_idx = cur

  local enable_sub = function(cond)
    return u.enable(opts.enable_sub[cond])
  end

  -- empty lines in the start of file
  if above_idx < 0 then
    if enable_sub('start') then
      if empty_pre and linenr == 1 then
        u.feedkeys('<bs>')
      elseif below_idx ~= end_nr then
        local col = u.get_line(below_idx):match('^%s*')
        u.del_lines(0, below_idx)
        u.set_cursor(1, col)
      else
        u.del_lines(0, below_idx)
      end
    else
      u.feedkeys('<bs>')
    end
    return true
  end

  -- local line1 = vim.api.nvim_buf_get_lines(0, above_idx, above_idx + 1, true)[1]:match('^(.-)%s*$')
  local line1 = u.get_line(above_idx):match('^(.-)%s*$')
  local indent1 = u.get_indent_level(line1)
  local indent2 = u.get_indent_level(cur_line)
  -- if indent2 == 0, i.e. cursor col is 1 then <c-u> will act as <bs>
  local loose_trigger_bracket = indent2 - indent1 <= opts.trigger_indent_level
  local trigger_bracket = indent2 > 0 and loose_trigger_bracket

  -- inside brackets, all blanks are deleted
  if has_right then
    if enable_sub('inside_brackets') then
      if below_idx - above_idx > 2 then
        u.del_lines(above_idx + 1, below_idx - 1)
        u.set_line(above_idx + 1, left_line)
        u.set_cursor(above_idx + 2, left_line)
      elseif loose_trigger_bracket then
        local line2 = u.get_line(below_idx):match('^%s*(.-)%s*$')
        u.del_lines(above_idx + 1, below_idx + 1)
        u.set_line(above_idx, line1 .. line2)
        u.set_cursor(above_idx + 1, vim.fn.strlen(line1))
      else
        u.feedkeys('<bs>')
      end
    else
      u.feedkeys('<bs>')
    end
  -- when there is a left bracket
  elseif has_left then
    if enable_sub('left_bracket') then
      u.set_line(above_idx, line1)
      if below_idx - above_idx > 1 and below_idx ~= end_nr then
        local col = #u.get_line(below_idx):match('^%s*')
        u.del_lines(above_idx + 1, below_idx)
        u.set_cursor(above_idx + 2, col)
      -- multiple empty lines at end of line
      elseif below_idx - above_idx > 2 and below_idx == end_nr then
        u.del_lines(above_idx + 1, below_idx - 1)
        u.set_line(above_idx + 1, left_line)
        u.set_cursor(above_idx + 2, left_line)
      else
        u.feedkeys(trigger_bracket and '<c-u><bs>' or '<bs>')
      end
    else
      u.feedkeys('<bs>')
    end
  -- multiple empty lines, delete to one empty line
  elseif below_idx - above_idx > 2 then
    if enable_sub('text_multi_line') then
      u.set_line(above_idx, line1)
      if empty_pre then
        local col = #u.get_line(below_idx):match('^%s*')
        u.del_lines(above_idx + 1, below_idx - 1)
        u.set_cursor(above_idx + 3, col)
      elseif below_idx - above_idx > 3 then
        u.del_lines(above_idx + 1, below_idx - 1)
        u.set_line(above_idx + 1, left_line)
        u.set_cursor(above_idx + 2, left_line)
      else
        u.feedkeys('<bs>')
      end
    else
      u.feedkeys('<bs>')
    end
  elseif enable_sub('text_delete_to_prev_indent') then
    delete_less_indent()
  else
    u.feedkeys('<bs>')
  end
  return true
end

local function del_current_line()
  local left_line, right_line = u.get_cursor_lr()

  -- number of chars to be delete on the lef and right
  local del_l, del_r
  for _, pair in ipairs(P:get_pairs()) do
    local left_blank = left_line:match(u.escape(pair.left) .. '(%s*)$')
    if not left_blank then goto continue end
    del_l = #left_blank
    local right_blank, right_part = right_line:match(fmt('^(%%s*)(%s)', u.escape(pair.right)))
    del_r = right_blank and #right_blank or #right_line:match('^%s*')
    if (del_l > 0 and del_r == 0) or (del_l == 1 and del_r == 1) then -- delete all blanks
    -- leave two blank if has right bracke, otherwise delete all blanks
    elseif del_l >= 1 and del_r >= 1 then
      del_l = right_blank and del_l - 1 or del_l
      del_r = right_blank and del_r - 1 or del_r
    elseif right_blank then -- del_l == 0, del bracket
      local lc, rc = P:get_count(left_line, right_line, pair.left, pair.right)
      del_l = 1
      -- respect balanced pair
      if (pair.opts.balanced and lc % 2 == 1 and rc % 2 == 1) or (not pair.opts.balanced and lc <= rc) then
        del_r = del_r + #right_part
      end
    else -- del_l == 0, del single bracket
      del_l = 1
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
  vim.api.nvim_set_current_line(left_line .. right_line:match('(.-)%s*$'))
  u.set_cursor(0, left_line)
end

function M.type()
  if not u.enable(P.delete.enable_cond) then
    return P.delete.enable_fallback() or ''
  end

  if del_empty_lines() then return '' end

  if not u.enable(P.delete.current_line.enable_cond) then
    return P.delete.current_line.enable_fallback() or ''
  end

  u.call(P.delete.before_hook)
  del_current_line()
  u.call(P.delete.after_hook)
  return ''
end

return M
