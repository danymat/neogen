return {
    parent = { "function_declaration" },

    data = {
        ["function_declaration"] = {
            ["0"] = {

                extract = function (node)
                    local results = {}
                    local tree = {
                        { retrieve = "first", node_type = "formal_parameters", subtree = {
                            { retrieve = "all", node_type = "identifier", extract = true }
                        } },
                        { retrieve = "first", node_type = "statement_block", subtree = {
                            { retrieve = "first", node_type = "return_statement", extract = true }
                        } }
                    }
                    local nodes = neogen.utilities.nodes:matching_nodes_from(node, tree)
                    local res = neogen.utilities.extractors:extract_from_matched(nodes)

                    results.parameters = res.identifier
                    results.return_statement = res.return_statement
                    return results
                end
            }
        }
    },

    template = {
        annotation_convention = "jsdoc",
        use_default_comment = false,

        jsdoc = {
            { nil, "/**" },
            { "parameters", " * @param {any} %s " },
            { "return_statement", " * @returns {any} " },
            { nil, " */" }
        }
    }
}
