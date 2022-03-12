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

--- check the type of variable
---@param var any @variable of any type
---@param expect_type string @expected type of the variable
---@param allow_nil boolean @allow the variable to be nil, default false
function M.check_type(var, expect_type, allow_nil)
  local var_type = type(var)
  if (not allow_nil or val ~= nil) and var_type ~= expect_type then
    error(fmt('expect type %s, but get type %s', expect_type, var_type))
  end
end

return M
