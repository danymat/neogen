neogen.utilities.nodes = {
    --- Get a list of child nodes that match the provided node name
    --- @param _ any
    --- @param parent userdata the parent's node
    --- @param node_name string the node type to search for (if multiple childrens, separate each one with "|")
    --- @return table a table of nodes that matched the name
    matching_child_nodes = function(_, parent, node_name)
        local results = {}
        local split = vim.split(node_name, "|", true)

        for child in parent:iter_children() do
            if vim.tbl_contains(split, child:type()) then
                table.insert(results, child)
            end
        end
        return results
    end,

    --- Get all required nodes from tree
    --- @param parent userdata the parent node
    --- @param tree table a nested table : { retrieve = "all|first", node_type = node_name, subtree = tree }
    --- If you want to extract the node, do not specify the subtree and instead: extract = true
    --- @param result table the table of results
    --- @return table result a table of k,v where k are node_types and v all matched nodes
    matching_nodes_from = function(self, parent, tree, result)
        result = result or {}

        for _, subtree in pairs(tree) do
            -- Match all child nodes
            local matched = self:matching_child_nodes(parent, subtree.node_type)

            -- Only keep first matched child node
            if subtree.retrieve == "first" and #matched ~= 0 then
                matched = { matched[1] }
            end

            for _, child in pairs(matched) do
                -- Add to results
                if subtree.extract == true then
                    if result[subtree.node_type] == nil then
                        result[subtree.node_type] = {}
                    end
                    table.insert(result[subtree.node_type], child)
                else
                    local test = self:matching_nodes_from(child, subtree.subtree, result)
                    result = vim.tbl_deep_extend("keep", result, test)
                end
            end
        end
        return result
    end,
}
