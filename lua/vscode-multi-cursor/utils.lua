local M = {}

local api = vim.api
local fn = vim.fn

---Return the line text and it's width
---@param lnum number
---@return string
---@return number
function M.getline(lnum)
  local line = fn.getline(lnum)
  return line, api.nvim_strwidth(line)
end

---@param a lsp.Position
---@param b lsp.Position
---@return -1|0|1 -1 before, 0 equal, 1 after
function M.compare_position(a, b)
  if a.line > b.line then return 1 end
  if a.line == b.line and a.character > b.character then return 1 end
  if a.line == b.line and a.character == b.character then return 0 end
  return -1
end

---@param p lsp.Position
---@param r lsp.Range
function M.position_in_range(p, r)
  return M.compare_position(p, r.start) >= 0 and M.compare_position(p, r['end']) <= 0
end

---@param a lsp.Range
---@param b lsp.Range
---@return boolean
function M.is_intersect(a, b)
  return M.position_in_range(a.start, b)
    or M.position_in_range(a['end'], b)
    or M.position_in_range(b.start, a)
    or M.position_in_range(b['end'], a)
end

return M
