---The default locator tries to find one of the nodes to match in the current node
--If it does not find one, will fetch the parents until he finds one
---@param node_info table
---@param nodes_to_match table
neogen.default_locator = function(node_info, nodes_to_match)
    -- If we find one of the wanted nodes in current one, return the current node
    if vim.tbl_contains(nodes_to_match, node_info.current:type()) then
        return node_info.current
    end

    -- Else, loop to parents until we find one of the nodes to match
    while node_info.current and not vim.tbl_contains(nodes_to_match, node_info.current:type()) do
        node_info.current = node_info.current:parent()
    end

    return node_info.current
end
