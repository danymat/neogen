return {
    parent = {
        func = {
            "method_declaration",
            "constructor_declaration",
            "operator_declaration",
            "delegate_declaration",
            "conversion_operator_declaration",
        },
        class = { "class_declaration" },
        type = { "field_declaration", "property_declaration", "event_field_declaration", "indexer_declaration" },
    },
    data = {
        func = {
            ["method_declaration|constructor_declaration|operator_declaration|delegate_declaration|conversion_operator_declaration"] = {
                ["0"] = {
                    extract = function(node)
                        local tree = {
                            {
                                retrieve = "first",
                                node_type = "parameter_list",
                                subtree = {
                                    {
                                        retrieve = "all",
                                        node_type = "parameter",
                                        subtree = {
                                            { position = 2, extract = true },
                                        },
                                    },
                                },
                            },
                            {
                                retrieve = "first",
                                node_type = "block",
                                subtree = {
                                    {
                                        retrieve = "first",
                                        recursive = true,
                                        node_type = "return_statement",
                                        extract = true,
                                    },
                                },
                            },
                        }
                        local nodes = neogen.utilities.nodes:matching_nodes_from(node, tree)
                        local res = neogen.utilities.extractors:extract_from_matched(nodes)
                        res.identifier = res["_"]
                        return res
                    end,
                },
            },
        },
        class = {
            ["class_declaration"] = {
                ["0"] = {
                    extract = function()
                        return {}
                    end,
                },
            },
        },
        type = {
            ["field_declaration|property_declaration|event_field_declaration"] = {
                ["0"] = {
                    extract = function()
                        return {}
                    end,
                },
            },
            ["indexer_declaration"] = {
                ["0"] = {
                    extract = function(node)
                        local tree = {
                            {
                                retrieve = "first",
                                node_type = "bracketed_parameter_list",
                                subtree = {
                                    {
                                        retrieve = "all",
                                        node_type = "parameter",
                                        subtree = {
                                            { retrieve = "first", node_type = "identifier", extract = true },
                                        },
                                    },
                                },
                            },
                            {
                                retrieve = "first",
                                node_type = "accessor_list",
                                subtree = {
                                    {
                                        retrieve = "all",
                                        node_type = "return_statement",
                                        recursive = true,
                                        extract = true,
                                    },
                                },
                            },
                        }
                        local nodes = neogen.utilities.nodes:matching_nodes_from(node, tree)
                        local res = neogen.utilities.extractors:extract_from_matched(nodes)
                        return res
                    end,
                },
            },
        },
    },
    template = {
        use_default_comment = false,
        annotation_convention = "xmldoc",

        xmldoc = {
            { nil, "/// <summary>", { no_results = true } },
            { nil, "/// $1", { no_results = true } },
            { nil, "/// </summary>", { no_results = true } },

            { nil, "/// <summary>", {} },
            { nil, "/// $1", {} },
            { "identifier", '/// <param name="%s">$1</param>', { type = { "func", "type" } } },
            { "return_statement", "/// <returns>$1</returns>", { type = { "func", "type" } } },
            { nil, "/// </summary>", {} },
        },
    },
}
