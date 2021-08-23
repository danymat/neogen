local ts_utils = require("nvim-treesitter.ts_utils")

---Default Generator:
---Uses the provided template to format the annotations with data found by the granulator
--- @param parent userdata the node used to generate the annotations
--- @param data table the data from the granulator, which is a set of [type] = results
--- @param template table a template from the configuration
--- There are some special fields it can take:
--- @return table { line, content }, with line being the line to append the content
neogen.default_generator = function(parent, data, template)
    local start_row, start_column, end_row, end_column = ts_utils.get_node_range(parent)
    P(ts_utils.get_node_range(parent))
    local commentstring, generated_template = vim.trim(vim.api.nvim_buf_get_option(0, "commentstring"):format(""))

    local row_to_place = start_row
    local col_to_place = start_column

    local append = template.append or {}

    if append.position == "after" then
        local child_node = neogen.utilities.nodes:first_child_node(parent, append.child_name)
        if child_node ~= nil then
            row_to_place, col_to_place, _ , _ = child_node:range()
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

            -- Checks for custom options
            -- Supported options:
            --   - before_first_item = value
            local opts = values[3] or {}

            -- Will append the item before all their nodes
            if opts.before_first_item then
                table.insert(result, prefix .. opts.before_first_item)
            end

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

    return row_to_place, col_to_place, parse_generated_template()
end
