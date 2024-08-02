local nodes_utils = require("neogen.utilities.nodes")
local helpers = require("neogen.utilities.helpers")
local extractors = require("neogen.utilities.extractors")
local locator = require("neogen.locators.default")
local template = require("neogen.template")
local i = require("neogen.types.template").item

local parent = {
    func = { "function_definition" },
    class = { "class_definition" },
    file = { "module" },
    type = { "expression_statement" },
}


--- Check `node` for the first parent matching `type_name`.
---
--- This function is *inclusive*. It tests `node` before checking any parent so
--- `node` is a possible return value.
---
---@param node TSNode A tree-sitter node to check for some parent.
---@param type_name string The tree-sitter type to check. e.g. `"function_definition"`.
---@return TSNode? # The found node, if any.
local get_nearest_parent = function(node, type_name)
    local current = node

    while current ~= nil
    do
        if current:type() == type_name
        then
            return current
        end

        current = current:parent()
    end

    return nil
end


--- Remove raise (aka throw) nodes so there is only one node per-type.
---
---@param nodes table<string, TSNode[]> The nodes to simplify / reduce.
local deduplicate_throw_nodes = function(nodes)
    if not nodes[i.Throw] then
        return
    end

    local output = {}

    local seen = {}

    for _, node in ipairs(nodes[i.Throw]) do
        local text = helpers.get_node_text(node)[1]

        if not vim.tbl_contains(seen, text) then
            table.insert(seen, text)
            table.insert(output, node)
        end
    end

    nodes[i.Throw] = output
end

--- Modify `nodes` if the found return(s) are **all** bare-returns.
---
--- A bare-return is used to return early from a function and aren't meant to be
--- assigned so they should not be included in docstring output.
---
--- If at least one return is not a bare-return then this function does nothing.
---
---@param nodes table<string, TSNode[]>
local validate_bare_returns = function(nodes)
    local return_nodes = nodes[i.Return]
    local has_data = false

    for _, node in pairs(return_nodes) do
        if node:child_count() > 1
        then
            has_data = true
        end
    end

    if not has_data
    then
        nodes[i.Return] = nil
    end
end


--- Check if any of ``nodes`` has ``parent`` as a direct function parent.
---
---@param nodes table<string, TSNode[]>
---    The extracted tree-sitter Return nodes to consider. If at least one
---    found return has `parent` then this function does nothing. But if
---    no `parent` is found then neogen ignores return annotations.
---@param parent TSNode
---    The direct function to check for. If there is any function_definition
---    between each node in `nodes` and this `parent` then we consider that node
---    "ignorable".
local validate_direct_returns = function(nodes, parent)
    local return_nodes = nodes[i.Return]

    for _, node in pairs(return_nodes) do
        if get_nearest_parent(node, "function_definition") == parent
        then
            return
        end
    end

    nodes[i.Return] = nil
end


--- Remove `i.Return` details from `nodes` if a Python generator was found.
---
--- If there is at least one `yield` found, Python converts the function to a generator.
---
--- In which case, any `return` statement no longer actually functions as an
--- actual "Returns:" docstring block so we need to strip them.
---
---@param nodes table
local validate_yield_nodes = function(nodes)
    if nodes[i.Yield] ~= nil and nodes[i.Return] ~= nil
    then
        nodes[i.Return] = nil
    end
end


return {
    -- Search for these nodes
    parent = parent,
    -- Traverse down these nodes and extract the information as necessary
    data = {
        func = {
            ["function_definition"] = {
                ["0"] = {
                    extract = function(node)
                        local tree = {
                            {
                                retrieve = "all",
                                node_type = "parameters",
                                subtree = {
                                    { retrieve = "all", node_type = "identifier", extract = true, as = i.Parameter },
                                    {
                                        retrieve = "all",
                                        node_type = "default_parameter",
                                        subtree = {
                                            {
                                                position = 1,
                                                node_type = "identifier",
                                                extract = true,
                                                as = i.Parameter,
                                            },
                                        },
                                    },
                                    {
                                        retrieve = "all",
                                        node_type = "typed_parameter",
                                        extract = true,
                                        as = i.Tparam,
                                    },
                                    {
                                        retrieve = "all",
                                        node_type = "typed_default_parameter",
                                        as = i.Tparam,
                                        extract = true,
                                    },
                                    {
                                        retrieve = "first",
                                        node_type = "list_splat_pattern",
                                        extract = true,
                                        as = i.ArbitraryArgs,
                                    },
                                    {
                                        retrieve = "first",
                                        node_type = "dictionary_splat_pattern",
                                        extract = true,
                                        as = i.ArbitraryArgs,
                                    },
                                },
                            },
                            {
                                retrieve = "first",
                                node_type = "block",
                                subtree = {
                                    {
                                        retrieve = "all",
                                        node_type = "return_statement",
                                        recursive = true,
                                        extract = true,
                                        as = i.Return,
                                    },
                                    {
                                        retrieve = "all",
                                        node_type = "expression_statement",
                                        recursive = true,
                                        subtree = {
                                            {
                                                retrieve = "first",
                                                node_type = "yield",
                                                recursive = true,
                                                extract = true,
                                                as = i.Yield,
                                            },
                                        },
                                    },
                                    {
                                        retrieve = "all",
                                        node_type = "raise_statement",
                                        recursive = true,
                                        subtree = {
                                            {
                                                retrieve = "first",
                                                node_type = "call",
                                                recursive = true,
                                                subtree = {
                                                    {
                                                        retrieve = "first",
                                                        node_type = "identifier",
                                                        extract = true,
                                                        as = i.Throw,
                                                    }
                                                }
                                            },
                                        },
                                    },
                                    {
                                        retrieve = "all",
                                        node_type = "raise_statement",
                                        recursive = true,
                                        subtree = {
                                            {
                                                retrieve = "first",
                                                node_type = "call",
                                                recursive = true,
                                                subtree = {
                                                    {
                                                        retrieve = "first",
                                                        node_type = "attribute",
                                                        extract = true,
                                                        as = i.Throw,
                                                    }
                                                }
                                            },
                                        },
                                    },
                                },
                            },
                            {
                                retrieve = "all",
                                node_type = "type",
                                as = i.ReturnTypeHint,
                                extract = true,
                            },
                        }
                        local nodes = nodes_utils:matching_nodes_from(node, tree)
                        local temp = {}
                        if nodes[i.Tparam] then
                            temp[i.Tparam] = {}
                            for _, n in pairs(nodes[i.Tparam]) do
                                local type_subtree = {
                                    { retrieve = "all", node_type = "identifier", extract = true, as = i.Parameter },
                                    { retrieve = "all", node_type = "type",       extract = true, as = i.Type },
                                }
                                local typed_parameters = nodes_utils:matching_nodes_from(n, type_subtree)
                                typed_parameters = extractors:extract_from_matched(typed_parameters)
                                table.insert(temp[i.Tparam], typed_parameters)
                            end
                        end

                        if nodes[i.Return] then
                            validate_direct_returns(nodes, node)
                        end

                        if nodes[i.Return] then
                            validate_bare_returns(nodes)
                        end

                        validate_yield_nodes(nodes)

                        deduplicate_throw_nodes(nodes)

                        local res = extractors:extract_from_matched(nodes)
                        res[i.Tparam] = temp[i.Tparam]

                        -- Return type hints takes precedence over all other types for generating template
                        if res[i.ReturnTypeHint] then
                            res[i.HasReturn] = nil
                            if res[i.ReturnTypeHint][1] == "None" then
                                res[i.ReturnTypeHint] = nil
                            end
                        end

                        -- Check if the function is inside a class
                        -- If so, remove reference to the first parameter (that can be `self`, `cls`, or a custom name)
                        if res[i.Parameter] and locator({ current = node }, parent.class) then
                            local remove_identifier = true
                            -- Check if function is a static method. If so, will not remove the first parameter
                            if node:parent():type() == "decorated_definition" then
                                local decorator = nodes_utils:matching_child_nodes(node:parent(), "decorator")
                                decorator = helpers.get_node_text(decorator[1])[1]
                                if decorator == "@staticmethod" then
                                    remove_identifier = false
                                end
                            elseif node:parent():parent():type() == "function_definition" then
                                remove_identifier = false
                            end

                            if remove_identifier then
                                table.remove(res[i.Parameter], 1)
                                if vim.tbl_isempty(res[i.Parameter]) then
                                    res[i.Parameter] = nil
                                end
                            end
                        end

                        local results = helpers.copy({
                            [i.HasParameter] = function(t)
                                return (t[i.Parameter] or t[i.Tparam]) and { true }
                            end,
                            [i.HasReturn] = function(t)
                                return (not t[i.Yield] and (t[i.ReturnTypeHint] or t[i.Return]) and { true })
                            end,
                            [i.HasThrow] = function(t)
                                return t[i.Throw] and { true }
                            end,
                            [i.Type] = true,
                            [i.Parameter] = true,
                            [i.Return] = true,
                            [i.ReturnTypeHint] = true,
                            [i.HasYield] = function(t)
                                return t[i.Yield] and { true }
                            end,
                            [i.ArbitraryArgs] = true,
                            [i.Kwargs] = true,
                            [i.Throw] = true,
                            [i.Tparam] = true,
                        }, res) or {}

                        -- Removes generation for returns that are not typed
                        if results[i.ReturnTypeHint] then
                            results[i.Return] = nil
                        end

                        return results
                    end,
                },
            },
        },
        class = {
            ["class_definition"] = {
                ["0"] = {
                    extract = function(node)
                        local results = {}
                        local tree = {
                            {
                                retrieve = "first",
                                node_type = "block",
                                subtree = {
                                    {
                                        retrieve = "first",
                                        node_type = "function_definition",
                                        subtree = {
                                            {
                                                retrieve = "first",
                                                node_type = "block",
                                                subtree = {
                                                    {
                                                        retrieve = "all",
                                                        node_type = "expression_statement",
                                                        subtree = {
                                                            {
                                                                retrieve = "first",
                                                                node_type = "assignment",
                                                                extract = true,
                                                            },
                                                        },
                                                    },
                                                },
                                            },
                                        },
                                    },
                                    {
                                        retrieve = "all",
                                        node_type = "expression_statement",
                                        subtree = {
                                            {
                                                retrieve = "first",
                                                node_type = "assignment",
                                                extract = true,
                                                as = i.ClassAttribute,
                                            },
                                        },
                                    },
                                },
                            },
                        }

                        local nodes = nodes_utils:matching_nodes_from(node, tree)

                        if vim.tbl_isempty(nodes) then
                            return {}
                        end

                        -- Initialize results
                        results[i.ClassAttribute] = {}

                        -- Extracting left field for the ones already marked as attributes
                        if nodes[i.ClassAttribute] then
                            for _, assignment in pairs(nodes[i.ClassAttribute]) do
                                local left = assignment:field("left")
                                left = left and helpers.get_node_text(left[1])[1]
                                table.insert(results[i.ClassAttribute], left)
                            end
                        end

                        -- For other attributes only marked as assignments, we will check if they are not private and add them to the list
                        -- Deliberately check inside the init function for assignments to "self"
                        if nodes["assignment"] then
                            for _, assignment in pairs(nodes["assignment"]) do
                                -- Getting left side in assignment
                                local left = assignment:field("left")
                                -- Checking if left side is an "attribute", which means assigning to an attribute to the function
                                if not vim.tbl_isempty(left) and not vim.tbl_isempty(left[1]:field("attribute")) then
                                    --Adding it to the list
                                    local left_attribute = assignment:field("left")[1]:field("attribute")[1]
                                    left_attribute = helpers.get_node_text(left_attribute)[1]

                                    if not vim.startswith(left_attribute, "_") then
                                        table.insert(results[i.ClassAttribute], left_attribute)
                                    end
                                end
                            end
                        end
                        if vim.tbl_isempty(results[i.ClassAttribute]) then
                            results[i.ClassAttribute] = nil
                        end

                        return results
                    end,
                },
            },
        },
        file = {
            ["module"] = {
                ["0"] = {
                    extract = function()
                        return {}
                    end,
                },
            },
        },
        type = {
            ["0"] = {
                extract = function()
                    return {}
                end,
            },
        },
    },
    -- Use default granulator and generator
    locator = nil,
    granulator = nil,
    generator = nil,
    template = template
        :config({
            append = { position = "after", child_name = "comment", fallback = "block", disabled = { "file" } },
            position = function(node, type)
                if type == "file" then
                    -- Checks if the file starts with #!, that means it's a shebang line
                    -- We will then write file annotations just after it
                    for child in node:iter_children() do
                        if child:type() == "comment" then
                            local start_row = child:start()
                            if start_row == 0 then
                                if vim.startswith(helpers.get_node_text(node)[1], "#!") then
                                    return 1, 0
                                end
                            end
                        end
                    end
                    return 0, 0
                end
            end,
        })
        :add_default_annotation("google_docstrings")
        :add_annotation("numpydoc")
        :add_annotation("reST"),
}
