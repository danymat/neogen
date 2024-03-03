local helpers = require("neogen.utilities.helpers")

--- Tries to use the configuration to find all required content nodes from the parent node
---@param parent_node TSNode the node found by the locator
---@param node_data table the data from configurations[lang].data
return function(parent_node, node_data)
    local result = {}
    if not parent_node then
        return result
    end

    for parent_type, child_data in pairs(node_data) do
        local matches = helpers.split(parent_type, "|", true)

        -- Look if the parent node is one of the matches
        if vim.tbl_contains(matches, parent_node:type()) then
            -- For each child_data in the matched parent node
            for i, data in pairs(child_data) do
                local index = tonumber(i)
                assert(index, "Need a valid index")

                local child_node = index == 0 and parent_node or parent_node:named_child(index - 1)

                if not child_node then
                    return
                end

                if not data.match or child_node:type() == data.match then
                    if not type(data.extract) == "function" then
                        return
                    end

                    -- Extract content from it { [type] = { data } }
                    for type, extracted_data in pairs(data.extract(child_node)) do
                        result[type] = extracted_data
                    end
                end
            end
        end
    end

    return result
end
