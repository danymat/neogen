local nodes_utils = require("neogen.utilities.nodes")
local extractors = require("neogen.utilities.extractors")
local template = require("neogen.template")
local i = require("neogen.types.template").item

local parent = {
    func = { "function_definition" },
    class = { "struct_definition" },
}

--- Extract data for typed parameters
---@param nodes
---@param results
---@return
local function process_typed_parameters(nodes, results)
    if nodes["typed_expression"] then
        results["typed_parameters"] = {}
        for _, n in pairs(nodes["typed_expression"]) do
            local type_subtree = {
                { position = 1, extract = true, as = i.Parameter },
                { position = 2, extract = true, as = i.Type },
            }
            local typed_parameters = nodes_utils:matching_nodes_from(n, type_subtree)
            typed_parameters = extractors:extract_from_matched(typed_parameters)
            table.insert(results["typed_parameters"], typed_parameters)
        end
    end
    return results
end

return {
    -- Search for these nodes
    parent = parent,

    -- Traverse down these nodes and extract the information as necessary
    data = {
        class = {

            ["struct_definition"] = {
                ["0"] = {
                    extract = function(node)
                        local results = {}

                        local tree = {
                            -- Get the name of the struct
                            {
                                retrieve = "first",
                                node_type = "identifier",
                                extract = true,
                                as = "name",
                            },
                            -- Get type parameters
                            {
                                retrieve = "first",
                                recursive = true,
                                node_type = "type_parameter_list",
                                subtree = {
                                    {
                                        retrieve = "all",
                                        node_type = "identifier",
                                        extract = true,
                                        as = "type_params",
                                    },
                                },
                            },
                            -- Fields
                            {
                                retrieve = "all",
                                node_type = "typed_expression",
                                extract = true,
                            },
                        }
                        local nodes = nodes_utils:matching_nodes_from(node, tree)
                        results = process_typed_parameters(nodes, results)
                        local res = extractors:extract_from_matched(nodes)

                        local signature = res.name[1]
                        if res.type_params then
                            signature = signature .. "{" .. table.concat(res.type_params, ", ") .. "}"
                        end

                        results.signature = { signature }
                        results[i.HasParameter] = (res.typed_expression or res.identifier) and { true } or nil
                        results[i.Type] = res.type
                        results[i.Parameter] = res.identifier or nil

                        return results
                    end,
                },
            },
        },
        func = {

            ["function_definition"] = {

                ["0"] = {
                    extract = function(node)
                        local results = {}

                        local tree = {
                            {
                                retrieve = "first",
                                node_type = "signature",
                                recursive = true,
                                subtree = {
                                    {
                                        retrieve = "first",
                                        node_type = "call_expression",
                                        recursive = true,
                                        subtree = {
                                            -- Get the name of the function
                                            {
                                                position = 1,
                                                node_type = "identifier",
                                                extract = true,
                                                as = "f_name",
                                            },
                                            -- ... this considers cases like 'Base.add(...)'
                                            {
                                                position = 1,
                                                node_type = "field_expression",
                                                extract = true,
                                                as = "f_name",
                                            },
                                        },
                                    },
                                    {
                                        retrieve = "first",
                                        node_type = "argument_list",
                                        recursive = true,
                                        subtree = {
                                            {
                                                retrieve = "all",
                                                as = "param_list",
                                                extract = true,
                                            },
                                        },
                                    },
                                },
                            },
                            {
                                retrieve = "first",
                                node_type = "argument_list",
                                recursive = true,
                                subtree = {
                                    -- Parameters without type definition
                                    {
                                        retrieve = "all",
                                        node_type = "identifier",
                                        extract = true,
                                    },
                                    -- Typed parameters
                                    {
                                        retrieve = "all",
                                        node_type = "typed_expression",
                                        extract = true,
                                    },
                                    -- Optional parameters
                                    {
                                        retrieve = "all",
                                        node_type = "named_argument",
                                        subtree = {
                                            { retrieve = "all", node_type = "typed_expression", extract = true },
                                        },
                                    },
                                    {
                                        retrieve = "all",
                                        node_type = "named_argument",
                                        subtree = { { retrieve = "all", node_type = "identifier", extract = true } },
                                    },
                                    -- Splat parameters
                                    {
                                        retrieve = "all",
                                        node_type = "splat_expression",
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
                                        extract = true,
                                    },
                                },
                            },
                        }
                        local nodes = nodes_utils:matching_nodes_from(node, tree)

                        -- Add table with {params, types}
                        results = process_typed_parameters(nodes, results)

                        local res = extractors:extract_from_matched(nodes)
                        -- Make the signature
                        local signature
                        if res.param_list then
                            signature = res.f_name[1] .. "(" .. table.concat(res.param_list, ", ") .. ")"
                        else
                            signature = res.f_name[1] .. "()"
                        end

                        results[i.HasParameter] = (res.typed_expression or res.identifier) and { true } or nil
                        results[i.Type] = res.type
                        results.signature = { signature }
                        results.params = res.params
                        results[i.Parameter] = res.identifier
                        results[i.Return] = res.return_statement
                        results[i.ReturnTypeHint] = res[i.ReturnTypeHint]
                        results[i.HasReturn] = (res.return_statement or res.anonymous_return or res[i.ReturnTypeHint]) and
                            { true }
                            or nil

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

    template = template:add_default_annotation("julia"),
}
