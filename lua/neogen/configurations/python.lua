local ts_utils = require("nvim-treesitter.ts_utils")

return {
    -- Search for these nodes
    parent = { "function_definition", "class_definition" },

    -- Traverse down these nodes and extract the information as necessary
    data = {
        ["function_definition"] = {
            ["2"] = {
                match = "parameters",

                extract = function(node)
                    local regular_params = neogen.utility:extract_children("identifier")(node)

                    return {
                        parameters = regular_params,
                    }
                end,
            },
        },
    },

    -- Use default granulator and generator
    locator = nil,
    granulator = nil,
    generator = nil,

    template = {
        annotation_convention = "google_docstrings", -- required: Which annotation convention to use (default_generator)
        append = { position = "after", child_name = "block" }, -- optional: where to append the text (default_generator)
        use_default_comment = false, -- If you want to prefix the template with the default comment for the language (default_generator)
        google_docstrings = {
            { nil, '"""' },
            { "parameters", "\t%s: ", { before_first_item = "Args: " } }, -- FIXME when no parameter is set
            { nil, '"""' },
        },
    },
}
