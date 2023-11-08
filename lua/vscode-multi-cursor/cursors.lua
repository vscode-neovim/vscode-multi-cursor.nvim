local M = {}

local api = vim.api
local fn = vim.fn

local Config = require 'vscode-multi-cursor.config'
local Cursor = require 'vscode-multi-cursor.cursor'
local STATE = require 'vscode-multi-cursor.state'
local util = require 'vscode-multi-cursor.util'

local compare_position = util.compare_position
local getline = util.getline
local feedkeys = util.feedkeys

---@alias MotionType 'char' | 'line' | 'block'

local mode2type = { v = 'char', V = 'line', ['\x16'] = 'block' }

---@param motion MotionType
---@param no_hl? boolean Avoid unnecessary highlights and screen flickering when starting multi-cursors from visual mode
local function create_cursor(motion, no_hl)
  STATE.check_buffer()

  local hl = no_hl ~= true
  local mode = api.nvim_get_mode().mode ---@type string

  if not motion then
    if mode == 'n' then
      vim.go.operatorfunc = [[v:lua.require'vscode-multi-cursor'.create_cursor]]
      return 'g@'
    elseif mode ~= '\x16' and mode:lower() ~= 'v' then
      return
    end
  end

  local select_type = motion and motion or mode2type[mode]

  feedkeys '<ESC>'

  local start_pos ---@type number[]
  local end_pos ---@type number[]
  if motion then
    end_pos = api.nvim_buf_get_mark(0, ']')
    start_pos = api.nvim_buf_get_mark(0, '[')
  else
    start_pos = { fn.line 'v', fn.col 'v' - 1 }
    end_pos = { fn.line '.', fn.col '.' - 1 }
  end

  if start_pos[1] > end_pos[1] or (start_pos[1] == end_pos[1] and start_pos[2] > end_pos[2]) then
    start_pos, end_pos = end_pos, start_pos
  end

  if select_type == 'char' then
    if start_pos[1] == end_pos[1] then
      local _, width = getline(start_pos[1])
      if width == 0 then
        return
      end
    end
    local cursor = Cursor.new(start_pos, end_pos)
    STATE.add_cursor(cursor, hl)
  elseif select_type == 'line' then
    for lnum = start_pos[1], end_pos[1] do
      local _, line_width = getline(lnum)
      if line_width > 0 then
        local cursor = Cursor.new({ lnum, 0 }, { lnum, line_width - 1 }, true)
        STATE.add_cursor(cursor, hl)
      end
    end
  elseif select_type == 'block' then
    local start_dis_col, end_dis_col
    do
      local start_line_text = fn.getline(start_pos[1])
      local end_line_text = fn.getline(end_pos[1])

      local start_col = start_pos[2]
      local end_col = end_pos[2]

      local start_part = fn.strpart(start_line_text, 0, start_col)
      local end_part = fn.strpart(end_line_text, 0, end_col)

      start_dis_col = fn.strdisplaywidth(start_part)
      end_dis_col = fn.strdisplaywidth(end_part)
    end

    for lnum = start_pos[1], end_pos[1] do
      local line, line_width = getline(lnum)
      if line_width > 0 then
        local start_col = util.discol_to_col(line, start_dis_col)
        local end_col = util.discol_to_col(line, end_dis_col)
        local safe_end_col = math.min(line_width - 1, end_col) -- zero indexed
        local safe_start_col = start_col < safe_end_col and start_col or safe_end_col
        local cursor = Cursor.new({ lnum, safe_start_col }, { lnum, safe_end_col })
        STATE.add_cursor(cursor, hl)
      end
    end
  end
end

---@param right boolean
---@param edge boolean
---@param opts? Config
local function start_multiple_cursors(right, edge, opts)
  local mode = api.nvim_get_mode().mode
  if mode:lower() == 'v' or mode == '\x16' then
    create_cursor(nil, true)
  end

  if #STATE.cursors == 0 then
    return
  end

  local config = Config.get(opts)

  if right then
    STATE.cursors[1]:jump_to_end()
  else
    STATE.cursors[1]:jump_to_start()
  end

  feedkeys('<ESC>' .. (right and 'a' or 'i'))

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

      if config.no_selection then
        range.start = range['end']
      end

      return range
    end,
    STATE.cursors
  )

  if vim.g.vscode then
    require('vscode-neovim').action('start-multiple-cursors', { args = { ranges } })
  end
end

---@param direction -1|1 -1 previous, 1 next
local function navigate(direction)
  if #STATE.cursors == 0 then
    return
  end
  if #STATE.cursors == 1 then
    STATE.cursors[1]:jump_to_start()
  end

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

--stylua: ignore start
M.cancel          = function()     return STATE.reset()                              end
M.start_left      = function(opts) return start_multiple_cursors(false, false, opts) end
M.start_left_edge = function(opts) return start_multiple_cursors(false, true, opts)  end
M.start_right     = function(opts) return start_multiple_cursors(true, true, opts)   end
M.prev_cursor     = function()     return navigate(-1)                               end
M.next_cursor     = function()     return navigate(1)                                end
M.create_cursor   = function(...)  return create_cursor(...)                         end
--stylua: ignore end

---------------------------
---- Flash integration ----
---------------------------

local function with_flash(func)
  return function(...)
    local ok, flash = pcall(require, 'flash')
    if ok then
      func(flash, ...)
    else
      vim.notify "Can't load flash, make sure you have installed flash.nvim"
    end
  end
end
---Create cursor using flash
M.flash_char = with_flash(function(flash)
  flash.jump {
    search = { multi_window = false },
    action = function(match)
      local pos = match.pos
      local _, width = getline(pos[1])
      if width > 0 then
        STATE.add_cursor(Cursor.new(pos, pos))
      end
      flash.jump { continue = true }
    end,
  }
end)

---Create cursor using flash
M.flash_word = with_flash(function(flash)
  flash.jump {
    pattern = '.',
    search = {
      multi_window = false,
      mode = function(pattern)
        if pattern:sub(1, 1) == '.' then
          pattern = pattern:sub(2)
        end
        return ([[\<%s\w*\>]]):format(pattern), ([[\<%s]]):format(pattern)
      end,
    },
    jump = { pos = 'range' },
    action = function(match)
      STATE.add_cursor(Cursor.new(match.pos, match.end_pos))
      flash.jump { continue = true }
    end,
  }
end)

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
    callback = STATE.check_buffer,
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
    k({ 'n' }, 'mcs', M.flash_char, { desc = 'Create cursor using flash' })
    k({ 'n' }, 'mcw', M.flash_word, { desc = 'Create selection using flash' })
  end
end

return M
