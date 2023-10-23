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
k({ 'n' }, 'mcs', cursors.flash_char, { desc = 'Create cursor using flash' })
k({ 'n' }, 'mcw', cursors.flash_word, { desc = 'Create selection using flash' })
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

Tips:

1. Add current word range and go to next

```lua
vim.keymap.set('n', '<C-d>', 'mciw*<Cmd>nohl<CR>', { remap = true })
```

<!-- vim.keymap.set('x', '<C-d>', [[y/\V<C-r>=escape(@",'/\')<CR><CR>gNmcgn<Cmd>nohl<Cr>]], { remap = true }) -->

![C-d](https://github.com/vscode-neovim/vscode-multi-cursor.nvim/assets/47070852/7e829df2-83e1-4343-beaf-5f8ce4e7e55b)

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

You can clear the existing cursor range by redefining the cursor within the existing cursor range.

![clear](https://github.com/vscode-neovim/vscode-multi-cursor.nvim/assets/47070852/9e28b2e6-cbb6-4790-b8dc-04a248e3e789)

### Navigate through cursors

- `[mc` - `prev_cursor`: Go to the previous cursor position
- `]mc` - `next_cursor`: Go to the next cursor position

### Flash integration

You need to install `folke/flash.nvim` first.

- `mcs` - `flash_char`: Defines the cursor on any character.

    ![flash_char](https://github.com/vscode-neovim/vscode-multi-cursor.nvim/assets/47070852/c3a98e00-6e54-4451-aaed-d57045e02968)

- `mcw` - `flash_word`: Defines the selection on any word.

    ![flash_word](https://github.com/vscode-neovim/vscode-multi-cursor.nvim/assets/47070852/dc9f3629-fa1b-4c8d-bfcc-e099c0b56699)

### Wrapped VSCode commands

Wraped some VSCode commands used for multi-cursor to make them work properly.

```lua
local C = require 'vscode-multi-cursor'
```

- `C.addSelectionToNextFindMatch`

  Wraps `editor.action.addSelectionToNextFindMatch`, [Ctrl+D](https://code.visualstudio.com/docs/editor/codebasics#:~:text=these%20default%20shortcuts.-,Ctrl%2BD,-selects%20the%20word) in VSCode.

- `C.addSelectionToPreviousFindMatch`

  Wraps `editor.action.addSelectionToPreviousFindMatch`

- `C.selectHighlights`

  Wraps `editor.action.selectHighlights`, [Ctrl+Shift+L](https://code.visualstudio.com/docs/editor/codebasics#:~:text=more%20cursors%20with-,Ctrl%2BShift%2BL,-%2C%20which%20will%20add) in VSCode.

For example, use `<C-d>` to add selection to next find match:

nvim config:

```lua
vim.keymap.set({ "n", "x", "i" }, "<C-d>", function()
  require("vscode-multi-cursor").addSelectionToNextFindMatch()
end)
```

vscode keybindings.json:

```json
{
  "args": "<C-d>",
  "command": "vscode-neovim.send",
  "key": "ctrl+d",
  "when": "editorFocus && neovim.init"
}
```

## Highlights

| Group               | Default                     | Description           |
| ------------------- | --------------------------- | --------------------- |
| `VSCodeCursor`      | bg: `#177cb0` fg: `#ffffff` | Left and right cursor |
| `VSCodeCursorRange` | bg: `#48c0a3` fg: `#ffffff` | Selected region       |
