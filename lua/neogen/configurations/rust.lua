return {
    parent = {
        func = { "function_item" },
        class = { "struct_item" },
        file = { "source_file" },
    },
    data = {
        func = {
            ["function_item"] = {
                ["0"] = {
                    extract = function()
                        return {}
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
            ["struct_item"] = {
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
        annotation_convention = "rustdoc",
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
            { nil, "/", { type = { "class" } } },
            { "field_identifier", "/ * %s: $1", { type = { "class" } } },
        },
    },
}
