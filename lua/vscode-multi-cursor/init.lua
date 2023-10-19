local M = {}

local is_set

function M.setup(opts) require('vscode-multi-cursor.cursors').setup(opts) end

return setmetatable(M, {
  __index = function(_, k)
    if not is_set then
      M.setup()
      is_set = true
    end
    return require('vscode-multi-cursor.cursors')[k] or require('vscode-multi-cursor.wrappers')[k]
  end,
})
