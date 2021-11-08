<div align="center">
<img src="https://user-images.githubusercontent.com/5306901/130352268-226f51a7-b203-4e74-aa71-2e53cb276ac0.png" width=250><br>
	
# Neogen - Your Annotation Toolkit

</div>

# Table Of Contents

* [Features](#features)
* [Requirements](#requirements)
* [Installation](#installation)
* [Usage](#usage)
* [Configuration](#configuration)
* [Supported Languages](#supported-languages)
* [Adding Languages](#adding-languages)
* [GIFS](#gifs)


## Features

- Create annotations with one keybind, and jump your cursor using `Tab`.
- Defaults for multiple languages and annotation conventions
- Extremely customizable and extensible
- Written in lua

![screen2](https://user-images.githubusercontent.com/5306901/135055065-08def797-e5af-49c9-b530-dd5973045c4e.gif)

## Requirements

- Install [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)

## Installation

Use your favorite package manager to install Neogen, e.g:

```lua
use { 
    "danymat/neogen", 
    config = function()
        require('neogen').setup {
            enabled = true
        }
    end,
    requires = "nvim-treesitter/nvim-treesitter"
}
```

## Usage

I exposed a function to generate the annotations.

```lua
require('neogen').generate()
```

You can bind it to your keybind of choice, like so:

```lua
local opts = { noremap = true, silent = true }
vim.api.nvim_set_keymap("n", "<Leader>nf", ":lua require('neogen').generate()<CR>", opts)
```

Calling the `generate` function without any parameters will try to generate annotations for the current function.

You can provide some options for the generate, like so:

```lua
require('neogen').generate({
    type = "func" -- the annotation type to generate. Currently supported: func, class, type
})
```

For example, I can add an other keybind to generate class annotations:

```lua
local opts = { noremap = true, silent = true }
vim.api.nvim_set_keymap("n", "<Leader>nc", ":lua require('neogen').generate({ type = 'class' })<CR>", opts)
```

### Cycle between annotations

I added support passing cursor positionings in templates.

That means you can now cycle your cursor between different parts of the annotation.

The default keybind is `<C-e>` in insert mode. 

If you want to add `<Tab>` completion instead, be sure you don't have a completion plugin. If so, you have to configure them:

<details>
   <summary>nvim-cmp</summary>
  
```lua
local cmp = require('cmp')
local neogen = require('neogen')

local t = function(str)
    return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local check_back_space = function()
    local col = vim.fn.col '.' - 1
    return col == 0 or vim.fn.getline('.'):sub(col, col):match '%s' ~= nil
end

cmp.setup {
    ...

    -- You must set mapping if you want.
    mapping = {
        ["<tab>"] = cmp.mapping(function(fallback)
            if vim.fn.pumvisible() == 1 then
                vim.fn.feedkeys(t("<C-n>"), "n")
            elseif neogen.jumpable() then
                vim.fn.feedkeys(t("<cmd>lua require('neogen').jump_next()<CR>"), "")
            elseif check_back_space() then
                vim.fn.feedkeys(t("<tab>"), "n")
            else
                fallback()
            end
        end, {
            "i",
            "s",
        }),
    },
    ...
}
```

  </details>

## Configuration

```lua
require('neogen').setup {
        enabled = true,             --if you want to disable Neogen
        input_after_comment = true, -- (default: true) automatic jump (with insert mode) on inserted annotation
        jump_map = "<C-e>"          -- The keymap in order to jump in the annotation fields (in insert mode)
    }
}
```

If you're not satisfied with the default configuration for a language, you can change the defaults like this:

```lua
require('neogen').setup {
    enabled = true,
	languages = {
	    lua = {
	        template = {
                    annotation_convention = "emmylua" -- for a full list of annotation_conventions, see supported-languages below,
		    ... -- for more template configurations, see the language's configuration file in configurations/{lang}.lua
		}
	    },
	    ...
    }
}
```

## Supported Languages

There is a list of supported languages and fields, with their annotation style

| Language | Annotation conventions | Supported fields | Supported annotation types
|---|---|---|---|
| lua | | | `func`, `class`, `type` |
| | [Emmylua](https://emmylua.github.io/) (`"emmylua"`) | `@param`, `@varargs`, `@return`, `@class`, `@type` |
| | [Ldoc](https://stevedonovan.github.io/ldoc/manual/doc.md.html) (`"ldoc"`) | `@param`, `@varargs`, `@return`, `@class`, `@type` |
| python | | | `func`, `class` |
| | [Google docstrings](https://google.github.io/styleguide/pyguide.html) (`"google_docstrings"`) | `Args`, `Attributes`, `Returns` |
| | [Numpydoc](https://numpydoc.readthedocs.io/en/latest/format.html) (`"numpydoc"`)| `Arguments`, `Attributes`, `Returns`|
| javascript | | | `func`, `class` |
| | [JSDoc](https://jsdoc.app) (`"jsdoc"`) | `@param`, `@returns`, `@class`, `@classdesc` |
| typescript | | | `func`, `class` |
| | [JSDoc](https://jsdoc.app) (`"jsdoc"`) | `@param`, `@returns`, `@class`, `@classdesc`, `@type` |
| c | | | `func` |
| | [Doxygen](https://www.doxygen.nl/manual/commands.html) (`"doxygen"`) | `@param`, `@returns`, `@brief`| 
| cpp | | | `func` |
| | [Doxygen](https://www.doxygen.nl/manual/commands.html) (`"doxygen"`) | `@param`, `@returns`, `@tparam`, `@brief`| 
| go | | | |
| | [Godoc](https://go.dev/blog/godoc) (`"godoc"`) | |
| java | | | `class` |
| | [Javadoc](https://docs.oracle.com/javase/1.5.0/docs/tooldocs/windows/javadoc.html#documentationcomments) (`"javadoc"`) | |


## Adding Languages

1. Using the defaults to generate a new language support: [Adding Languages](./docs/adding-languages.md)
2. (advanced) Only if the defaults aren't enough, please see here: [Advanced Integration](./docs/advanced-integration.md)

## GIFS

![screen1](https://user-images.githubusercontent.com/5306901/135055052-6ee6a5e8-3f30-4c41-872e-e624e21a1e98.gif)

![screen3](https://user-images.githubusercontent.com/5306901/135055174-2a9d8b88-7b23-4513-af91-135d885783ec.gif)
	
![screen4](https://user-images.githubusercontent.com/5306901/135056308-9808c231-b1fd-4c41-80bd-85a08d7286dd.gif)

## Credits

- Binx, for making that gorgeous logo for free!
	- [Github](https://github.com/Binx-Codes/)
	- [Reddit](https://www.reddit.com/u/binxatmachine)
