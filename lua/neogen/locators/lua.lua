local default_locator = require("neogen.locators.default")

return function(node_info, nodes_to_match)
    -- We're dealing with a lua comment and we need to escape its grasp
    if node_info.current and node_info.current:type() == "source" then
        local start_row, _, _, _ = vim.treesitter.get_node_range(node_info.current)
        vim.api.nvim_win_set_cursor(0, { start_row + 1, 0 })
        node_info.current = vim.treesitter.get_node()
    end

    local found_node = default_locator(node_info, nodes_to_match)

    -- for functions like "local x = function ()...end" the assignment_statement
    -- will be fetched just before the variable_declaration
    -- So we need to make sure to return the variable_declaration instead
    -- otherwise it'll mess up in our annotation placement
    if found_node and found_node:type() == "assignment_statement" then
        local parent = found_node:parent()
        if parent and parent:type() == "variable_declaration" then
            return parent
        end
    end

    return found_node
end
