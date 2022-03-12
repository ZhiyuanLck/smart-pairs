local M = {}
local fmt = string.format

--- vim warning
---@param msg string @message
function M.warn(msg)
  vim.cmd(fmt([[
    echohl WarningMsg
    echom "smart-pairs warning: %s"
    echohl None
  ]], msg:gsub('"', '\\"')))
end

return M
