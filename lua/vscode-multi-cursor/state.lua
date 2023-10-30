local M = {}

local api = vim.api

local Config = require 'vscode-multi-cursor.config'
local util = require 'vscode-multi-cursor.util'

local buffer = 0 ---@type integer
local cursors = {} ---@type Cursor[]

---@param cursor Cursor
---@param highlight boolean
---@return boolean
function M.add_cursor(cursor, highlight)
  local ignore = false

  cursors = vim.tbl_filter(
    ---@param other Cursor
    function(other)
      if util.is_intersect(cursor.range, other.range) then
        ignore = true
        other:dispose()
        return false
      end
      return true
    end,
    cursors
  )

  if not ignore then
    table.insert(cursors, cursor)
    if highlight ~= false then
      cursor:highlight()
    end
  end

  table.sort(cursors, function(a, b)
    return util.compare_position(a.range.start, b.range.start) == -1
  end)

  return not ignore
end

function M.reset()
  if #cursors > 0 then
    buffer = api.nvim_get_current_buf()
    cursors = {}
    for _, buf in ipairs(api.nvim_list_bufs()) do
      api.nvim_buf_clear_namespace(buf, Config.ns, 0, -1)
    end
  end
end

function M.check_buffer()
  if buffer ~= api.nvim_get_current_buf() then
    M.reset()
  end
end

return setmetatable(M, {
  __index = function(_, k)
    if k == 'buffer' then
      return buffer
    elseif k == 'cursors' then
      return cursors
    end
  end,
})
