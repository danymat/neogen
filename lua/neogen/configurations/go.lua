local template = require("neogen.utilities.template")

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

    template = template:config({ use_default_comment = true }):add_default_template("godoc"),
}
