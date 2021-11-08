local c_params = {
    retrieve = "first",
    node_type = "parameter_list",
    subtree = {
        {
            retrieve = "all",
            node_type = "parameter_declaration",
            subtree = {
                { retrieve = "first", recursive = true, node_type = "identifier", extract = true },
            },
        },
        -- This one is only used in cpp, considering moving it elsewhere to refactor
        {
            retrieve = "all",
            node_type = "variadic_parameter_declaration",
            subtree = {
                { retrieve = "first", recursive = true, node_type = "identifier", extract = true },
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
            retrieve = "first",
            recursive = true,
            node_type = "function_declarator",
            extract = true,
        },
        {
            retrieve = "first",
            node_type = "compound_statement",
            subtree = {
                { retrieve = "first", node_type = "return_statement", extract = true },
            },
        },
        {
            retrieve = "first",
            node_type = "primitive_type",
            extract = true,
        },
        {
            retrieve = "first",
            node_type = "pointer_declarator",
            extract = true,
        },
        c_params,
    }

    local nodes = neogen.utilities.nodes:matching_nodes_from(node, tree)
    local res = neogen.utilities.extractors:extract_from_matched(nodes)

    if nodes.function_declarator then
        local subnodes = neogen.utilities.nodes:matching_nodes_from(nodes.function_declarator[1], tree)
        local subres = neogen.utilities.extractors:extract_from_matched(subnodes)
        res = vim.tbl_deep_extend("keep", res, subres)
    end

    local has_return_statement = function()
        if res.return_statement then
            -- function implementation
            return res.return_statement
        elseif res.function_declarator and res.primitive_type then
            if res.primitive_type[1] ~= "void" or res.pointer_declarator then
                -- function prototype
                return res.primitive_type
            end
        end
        -- not found
        return nil
    end

    return {
        parameters = res.identifier,
        return_statement = has_return_statement(),
    }
end

return {
    parent = {
        func = { "function_declaration", "function_definition", "declaration" },
    },

    data = {
        func = {
            ["function_declaration|function_definition|declaration"] = {
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
            { nil, "/**", { no_results = true } },
            { nil, " * @brief $1", { no_results = true } },
            { nil, " */", { no_results = true } },

            { nil, "/**" },
            { nil, " * @brief $1" },
            { nil, " *" },
            { "parameters", " * @param %s $1" },
            { "return_statement", " * @returns $1" },
            { nil, " */" },
        },
    },
}
