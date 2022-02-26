local ts_utils = require("nvim-treesitter.ts_utils")
local default_locator = require("neogen.locators.default")

return function(node_info, nodes_to_match)
    local found_node = default_locator(node_info, nodes_to_match)

    if found_node and found_node:type() == "class_declaration" then
        local parent = found_node:parent()
        if parent and parent:type() == "export_statement" then
            return parent
        end
    end

    return found_node
end
