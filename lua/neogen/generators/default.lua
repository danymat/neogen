local ts_utils = require("nvim-treesitter.ts_utils")

---Default Generator:
---Uses the provided template to format the annotations with data found by the granulator
--- @param parent userdata the node used to generate the annotations
--- @param data table the data from the granulator, which is a set of [type] = results
--- @param template table a template from the configuration
--- @return table { line, content, opts }, with line being the line to append the content

neogen.default_generator = function(parent, data, template)
    local start_row, start_column, end_row, end_column = ts_utils.get_node_range(parent)
    local commentstring, generated_template = vim.trim(vim.api.nvim_buf_get_option(0, "commentstring"):format(""))

    local row_to_place = start_row
    local col_to_place = start_column

    local append = template.append or {}

    if append.position == "after" then
        local child_node = neogen.utilities.nodes:matching_child_nodes(parent, append.child_name)[1]
        if child_node ~= nil then
            row_to_place, col_to_place, _, _ = child_node:range()
        end
    end

    if not template or not template.annotation_convention then
        -- Default template
        generated_template = {
            { nil, "" },
            { "name", " @Summary " },
            { "parameters", " @Param " },
            { "return", " @Return " },
        }
    elseif type(template) == "function" then
        -- You can also pass a function as a template
        generated_template = template(parent, commentstring, data)
    else
        generated_template = template[template.annotation_convention]
    end

    local function parse_generated_template()
        local result = {}
        local prefix = (" "):rep(col_to_place)

        -- Do not append the comment string if not wanted
        if template.use_default_comment ~= false then
            prefix = prefix .. commentstring
        end

        for _, values in ipairs(generated_template) do
            local type = values[1]
            local formatted_string = values[2]
            local opts = values[3] or {}
            
            -- Will append the item before all their nodes
            if opts.before_first_item and data[type] then
                for i, value in ipairs(opts.before_first_item) do
                    if value == "" then
                        table.insert(result, value)
                    else
                        table.insert(result, prefix .. value)
                    end
                end
            end

            -- If there is no data returned, will append the string with opts.no_results
            if opts.no_results == true and vim.tbl_isempty(data) then
                if formatted_string == "" then
                    table.insert(result, formatted_string)
                else
                    table.insert(result, prefix .. formatted_string)
                end
            else
                -- append the output as is
                if type == nil and opts.no_results ~= true and not vim.tbl_isempty(data) then
                    if formatted_string == "" then
                        table.insert(result, formatted_string)
                    else
                        table.insert(result, prefix .. formatted_string:format(""))
                    end
                else
                    -- Format the output with the corresponding data
                    if data[type] then
                        for _, value in ipairs(data[type]) do
                            if formatted_string == "" then
                                table.insert(result, formatted_string)
                            else
                                table.insert(result, prefix .. formatted_string:format(value))
                            end
                        end
                    end
                end
            end
        end

        return result
    end

    return row_to_place, col_to_place, parse_generated_template()
end
