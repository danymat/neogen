local ts_utils = require("nvim-treesitter.ts_utils")

return {
    -- Search for these nodes
    parent = { func = { "function_definition" }, class = { "class_definition" }, file = { "module" } },

    -- Traverse down these nodes and extract the information as necessary
    data = {
        func = {
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
        },
        class = {
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

                        if vim.tbl_isempty(nodes) then
                            return {}
                        end

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
        file = {
            ["module"] = {
                ["0"] = {
                    extract = function()
                        return {}
                    end,
                },
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
        position = function(node, type)
            if type == "file" then
                -- Checks if the file starts with #!, that means it's a shebang line
                -- We will then write file annotations just after it
                for child in node:iter_children() do
                    if child:type() == "comment" then
                        local start_row = child:start()
                        if start_row == 0 then
                            if vim.startswith(ts_utils.get_node_text(node, 0)[1], "#!") then
                                return 1, 0
                            end
                        end
                    end
                end
                return 0, 0
            end
        end,

        google_docstrings = {
            { nil, '""" $1 """', { no_results = true, type = { "class", "func" } } },
            { nil, '"""$1', { no_results = true, type = { "file" } } },
            { nil, "", { no_results = true, type = { "file" } } },
            { nil, "$1", { no_results = true, type = { "file" } } },
            { nil, '"""', { no_results = true, type = { "file" } } },
            { nil, "", { no_results = true, type = { "file" } } },

            { nil, '"""$1' },
            { "parameters", "\t%s: $1", { before_first_item = { "", "Args:" } } },
            { "attributes", "\t%s: $1", { before_first_item = { "", "Attributes: " } } },
            { "return_statement", "\t$1", { before_first_item = { "", "Returns: " } } },
            { nil, '"""' },
        },
        numpydoc = {
            { nil, '""" $1 """', { no_results = true, type = { "class", "func" } } },
            { nil, '"""$1', { no_results = true, type = { "file" } } },
            { nil, "", { no_results = true, type = { "file" } } },
            { nil, "$1", { no_results = true, type = { "file" } } },
            { nil, '"""', { no_results = true, type = { "file" } } },
            { nil, "", { no_results = true, type = { "file" } } },

            { nil, '"""$1' },
            { "parameters", "%s: $1", { before_first_item = { "", "Parameters", "----------" } } },
            { "attributes", "%s: $1", { before_first_item = { "", "Attributes", "----------" } } },
            { "return_statement", "$1", { before_first_item = { "", "Returns", "-------" } } },
            { nil, '"""' },
        },
    },
}
