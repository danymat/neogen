local ts_utils = require("nvim-treesitter.ts_utils")

---Default Generator:
---Uses the provided template to format the annotations with data found by the granulator
--- @param parent userdata the node used to generate the annotations
--- @param data table the data from the granulator, which is a set of [type] = results
--- @param template table a template from the configuration
--- @return table { line, content }, with line being the line to append the content
neogen.default_generator = function(parent, data, template)
    local start_row, start_column, _, _ = ts_utils.get_node_range(parent)
    local commentstring, generated_template = vim.trim(vim.api.nvim_buf_get_option(0, "commentstring"):format(""))

    if not template then
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
        generated_template = template
    end

    local function parse_generated_template()
        local result = {}
        local prefix = (" "):rep(start_column) .. commentstring

        for _, values in ipairs(generated_template) do
            local type = values[1]

            if not type then
                table.insert(result, prefix .. values[2]:format(""))
            else
                if data[type] then
                    if #vim.tbl_values(data[type]) == 1 then
                        table.insert(result, prefix .. values[2]:format(data[type][1]))
                    else
                        for _, value in ipairs(data[type]) do
                            table.insert(result, prefix .. values[2]:format(value))
                        end
                    end
                end
            end
        end

        return result
    end

    return start_row, start_column, parse_generated_template()
end
