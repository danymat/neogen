local ok, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
assert(ok, "neogen requires nvim-treesitter to operate :(")

local conf = require("neogen.config").get()
local granulator = require("neogen.granulator")
local helpers = require("neogen.utilities.helpers")
local notify = helpers.notify

local mark = require("neogen.mark")
local nodes = require("neogen.utilities.nodes")
local default_locator = require("neogen.locators.default")

local function get_parent_node(filetype, typ, language)
    local parser = vim.treesitter.get_parser(0, filetype)
    local tstree = parser:parse()[1]
    local tree = tstree:root()

    language.locator = language.locator or default_locator
    -- Use the language locator to locate one of the required parent nodes above the cursor
    return language.locator({root = tree, current = ts_utils.get_node_at_cursor(0)}, language.parent[typ])
end

---Generates the prefix according to `template` options.
---Prefix is generated with an offset (currently spaces) repetition of `n` times.
---If `template.use_default_comment` is not set to false, the `commentstring` is added
---@param template table
---@param commentstring string
---@param n integer
---@return string
local function prefix_generator(template, commentstring, n)
    local prefix = (" "):rep(n)

    -- Do not append the comment string if not wanted
    if template.use_default_comment ~= false then
        prefix = prefix .. commentstring
    end
    return prefix
end

local function get_place_pos(parent, position, append, typ)
    local row, col
    -- You can use a custom position placement
    if position and type(position) == "function" then
        row, col = position(parent, typ)
    end

    -- If the custom placement does not return the correct row and cols, default to the node range
    -- Same if there is no custom placement
    if not row and not col then
        -- Because the file type is always at top
        if typ == "file" then
            row, col = 0, 0
        else
            row, col = ts_utils.get_node_range(parent)
        end
    end

    append = append or {}

    if append.position == "after" and not vim.tbl_contains(append.disabled or {}, typ) then
        local child_node = nodes:matching_child_nodes(parent, append.child_name)[1]
        if not child_node and append.fallback then
            local fallback = nodes:matching_child_nodes(parent, append.fallback)[1]
            if fallback then
                row, col = fallback:range()
            end
        else
            row, col = child_node:range()
        end
    end

    return row, col
end

---Uses the provided template to format the annotations with data found by the granulator
---@param parent userdata the node used to generate the annotations
---@param data table the data from the granulator, which is a set of [type] = results
---@param template table a template from the configuration
---@param jump_text string jump_text from the default or language configuration
---@param required_type string
---@return table { line, content }, with line being the line to append the content
local function generate_content(parent, data, template, required_type, jump_text)
    local row, col = get_place_pos(parent, template.position, template.append, required_type)

    local commentstring = vim.trim(vim.bo.commentstring:format(""))
    local generated_template = template[template.annotation_convention]

    local result = {}
    local prefix = prefix_generator(template, commentstring, col)

    local function append_str(str)
        table.insert(result, str == "" and str or prefix .. str)
    end

    for _, values in ipairs(generated_template) do
        local inserted_type, formatted_str, opts = unpack(values)
        opts = opts or {}
        if type(opts.type) ~= "table" or vim.tbl_contains(opts.type, required_type) then
            -- Will append the item before all their nodes
            if type(opts.before_first_item) == "table" and data[inserted_type] then
                for _, s in ipairs(opts.before_first_item) do
                    append_str(s)
                end
            end

            local ins_type = type(inserted_type)
            if ins_type == "nil" then
                local no_data = vim.tbl_isempty(data)
                if opts.no_results then
                    if no_data then
                        append_str(formatted_str)
                    end
                elseif not no_data then
                    append_str(formatted_str:format(""))
                end
            elseif ins_type == "string" and type(data[inserted_type]) == "table" then
                -- Format the output with the corresponding data
                for _, s in ipairs(data[inserted_type]) do
                    append_str(formatted_str:format(s))
                    if opts.after_each then
                        append_str(opts.after_each:format(s))
                    end
                end
            elseif ins_type == "table" and #inserted_type > 0 and type(data[opts.required]) == "table" then
                -- First item in the template item can be a table.
                -- in this case, the template will use provided types to generate the line.
                -- e.g {{ "type", "parameter"}, "* @type {%s} %s"}
                -- will replace every %s with the provided data from those types

                -- If one item is missing, it'll use the required option to iterate
                -- and will replace the missing item with default jump_text
                for _, extracted in pairs(data[opts.required]) do
                    local fmt_args = {}
                    for _, typ in ipairs(inserted_type) do
                        if extracted[typ] then
                            table.insert(fmt_args, extracted[typ][1])
                        else
                            table.insert(fmt_args, jump_text)
                        end
                    end
                    append_str(formatted_str:format(unpack(fmt_args)))
                    if opts.after_each then
                        append_str(opts.after_each:format(unpack(fmt_args)))
                    end
                end
            end
        end
    end

    return row, result
end

return setmetatable({}, {
    __call = function(_, filetype, typ)
        if filetype == "" then
            notify("No filetype detected", vim.log.levels.WARN)
            return
        end
        local language = conf.languages[filetype]
        if not language then
            notify("Language " .. filetype .. " not supported.", vim.log.levels.WARN)
            return
        end
        typ = (type(typ) ~= "string" or typ == "") and "func" or typ -- Default type
        local template = language.template
        if not language.parent[typ] or not language.data[typ] or not template or not template.annotation_convention then
            notify("Type `" .. typ .. "` not supported", vim.log.levels.WARN)
            return
        end

        local parent_node = get_parent_node(filetype, typ, language)
        if not parent_node then
            return
        end

        local data = granulator(parent_node, language.data[typ])

        local jump_text = language.jump_text or conf.jump_text

        -- Will try to generate the documentation from a template and the data found from the granulator
        local row, template_content = generate_content(parent_node, data, template, typ, jump_text)

        local content = {}
        local marks_pos = {}

        local input_after_comment = conf.input_after_comment

        local pattern = jump_text .. (input_after_comment and "[|%w]*" or "|?")
        for r, line in ipairs(template_content) do
            local last_col = 0
            local len = 1
            local sects = {}
            while true do
                local s, e = line:find(pattern, last_col + 1)
                if not s then
                    table.insert(sects, line:sub(last_col + 1, -1))
                    break
                end
                table.insert(sects, line:sub(last_col + 1, s - 1))
                if input_after_comment then
                    len = len + s - last_col - 1
                    table.insert(marks_pos, {row + r - 1, len - 1})
                end
                last_col = e
            end
            table.insert(content, table.concat(sects, ""))
        end

        -- Append content to row
        vim.api.nvim_buf_set_lines(0, row, row, true, content)

        if #marks_pos > 0 then
            -- start session of marks
            mark:start()
            for _, pos in ipairs(marks_pos) do
                mark:add_mark(pos)
            end
            vim.cmd("startinsert")
            mark:jump()
        end
    end
})

