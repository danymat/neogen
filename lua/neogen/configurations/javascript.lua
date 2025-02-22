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
        property = {
            "property_signature",
            "property_identifier",
        },
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
        property = {
            ["property_signature|property_identifier"] = {
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

    locator = require("neogen.locators.typescript"),

    template = template
        :config({
            append = { position = "after", child_name = "comment", fallback = "block", disabled = { "file" } },
            position = function(node, type)
                if vim.tbl_contains({ "func", "class" }, type) then
                    local parent = node:parent()

                    -- Verify if the parent is an export_statement (prevents offset of generated annotation)
                    if parent and parent:type() == "export_statement" then
                        local row, col = vim.treesitter.get_node_range(parent)
                        return row, col
                    end
                    return
                end
                if vim.tbl_contains({ "property" }, type) then
                    local parent = node:parent()

                    if parent and vim.tbl_contains({ "public_field_definition" }, parent:type()) then
                        local row, col = vim.treesitter.get_node_range(parent)
                        return row, col
                    end
                    return
                end
            end,
        })
        :add_default_annotation("jsdoc"),
}
