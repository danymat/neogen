local ts_utils = require("nvim-treesitter.ts_utils")

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
                    local regular_params = neogen.utilities.extractors:extract_children_text("identifier")(node)
                    local varargs = neogen.utilities.extractors:extract_children_text("spread")(node)

                    return {
                        parameters = regular_params,
                        vararg = varargs,
                    }
                end,
            },
        },
        ["local_variable_declaration|field|variable_declaration"] = {
            ["2"] = {
                match = "function_definition",

                extract = function(node)
                    local regular_params = neogen.utilities.extractors:extract_children_from({
                        [1] = "extract",
                    }, "identifier")(node)

                    local varargs = neogen.utilities.extractors:extract_children_from({
                        [1] = "extract",
                    }, "spread")(node)

                    local return_statement = neogen.utilities.extractors:extract_children_text("return_statement")(node)

                    return {
                        parameters = regular_params,
                        vararg = varargs,
                        return_statement = return_statement,
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
