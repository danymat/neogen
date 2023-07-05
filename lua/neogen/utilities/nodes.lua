local helpers = require("neogen.utilities.helpers")
return {
    --- Get a list of child nodes that match the provided node name
    --- @param _ any
    --- @param parent TSNode the parent's node
    --- @param node_type? string the node type to search for (if multiple childrens, separate each one with "|")
    --- @return table a table of nodes that matched the name
    matching_child_nodes = function(_, parent, node_type)
        local results = {}
        -- Return all nodes if there is no node name
        if not node_type then
            for child in parent:iter_children() do
                if child:named() then
                    table.insert(results, child)
                end
            end
        else
            local types = helpers.split(node_type, "|", true)
            for child in parent:iter_children() do
                if vim.tbl_contains(types, child:type()) then
                    table.insert(results, child)
                end
            end
        end

        return results
    end,

    --- Find all nested childs from `parent` that match `node_name`. Returns a table of found nodes
    --- @param parent TSNode
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

            self:recursive_find(child, node_name, { results = results })
        end

        return results
    end,

    --- Get all required nodes from tree
    --- @param parent TSNode the parent node
    --- @param tree table a nested table : { retrieve = "all|first", node_type = node_name, subtree = tree, recursive = true }
    --- If you want to extract the node, do not specify the subtree and instead: extract = true
    --- Optional: you can specify position = number instead of retrieve, and it will fetch the child node at position number
    --- @param result? table the table of results
    --- @return table result a table of k,v where k are node_types and v all matched nodes
    matching_nodes_from = function(self, parent, tree, result)
        result = result or {}

        for _, subtree in pairs(tree) do
            assert(
                not subtree.retrieve or vim.tbl_contains({ "all", "first" }, subtree.retrieve),
                "Supported nodes matching: all|first"
            )

            -- Match all child nodes of the parent node
            local matched = self:matching_child_nodes(parent, subtree.node_type)

            -- Only keep the node with custom position
            if not subtree.retrieve then
                assert(type(subtree.position) == "number", "please require position if retrieve is nil")
                matched = { matched[subtree.position] }
            end

            if subtree.recursive then
                local first = subtree.retrieve == "first"
                matched = self:recursive_find(parent, subtree.node_type, { first = first })
            end

            for _, child in pairs(matched) do
                if subtree.extract then
                    local name = subtree.as and subtree.as or (subtree.node_type or "_")
                    if not result[name] then
                        result[name] = {}
                    end
                    table.insert(result[name], child)
                else
                    self:matching_nodes_from(child, subtree.subtree, result)
                end
            end
        end
        return result
    end,
}
