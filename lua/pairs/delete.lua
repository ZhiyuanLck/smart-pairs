local M = {}
local fmt = string.format
local u = require('pairs.utils')
local P = require('pairs')

local function del_empty_lines()
  local cur_line = vim.api.nvim_get_current_line()
  local empty_line = cur_line:match('^%s*$') ~= nil
  local empty_pre

  if not empty_line then
    local left_line = u.get_cursor_l()
    empty_pre = left_line:match('^%s*$') ~= nil
    if not empty_pre then return false end
  end

  local opts = P.delete.empty_line

  if not opts.enable then
    u.feedkeys('<bs>')
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

  local left, has_left
  if line then
    for _, pair in ipairs(P:get_pairs()) do
      left = line:match(fmt('(%s)%%s*$', u.escape(pair.left)))
      if left then
        has_left = pair.opts.cross_line
        break
      end
    end
  end

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

  local has_right
  if has_left and line then
    has_right = line:match(fmt('^%%s*(%s)', u.escape(P:get_right(left))))
  end

  -- 0-indexed line index of first nonempty line when searching below
  local below_idx = cur

  -- if cursor is in the start of line
  if empty_pre then
    if below_idx - above_idx <= 2 then
      u.feedkeys('<bs>')
      return true
    end
  end

  -- empty lines in the start of file
  if above_idx < 0 then
    if opts.enable_start then
      if below_idx ~= end_nr then
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
  local trigger_text = indent2 > 0 and indent2 - indent1 <= opts.trigger_indent_level.text
  local loose_trigger_bracket = indent2 - indent1 <= opts.trigger_indent_level.bracket
  local trigger_bracket = indent2 > 0 and loose_trigger_bracket

  -- inside brackets, all blanks are deleted
  if has_left and has_right then
    if opts.enable_bracket and loose_trigger_bracket then
      local line2 = u.get_line(below_idx):match('^%s*(.-)$')
      u.del_lines(above_idx + 1, below_idx + 1)
      u.set_line(above_idx, line1 .. line2)
      u.set_cursor(above_idx + 1, vim.fn.strlen(line1))
    else
      u.feedkeys('<bs>')
    end
  -- multiple empty lines
  elseif below_idx - above_idx > 2 then
    if opts.enable_multiline then
      u.set_line(above_idx, line1)
      if empty_pre then
        local col = #u.get_line(below_idx):match('^%s*')
        u.del_lines(above_idx + 1, below_idx - 1)
        u.set_cursor(above_idx + 3, col)
      else
        u.del_lines(above_idx + 1, below_idx)
        u.set_cursor(above_idx + 1, line1)
        u.feedkeys('<cr>')
      end
    else
      u.feedkeys('<bs>')
    end
  -- one empty line
  elseif opts.enable_oneline and not empty_pre then
    u.set_line(above_idx, line1)
    if left then
      u.feedkeys(trigger_bracket and '<c-u><bs>' or '<bs>')
    else
      u.feedkeys(trigger_text and '<c-u><bs>' or '<bs>')
    end
  else
    u.feedkeys('<bs>')
  end
  return true
end

function M.type()
  if del_empty_lines() then return end

  local left_line, right_line = u.get_cursor_lr()

  local del_l, del_r
  for _, pair in ipairs(P:get_pairs()) do
    local left_blank = left_line:match(u.escape(pair.left) .. '(%s*)$')
    if not left_blank then goto continue end
    del_l = #left_blank
    -- local right_part, right_blank = right_line:match('^(%s*)' .. escape(pair.right))
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
      del_r = lc > rc and del_r or del_r + #right_part
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
  vim.api.nvim_set_current_line(left_line .. right_line)
  u.set_cursor(0, left_line)
end

return M
