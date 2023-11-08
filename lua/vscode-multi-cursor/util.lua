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
  if a.line > b.line then
    return 1
  end
  if a.line == b.line and a.character > b.character then
    return 1
  end
  if a.line == b.line and a.character == b.character then
    return 0
  end
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

function M.get_range()
  local mode = api.nvim_get_mode().mode

  local A = fn.getpos 'v'
  local B = fn.getpos '.'
  local start_pos = { A[2], A[3] - 1 }
  local end_pos = { B[2], B[3] - 1 }

  if start_pos[1] > end_pos[1] or (start_pos[1] == end_pos[1] and start_pos[2] > end_pos[2]) then
    start_pos, end_pos = end_pos, start_pos
  end

  if mode == 'V' then
    start_pos = { start_pos[1], 0 }
    end_pos = { end_pos[1], math.max(0, api.nvim_strwidth(fn.getline(end_pos[1])) - 1) }
  end

  api.nvim_win_set_cursor(0, end_pos)

  return vim.lsp.util.make_given_range_params(start_pos, end_pos, 0, 'utf-16').range
end

---display-col to col
---@param line string
---@param discol number
function M.discol_to_col(line, discol)
  local col = 0
  local max_col = api.nvim_strwidth(line)
  local curr_col, curr_discol
  while col <= max_col do
    curr_col = math.floor((col + max_col) / 2)
    curr_discol = fn.strdisplaywidth(fn.strpart(line, 0, curr_col))
    if curr_discol == discol then
      return curr_col
    elseif curr_discol > discol then
      max_col = curr_col - 1
    else
      col = curr_col + 1
    end
  end
  return curr_col
end

return M
