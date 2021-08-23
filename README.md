<div align="center">
<img src="https://user-images.githubusercontent.com/5306901/130352268-226f51a7-b203-4e74-aa71-2e53cb276ac0.png" width=250><br>
	
# Neogen - Your Annotation Toolkit

</div>

# Table Of Contents

* [Features](#features)
* [Requirements](#requirements)
* [Installation](#installation)
* [Configuration](#configuration)
* [Supported Languages](#supported-languages)
* [Usage](#usage)
* [GIFS](#gifs)
* [Contributing](#contributing)

## Features

- Create annotations with one keybind
- Defaults for multiple languages and annotation conventions
- Extremely customizable and extensible
- Written in lua

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

## Configuration

```lua
require('neogen').setup {
        enabled = true,             -- required for Neogen to work
        input_after_comment = true, -- automatic jump (with insert mode) on inserted annotation
    }
}
```

The configuration file a language is in `lua/configurations/{lang}.lua`. 

_Note: Be aware that Neogen uses Treesitter to operate. You can install [TSPlayground](https://github.com/nvim-treesitter/playground) to check the AST._

If you're not satisfied with the default configuration for the language, you can change the defaults like this:

```lua
require('neogen').setup {
        enabled = true,             -- required for Neogen to work
	languages = {
	    lua = {
	        template = {
		    { nil, "- " }, -- First annotation line will be {default_comment}- (in lua ---)
        	    { "parameters", "- @param %s any" }, -- If matching parameters, will ouput --- @param {param} any
	            { "vararg", "- @vararg any" },
	            { "return_statement", "- @return any" }
		}
	    }
	}
    }
}
```

## Supported Languages

There is a list of supported languages and fields, with their annotation style

| Language | Annotation conventions | Supported fields |
|---|---|---|
| lua | Emmylua | `@param`, `@varargs`, `@return` |

## Usage

I exposed a command `:Neogen` to generate the annotations.
You can bind it to your keybind of choice, like so:

```lua
vim.api.nvim_set_keymap("n", "<Leader>ng", ":Neogen<CR>", {})
```

It'll generate the annotations provided by neogen.

## GIFS

![](./.images/recording_1.mov)

## Contributing

Adding support for new languages is quite easy, and a documentation will be available soon!

## Credits

- Binx, for making that gorgeous logo for free!
	- [Github](https://github.com/Binx-Codes/)
	- [Reddit](https://www.reddit.com/u/binxatmachine)
