local M = {}

function M.setup(opts) require('vscode-multi-cursor.cursors').setup(opts) end

_G._C = setmetatable(M, {
  __index = function(_, k)
    return require('vscode-multi-cursor.cursors')[k] or require('vscode-multi-cursor.wrappers')[k]
  end,
})

return _C
