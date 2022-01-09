return {
    parent = {
        func = { "function_item" },
        class = { "struct_item" },
        file = { "source_file" },
    },
    data = {
        func = {
            ["function_item"] = {
                ["0"] = {
                    extract = function()
                        return {}
                    end,
                },
            },
        },
        file = {
            ["source_file"] = {
                ["0"] = {
                    extract = function()
                        return {}
                    end,
                },
            },
        },
        class = {
            ["struct_item"] = {
                ["0"] = {
                    extract = function()
                        return {}
                    end,
                },
            },
        },
    },

    template = {
        annotation_convention = "rustdoc",
        rustdoc = {
            { nil, "! $1", { no_results = true, type = { "file" } } },
            { nil, "", { no_results = true, type = { "file" } } },

            { nil, "/ $1", { no_results = true, type = { "func", "class" } } },
        },
    },
}
