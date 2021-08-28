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
* [GIFS](#gifs)

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

| Language | Annotation conventions | Supported fields |
|---|---|---|
| lua | | |
| | [Emmylua](https://emmylua.github.io/) (`"emmylua"`) | `@param`, `@varargs`, `@return`, `@class`, `@type` |
| python | | |
| | [Google docstrings](https://google.github.io/styleguide/pyguide.html) (`"google_docstrings"`) | `Args`, `Attributes`, `Returns` |
| | [Numpydoc](https://numpydoc.readthedocs.io/en/latest/format.html) (`"numpydoc"`)| `Arguments`, `Attributes`, `Returns`|
| javascript | | |
| | [JSDoc](https://jsdoc.app) (`"jsdoc"`) | `@param`, `@returns`, `@class`, `@classdesc` |
| c | | |
| | [Doxygen](https://www.doxygen.nl/manual/commands.html) (`"doxygen"`) | `@param`, `@returns` | 


## Adding Languages

### Configuration file

The configuration file for a language is in `lua/configurations/{lang}.lua`. 

_Note: Be aware that Neogen uses Treesitter to operate. You can install [TSPlayground](https://github.com/nvim-treesitter/playground) to check the AST._

Below is a commented sample of the configuration file for `lua`.

```lua
-- Search for these nodes
parent = { "function", "local_function", "local_variable_declaration", "field", "variable_declaration" },
                                                                                                          
-- Traverse down these nodes and extract the information as necessary
data = {
    -- If function or local_function is found as a parent
    ["function|local_function"] = {
        -- Get second child from the parent node
        ["2"] = {
            -- This second child has to be of type "parameters", otherwise does nothing
            match = "parameters",
                                                                                       
	    -- Extractor function that returns a set of TSname = values with values being of type string[]
            extract = function(node)
                local regular_params = neogen.utilities.extractors:extract_children_text("identifier")(node)
                local varargs = neogen.utilities.extractors:extract_children_text("spread")(node)
                                                                                                          
                return {
                    parameters = regular_params,
                    vararg = varargs,
                }
            end,
        },
    },
},
                                                                                                          
-- Custom lua locator that escapes from comments (More on locators below)
-- Passing nil will use the default locator
locator = require("neogen.locators.lua"),
                                                                                                          
-- Use default granulator and generator (More on them below)
granulator = nil,
generator = nil,
                                                            
-- Template to use with the generator. (More on this below)
template = {
    -- Which annotation convention to use
    annotation_convention = "emmylua",
    emmylua = {
        { nil, "- " },
        { "parameters", "- @param %s any" },
        { "vararg", "- @vararg any" },
        { "return_statement", "- @return any" }
    }
},
```

The Neogen code is then divided in 3 major concepts:

### Locators

A locator tries to find (from the cursor node) one of the nodes from `parents` field specified in configuration.

This is the signature of the function:

```lua
function(node_info, nodes_to_match)
    return node
end
```

- With `node_info` being a table with 2 fields:

```lua
{
    root = root_node -- <TSnode>
    current = current_node -- <TSnode>
}
```

- `nodes_to_match` is the field from `parents` in language configuration.

_Default: The default locator (in `lua/locators/default.lua`) just go back to the parent node of the current one and sees if it's one of the requested parents._

### Granulators

Now that a parent node is found (with locators) from the cursor location, it's time to use this node to find all requested fields.

The function signature is this:

```lua
function(parent_node, node_data)
    return result
end
```

- `parent_node` being the node returned from the locator
- `result` is a table containing a set of `type = values` with values from type `string[]`, and type being a TS node name.
- `node_data` being the field `data` from configuration file. For example, if the `data` field is this one:

```lua
data = {
    ["function|local_function"] = {
        -- get second child from the parent node
        ["2"] = {
            -- it has to be of type "parameters"
            match = "parameters",

            extract = function(node)
                local tree = {
                    { retrieve = "all", node_type = "identifier", extract = true },
                    { retrieve = "all", node_type = "spread", extract = true }
                }
                local nodes = neogen.utilities.nodes:matching_nodes_from(node, tree)
                local res = neogen.utilities.extractors:extract_from_matched(nodes)

                return {
                    parameters = res.identifier,
                    vararg = res.spread,
                }
            end,
        },
    },
}
```

Notes:

- If you create your own granulator, you can add any kind of parameters in the `data` field from configuration file as long as the function signature is the same provided. 
- Utilities are provided. You can check out their documentation in `lua/utilities/`.

### Generators

A generator takes in the results from the granulator and tries to generate the template according to the language's configuration.

This is the function signature for a generator:

```lua
function(parent, data, template)
    return start_row, start_col, generated_template
end
```

- `parent` is the parent node found with the locator
- `data` is the result from the granulator
- `template` being the `template` field from the language configuration file.
- `start_row` is the row in which we will append `generated_template` 
- `start_col` is the col in which the `generated_template` will start
- `generated_template` is the output we will append on the specified locations.

## GIFS

![](./.images/recording_1.mov)

## Credits

- Binx, for making that gorgeous logo for free!
	- [Github](https://github.com/Binx-Codes/)
	- [Reddit](https://www.reddit.com/u/binxatmachine)
