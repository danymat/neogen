---@class Neogen.node_info
---@field current TSNode the current node from cursor
---@field root? TSNode the root node

--- The default locator tries to find one of the nodes to match in the current node
--- If it does not find one, will fetch the parents until he finds one
---@param node_info Neogen.node_info a node informations
---@param nodes_to_match TSNode[] a list of parent nodes to match
---@return TSNode? node one of the nodes to match directly above the given node
return function(node_info, nodes_to_match)
    if not node_info.current then
        if vim.tbl_contains(nodes_to_match, node_info.root:type()) then
            return node_info.root
        end

        return
    end

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
