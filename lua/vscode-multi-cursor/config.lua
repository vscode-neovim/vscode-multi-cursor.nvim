---@class Config
---@field default_mappings boolean
---@field no_selection boolean
---@field ns? number
local M = {
  ns = vim.api.nvim_create_namespace 'vscode-multi-cursor',
}

---@type Config
local defaults = {
  -- Whether to set default mappings
  default_mappings = true,
  -- If set to true, only multiple cursors will be created without multiple selections
  no_selection = false,
}

local config
function M.setup(opts)
  config = {}
  config = M.get(opts)
end

---@param opts? Config
---@return Config
function M.get(opts)
  opts = opts or {}
  local c = vim.tbl_extend('force', defaults, config or {})
  return vim.tbl_extend('force', c, opts or {})
end

return setmetatable(M, { __index = function(_, k) return config[k] end })
