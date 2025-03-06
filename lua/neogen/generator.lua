local helpers = require("neogen.utilities.helpers")
local notify = helpers.notify

local conf = require("neogen.config").get()
local granulator = require("neogen.granulator")

local mark = require("neogen.mark")
local nodes = require("neogen.utilities.nodes")
local default_locator = require("neogen.locators.default")
local snippet = require("neogen.snippet")
local JUMP_TEXT = "$1"
local ANY_TYPE = "any"
local all_types_map, reverse_type_map, populated_filetypes = {}, {}, {}

local function todo_text(type)
    local i = require("neogen.types.template").item
    local todo = conf.placeholders_text
    return ({
        [i.Tparam] = todo["tparam"],
        [i.Parameter] = todo["parameter"],
        [i.Return] = todo["return"],
        [i.Yield] = todo["yield"],
        [i.ReturnTypeHint] = todo["return"],
        [i.ReturnAnonym] = todo["return"],
        [i.ClassName] = todo["class"],
        [i.Throw] = todo["throw"],
        [i.Vararg] = todo["varargs"],
        [i.Type] = todo["type"],
        [i.ClassAttribute] = todo["attribute"],
        [i.HasParameter] = todo["parameter"],
        [i.HasReturn] = todo["return"],
        [i.HasThrow] = todo["throw"],
        [i.HasYield] = todo["yield"],
        [i.ArbitraryArgs] = todo["args"],
        [i.Kwargs] = todo["kwargs"],
    })[type] or todo["description"]
end

--- Create per filetype table of node types
---@param filetype string
---@param language any
local function populate_filetype(filetype, language)
    for lang_type, set in pairs(language.parent) do
        if all_types_map[filetype] == nil then
            all_types_map[filetype] = {}
        end

        if reverse_type_map[filetype] == nil then
            reverse_type_map[filetype] = {}
        end

        for _, v in ipairs(set) do
            table.insert(all_types_map[filetype], v)
            reverse_type_map[filetype][v] = lang_type
        end
    end
end

-- Get nearest parent node
local function get_parent_node(filetype, node_type, language)
    local parser_name = vim.treesitter.language.get_lang(filetype)
    local parser = vim.treesitter.get_parser(0, parser_name)
    local tstree = parser:parse()[1]
    local tree = tstree:root()
    local current_node = vim.treesitter.get_node({ ignore_injections = false })
    local match_any = node_type == ANY_TYPE
    local target_node, target_type
    local locator = language.locator or default_locator

    -- Get a node. `type` could be a string or table
    local function get_node(type)
        return locator({
            root = tree,
            current = current_node,
        }, type)
    end

    if match_any then
        -- Populate node types for filetype if not already
        if populated_filetypes[filetype] == nil then
            populate_filetype(filetype, language)
            populated_filetypes[filetype] = true
        end

        target_node = get_node(all_types_map[filetype])

        -- Lookup node type from a map since type names slightly differ
        target_type = target_node and reverse_type_map[filetype][target_node:type()]
    else
        target_node = get_node(language.parent[node_type])
        target_type = node_type
    end

    return target_node, target_type
end

--- Generates the prefix according to `template` options.
--- Prefix is generated with an offset (currently spaces) repetition of `n` times.
--- If `template.use_default_comment` is not set to false, the `commentstring` is added
---@param template table
---@param commentstring string
---@param n integer
---@return string
local function prefix_generator(template, commentstring, n)
    local prefix = (vim.bo.expandtab and " " or "\t"):rep(n)

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
            row, col = vim.treesitter.get_node_range(parent)
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

--- Uses the provided template to format the annotations with data found by the granulator
---@param parent userdata the node used to generate the annotations
---@param data table the data from the granulator, which is a set of [type] = results
---@param template table a template from the configuration
---@param required_type string
---@param annotation_convention string
---@return table { line, content }, with line being the line to append the content
local function generate_content(parent, data, template, required_type, annotation_convention)
    local row, col = get_place_pos(parent, template.position, template.append, required_type)

    local commentstring = vim.trim(vim.bo.commentstring:format(""))
    annotation_convention = annotation_convention or template.annotation_convention
    local generated_template = template[annotation_convention]

    local result = {}
    local default_text = {}
    local prefix = prefix_generator(template, commentstring, col)

    local n = 0

    local function append_str(str, inserted_type)
        table.insert(result, str == "" and str or prefix .. str)
        local x -- placeholders in the same line after the first are 'descriptions'
        for _ in string.gmatch(str, "%$1") do
            n = n + 1
            default_text[n] = not x and todo_text(inserted_type) or todo_text()
            x = true
        end
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
                    append_str(formatted_str:format(s), inserted_type)
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
                -- and will replace the missing item with JUMP_TEXT
                for _, extracted in pairs(data[opts.required]) do
                    local fmt_args = {}
                    for _, typ in ipairs(inserted_type) do
                        if extracted[typ] then
                            table.insert(fmt_args, extracted[typ][1])
                        else
                            table.insert(fmt_args, JUMP_TEXT)
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

    return row, result, default_text
end

return setmetatable({}, {
    __call = function(_, filetype, node_type, return_snippet, annotation_convention)
        if filetype == "" then
            notify("No filetype detected", vim.log.levels.WARN)
            return
        end
        local language = conf.languages[filetype]
        if not language then
            notify("Language " .. filetype .. " not supported.", vim.log.levels.WARN)
            return
        end
        node_type = (type(node_type) ~= "string" or node_type == "") and ANY_TYPE or node_type -- Default type

        local template = language.template
        if not template or not template.annotation_convention then
            notify("Language " .. filetype .. " does not support any annotation convention", vim.log.levels.WARN)
            return
        end

        annotation_convention = annotation_convention or {}
        if annotation_convention[filetype] and not template[annotation_convention[filetype]] then
            notify(
                ("Annotation convention %s not supported for language %s"):format(
                    annotation_convention[filetype],
                    filetype
                ),
                vim.log.levels.WARN
            )
            return
        end

        if node_type ~= ANY_TYPE then
            if not language.parent[node_type] or not language.data[node_type] then
                notify("Type `" .. node_type .. "` not supported", vim.log.levels.WARN)
                return
            end
        end

        local parent_node, node_type = get_parent_node(filetype, node_type, language)
        if not parent_node then
            return
        end

        local data = granulator(parent_node, language.data[node_type])

        -- Will try to generate the documentation from a template and the data found from the granulator
        local row, template_content, default_text =
            generate_content(parent_node, data, template, node_type, annotation_convention[filetype])

        local content = {}
        local marks_pos = {}

        local input_after_comment = conf.input_after_comment

        local pattern = JUMP_TEXT .. (input_after_comment and "[|%w]*" or "|?")
        for r, line in ipairs(template_content) do
            local last_col = 0
            local len = 1

            -- Replace each JUMP_TEXT with an pending text
            local insert = string.gsub(line, pattern, "")
            table.insert(content, insert)

            -- Find each JUMP_TEXT and create a mark for it
            while true do
                local s, e = string.find(line, pattern, last_col + 1)
                if not s then
                    break
                end
                if input_after_comment then
                    len = len + s - last_col - 1
                    local m = { row = row + r - 1, col = len - 1 }
                    table.insert(marks_pos, m)
                    m.text = default_text[#marks_pos]
                end
                last_col = e
            end
        end

        if return_snippet then
            -- User just wants the snippet, so we give him the snippet plus placement informations
            local generated_snippet = snippet.to_snippet(content, marks_pos, { row, 0 })
            return generated_snippet, row
        end

        local snippet_engine = conf.snippet_engine
        if snippet_engine then
            -- User want to use a snippet engine instead of native handling
            local engines = snippet.engines
            if not vim.tbl_contains(vim.tbl_keys(engines), snippet_engine) then
                notify(string.format("Snippet engine '%s' not supported", snippet_engine), vim.log.levels.ERROR)
                return
            end

            -- Converts the content to a lsp compatible snippet
            local generated_snippet = snippet.to_snippet(content, marks_pos, { row, 0 })
            -- Calls the snippet expand function for required snippet engine
            engines[snippet_engine](generated_snippet, { row, 0 })
            return
        end

        -- We use default marks for jumping between annotations
        -- Append content to row
        vim.api.nvim_buf_set_lines(0, row, row, true, content)

        if #marks_pos > 0 then
            -- Start session of marks
            mark:start()
            for _, pos in ipairs(marks_pos) do
                mark:add_mark(pos)
            end
            vim.cmd("startinsert")
            mark:jump()
            -- Add range mark after first jump
            mark:add_range_mark({ row, 0, row + #template_content, 1 })
        end
    end,
})
