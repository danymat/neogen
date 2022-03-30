local ts_utils = require("nvim-treesitter.ts_utils")
local nodes_utils = require("neogen.utilities.nodes")
local extractors = require("neogen.utilities.extractors")
local locator = require("neogen.locators.default")
local template = require("neogen.template")
local i = require("neogen.types.template").item

local parent = {
    func = { "function_definition" },
}

return {
    -- Search for these nodes
    parent = parent,

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
                                node_type = "parameter_list",
                                subtree = {
                                    {
                                        retrieve = "all",
                                        node_type = "typed_parameter",
                                        extract = true,
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
                                        extract = true,
                                    },
                                },
                            },
                        }
                        local nodes = nodes_utils:matching_nodes_from(node, tree)
                        if nodes["typed_parameter"] then
                            results["typed_parameters"] = {}
                            for _, n in pairs(nodes["typed_parameter"]) do
                                local type_subtree = {
                                    { position = 1, extract = true, as = i.Parameter },
                                    { position = 2, extract = true, as = i.Type },
                                }
                                local typed_parameters = nodes_utils:matching_nodes_from(n, type_subtree)
                                typed_parameters = extractors:extract_from_matched(typed_parameters)
                                table.insert(results["typed_parameters"], typed_parameters)
                            end
                        end
                        local res = extractors:extract_from_matched(nodes)

                        return results
                    end,
                },
            },
        },
    },

    -- Use default granulator and generator
    locator = nil,
    granulator = nil,
    generator = nil,

    template = template:add_default_annotation("julia_test"),
}
