local ok, ts_utils = pcall(require, "nvim-treesitter.ts_utils")

assert(ok, "neogen requires nvim-treesitter to operate :(")

local neogen = {
    utility = {
        wrap = function(name, ...)
            local args = { ... }

            return function()
                name(table.unpack(args))
            end
        end,

        extract_children = function(_, name)
            return function(node)
                local result = {}
                local split = vim.split(name, "|", true)

                for child in node:iter_children() do
                    if vim.tbl_contains(split, child:type()) then
                        table.insert(result, ts_utils.get_node_text(child)[1])
                    end
                end

                return result
            end
        end,

        extract_children_from = function(self, name, nodes)
            return function(node)
                local result = {}

                for i, value in ipairs(nodes) do
                    local child_node = node:named_child(i - 1)

                    if value == "extract" then
                        return self:extract_children(name)(child_node)
                    else
                        return self:extract_children_from(name, value)(node)
                    end
                end

                return result
            end
        end,
    },

    default_locator = function(node_info, nodes_to_match)
        if vim.tbl_contains(nodes_to_match, node_info.current:type()) then
            return node_info.current
        end

        while node_info.current and not vim.tbl_contains(nodes_to_match, node_info.current:type()) do
            node_info.current = node_info.current:parent()
        end

        return node_info.current
    end,

    default_granulator = function(parent_node, node_data)
        local result = {}

        for parent_type, child_data in pairs(node_data) do
            local matches = vim.split(parent_type, "|", true)
            if vim.tbl_contains(matches, parent_node:type()) then
                for i, _ in pairs(node_data[parent_type]) do
                    local data = child_data[i]

                    local child_node = parent_node:named_child(tonumber(i) - 1)

                    if not child_node then
                        return
                    end

                    if child_node:type() == data.match or not data.match then
                        local extract = {}

                        if data.extract then
                            extract = data.extract(child_node)

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
                            extract = ts_utils.get_node_text(child_node)
                            result[data.type] = extract
                        end
                    end
                end
            end
        end

        return result
    end,

    default_generator = function(parent, data, template)
        local start_row, start_column, _, _ = ts_utils.get_node_range(parent)
        local commentstring, generated_template = vim.trim(vim.api.nvim_buf_get_option(0, "commentstring"):format(""))

        if not template then
            generated_template = {
                { nil, "" },
                { "name", " @Summary " },
                { "parameters", " @Param " },
                { "return", " @Return " },
            }
        elseif type(template) == "function" then
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

        return start_row, parse_generated_template()
    end,
}

-- TODO: Move code here
neogen.generate = function(searcher, generator) end

neogen.auto_generate = function(custom_template)
    vim.treesitter.get_parser(0):for_each_tree(function(tree, language_tree)
        local searcher = neogen.configuration.languages[language_tree:lang()]

        if searcher then
            searcher.locator = searcher.locator or neogen.default_locator
            searcher.granulator = searcher.granulator or neogen.default_granulator
            searcher.generator = searcher.generator or neogen.default_generator

            local located_parent_node = searcher.locator({
                root = tree:root(),
                current = ts_utils.get_node_at_cursor(0),
            }, searcher.parent)

            if not located_parent_node then
                return
            end

            local data = searcher.granulator(located_parent_node, searcher.data)

            if data and not vim.tbl_isempty(data) then
                local to_place, content = searcher.generator(
                    located_parent_node,
                    data,
                    custom_template or searcher.template
                )

                vim.fn.append(to_place, content)
            end
        end
    end)
end

function neogen.generate_command()
    vim.api.nvim_command('command! -range -bar Neogen lua require("neogen").auto_generate()')
end

neogen.setup = function(opts)
    neogen.configuration = vim.tbl_deep_extend("keep", opts or {}, {
        -- DEFAULT CONFIGURATION
        languages = {
            lua = {
                -- Search for these nodes
                parent = { "function", "local_function", "local_variable_declaration", "field" },

                -- Traverse down these nodes and extract the information as necessary
                data = {
                    ["function|local_function"] = {
                        ["2"] = {
                            match = "parameters",

                            extract = function(node)
                                local regular_params = neogen.utility:extract_children("identifier")(node)
                                local varargs = neogen.utility:extract_children("spread")(node)

                                return {
                                    parameters = regular_params,
                                    vararg = varargs,
                                }
                            end,
                        },
                    },
                    ["local_variable_declaration|field"] = {
                        ["2"] = {
                            match = "function_definition",

                            extract = function(node)
                                local regular_params = neogen.utility:extract_children_from("identifier", {
                                    [1] = "extract",
                                })(node)

                                local varargs = neogen.utility:extract_children_from("spread", {
                                    [1] = "extract",
                                })(node)

                                return {
                                    parameters = regular_params,
                                    vararg = varargs,
                                }
                            end,
                        },
                    },
                },

                -- Custom lua locator that escapes from comments
                locator = function(node_info, nodes_to_match)
                    -- We're dealing with a lua comment and we need to escape its grasp
                    if node_info.current:type() == "source" then
                        local start_row, _, _, _ = ts_utils.get_node_range(node_info.current)
                        vim.api.nvim_win_set_cursor(0, { start_row, 0 })
                        node_info.current = ts_utils.get_node_at_cursor()
                    end

                    return neogen.default_locator(node_info, nodes_to_match)
                end,

                -- Use default granulator and generator
                granulator = nil,
                generator = nil,

                template = {
                    { nil, "-" },
                    { "parameters", "-@param %s any" },
                    { "vararg", "-@vararg any" },
                },
            },
        },
    })

    neogen.generate_command()
end

return neogen
