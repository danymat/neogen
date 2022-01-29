local ts_utils = require("nvim-treesitter.ts_utils")
local nodes_utils = require("neogen.utilities.nodes")
local extractors = require("neogen.utilities.extractors")

return {
    -- Search for these nodes
    parent = {
        func = { "function_definition" },
        class = { "class_definition" },
        file = { "module" },
        type = { "expression_statement" },
    },

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
                                        extract = true,
                                    },
                                    {
                                        retrieve = "all",
                                        node_type = "typed_default_parameter",
                                        extract = true,
                                        subtree = { { retrieve = "all", node_type = "identifier", extract = true } },
                                    },
                                },
                            },
                            {
                                retrieve = "first",
                                node_type = "block",
                                subtree = {
                                    {
                                        retrieve = "all",
                                        node_type = "return_statement",
                                        recursive = true,
                                        subtree = {
                                            {
                                                retrieve = "all",
                                                node_type = "true|false|integer|binary_operator|expression_list",
                                                as = "anonymous_return",
                                                recursive = true,
                                                extract = true,
                                            },
                                            {
                                                retrieve = "all",
                                                node_type = "identifier",
                                                as = "return_statement",
                                                recursive = true,
                                                extract = true,
                                            },
                                        },
                                    },
                                },
                            },
                            {
                                retrieve = "all",
                                node_type = "type",
                                as = "return_type",
                                recursive = true,
                                extract = true,
                            },
                        }
                        local nodes = nodes_utils:matching_nodes_from(node, tree)
                        if nodes["typed_parameter"] then
                            results["typed_parameters"] = {}
                            for _, n in pairs(nodes["typed_parameter"]) do
                                local type_subtree = {
                                    { retrieve = "all", node_type = "identifier", extract = true },
                                    { retrieve = "all", node_type = "type", extract = true },
                                }
                                local typed_parameters = nodes_utils:matching_nodes_from(n, type_subtree)
                                typed_parameters = extractors:extract_from_matched(typed_parameters)
                                table.insert(results["typed_parameters"], typed_parameters)
                            end
                        end
                        local res = extractors:extract_from_matched(nodes)

                        if nodes["anonymous_return"] then
                            local _res = extractors:extract_from_matched(nodes, { type = true })
                            results.anonymous_return = _res.anonymous_return
                        end

                        results.has_identifier = (res.typed_parameter or res.identifier) and { true } or nil
                        results.type = res.type
                        results.parameters = res.identifier
                        results.return_statement = res.return_statement
                        results.has_return = (res.return_statement or res.anonymous_return) and { true } or nil
                        return results
                    end,
                },
            },
        },
        class = {
            ["class_definition"] = {
                ["0"] = {
                    extract = function(node)
                        local results = {}
                        local tree = {
                            {
                                retrieve = "first",
                                node_type = "block",
                                subtree = {
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
                                                            {
                                                                retrieve = "first",
                                                                node_type = "assignment",
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
                        }

                        local nodes = nodes_utils:matching_nodes_from(node, tree)

                        if vim.tbl_isempty(nodes) then
                            return {}
                        end

                        results.attributes = {}
                        for _, assignment in pairs(nodes["assignment"]) do
                            local left_side = assignment:field("left")[1]
                            local left_attribute = left_side:field("attribute")[1]
                            left_attribute = ts_utils.get_node_text(left_attribute)[1]
                            if left_attribute and not vim.startswith(left_attribute, "_") then
                                table.insert(results.attributes, left_attribute)
                            end
                        end
                        if vim.tbl_isempty(results.attributes) then
                            results.attributes = nil
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
        type = {
            ["0"] = {
                extract = function()
                    return {}
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
        append = { position = "after", child_name = "comment", fallback = "block" }, -- optional: where to append the text (default_generator)
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

            { nil, "# $1", { no_results = true, type = { "type" } } },

            { nil, '"""$1' },
            { "has_identifier", "", { type = { "func" } } },
            { "has_identifier", "Args:", { type = { "func" } } },
            { "parameters", "\t%s ($1): $1", { type = { "func" } } },
            { { "identifier", "type" }, "\t%s (%s): $1", { required = "typed_parameters", type = { "func" } } },
            { "attributes", "\t%s: $1", { before_first_item = { "", "Attributes: " } } },
            { "has_return", "", { type = { "func" } } },
            { "has_return", "Returns:", { type = { "func" } } },
            { "has_return", "\t$1", { type = { "func" } } },
            { nil, '"""' },
        },
        numpydoc = {
            { nil, '""" $1 """', { no_results = true, type = { "class", "func" } } },
            { nil, '"""$1', { no_results = true, type = { "file" } } },
            { nil, "", { no_results = true, type = { "file" } } },
            { nil, "$1", { no_results = true, type = { "file" } } },
            { nil, '"""', { no_results = true, type = { "file" } } },
            { nil, "", { no_results = true, type = { "file" } } },

            { nil, "# $1", { no_results = true, type = { "type" } } },

            { nil, '"""$1' },
            { "has_identifier", "", { type = { "func" } } },
            { "has_identifier", "Parameters", { type = { "func" } } },
            { "has_identifier", "----------", { type = { "func" } } },
            {
                "parameters",
                "%s: $1",
                { after_each = "\t$1", type = { "func" } },
            },
            {
                { "identifier", "type" },
                "%s: %s",
                { after_each = "\t$1", required = "typed_parameters", type = { "func" } },
            },
            { "attributes", "%s: $1", { before_first_item = { "", "Attributes", "----------" } } },
            { "has_return", "", { type = { "func" } } },
            { "has_return", "Returns", { type = { "func" } } },
            { "has_return", "-------", { type = { "func" } } },
            {
                "return_statement",
                "%s : $1",
                { after_each = "\t$1" },
            },
            {
                "anonymous_return",
                "%s",
                { after_each = "\t$1" },
            },
            { nil, '"""' },
        },
        reST = {
            { nil, '""" $1 """', { no_results = true, type = { "class", "func" } } },
            { nil, '"""$1', { no_results = true, type = { "file" } } },
            { nil, "", { no_results = true, type = { "file" } } },
            { nil, "$1", { no_results = true, type = { "file" } } },
            { nil, '"""', { no_results = true, type = { "file" } } },
            { nil, "", { no_results = true, type = { "file" } } },

            { nil, "# $1", { no_results = true, type = { "type" } } },

            { nil, '"""$1' },
            { nil, "" },
            {
                "parameters",
                ":param %s: $1",
                { after_each = ":type %s: $1", type = { "func" } },
            },
            {
                { "identifier", "type" },
                ":param %s: $1",
                {
                    after_each = ":type %s: %s $1",
                    required = "typed_parameters",
                    type = { "func" },
                },
            },
            { "attributes", ":param %s: $1" },
            { "has_return", ":return: $1", { type = { "func" } } },
            { "has_return", ":rtype: $1", { type = { "func" } } },
            { nil, '"""' },
        },
    },
}
