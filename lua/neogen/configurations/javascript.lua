local i = require("neogen.types.template").item
local extractors = require("neogen.utilities.extractors")
local nodes_utils = require("neogen.utilities.nodes")
local template = require("neogen.template")

local function_tree = {
    {
        retrieve = "first",
        node_type = "formal_parameters",
        subtree = {
            { retrieve = "all", node_type = "identifier", recursive = true, extract = true, as = i.Parameter },
        },
    },
    {
        retrieve = "first",
        node_type = "statement_block",
        subtree = {
            { retrieve = "first", node_type = "return_statement", extract = true, as = i.Return },
        },
    },
}

return {
    parent = {
        func = {
            "function_declaration",
            "expression_statement",
            "variable_declaration",
            "lexical_declaration",
            "method_definition",
        },
        class = { "function_declaration", "expression_statement", "variable_declaration", "class_declaration" },
        file = { "program" },
        type = { "variable_declaration", "lexical_declaration" },
    },

    data = {
        func = {
            ["method_definition|function_declaration"] = {
                ["0"] = {

                    extract = function(node)
                        local tree = function_tree
                        local nodes = nodes_utils:matching_nodes_from(node, tree)
                        local res = extractors:extract_from_matched(nodes)

                        if res[i.Return] then
                            res[i.Return] = { true }
                        end
                        return res
                    end,
                },
            },
            ["expression_statement|variable_declaration"] = {
                ["0"] = {
                    extract = function(node)
                        local tree = { { retrieve = "all", node_type = "function", subtree = function_tree } }
                        local nodes = nodes_utils:matching_nodes_from(node, tree)
                        local res = extractors:extract_from_matched(nodes)

                        if res[i.Return] then
                            res[i.Return] = { true }
                        end
                        return res
                    end,
                },
            },
            ["lexical_declaration"] = {
                ["1"] = {
                    extract = function(node)
                        local tree = { { retrieve = "all", node_type = "arrow_function", subtree = function_tree } }
                        local nodes = nodes_utils:matching_nodes_from(node, tree)
                        local res = extractors:extract_from_matched(nodes)

                        if res[i.Return] then
                            res[i.Return] = { true }
                        end
                        return res
                    end,
                },
            },
        },
        class = {
            ["function_declaration|class_declaration|expression_statement|variable_declaration"] = {
                ["0"] = {

                    extract = function(_)
                        local results = {}
                        results[i.ClassName] = { "" }
                        return results
                    end,
                },
            },
        },
        file = {
            ["program"] = {
                ["0"] = {
                    extract = function()
                        return {}
                    end,
                },
            },
        },
        type = {
            ["variable_declaration|lexical_declaration"] = {
                ["0"] = {
                    extract = function()
                        return {}
                    end,
                },
            },
        },
    },

    template = template:add_default_annotation("jsdoc"),
}
