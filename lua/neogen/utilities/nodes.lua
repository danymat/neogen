neogen.utilities.nodes = {
    --- Get a list of child nodes that match the provided node name
    --- @param _ any
    --- @param parent userdata the parent's node
    --- @param node_name string the node type to search for
    --- @return table a table of nodes that matched the name
    matching_child_nodes = function (_, parent, node_name)
        local results = {}

        for child in parent:iter_children() do
            if child:type() == node_name then
                table.insert(results, child)
            end
        end
        return results
    end,
}
