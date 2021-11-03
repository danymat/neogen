neogen.utilities.nodes = {
    --- Get a list of child nodes that match the provided node name
    --- @param _ any
    --- @param parent userdata the parent's node
    --- @param node_name string|nil the node type to search for (if multiple childrens, separate each one with "|")
    --- @return table a table of nodes that matched the name
    matching_child_nodes = function(_, parent, node_name)
        local results = {}
        -- Return all nodes if there is no node name
        if node_name == nil then
            for child in parent:iter_children() do
                if child:named() then
                    table.insert(results, child)
                end
            end
        else
            local split = vim.split(node_name, "|", true)
            for child in parent:iter_children() do
                if vim.tbl_contains(split, child:type()) then
                    table.insert(results, child)
                end
            end
        end

        return results
    end,

    --- Find all nested childs from `parent` that match `node_name`. Returns a table of found nodes
    --- @param parent userdata
    --- @param node_name string
    --- @param opts table
    ---   - opts.first (bool):      if true, breaks at the first recursive item
    --- @return table
    recursive_find = function(self, parent, node_name, opts)
        opts = opts or {}
        local results = opts.results or {}

        for child in parent:iter_children() do
            -- Find the first recursive item and breaks
            if child:named() and child:type() == node_name then
                table.insert(results, child)
            end

            if opts.first and #results ~= 0 then
                break
            end

            local found = self:recursive_find(child, node_name, { results = results })
            vim.tbl_deep_extend("keep", results, found)
        end

        return results
    end,

    --- Get all required nodes from tree
    --- @param parent userdata the parent node
    --- @param tree table a nested table : { retrieve = "all|first", node_type = node_name, subtree = tree, recursive = true }
    --- If you want to extract the node, do not specify the subtree and instead: extract = true
    --- Optional: you can specify position = number instead of retrieve, and it will fetch the child node at position number
    --- @param result table the table of results
    --- @return table result a table of k,v where k are node_types and v all matched nodes
    matching_nodes_from = function(self, parent, tree, result)
        result = result or {}

        for _, subtree in pairs(tree) do
            if subtree.retrieve and not vim.tbl_contains({ "all", "first" }, subtree.retrieve) then
                assert(false, "Supported nodes matching: all|first")
                return
            end

            -- Match all child nodes of the parent node
            local matched = self:matching_child_nodes(parent, subtree.node_type)

            -- Only keep the node with custom position
            if subtree.retrieve == nil then
                if type(subtree.position) == "number" then
                    matched = { matched[subtree.position] }
                else
                    assert(false, "please require position if retrieve is nil")
                end
            end

            if subtree.recursive then
                local first = subtree.retrieve == "first"
                matched = self:recursive_find(parent, subtree.node_type, { first = first })
            end

            for _, child in pairs(matched) do
                if subtree.extract == true then
                    local name = subtree.node_type or "_"
                    if result[name] == nil then
                        result[name] = {}
                    end
                    table.insert(result[name], child)
                else
                    local nodes = self:matching_nodes_from(child, subtree.subtree, result)
                    result = vim.tbl_deep_extend("keep", result, nodes)
                end
            end
        end
        return result
    end,
}
