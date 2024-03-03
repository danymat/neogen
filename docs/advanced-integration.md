# Advanced Integration

## Configuration file

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

## Locators

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

## Granulators

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

## Generators

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
