local common_function_extractor = function(node)
    local tree = {
        {
            retrieve = "first",
            node_type = "parameters",
            subtree = {
                { retrieve = "all", node_type = "identifier", extract = true },
                { retrieve = "all", node_type = "spread", extract = true },
            },
        },
        { retrieve = "first", node_type = "return_statement", extract = true },
    }

    local nodes = neogen.utilities.nodes:matching_nodes_from(node, tree)
    local res = neogen.utilities.extractors:extract_from_matched(nodes)

    return {
        parameters = res.identifier,
        vararg = res.spread,
        return_statement = res.return_statement,
    }
end

return {
    -- Search for these nodes
    parent = {
        func = { "function", "local_function", "local_variable_declaration", "field", "variable_declaration" },
        class = { "local_variable_declaration" },
    },

    data = {
        func = {
            -- When the function is inside one of those
            ["local_variable_declaration|field|variable_declaration"] = {
                ["2"] = {
                    match = "function_definition",

                    extract = common_function_extractor,
                },
            },
            -- When the function is in the root tree
            ["function_definition|function|local_function"] = {
                ["0"] = {

                    extract = common_function_extractor,
                },
            },
        },
        class = {
            ["local_variable_declaration"] = {
                ["0"] = {
                    extract = function(node)
                        local tree = {
                            {
                                retrieve = "first",
                                node_type = "variable_declarator",
                                subtree = {
                                    { retrieve = "first", node_type = "identifier", extract = true },
                                },
                            },
                        }
                        local nodes = neogen.utilities.nodes:matching_nodes_from(node, tree)
                        local res = neogen.utilities.extractors:extract_from_matched(nodes)
                        return {
                            class_name = res.identifier,
                        }
                    end,
                },
            },
        },
    },

    -- Custom lua locator that escapes from comments
    locator = require("neogen.locators.lua"),

    -- Use default granulator and generator
    granulator = nil,
    generator = nil,

    template = {
        -- Which annotation convention to use
        annotation_convention = "emmylua",
        emmylua = {
            { nil, "- " },
            { nil, "- ", { no_results = true } },
            { "parameters", "- @param %s any" },
            { "vararg", "- @vararg any" },
            { "return_statement", "- @return any" },
            { "class_name", "- @class any" },
        },
    },
}
