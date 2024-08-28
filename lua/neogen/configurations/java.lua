local extractors = require("neogen.utilities.extractors")
local nodes_utils = require("neogen.utilities.nodes")
local template = require("neogen.template")
local i = require("neogen.types.template").item

local function_tree = {
    {
        retrieve = "first",
        node_type = "formal_parameters",
        subtree = {
            {
                retrieve = "all",
                node_type = "formal_parameter",
                subtree = {
                    { retrieve = "all", node_type = "identifier", extract = true },
                },
            },
        },
    },
    {
        retrieve = "all",
        node_type = "throws",
        subtree = {
            { retrieve = "all", node_type = "type_identifier", extract = true, as = "throw_statement" },
        },
    },
    {
        retrieve = "first",
        node_type = "block|constructor_body",
        subtree = {
            { retrieve = "first", node_type = "return_statement", extract = true },
            { retrieve = "all",   recursive = true,               node_type = "throw_statement", extract = true },
            {
                retrieve = "first",
                node_type = "try_statement",
                subtree = {
                    {
                        retrieve = "first",
                        node_type = "block",
                        subtree = {
                            {
                                retrieve = "first",
                                node_type = "return_statement",
                                extract = true,
                            },
                        },
                    },
                },
            },
        },
    },
}

return {
    parent = {
        class = { "class_declaration", "interface_declaration", "record_declaration" },
        func = { "method_declaration", "constructor_declaration" },
        type = { "field_declaration", "enum_constant", "formal_parameter" },
    },

    data = {
        func = {
            ["constructor_declaration"] = {
                ["0"] = {
                    extract = function(node)
                        local results = {}
                        local tree = function_tree

                        local nodes = nodes_utils:matching_nodes_from(node, tree)
                        local res = extractors:extract_from_matched(nodes)

                        results.throw_statement = res.throw_statement
                        results.parameters = res.identifier
                        return results
                    end,
                },
            },
            ["method_declaration"] = {
                ["0"] = {
                    extract = function(node)
                        local results = {}
                        local tree = function_tree

                        local nodes = nodes_utils:matching_nodes_from(node, tree)
                        local res = extractors:extract_from_matched(nodes)

                        results.parameters = res.identifier
                        if res.throws then
                            results.throw_statement = res.throws
                        else
                            results.throw_statement = res.throw_statement
                        end
                        results.return_statement = res.return_statement
                        return results
                    end,
                },
            },
        },
        class = {
            ["class_declaration"] = {
                ["0"] = {
                    extract = function(node)
                        local results = {}
                        local tree = { { retrieve = "all", node_type = "identifier", extract = true } }
                        local nodes = nodes_utils:matching_nodes_from(node, tree)
                        local res = extractors:extract_from_matched(nodes)

                        return {
                            [i.ClassName] = res.identifier
                        }
                    end,
                },
            },
            ["interface_declaration"] = {
                ["0"] = {
                    extract = function(node)
                        local results = {}
                        local tree = { { retrieve = "all", node_type = "identifier", extract = true } }
                        local nodes = nodes_utils:matching_nodes_from(node, tree)
                        local res = extractors:extract_from_matched(nodes)

                        return {
                            [i.ClassName] = res.identifier
                        }
                    end,
                },
            },
            ["record_declaration"] = {
                ["0"] = {
                    extract = function(node)
                        local results = {}
                        local tree = { { retrieve = "all", node_type = "identifier", extract = true } }
                        local nodes = nodes_utils:matching_nodes_from(node, tree)
                        local res = extractors:extract_from_matched(nodes)

                        return {
                            [i.ClassName] = res.identifier
                        }
                    end,
                },
            },
        },
        type = {
            ["field_declaration|enum_constant|formal_parameter"] = {
                ["0"] = {
                    extract = function()
                        return {}
                    end,
                },
            },
        },
    },

    template = template:add_default_annotation("javadoc"),
}
