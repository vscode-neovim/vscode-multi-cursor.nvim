local api, fn = vim.api, vim.fn

local Config = require 'vscode-multi-cursor.config'

---@param start_row number
---@param start_col number
---@param end_row number
---@param end_col number
---@param is_cursor boolean
---@return number
local function set_extmark(buf, start_row, start_col, end_row, end_col, is_cursor)
  return api.nvim_buf_set_extmark(buf, Config.ns, start_row, start_col, {
    end_row = end_row,
    end_col = end_col,
    hl_group = is_cursor and 'VSCodeCursor' or 'VSCodeCursorRange',
    priority = is_cursor and 9999 or 9998,
    strict = false,
  })
end

---@class Cursor
---@field range lsp.Range
---@field right_range fun(Cursor): lsp.Range
---@field left_range fun(Cursor): lsp.Range
---@field left_edge_range fun(Cursor): lsp.Range
---@field start_pos number[]
---@field end_pos number[]
---@field is_whole_line boolean
---@field bufnr number
---@field extmarks number[]
local M = {}

M.__index = M

function M:dispose()
  for _, id in ipairs(self.extmarks) do
    api.nvim_buf_del_extmark(self.bufnr, Config.ns, id)
  end
end

function M:right_range()
  return self.range
end

function M:left_range()
  local s_l = self.range.start.line
  local s_c = self.range.start.character
  local e_l = self.range['end'].line
  local e_c = self.range['end'].character

  local line = api.nvim_buf_get_lines(self.bufnr, s_l, s_l + 1, false)[1] or ''
  s_c = math.max(s_c, #(line:match '^%s*' or ''))
  if s_l == e_l and s_c > e_c then
    e_c = s_c
  end
  return { start = { line = e_l, character = e_c }, ['end'] = { line = s_l, character = s_c } }
end
function M:left_edge_range()
  return { start = self.range['end'], ['end'] = self.range.start }
end

function M:jump_to_start()
  return api.nvim_win_set_cursor(0, self.start_pos)
end

function M:jump_to_end()
  return api.nvim_win_set_cursor(0, self.end_pos)
end

function M:highlight()
  local s_row, s_col, e_row, e_col =
    self.start_pos[1] - 1, self.start_pos[2], self.end_pos[1] - 1, self.end_pos[2]
  -- range
  table.insert(self.extmarks, set_extmark(self.bufnr, s_row, s_col, e_row, e_col + 1, false))
  -- left cursor
  table.insert(self.extmarks, set_extmark(self.bufnr, s_row, s_col, s_row, s_col + 1, true))
  -- right cursor
  table.insert(self.extmarks, set_extmark(self.bufnr, e_row, e_col, e_row, e_col + 1, true))
end

---@param start_pos number[]
---@param end_pos number[]
---@param is_line boolean
---@return Cursor
function M.new(start_pos, end_pos, is_line)
  local self = setmetatable({}, M)
  self.start_pos = vim.deepcopy(start_pos)
  self.start_pos[2] = math.max(0, math.min(#fn.getline(start_pos[1]) - 1, start_pos[2]))
  self.end_pos = vim.deepcopy(end_pos)
  self.end_pos[2] = math.max(0, math.min(#fn.getline(end_pos[1]) - 1, end_pos[2]))
  self.is_whole_line = not not is_line
  self.bufnr = api.nvim_get_current_buf()
  self.extmarks = {}
  self.range = vim.lsp.util.make_given_range_params(start_pos, end_pos, self.bufnr, 'utf-16').range
  return self
end

return M
