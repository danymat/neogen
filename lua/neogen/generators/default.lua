local ts_utils = require("nvim-treesitter.ts_utils")

--- Generates the prefix according to `template` options.
--- Prefix is generated with an offset (currently spaces) repetition of `n` times.
--- If `template.use_default_comment` is not set to false, the `commentstring` is added
--- @param template table
--- @param commentstring string
--- @param n integer
--- @return string
local function prefix_generator(template, commentstring, n)
    local prefix = (" "):rep(n)

    -- Do not append the comment string if not wanted
    if template.use_default_comment ~= false then
        prefix = prefix .. commentstring
    end
    return prefix
end

--- Does some checks within the `value` and adds the `prefix` before it if required
--- @param prefix string
--- @param value string
--- @return string
local function conditional_prefix_inserter(prefix, value)
    if value == "" then
        return value
    else
        return prefix .. value
    end
end

--- Insert values from `items` in `result` and returns it
--- @param result table
--- @param items table
--- @param prefix string
--- @return table result
local function add_values_to_result(result, items, prefix)
    for _, value in ipairs(items) do
        local inserted = conditional_prefix_inserter(prefix, value)
        table.insert(result, inserted)
    end
    return result
end

---Default Generator:
---Uses the provided template to format the annotations with data found by the granulator
--- @param parent userdata the node used to generate the annotations
--- @param data table the data from the granulator, which is a set of [type] = results
--- @param template table a template from the configuration
--- @param type string
--- @return table { line, content, opts }, with line being the line to append the content
neogen.default_generator = function(parent, data, template, required_type)
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
        local prefix = prefix_generator(template, commentstring, col_to_place)

        for _, values in ipairs(generated_template) do
            local type = values[1]
            local formatted_string = values[2]
            local opts = values[3] or {
                type = { required_type }
            }

            -- Will append the item before all their nodes
            if opts.before_first_item and data[type] then
                result = add_values_to_result(result, opts.before_first_item, prefix)
            end

            if opts.type and vim.tbl_contains(opts.type, required_type) then
                -- If there is no data returned, will append the string with opts.no_results
                if opts.no_results == true and vim.tbl_isempty(data) then
                    local inserted = conditional_prefix_inserter(prefix, formatted_string)
                    table.insert(result, inserted)
                else
                    -- append the output as is
                    if type == nil and opts.no_results ~= true and not vim.tbl_isempty(data) then
                        local inserted = conditional_prefix_inserter(prefix, formatted_string:format(""))
                        table.insert(result, inserted)
                    else
                        -- Format the output with the corresponding data
                        if data[type] then
                            for _, value in ipairs(data[type]) do
                                local inserted = conditional_prefix_inserter(prefix, formatted_string:format(value))
                                table.insert(result, inserted)
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
