# neogen
A better Neovim documentation generator

![](./.images/recording_1.mov)

## Warning

This project is still in alpha !

Work In progress:
- lua: `@return`, `@param`

## Installation

1. Packer

```lua
use { 
    "danymat/neogen", 
    config = function()
        require('neogen').setup {
            enabled = true
        }
    end
}
```

## Usage

I exposed a command `:Neogen` to generate the annotations.
You can bind it to your keybind of choice:

```lua
vim.api.nvim_set_keymap("n", "<Leader>ng", ":Neogen<CR>", {})
```

If you are inside a function, it'll generate the documentation for you with Emmylua annotation convention

