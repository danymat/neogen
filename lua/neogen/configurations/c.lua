-- hello.c:
--
-- #include <stdio.h>
--
-- int main(int argc, char *argv[])
-- {
--     printf("Hello world!\n");
--     return 0;
-- }
--
-- AST
--
-- preproc_include [0, 0] - [2, 0]
--   path: system_lib_string [0, 9] - [0, 18]
-- function_definition [2, 0] - [6, 1]
--   type: primitive_type [2, 0] - [2, 3]
--   declarator: function_declarator [2, 4] - [2, 32]
--     declarator: identifier [2, 4] - [2, 8]
--     parameters: parameter_list [2, 8] - [2, 32]
--       parameter_declaration [2, 9] - [2, 17]
--         type: primitive_type [2, 9] - [2, 12]
--         declarator: identifier [2, 13] - [2, 17]
--       parameter_declaration [2, 19] - [2, 31]
--         type: primitive_type [2, 19] - [2, 23]
--         declarator: pointer_declarator [2, 24] - [2, 31]
--           declarator: array_declarator [2, 25] - [2, 31]
--             declarator: identifier [2, 25] - [2, 29]
--   body: compound_statement [3, 0] - [6, 1]
--     expression_statement [4, 4] - [4, 29]
--       call_expression [4, 4] - [4, 28]
--         function: identifier [4, 4] - [4, 10]
--         arguments: argument_list [4, 10] - [4, 28]
--           string_literal [4, 11] - [4, 27]
--             escape_sequence [4, 24] - [4, 26]
--     return_statement [5, 4] - [5, 13]
--       number_literal [5, 11] - [5, 12]

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
                                {
                                    retrieve = "all",
                                    node_type = "identifier",
                                    extract = true,
                                },

                                {
                                    retrieve = "all",
                                    node_type = "pointer_declarator",
                                    subtree = {
                                        {
                                            retrieve = "all",
                                            node_type = "identifier",
                                            extract = true,
                                        },

                                        {
                                            retrieve = "all",
                                            node_type = "array_declarator",
                                            subtree = {
                                                {
                                                    retrieve = "all",
                                                    node_type = "identifier",
                                                    extract = true,
                                                },
                                            },
                                        },
                                    },
                                },
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
            { nil, "/* */", { no_results = true } },
            { nil, "/**" },
            { nil, " * @brief " },
            { nil, " *" },
            { "parameters", " * @param[in] %s " },
            { "return_statement", " * @returns " },
            { nil, " */" },
        },
    },
}
