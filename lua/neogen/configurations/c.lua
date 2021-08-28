local c_params = {
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
}
local c_function_extractor = function(node)
    local tree = {
        {
            retrieve = "first",
            node_type = "function_declarator",
            subtree = {
                c_params,
            },
        },
        {
            retrieve = "first_recursive",
            node_type = "function_declarator",
            extract = true
        },
        {
            retrieve = "first",
            node_type = "compound_statement",
            subtree = {
                { retrieve = "first", node_type = "return_statement", extract = true },
            },
        },
        c_params
    }

    local nodes = neogen.utilities.nodes:matching_nodes_from(node, tree)
    local res = neogen.utilities.extractors:extract_from_matched(nodes)


    if nodes.function_declarator then
        local subnodes = neogen.utilities.nodes:matching_nodes_from(nodes.function_declarator[1], tree)
        local subres = neogen.utilities.extractors:extract_from_matched(subnodes)
        res = vim.tbl_deep_extend("keep", res, subres)
    end

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
