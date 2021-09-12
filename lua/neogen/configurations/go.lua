return {
    parent = {
        func = { "function_declaration" },
    },

    data = {
        func = {
            ["function_declaration"] = {
                ["0"] = {
                    extract = function()
                        return {}
                    end,
                },
            },
        },
    },

    template = {
        annotation_convention = "godoc",
        godoc = {
            { nil, " $1", { no_results = true } },
        },
    },
}
