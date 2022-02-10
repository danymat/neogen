local _template = require("neogen.template")
local i = require("neogen.types.template").item
local nodes_utils = require("neogen.utilities.nodes")
local extractors = require("neogen.utilities.extractors")

---@type neogen.Configuration
local template = {}

template.parent = {
    func = { "function_definition" },
    file = { "program" },
}

template.data = {
    func = {
        ["function_definition"] = {
            ["0"] = {
                extract = function(node)
                    local tree = {
                        {
                            node_type = "compound_statement",
                            retrieve = "first",
                            subtree = {
                                {
                                    node_type = "simple_expansion",
                                    retrieve = "all",
                                    recursive = true,
                                    as = i.Parameter,
                                    extract = true,
                                },
                                {
                                    node_type = "expansion",
                                    recursive = true,
                                    retrieve = "all",
                                    subtree = {
                                        { node_type = "variable_name", retrieve = "all", extract = true },
                                    },
                                },
                            },
                        },
                    }
                    local nodes = nodes_utils:matching_nodes_from(node, tree)
                    local res = extractors:extract_from_matched(nodes)
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
}

template.template = _template:add_default_annotation("google_bash")

return template
