---@param node_info Neogen.node_info
---@param nodes_to_match TSNode[]
---@return TSNode?
return function(node_info, nodes_to_match)
    local current = node_info.current
    local parents = { "class_definition", "function_definition", "module" }

    while current do
        if vim.tbl_contains(parents, current:type()) then
            return current
        end

        current = current:parent()
    end

    return nil
end
