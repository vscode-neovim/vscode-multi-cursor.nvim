local M = {}

function M.setup(opts) require('vscode-multi-cursor.cursors').setup(opts) end

return setmetatable(M, {
  __index = function(_, k) return require('vscode-multi-cursor.cursors')[k] end,
})
