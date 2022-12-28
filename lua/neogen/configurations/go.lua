local template = require("neogen.template")
local extractors = require("neogen.utilities.extractors")
local nodes_utils = require("neogen.utilities.nodes")

return {
    parent = {
        func = { "function_declaration", "method_declaration" },
        type = { "const_declaration", "var_declaration", "type_declaration" },
        file = { "package_clause" },
    },

    data = {
        func = {
            ["function_declaration"] = {
                ["0"] = {
                    extract = function(node)
                        local tree = {
                            {
                                retrieve = "first",
                                node_type = "identifier",
                                extract = "true",
                                as = "func_name",
                            },
                        }
                        local nodes = nodes_utils:matching_nodes_from(node, tree)
                        local res = extractors:extract_from_matched(nodes)
                        return res
                    end,
                },
            },
            ["method_declaration"] = {
                ["0"] = {
                    extract = function(node)
                        local tree = {
                            {
                                retrieve = "first",
                                node_type = "field_identifier",
                                extract = "true",
                                as = "func_name",
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
            ["package_clause"] = {
                ["0"] = {
                    extract = function(node)
                        local tree = {
                            {
                                retrieve = "first",
                                node_type = "package_identifier",
                                extract = "true",
                                as = "package_name",
                            },
                        }
                        local nodes = nodes_utils:matching_nodes_from(node, tree)
                        local res = extractors:extract_from_matched(nodes)
                        return res
                    end,
                },
            },
        },
        type = {
            ["const_declaration|var_declaration"] = {
                ["0"] = {
                    extract = function()
                        return {}
                    end,
                },
            },
            ["type_declaration"] = {
                ["0"] = {
                    extract = function(node)
                        local tree = {
                            {
                                retrieve = "all",
                                node_type = "type_spec",
                                subtree = {
                                    {
                                        retrieve = "first",
                                        node_type = "type_identifier",
                                        extract = true,
                                        as = "type_name",
                                    },
                                },
                            },
                        }
                        local nodes = nodes_utils:matching_nodes_from(node, tree)
                        local res = extractors:extract_from_matched(nodes)
                        return res
                    end,
                },
            },
        },
    },

    template = template:config({ use_default_comment = true }):add_default_annotation("godoc"),
}
