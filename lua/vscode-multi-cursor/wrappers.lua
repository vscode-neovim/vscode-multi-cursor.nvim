local M = {}

local function action(name, range, callback, restore_selection)
  return require('vscode-neovim').action(name, {
    range = range,
    callback = callback,
    restore_selection = restore_selection,
  })
end
local function defer(func, timeout) return vim.defer_fn(func, timeout or 50) end
local function get_range() return vim.lsp.util.make_given_range_params(nil, nil, 0, 'utf-16').range end
local function input(keys) return vim.api.nvim_input(keys) end

---@param next boolean true -> Next find math; false -> Previous find match
local function addSelectionToFindMatch(next)
  local cmd = ('editor.action.addSelectionTo%sFindMatch'):format(next and 'Next' or 'Previous')
  local do_cmd = function(cb) action(cmd, nil, cb) end
  local mode = vim.api.nvim_get_mode().mode

  if mode == 'i' then
    do_cmd()
    return
  end

  if mode == 'n' then
    do_cmd(function()
      input '<ESC>'
      defer(do_cmd)
    end)
    return
  end

  if mode:lower() == 'v' then
    input '<ESC>a'
    defer(function()
      action('noop', get_range(), function() defer(do_cmd) end, false)
    end)
    return
  end
end

M.addSelectionToNextFindMatch = function() addSelectionToFindMatch(true) end
M.addSelectionToPreviousFindMatch = function() addSelectionToFindMatch(false) end

function M.selectHighlights()
  local mode = vim.api.nvim_get_mode().mode
  local do_cmd = function() action 'editor.action.selectHighlights' end
  if mode == 'i' then
    do_cmd()
  elseif mode == 'n' then
    input 'a'
    defer(do_cmd)
  elseif mode:lower() == 'v' then
    input '<ESC>a'
    defer(function()
      action('noop', get_range(), function() defer(do_cmd) end, false)
    end)
  end
end

return M
