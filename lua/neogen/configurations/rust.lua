return {
    parent = {
        func = { "function_item", "function_signature_item" },
        class = { "struct_item", "trait_item" },
        file = { "source_file" },
    },
    data = {
        func = {
            ["function_item|function_signature_item"] = {
                ["0"] = {
                    extract = function(node)
                        local tree = {
                            {
                                retrieve = "first",
                                node_type = "parameters",
                                subtree = {
                                    {
                                        retrieve = "all",
                                        node_type = "parameter",
                                        subtree = {
                                            { retrieve = "first", node_type = "identifier", extract = true },
                                        },
                                    },
                                    {
                                        retrieve = "all",
                                        node_type = "type_identifier",
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
        file = {
            ["source_file"] = {
                ["0"] = {
                    extract = function()
                        return {}
                    end,
                },
            },
        },
        class = {
            ["struct_item|trait_item"] = {
                ["0"] = {
                    extract = function(node)
                        local tree = {
                            {
                                retrieve = "first",
                                node_type = "field_declaration_list",
                                subtree = {
                                    {
                                        retrieve = "all",
                                        node_type = "field_declaration",
                                        subtree = {
                                            { retrieve = "all", node_type = "field_identifier", extract = true },
                                        },
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
        annotation_convention = "alternative",
        rustdoc = {
            { nil, "! $1", { no_results = true, type = { "file" } } },
            { nil, "", { no_results = true, type = { "file" } } },

            { nil, "/ $1", { no_results = true, type = { "func", "class" } } },
            { nil, "/ $1", { type = { "func", "class" } } },
        },

        alternative = {
            { nil, "! $1", { no_results = true, type = { "file" } } },
            { nil, "", { no_results = true, type = { "file" } } },

            { nil, "/ $1", { no_results = true, type = { "func", "class" } } },

            { nil, "/ $1", { type = { "func", "class" } } },
            { nil, "/", { type = { "class", "func" } } },
            { "field_identifier", "/ * `%s`: $1", { type = { "class" } } },
            { "type_identifier", "/ * `%s`: $1", { type = { "func" } } },
            { "identifier", "/ * `%s`: $1", { type = { "func" } } },
        },
    },
}
