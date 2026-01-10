local template = require("neogen.template")
local extractors = require("neogen.utilities.extractors")
local nodes_utils = require("neogen.utilities.nodes")
local i = require("neogen.types.template").item

return {
    parent = {
        func = { "binary_operator" },
    },
    data = {
        func = {
            ["binary_operator"] = {
                ["0"] = {
                    extract = function(node)
                        local function_name_node = node:child(0)
                        local function_name = vim.treesitter.get_node_text(function_name_node, 0)
                        local res = {}
                        res["function_name"] = { function_name }

                        local parameters_tree = {
                            {
                                retrieve = "first",
                                node_type = "function_definition",
                                subtree = {
                                    {
                                        retrieve = "first",
                                        node_type = "parameters",
                                        subtree = {
                                            {
                                                retrieve = "all",
                                                node_type = "parameter",
                                                subtree = {
                                                    {
                                                        retrieve = "first",
                                                        node_type = "identifier|dots",
                                                        extract = true,
                                                        as = i.Parameter,
                                                    },
                                                },
                                            },
                                        },
                                    },
                                },
                            },
                        }

                        local parameters_nodes = nodes_utils:matching_nodes_from(node, parameters_tree)
                        local params_res = extractors:extract_from_matched(parameters_nodes)

                        for k, v in pairs(params_res) do
                            if k == "parameters" then
                                res[k] = v
                            end
                        end

                        return res
                    end,
                },
            },
        },
    },
    template = template:add_default_annotation("roxygen2"),
}
