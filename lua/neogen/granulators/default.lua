local ts_utils = require("nvim-treesitter.ts_utils")

neogen.default_granulator = function(parent_node, node_data)
    local result = {}

    for parent_type, child_data in pairs(node_data) do
        local matches = vim.split(parent_type, "|", true)

        -- Look if the parent node is one of the matches
        if vim.tbl_contains(matches, parent_node:type()) then
            -- For each child_data in the matched parent node
            for i, data in pairs(child_data) do
                local child_node = parent_node:named_child(tonumber(i) - 1)

                if not child_node then
                    return
                end

                if child_node:type() == data.match or not data.match then
                    local extract = {}

                    if data.extract then
                        -- Extract content from it { [type] = { data } }
                        extract = data.extract(child_node)

                        -- All extracted values are created added in result, like so: [data.type] = { extract }
                        if data.type then
                            -- Extract information into a one-dimensional array
                            local one_dimensional_arr = {}

                            for _, values in pairs(extract) do
                                table.insert(one_dimensional_arr, values)
                            end

                            result[data.type] = one_dimensional_arr
                        else
                            for type, extracted_data in pairs(extract) do
                                result[type] = extracted_data
                            end
                        end
                    else
                        -- if not extract function, get the text from the node (required: data.type)
                        extract = ts_utils.get_node_text(child_node)
                        result[data.type] = extract
                    end
                end
            end
        end
    end

    return result
end
