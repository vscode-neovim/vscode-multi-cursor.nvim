# vscode-multi-cursor

This plugin will help you create multiple selections (multi-cursor) in VSCode.

## Installation

Install the plugin with your preferred package manager:

[lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'vscode-neovim/vscode-multi-cursor.nvim',
  event = 'VeryLazy',
  cond = not not vim.g.vscode,
}
```

## Configuration

Default options:

```lua
require('vscode-multi-cursor').setup { -- Config is optional
  -- Whether to set default mappings
  default_mappings = true,
  -- If set to true, only multiple cursors will be created without multiple selections
  no_selection = false
}
```

Default mappings:

```lua
local cursors = require('vscode-multi-cursor')

local k = vim.keymap.set
k({ 'n', 'x' }, 'mc', cursors.create_cursor, { expr = true, desc = 'Create cursor' })
k({ 'n' }, 'mcc', cursors.cancel, { desc = 'Cancel/Clear all cursors' })
k({ 'n', 'x' }, 'mi', cursors.start_left, { desc = 'Start cursors on the left' })
k({ 'n', 'x' }, 'mI', cursors.start_left_edge, { desc = 'Start cursors on the left edge' })
k({ 'n', 'x' }, 'ma', cursors.start_right, { desc = 'Start cursors on the right' })
k({ 'n', 'x' }, 'mA', cursors.start_right, { desc = 'Start cursors on the right' })
k({ 'n' }, '[mc', cursors.prev_cursor, { desc = 'Goto prev cursor' })
k({ 'n' }, ']mc', cursors.next_cursor, { desc = 'Goto next cursor' })
k({ 'n' }, 'mcs', cursors.flash_jump, { desc = 'Create cursor using flash' })
```

You can refer to customize the mappings.

## Usage

All examples use the default mappings.

Firstly, this plugin is purely for assisting in creating multiple cursors in vscode and does not include any editing functionality.

The basic usage flow is as follows: 1. Add cursors 2. Start editing

### Add selections (cursors)

- `mc` - `create_cursor`: Create selections (cursors)

It can be used in operator pending mode.

For example, you can use `mciw` to add a selection of the word under the cursor, use `mcl` to add the current cursor position, `mce` `mcj`, etc.

You can define selections and cursors by selecting any content in visual mode and then pressing `mc`.

![basic](https://github.com/vscode-neovim/vscode-multi-cursor.nvim/assets/47070852/7ed98334-ccfb-4d35-bbf0-1f631c01255a)

### Start editing

- `mi` - `start_left`: Start editing to the left of the cursor range. In visual line mode, the cursor will be positioned at the first non-space character
- `mI` - `start_left_edge`: Start editing at the far left of the cursor range
- `ma` - `start_right`: Start editing to the right of the cursor range
- `mA` - `start_right`: Same as `ma`

Note: You can press `mc` in visual mode to start editing directly.

All `start` functions accept an optional options. Fields are the same as the plugin options.

For example, remapping vim's `I` and `A` in visual mode:

```lua
local k = vim.keymap.set
k({ 'x' }, 'I', function()
    local mode = api.nvim_get_mode().mode
    M.start_left_edge { no_selection = mode == '\x16' }
end)
k({ 'x' }, 'A', function()
    local mode = api.nvim_get_mode().mode
    M.start_right { no_selection = mode == '\x16' }
end)
```

### Clear all selections (cursors)

- `mcc` - `cancel` Clear all cursors

### Navigate through cursors

- `[mc` - `prev_cursor`: Go to the previous cursor position
- `]mc` - `next_cursor`: Go to the next cursor position

### Flash integration

You need to install `folke/flash.nvim` first.

- `mcs` - `flash_jump`: define cursors using the jump feature combined with `flash`.

![flash](https://github.com/vscode-neovim/vscode-multi-cursor.nvim/assets/47070852/1a1dc777-e394-4a50-882b-703b3cfc892d)

### Wrapped VSCode commands

```lua
local C = require 'vscode-multi-cursor'
```

- `C.addSelectionToNextFindMatch`

    Wraps `editor.action.addSelectionToNextFindMatch`, [Ctrl+D](https://code.visualstudio.com/docs/editor/codebasics#:~:text=these%20default%20shortcuts.-,Ctrl%2BD,-selects%20the%20word) in VSCode.


- `C.addSelectionToPreviousFindMatch`

    Wraps `editor.action.addSelectionToPreviousFindMatch`

- `C.selectHighlights`

    Wraps `editor.action.selectHighlights`, [Ctrl+Shift+L](https://code.visualstudio.com/docs/editor/codebasics#:~:text=more%20cursors%20with-,Ctrl%2BShift%2BL,-%2C%20which%20will%20add) in VSCode.
