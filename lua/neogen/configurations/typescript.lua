local extractors = require("neogen.utilities.extractors")
local nodes_utils = require("neogen.utilities.nodes")
local i = require("neogen.types.template").item
local template = require("neogen.template")

local construct_type_annotation = function(parameters)
    local results = parameters and {} or nil
    if parameters then
        for _, param in pairs(parameters) do
            local subtree = {
                { retrieve = "all", node_type = "identifier", extract = true, as = i.Parameter },
                { retrieve = "all", node_type = "type_identifier", recursive = true, extract = true, as = i.Type },
            }
            local typed_parameters = nodes_utils:matching_nodes_from(param, subtree)
            typed_parameters = extractors:extract_from_matched(typed_parameters)
            table.insert(results, typed_parameters)
        end
    end
    return results
end

local function_tree = {
    {
        retrieve = "first",
        node_type = "formal_parameters",
        subtree = {
            {
                retrieve = "all",
                node_type = "required_parameter",
                extract = true,
                as = i.Tparam,
            },
            {
                retrieve = "all",
                node_type = "optional_parameter",
                extract = true,
                as = i.Tparam,
            },
        },
    },
    {
        retrieve = "first",
        node_type = "statement_block",
        subtree = {
            { retrieve = "first", node_type = "return_statement", extract = true, as = i.Return },
        },
    },
    {
        retrieve = "first",
        node_type = "type_annotation",
        subtree = {
            { retrieve = "all", node_type = "type_identifier", extract = true, as = i.Return },
        },
    },
    {
        retrieve = "first",
        node_type = "type_parameters",
        subtree = {
            {
                retrieve = "all",
                node_type = "type_parameter",
                extract = true,
                as = i.Type,
            },
        },
    },
}

return {
    parent = {
        func = {
            "function_declaration",
            "function_signature",
            "expression_statement",
            "variable_declaration",
            "lexical_declaration",
            "method_definition",
        },
        class = {
            "function_declaration",
            "expression_statement",
            "variable_declaration",
            "class_declaration",
            "export_statement",
        },
        type = { "variable_declaration", "lexical_declaration" },
        file = { "program" },
    },

    data = {
        func = {
            ["function_declaration|method_definition|function_signature"] = {
                ["0"] = {

                    extract = function(node)
                        local tree = function_tree
                        local nodes = nodes_utils:matching_nodes_from(node, tree)
                        local res = extractors:extract_from_matched(nodes)
                        res[i.Tparam] = construct_type_annotation(nodes[i.Tparam])
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
                        res[i.Tparam] = construct_type_annotation(nodes[i.Tparam])
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
                        res[i.Tparam] = construct_type_annotation(nodes[i.Tparam])
                        if res[i.Return] then
                            res[i.Return] = { true }
                        end
                        return res
                    end,
                },
            },
        },
        class = {
            ["function_declaration|class_declaration|expression_statement|variable_declaration|export_statement"] = {
                ["0"] = {

                    extract = function(_)
                        local results = {}
                        results[i.ClassName] = { "" }
                        return results
                    end,
                },
            },
        },
        type = {
            ["variable_declaration|lexical_declaration"] = {
                ["1"] = {
                    extract = function(node)
                        local tree = {
                            {
                                retrieve = "first",
                                node_type = "identifier",
                                extract = true,
                                as = i.Type,
                            },
                        }
                        local nodes = nodes_utils:matching_nodes_from(node, tree)
                        local res = extractors:extract_from_matched(nodes)
                        return res
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
    },

    locator = require("neogen.locators.typescript"),

    template = template:add_default_annotation("jsdoc"):add_default_annotation("tsdoc"),
}
