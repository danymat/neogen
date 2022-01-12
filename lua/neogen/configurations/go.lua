return {
    parent = {
        func = { "function_declaration" },
        type = { "package_clause", "const_declaration", "var_declaration" },
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
        type = {
            ["package_clause|const_declaration|var_declaration"] = {
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
