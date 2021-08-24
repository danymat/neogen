local ts_utils = require("nvim-treesitter.ts_utils")

return {
    -- Search for these nodes
    parent = { "function_definition", "class_definition" },

    -- Traverse down these nodes and extract the information as necessary
    data = {
        ["function_definition"] = {
            ["0"] = {
                extract = function(node)
                    local results = {}

                    local tree = {
                        {
                            retrieve = "all",
                            node_type = "parameters",
                            subtree = {
                                { retrieve = "all", node_type = "identifier", extract = true },

                                {
                                    retrieve = "all",
                                    node_type = "default_parameter",
                                    subtree = { { retrieve = "all", node_type = "identifier", extract = true } },
                                },
                                {
                                    retrieve = "all",
                                    node_type = "typed_parameter",
                                    subtree = { { retrieve = "all", node_type = "identifier", extract = true } },
                                },
                                {
                                    retrieve = "all",
                                    node_type = "typed_default_parameter",
                                    subtree = { { retrieve = "all", node_type = "identifier", extract = true } },
                                },
                            },
                        },
                        {
                            retrieve = "first",
                            node_type = "block",
                            subtree = {
                                { retrieve = "all", node_type = "return_statement", extract = true },
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
        ["class_definition"] = {
            ["2"] = {
                match = "block",

                extract = function(node)
                    local results = {}
                    local tree = {
                        {
                            retrieve = "first",
                            node_type = "function_definition",
                            subtree = {
                                {
                                    retrieve = "first",
                                    node_type = "block",
                                    subtree = {
                                        {
                                            retrieve = "all",
                                            node_type = "expression_statement",
                                            subtree = {
                                                { retrieve = "first", node_type = "assignment", extract = true },
                                            },
                                        },
                                    },
                                },
                            },
                        },
                    }

                    local nodes = neogen.utilities.nodes:matching_nodes_from(node, tree)

                    results.attributes = {}
                    for _, assignment in pairs(nodes["assignment"]) do
                        local left_side = assignment:field("left")[1]
                        local left_attribute = left_side:field("attribute")[1]
                        table.insert(results.attributes, ts_utils.get_node_text(left_attribute)[1])
                    end

                    return results
                end,
            },
        },
    },

    -- Use default granulator and generator
    locator = nil,
    granulator = nil,
    generator = nil,

    template = {
        annotation_convention = "google_docstrings", -- required: Which annotation convention to use (default_generator)
        append = { position = "after", child_name = "block" }, -- optional: where to append the text (default_generator)
        use_default_comment = false, -- If you want to prefix the template with the default comment for the language, e.g for python: # (default_generator)
        google_docstrings = {
            { nil, '"""' },
            { nil, '""" """', { no_results = true } },
            { "parameters", "\t%s: ", { before_first_item = { "", "Args:" } } },
            { "attributes", "\t%s: ", { before_first_item = { "", "Attributes: " } } },
            { "return_statement", "", { before_first_item = { "", "Returns: " } } },
            { nil, "" },
            { nil, '"""' },
        },
        numpydoc = {
            { nil, '"""' },
            { nil, '""" """', { no_results = true } },
            { "parameters", "%s: ", { before_first_item = { "", "Parameters", "----------" } } },
            { "attributes", "%s: ", { before_first_item = { "", "Attributes", "----------" } } },
            { "return_statement", "", { before_first_item = { "", "Returns", "-------" } } },
            { nil, "" },
            { nil, '"""' },
        },
    },
}
