local _template = require("neogen.template")
local i = require("neogen.types.template").item
local extractors = require("neogen.utilities.extractors")
local nodes_utils = require("neogen.utilities.nodes")

---@type neogen.Configuration
local template = {}

template.parent = {
    class = { "class_declaration" },
    func = { "function_declaration" },
}

template.data = {
    func = {
        ["function_declaration"] = {
            ["0"] = {
                extract = function(node)
                    local tree = {
                        {
                            node_type = "parameter",
                            retrieve = "all",
                            subtree = {
                                {
                                    node_type = "simple_identifier",
                                    as = i.Parameter,
                                    retrieve = "first",
                                    extract = true,
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
    class = {
        ["class_declaration"] = {
            ["0"] = {
                extract = function(node)
                    local tree = {
                        {
                            node_type = "primary_constructor",
                            retrieve = "first",
                            subtree = {
                                {
                                    node_type = "class_parameter",
                                    retrieve = "all",
                                    subtree = {
                                        {
                                            node_type = "simple_identifier",
                                            retrieve = "first",
                                            extract = true,
                                            as = i.ClassAttribute,
                                        },
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
}

template.template = _template:add_default_annotation("kdoc")

return template
