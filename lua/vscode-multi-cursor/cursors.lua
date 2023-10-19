local api = vim.api

local util = require 'vscode-multi-cursor.utils'
local Cursor = require 'vscode-multi-cursor.cursor'
local Config = require 'vscode-multi-cursor.config'

local compare_position = util.compare_position
local is_intersect = util.is_intersect
local getline = util.getline

---@alias MotionType 'char' | 'line' | 'block'

local STATE = {
  bufnr = 0, ---@type integer
  cursors = {}, ---@type Cursor[]
}

---@param cursor Cursor
---@param highlight boolean
---@return boolean
local function add_cursor(cursor, highlight)
  local ignore = false

  STATE.cursors = vim.tbl_filter(
    ---@param other Cursor
    function(other)
      if is_intersect(cursor.range, other.range) then
        ignore = true
        other:dispose()
        return false
      end
      return true
    end,
    STATE.cursors
  )

  if not ignore then
    table.insert(STATE.cursors, cursor)
    if highlight ~= false then cursor:highlight() end
  end

  table.sort(
    STATE.cursors,
    function(a, b) return compare_position(a.range.start, b.range.start) == -1 end
  )

  return not ignore
end

local function reset()
  STATE.bufnr = api.nvim_get_current_buf()
  for _, cursor in ipairs(STATE.cursors) do
    cursor:dispose()
  end
  STATE.cursors = {}
end

---@param motion MotionType
---@param no_hl? boolean Avoid unnecessary highlights and screen flickering when starting multi-cursors from visual mode
---@param cb? function
local function create_cursor(motion, no_hl, cb)
  local hl = no_hl ~= true
  local mode = api.nvim_get_mode().mode ---@type string
  if mode == 'i' then return end
  local curbuf = api.nvim_get_current_buf()
  if curbuf ~= STATE.bufnr then reset() end

  if not motion then
    if mode == 'n' then
      vim.go.operatorfunc = [[v:lua.require'vscode-multi-cursor'.create_cursor]]
      return 'g@'
    elseif mode:lower() ~= 'v' and mode ~= '\x16' then
      return
    end
  end

  api.nvim_input '<ESC>'

  vim.defer_fn(function()
    local _start_pos = api.nvim_buf_get_mark(0, motion and '[' or '<') ---@type number[]
    local _end_pos = api.nvim_buf_get_mark(0, motion and ']' or '>') ---@type number[]
    local select_type ---@type MotionType
    if motion then
      select_type = motion
    else
      if mode == 'v' then
        select_type = 'char'
      elseif mode == 'V' then
        select_type = 'line'
      elseif mode == '\x16' then
        select_type = 'block'
      else
        return
      end
    end

    local start_pos, end_pos = _start_pos, _end_pos
    if
      _start_pos[1] > _end_pos[1] or (_start_pos[1] == _end_pos[1] and _start_pos[2] > _end_pos[2])
    then
      start_pos, end_pos = _end_pos, _start_pos
    end

    if select_type == 'char' then
      if start_pos[1] == end_pos[1] then
        local _, width = getline(start_pos[1])
        if width == 0 then return end
      end
      local cursor = Cursor.new(start_pos, end_pos)
      add_cursor(cursor, hl)
    elseif select_type == 'line' then
      for lnum = start_pos[1], end_pos[1] do
        local _, line_width = getline(lnum)
        if line_width > 0 then
          local cursor = Cursor.new({ lnum, 0 }, { lnum, line_width - 1 }, true)
          add_cursor(cursor, hl)
        end
      end
    elseif select_type == 'block' then
      local start_col = start_pos[2]
      local end_col = end_pos[2]
      for lnum = start_pos[1], end_pos[1] do
        local _, line_width = getline(lnum)
        if line_width > 0 then
          local safe_end_col = math.min(line_width - 1, end_col) -- zero indexed
          local safe_start_col = start_col < safe_end_col and start_col or safe_end_col
          local cursor = Cursor.new({ lnum, safe_start_col }, { lnum, safe_end_col })
          add_cursor(cursor, hl)
        end
      end
    end

    if cb then cb() end
  end, 30)
end

---@param right boolean
---@param edge boolean
---@param opts? Config
local function _start_multiple_cursors(right, edge, opts)
  if #STATE.cursors == 0 then return end

  local config = Config.get(opts)

  if right then
    STATE.cursors[1]:jump_to_end()
  else
    STATE.cursors[1]:jump_to_start()
  end
  api.nvim_input('<ESC>' .. (right and 'a' or 'i'))

  local ranges = vim.tbl_map(
    ---@param cursor Cursor
    function(cursor)
      local range ---@type lsp.Range
      if right then
        range = cursor:right_range()
      elseif cursor.is_whole_line then
        range = edge and cursor:left_edge_range() or cursor:left_range()
      else
        range = cursor:left_edge_range()
      end

      local start, end_ = range.start, range['end']
      if start.line == end_.line and math.abs(start.character - end_.character) == 1 then
        range.start = end_
      end

      if config.no_selection then range.start = range['end'] end

      return range
    end,
    STATE.cursors
  )
  if vim.g.vscode then
    require('vscode-neovim').action('start-multiple-cursors', { args = { ranges } })
  end
end

---@param right boolean
---@param edge boolean
---@param opts? Config
local function start_multiple_cursors(right, edge, opts)
  local mode = api.nvim_get_mode().mode
  if mode:lower() == 'v' or mode == '\x16' then
    create_cursor(nil, true)
    vim.defer_fn(function() _start_multiple_cursors(right, edge, opts) end, 60)
  else
    _start_multiple_cursors(right, edge, opts)
  end
end

---@param direction -1|1 -1 previous, 1 next
local function navigate(direction)
  if #STATE.cursors == 0 then return end
  if #STATE.cursors == 1 then STATE.cursors[1]:jump_to_start() end

  local curr_pos = vim.lsp.util.make_position_params(0, 'utf-16').position
  local cursor
  if direction == -1 then
    cursor = STATE.cursors[#STATE.cursors]
    for i = #STATE.cursors, 1, -1 do
      if compare_position(STATE.cursors[i].range['end'], curr_pos) == -1 then
        cursor = STATE.cursors[i]
        break
      end
    end
  else
    cursor = STATE.cursors[1]
    for i = 1, #STATE.cursors do
      if compare_position(STATE.cursors[i].range.start, curr_pos) == 1 then
        cursor = STATE.cursors[i]
        break
      end
    end
  end
  cursor:jump_to_start()
end

---Create cursor using flash
local flash_jump
flash_jump = function()
  local ok, flash = pcall(require, 'flash')
  if not ok then
    vim.notify "Can't load flash, make sure you have installed flash.nvim"
    return
  end
  flash.jump {
    search = { multi_window = false },
    action = function(match, state)
      local pos = match.pos
      local _, width = getline(pos[1])
      if width > 0 then add_cursor(Cursor.new(pos, pos)) end
      state:restore()
      flash_jump()
    end,
  }
end

local M = {
  --stylua: ignore start
  cancel = function() reset() end,
  start_left = function(opts) start_multiple_cursors(false, false, opts) end,
  start_left_edge = function(opts) start_multiple_cursors(false, true, opts) end,
  start_right = function(opts) start_multiple_cursors(true, true, opts) end,
  prev_cursor = function() navigate(-1) end,
  next_cursor = function() navigate(1) end,
  create_cursor = create_cursor,
  flash_jump = flash_jump,
  --stylua: ignore end
}

function M.set_highlight()
  api.nvim_set_hl(0, 'VSCodeCursor', { bg = '#177cb0', fg = '#ffffff', default = true })
  api.nvim_set_hl(0, 'VSCodeCursorRange', { bg = '#48c0a3', fg = '#ffffff', default = true })
end

function M.setup(opts)
  Config.setup(opts)

  M.set_highlight()

  -- Autocmds
  local group = api.nvim_create_augroup('vscode-multiple-cursors', {})
  api.nvim_create_autocmd(
    { 'VimEnter', 'ColorScheme' },
    { group = group, callback = M.set_highlight }
  )
  api.nvim_create_autocmd({ 'WinEnter' }, {
    group = group,
    callback = function()
      if api.nvim_get_current_buf() ~= STATE.bufnr then M.cancel() end
    end,
  })
  api.nvim_create_autocmd({ 'InsertEnter', 'TextChanged' }, {
    group = group,
    callback = M.cancel,
  })

  -- Mappings
  if Config.default_mappings then
    local k = vim.keymap.set
    k({ 'n', 'x' }, 'mc', M.create_cursor, { expr = true, desc = 'Create cursor' })
    k({ 'n' }, 'mcc', M.cancel, { desc = 'Cancel/Clear all cursors' })
    k({ 'n', 'x' }, 'mi', M.start_left, { desc = 'Start cursors on the left' })
    k({ 'n', 'x' }, 'mI', M.start_left_edge, { desc = 'Start cursors on the left edge' })
    k({ 'n', 'x' }, 'ma', M.start_right, { desc = 'Start cursors on the right' })
    k({ 'n', 'x' }, 'mA', M.start_right, { desc = 'Start cursors on the right' })
    k({ 'n' }, '[mc', M.prev_cursor, { desc = 'Goto prev cursor' })
    k({ 'n' }, ']mc', M.next_cursor, { desc = 'Goto next cursor' })
    k({ 'n' }, 'mcs', M.flash_jump, { desc = 'Create cursor using flash' })
  end
end

return M
