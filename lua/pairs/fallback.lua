local M = {
  delete = {
    empty_line = {},
    current_line = {}
  },
}

local u = require('pairs.utils')

function M.enter()
  u.feedkeys('<cr>')
end

function M.space()
  u.feedkeys('<space>')
end

function M.delete()
  u.feedkeys('<bs>')
end

return M
