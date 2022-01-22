local construct_type_annotation = function(parameters)
    local results = parameters and {} or nil
    if parameters then
        for _, param in pairs(parameters) do
            local subtree = {
                { retrieve = "all", node_type = "identifier", extract = true },
                { retrieve = "all", node_type = "type_identifier", recursive = true, extract = true },
            }
            local typed_parameters = neogen.utilities.nodes:matching_nodes_from(param, subtree)
            typed_parameters = neogen.utilities.extractors:extract_from_matched(typed_parameters)
            table.insert(results, typed_parameters)
        end
    end
    return results
end

local function_tree = {
    {
        retrieve = "first",
        node_type = "formal_parameters",
        subtree = {
            {
                retrieve = "all",
                node_type = "required_parameter",
                extract = true,
            },
            {
                retrieve = "all",
                node_type = "optional_parameter",
                extract = true,
            },
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
    parent = {
        func = { "function_declaration", "expression_statement", "variable_declaration", "lexical_declaration" },
        class = { "function_declaration", "expression_statement", "variable_declaration", "class_declaration" },
        type = { "variable_declaration", "lexical_declaration" },
        file = { "program" },
    },

    data = {
        func = {
            ["function_declaration"] = {
                ["0"] = {

                    extract = function(node)
                        local results = {}
                        local tree = function_tree
                        local nodes = neogen.utilities.nodes:matching_nodes_from(node, tree)
                        local res = neogen.utilities.extractors:extract_from_matched(nodes)

                        results.type = construct_type_annotation(nodes.required_parameter)
                        results.opt_type = construct_type_annotation(nodes.optional_parameter)
                        results.parameters = res.identifier
                        results.return_statement = res.return_statement
                        return results
                    end,
                },
            },
            ["expression_statement|variable_declaration"] = {
                ["0"] = {
                    extract = function(node)
                        local results = {}
                        local tree = { { retrieve = "all", node_type = "function", subtree = function_tree } }
                        local nodes = neogen.utilities.nodes:matching_nodes_from(node, tree)
                        local res = neogen.utilities.extractors:extract_from_matched(nodes)

                        results.type = construct_type_annotation(nodes.type_annotation)
                        results.opt_type = construct_type_annotation(nodes.optional_parameter)
                        results.parameters = res.identifier
                        results.return_statement = res.return_statement
                        return results
                    end,
                },
            },
            ["lexical_declaration"] = {
                ["1"] = {
                    extract = function(node)
                        local results = {}
                        local tree = { { retrieve = "all", node_type = "arrow_function", subtree = function_tree } }
                        local nodes = neogen.utilities.nodes:matching_nodes_from(node, tree)
                        local res = neogen.utilities.extractors:extract_from_matched(nodes)

                        results.type = construct_type_annotation(nodes.type_annotation)
                        results.opt_type = construct_type_annotation(nodes.optional_parameter)
                        results.parameters = res.identifier
                        results.return_statement = res.return_statement
                        return results
                    end,
                },
            },
        },
        class = {
            ["function_declaration|class_declaration|expression_statement|variable_declaration"] = {
                ["0"] = {

                    extract = function(_)
                        local results = {}
                        results.class_tag = { "" }
                        return results
                    end,
                },
            },
        },
        type = {
            ["variable_declaration|lexical_declaration"] = {
                ["1"] = {
                    extract = function(node)
                        local res = {}
                        local tree = {
                            {
                                retrieve = "first",
                                node_type = "identifier",
                                extract = true,
                            },
                        }
                        local nodes = neogen.utilities.nodes:matching_nodes_from(node, tree)
                        local results = neogen.utilities.extractors:extract_from_matched(nodes)

                        res.type = results.identifier
                        return res
                    end,
                },
            },
        },
        file = {
            ["program"] = {
                ["0"] = {
                    extract = function()
                        return {}
                    end,
                },
            },
        },
    },

    template = {
        annotation_convention = "jsdoc",
        use_default_comment = false,
        jsdoc = {
            { nil, "/* $1 */", { no_results = true, type = { "class", "func" } } },

            { nil, "/**", { no_results = true, type = { "file" } } },
            { nil, " * @module $1", { no_results = true, type = { "file" } } },
            { nil, " */", { no_results = true, type = { "file" } } },

            { nil, "/**", { type = { "class", "func" } } },
            { "class_tag", " * @classdesc $1", { before_first_item = { " * ", " * @class" }, type = { "class" } } },
            {
                { "type_identifier", "identifier" },
                " * @param {%s} %s $1",
                { required = "opt_type", type = { "func" } },
            },
            {
                { "type_identifier", "identifier" },
                " * @param {%s} %s $1",
                { required = "type", type = { "func" } },
            },
            { "return_statement", " * @returns {$1} $1", { type = { "func" } } },
            { nil, " */", { type = { "class", "func" } } },

            { "type", "/* @type {$1|any} */", { type = { "type" } } },
        },
    },
}
