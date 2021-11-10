return {
    parent = {
        class = { "class_declaration" },
        func = { "method_declaration" },
    },

    data = {
        func = {
            ["method_declaration"] = {
                ["0"] = {
                    extract = function(node)
                        local results = {}
                        local tree = {
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
                                retrieve = "first",
                                node_type = "block",
                                subtree = {
                                    { retrieve = "first", node_type = "return_statement", extract = true },
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

                        local nodes = neogen.utilities.nodes:matching_nodes_from(node, tree)
                        local res = neogen.utilities.extractors:extract_from_matched(nodes)

                        results.parameters = res.identifier
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
                        local nodes = neogen.utilities.nodes:matching_nodes_from(node, tree)
                        local res = neogen.utilities.extractors:extract_from_matched(nodes)

                        results.class_name = res.identifier
                        return results
                    end,
                },
            },
        },
    },

    template = {
        annotation_convention = "javadoc",
        use_default_comment = false,

        javadoc = {
            { nil, "/**", { no_results = true } },
            { nil, " * $1", { no_results = true } },
            { nil, " */", { no_results = true } },

            { nil, "/**" },
            { nil, " * $1" },
            { "parameters", " * @param %s $1" },
            { "return_statement", " * @return $1" },
            { nil, " */" },
        },
    },
}
