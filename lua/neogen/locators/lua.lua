local ts_utils = require("nvim-treesitter.ts_utils")

return function(node_info, nodes_to_match)
    -- We're dealing with a lua comment and we need to escape its grasp
    if node_info.current:type() == "source" then
        local start_row, _, _, _ = ts_utils.get_node_range(node_info.current)
        vim.api.nvim_win_set_cursor(0, { start_row, 0 })
        node_info.current = ts_utils.get_node_at_cursor()
    end

    return neogen.default_locator(node_info, nodes_to_match)
end
