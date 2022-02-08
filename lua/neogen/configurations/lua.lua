local extractors = require("neogen.utilities.extractors")
local i = require("neogen.types.template").item
local nodes_utils = require("neogen.utilities.nodes")
local template = require("neogen.template")

local function_extractor = function(node, type)
    if not vim.tbl_contains({ "local", "function" }, type) then
        error("Incorrect call for function_extractor")
    end

    local tree = {
        {
            retrieve = "first",
            node_type = "parameters",
            subtree = {
                { retrieve = "all", node_type = "identifier", extract = true, as = i.Parameter },
                { retrieve = "all", node_type = "vararg_expression", extract = true, as = i.Vararg },
            },
        },
        {
            retrieve = "first",
            node_type = "block",
            subtree = {
                { retrieve = "first", node_type = "return_statement", extract = true, as = i.Return },
            },
        },
    }

    if type == "local" then
        tree = {
            {
                retrieve = "first",
                recursive = true,
                node_type = "function_definition",
                subtree = tree,
            },
        }
    end

    local nodes = nodes_utils:matching_nodes_from(node, tree)
    local res = extractors:extract_from_matched(nodes)
    return res
end

local extract_from_var = function(node)
    local tree = {
        {
            retrieve = "first",
            node_type = "assignment_statement",
            subtree = {
                {
                    retrieve = "first",
                    node_type = "variable_list",
                    subtree = {
                        { retrieve = "all", node_type = "identifier", extract = true },
                    },
                },
            },
        },
        {
            position = 2,
            extract = true,
        },
    }
    local nodes = nodes_utils:matching_nodes_from(node, tree)
    return nodes
end

return {
    -- Search for these nodes
    parent = {
        func = { "function_declaration", "assignment_statement", "variable_declaration", "field" },
        class = { "local_variable_declaration", "variable_declaration" },
        type = { "local_variable_declaration", "variable_declaration" },
        file = { "chunk" },
    },

    data = {
        func = {
            -- When the function is inside one of those
            ["variable_declaration|assignment_statement|field"] = {
                ["0"] = {
                    extract = function(node)
                        return function_extractor(node, "local")
                    end,
                },
            },
            -- When the function is in the root tree
            ["function_declaration"] = {
                ["0"] = {
                    extract = function(node)
                        return function_extractor(node, "function")
                    end,
                },
            },
        },
        class = {
            ["local_variable_declaration|variable_declaration"] = {
                ["0"] = {
                    extract = function(node)
                        local nodes = extract_from_var(node)
                        local res = extractors:extract_from_matched(nodes)
                        return {
                            [i.ClassName] = res.identifier,
                        }
                    end,
                },
            },
        },
        type = {
            ["local_variable_declaration|variable_declaration"] = {
                ["0"] = {
                    extract = function(node)
                        local result = {}
                        result[i.Type] = {}

                        local nodes = extract_from_var(node)
                        local res = extractors:extract_from_matched(nodes, { type = true })

                        -- We asked the extract_from_var function to find the type node at right assignment.
                        -- We check if it found it, or else will put `any` in the type
                        if res["_"] then
                            vim.list_extend(result[i.Type], res["_"])
                        else
                            if res.identifier or res.field_expression then
                                vim.list_extend(result[i.Type], { "any" })
                            end
                        end
                        return result
                    end,
                },
            },
        },
        file = {
            ["chunk"] = {
                ["0"] = {
                    extract = function()
                        return {}
                    end,
                },
            },
        },
    },

    -- Custom lua locator that escapes from comments
    locator = require("neogen.locators.lua"),

    template = template:config({ use_default_comment = true }):add_default_annotation("emmylua"):add_annotation("ldoc"),
}
