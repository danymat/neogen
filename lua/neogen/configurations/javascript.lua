local function_tree = {
    {
        retrieve = "first",
        node_type = "formal_parameters",
        subtree = {
            { retrieve = "all", node_type = "identifier", extract = true },
        },
    },
    {
        retrieve = "first",
        node_type = "statement_block",
        subtree = {
            { retrieve = "first", node_type = "return_statement", extract = true },
        },
    },
}
return {
    parent = { "function_declaration", "expression_statement", "variable_declaration" },

    data = {
        ["function_declaration"] = {
            ["0"] = {

                extract = function(node)
                    local results = {}
                    local tree = function_tree
                    local nodes = neogen.utilities.nodes:matching_nodes_from(node, tree)
                    local res = neogen.utilities.extractors:extract_from_matched(nodes)

                    results.parameters = res.identifier
                    results.return_statement = res.return_statement
                    return results
                end,
            },
        },
        ["expression_statement|variable_declaration"] = {
            ["1"] = {
                extract = function(node)
                    local results = {}
                    local tree = { { retrieve = "all", node_type = "function", subtree = function_tree } }
                    local nodes = neogen.utilities.nodes:matching_nodes_from(node, tree)
                    local res = neogen.utilities.extractors:extract_from_matched(nodes)

                    results.parameters = res.identifier
                    results.return_statement = res.return_statement
                    return results
                end,
            },
        },
    },

    template = {
        annotation_convention = "jsdoc",
        use_default_comment = false,

        jsdoc = {
            { nil, "/* */", { no_results = true } },
            { nil, "/**" },
            { "parameters", " * @param {any} %s " },
            { "return_statement", " * @returns {any} " },
            { nil, " */" },
        },
    },
}
