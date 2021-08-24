return {
    -- Search for these nodes
    parent = { "function", "local_function", "local_variable_declaration", "field", "variable_declaration" },

    -- Traverse down these nodes and extract the information as necessary
    data = {
        ["function|local_function"] = {
            -- Get second child from the parent node
            ["2"] = {
                -- It has to be of type "parameters"
                match = "parameters",

                extract = function(node)
                    local tree = {
                        { retrieve = "all", node_type = "identifier", extract = true },
                        { retrieve = "all", node_type = "spread", extract = true },
                    }
                    local nodes = neogen.utilities.nodes:matching_nodes_from(node, tree)
                    local res = neogen.utilities.extractors:extract_from_matched(nodes)

                    return {
                        parameters = res.identifier,
                        vararg = res.spread,
                    }
                end,
            },
        },
        ["local_variable_declaration|field|variable_declaration"] = {
            ["2"] = {
                match = "function_definition",

                extract = function(node)
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
                end,
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
            { "parameters", "- @param %s any" },
            { "vararg", "- @vararg any" },
            { "return_statement", "- @return any" },
        },
    },
}
