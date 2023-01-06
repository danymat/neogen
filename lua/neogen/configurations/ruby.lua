local _template = require("neogen.template")
local i = require("neogen.types.template").item
local nodes_utils = require("neogen.utilities.nodes")
local extractors = require("neogen.utilities.extractors")

local template = {}

template.parent = {
    func = { "method", "singleton_method" },
    class = { "class", "module" },
    type = { "call" },
}

local identifier = {
    retrieve = "first",
    node_type = "identifier",
    as = i.Parameter,
    extract = true,
}

template.data = {
    func = {
        ["method|singleton_method"] = {
            ["0"] = {
                extract = function(node)
                    local tree = {
                        {
                            retrieve = "first",
                            node_type = "method_parameters",
                            subtree = {
                                {
                                    retrieve = "all",
                                    node_type = "optional_parameter",
                                    subtree = {
                                        identifier,
                                    },
                                },
                                identifier,
                            },
                        },
                        {
                            retrieve = "all",
                            node_type = "return",
                            as = i.Return,
                            extract = true,
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
        ["class|module"] = {
            ["0"] = {
                extract = function()
                    return {}
                end,
            },
        },
    },
    type = {
        ["call"] = {
            ["0"] = {
                extract = function()
                    return {}
                end,
            },
        },
    },
}

template.template = _template:add_default_annotation("yard"):add_annotation("rdoc"):add_annotation("tomdoc")

return template
