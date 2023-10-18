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

```lua
require('vscode-multi-cursor').setup {
  default_mappings = true, -- Optional, defaults to true
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

`mc` can be used in operator pending mode.

For example, you can use `mciw` to add a selection of the word under the cursor, use `mcl` to add the current cursor position, `mce` `mcj`, etc.

You can define selections and cursors by selecting any content in visual mode and then pressing `mc`.

![basic](https://github.com/vscode-neovim/vscode-multi-cursor.nvim/assets/47070852/7ed98334-ccfb-4d35-bbf0-1f631c01255a)

### Start editing

- `mi` Start editing to the left of the cursor range, in visual line mode, the cursor will be positioned at the first non-space character
- `mI` Start editing at the far left of the cursor range
- `ma` Start editing to the right of the cursor range
- `mA` Same as `ma`

You can press `mc` in visual mode to start editing directly.

### Clear all selections (cursors)

- `mcc` Clear all cursors

### Navigate through cursors

- `[mc` - Go to the previous cursor position
- `]mc` - Go to the next cursor position

### Flash integration

You need to install `folke/flash.nvim` first.

Use `mcs` to define cursors using the jump feature combined with `flash`.

![flash](https://github.com/vscode-neovim/vscode-multi-cursor.nvim/assets/47070852/1a1dc777-e394-4a50-882b-703b3cfc892d)
