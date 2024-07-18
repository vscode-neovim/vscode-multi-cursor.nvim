---@diagnostic disable: duplicate-set-field
local M = {}

local api = vim.api
local fn = vim.fn

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
    end_pos = { end_pos[1], #fn.getline(end_pos[1]) }
  end

  api.nvim_win_set_cursor(0, end_pos)

  return vim.lsp.util.make_given_range_params(start_pos, end_pos, 0, 'utf-16').range
end

function M.char_at_col(line, byte_col)
  local line_str = fn.getline(line)
  local char_idx = fn.charidx(line_str, (byte_col - 1))
  local char_nr = fn.strgetchar(line_str, char_idx)
  if char_nr ~= -1 then
    return fn.nr2char(char_nr)
  end
end

if fn.has 'nvim-0.10.0' == 0 then
  M.virtcol2col = fn.virtcol2col
else
  M.virtcol2col = function(winid, lnum, virtcol)
    local byte_idx = fn.virtcol2col(winid, lnum, virtcol) - 1
    local buf = api.nvim_win_get_buf(winid)
    local line = M.get_line(buf, lnum - 1)
    local char_idx = fn.charidx(line, byte_idx)
    local prefix = fn.strcharpart(line, 0, char_idx + 1)
    return #prefix
  end
end

return M
