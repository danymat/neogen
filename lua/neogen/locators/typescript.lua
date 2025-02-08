local default_locator = require("neogen.locators.default")

---@param node_info Neogen.node_info
---@param nodes_to_match TSNode[]
---@return TSNode?
return function(node_info, nodes_to_match)
    local found_node = default_locator(node_info, nodes_to_match)

    if found_node and vim.tbl_contains({ "class_declaration" }, found_node:type()) then
        local parent = found_node:parent()
        if parent and parent:type() == "export_statement" then
            return parent
        end
    end

    if found_node and vim.tbl_contains({ "property_identifier" }, found_node:type()) then
        local parent = found_node:parent()
        if parent and parent:type() == "method_definition" then
            return parent
        end
    end

    return found_node
end
