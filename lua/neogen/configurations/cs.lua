local extractors = require("neogen.utilities.extractors")
local nodes_utils = require("neogen.utilities.nodes")
local template = require("neogen.template")
local i = require("neogen.types.template").item

local is_void = function(return_statement)
    if not return_statement then
        return
    end
    for _, value in ipairs(return_statement) do
        if value == "void" then
            return true
        end
    end
    return false
end

local get_parameters_tree = function()
    return {
        retrieve = "first",
        node_type = "parameter_list",
        subtree = {
            {
                retrieve = "all",
                node_type = "parameter",
                subtree = {
                    { position = -1, extract = true, as = i.Parameter },
                },
            },
        },
    }
end

local get_type_parameters_tree = function()
    return {
        retrieve = "first",
        node_type = "type_parameter_list",
        subtree = {
            {
                retrieve = "all",
                node_type = "type_parameter",
                subtree = {
                    { position = 1, extract = true, as = i.Tparam },
                },
            },
        },
    }
end

return {
    parent = {
        func = {
            "method_declaration",
            "constructor_declaration",
            "operator_declaration",
            "delegate_declaration",
            "conversion_operator_declaration",
        },
        class = { "interface_declaration", "class_declaration", "record_declaration", "struct_declaration" },
        type = { "field_declaration", "property_declaration", "event_field_declaration", "indexer_declaration" },
    },
    data = {
        func = {
            ["method_declaration|constructor_declaration|operator_declaration|delegate_declaration|conversion_operator_declaration"] = {
                ["0"] = {
                    extract = function(node)
                        local tree = {
                            get_type_parameters_tree(),
                            get_parameters_tree(),
                            {
                                retrieve = "all",
                                extract = true,
                                as = i.Return,
                            },
                        }
                        local nodes = nodes_utils:matching_nodes_from(node, tree)
                        local res = extractors:extract_from_matched(nodes)

                        local has_no_return = node:type() == "constructor_declaration"
                                              or is_void(res.return_statement);
                        if has_no_return then
                            res.return_statement = nil
                        else
                            res.return_statement = { res.return_statement[1] }
                        end
                        res.identifier = res["_"]
                        return res
                    end,
                },
            },
        },
        class = {
            ["interface_declaration"] = {
                ["0"] = {
                    extract = function(node)
                        local tree = {
                            get_type_parameters_tree()
                        }
                        local nodes = nodes_utils:matching_nodes_from(node, tree)
                        local res = extractors:extract_from_matched(nodes)
                        res.identifier = res["_"]
                        return res
                    end,
                },
            },
            ["class_declaration|record_declaration|struct_declaration"] = {
                ["0"] = {
                    extract = function(node)
                        local tree = {
                            get_type_parameters_tree(),
                            get_parameters_tree(),
                        }
                        local nodes = nodes_utils:matching_nodes_from(node, tree)
                        local res = extractors:extract_from_matched(nodes)
                        res.identifier = res["_"]
                        return res
                    end,
                },
            },
        },
        type = {
            ["field_declaration|property_declaration|event_field_declaration"] = {
                ["0"] = {
                    extract = function()
                        return {}
                    end,
                },
            },
            ["indexer_declaration"] = {
                ["0"] = {
                    extract = function(node)
                        local tree = {
                            {
                                retrieve = "first",
                                node_type = "bracketed_parameter_list",
                                subtree = {
                                    {
                                        retrieve = "all",
                                        node_type = "parameter",
                                        subtree = {
                                            {
                                                retrieve = "first",
                                                node_type = "identifier",
                                                extract = true,
                                                as = i.Parameter,
                                            },
                                        },
                                    },
                                },
                            },
                            {
                                retrieve = "first",
                                node_type = "accessor_list",
                                subtree = {
                                    {
                                        retrieve = "all",
                                        node_type = "accessor_declaration",
                                        as = i.Return,
                                        extract = true,
                                    },
                                },
                            },
                        }
                        local nodes = nodes_utils:matching_nodes_from(node, tree)
                        local res = extractors:extract_from_matched(nodes)

                        local has_getter = false;
                        if res.return_statement then
                            for _, value in ipairs(res.return_statement) do
                                if vim.startswith(value, "get") then
                                    has_getter = true
                                    break
                                end
                            end
                        end
                        if has_getter then
                            res.return_statement = { "get" }
                        else
                            res.return_statement = nil
                        end

                        return res
                    end,
                },
            },
        },
    },
    template = template:add_default_annotation("doxygen"):add_annotation("xmldoc"),
}
