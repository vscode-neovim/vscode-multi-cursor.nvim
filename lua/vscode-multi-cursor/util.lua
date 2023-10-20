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

function M.feedkeys(keys)
  return api.nvim_feedkeys(api.nvim_replace_termcodes(keys, true, true, true), 'n', false)
end

---@param start_pos integer[]|nil {row, col} mark-indexed position.
---@param end_pos integer[]|nil {row, col} mark-indexed position.
---@param bufnr integer|nil
function M.get_range(start_pos, end_pos, bufnr)
  return vim.lsp.util.make_given_range_params(
    start_pos or { fn.line 'v', fn.col 'v' - 1 },
    end_pos or { fn.line '.', fn.col '.' - 1 },
    bufnr or 0,
    'utf-16'
  ).range
end

return M
