neogen.utilities.nodes = {
    --- Get first child node that match the provided node name
    --- @param _ any
    --- @param parent userdata the parent's node
    --- @param node_name string the node type to search for
    --- @return userdata node the first encountered child node
    first_child_node = function (_, parent, node_name)
        for child in parent:iter_children() do
            if child:type() == node_name then
                return child
            end
        end
    end
}
