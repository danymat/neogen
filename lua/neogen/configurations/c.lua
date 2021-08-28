local c_function_extractor = function(node)
    local tree = {
        {
            retrieve = "first",
            node_type = "function_declarator",
            subtree = {
                {
                    retrieve = "first",
                    node_type = "parameter_list",
                    subtree = {
                        {
                            retrieve = "all",
                            node_type = "parameter_declaration",
                            subtree = {
                                { retrieve = "first_recursive", node_type = "identifier", extract = true}
                            },
                        },
                    },
                },
            },
        },
        {
            retrieve = "first",
            node_type = "compound_statement",
            subtree = {
                { retrieve = "first", node_type = "return_statement", extract = true },
            },
        },
    }

    local nodes = neogen.utilities.nodes:matching_nodes_from(node, tree)
    local res = neogen.utilities.extractors:extract_from_matched(nodes)

    return {
        parameters = res.identifier,
        return_statement = res.return_statement,
    }
end

return {
    parent = {
        func = { "function_declaration", "function_definition" },
    },

    data = {
        func = {
            ["function_declaration|function_definition"] = {
                ["0"] = {
                    extract = c_function_extractor,
                },
            },
        },
    },

    -- Use default granulator and generator
    granulator = nil,
    generator = nil,

    template = {
        annotation_convention = "doxygen",
        use_default_comment = false,

        doxygen = {
            { nil, "/* $1 */", { no_results = true } },
            { nil, "/**" },
            { nil, " * @brief $1" },
            { nil, " *" },
            { "parameters", " * @param[in] %s $1" },
            { "return_statement", " * @returns $1" },
            { nil, " */" },
        },
    },
}
