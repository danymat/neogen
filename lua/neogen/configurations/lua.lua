return {
    -- Search for these nodes
    parent = { "function", "local_function", "local_variable_declaration", "field", "variable_declaration"},

    -- Traverse down these nodes and extract the information as necessary
    data = {
        ["function|local_function"] = {
            ["2"] = {
                match = "parameters",

                extract = function(node)
                    local regular_params = neogen.utility:extract_children("identifier")(node)
                    local varargs = neogen.utility:extract_children("spread")(node)

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
                    local regular_params = neogen.utility:extract_children_from("identifier", {
                        [1] = "extract",
                    })(node)

                    local varargs = neogen.utility:extract_children_from("spread", {
                        [1] = "extract",
                    })(node)

                    return {
                        parameters = regular_params,
                        vararg = varargs,
                    }
                end,
            },
        },
    },

    -- Custom lua locator that escapes from comments
    locator = function(node_info, nodes_to_match)
        -- We're dealing with a lua comment and we need to escape its grasp
        if node_info.current:type() == "source" then
            local start_row, _, _, _ = ts_utils.get_node_range(node_info.current)
            vim.api.nvim_win_set_cursor(0, { start_row, 0 })
            node_info.current = ts_utils.get_node_at_cursor()
        end

        return neogen.default_locator(node_info, nodes_to_match)
    end,

    -- Use default granulator and generator
    granulator = nil,
    generator = nil,

    template = {
        { nil, "- " },
        { "parameters", "- @param %s any" },
        { "vararg", "- @vararg any" },
    },
}
