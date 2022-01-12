local ok, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
assert(ok, "neogen requires nvim-treesitter to operate :(")

---@diagnostic disable-next-line: lowercase-global
neogen = {}

-- Require utilities
neogen.utilities = {}
require("neogen.utilities.extractors")
require("neogen.utilities.nodes")
require("neogen.utilities.cursor")
require("neogen.utilities.helpers")

-- Require defaults
require("neogen.locators.default")
require("neogen.granulators.default")
require("neogen.generators.default")

local notify = neogen.utilities.helpers.notify

neogen.generate = function(opts)
    opts = opts or {}
    opts.type = (opts.type == nil or opts.type == "") and "func" or opts.type -- Default type

    if not neogen.configuration.enabled then
        notify("Neogen not enabled. Please enable it.", vim.log.levels.WARN)
        return
    end

    if vim.bo.filetype == "" then
        notify("No filetype detected", vim.log.levels.WARN)
        return
    end

    local parser = vim.treesitter.get_parser(0, vim.bo.filetype)
    local tstree = parser:parse()[1]
    local tree = tstree:root()

    local language = neogen.configuration.languages[vim.bo.filetype]

    if not language then
        notify("Language " .. vim.bo.filetype .. " not supported.", vim.log.levels.WARN)
        return
    end

    language.locator = language.locator or neogen.default_locator
    language.granulator = language.granulator or neogen.default_granulator
    language.generator = language.generator or neogen.default_generator

    if not language.parent[opts.type] or not language.data[opts.type] then
        notify("Type `" .. opts.type .. "` not supported", vim.log.levels.WARN)
        return
    end

    -- Use the language locator to locate one of the required parent nodes above the cursor
    local located_parent_node = language.locator({
        root = tree,
        current = ts_utils.get_node_at_cursor(0),
    }, language.parent[opts.type])

    if not located_parent_node then
        return
    end

    -- Use the language granulator to get the required content inside the node found with the locator
    local data = language.granulator(located_parent_node, language.data[opts.type])

    if data then
        -- Will try to generate the documentation from a template and the data found from the granulator
        local to_place, start_column, content = language.generator(
            located_parent_node,
            data,
            language.template,
            opts.type
        )

        if #content ~= 0 then
            neogen.utilities.cursor.del_extmarks() -- Delete previous extmarks before setting any new ones

            local jump_text = language.jump_text or neogen.configuration.jump_text

            --- Removes jump_text marks and keep the second part of jump_text|other_text if there is one (which is other_text)
            local delete_marks = function(v)
                local pattern = jump_text .. "[|%w]+"
                local matched = string.match(v, pattern)

                if matched then
                    local split = vim.split(matched, "|", true)
                    if #split == 2 and neogen.configuration.input_after_comment == false then
                        return string.gsub(v, jump_text .. "|", "")
                    end
                else
                    return string.gsub(v, jump_text, "")
                end

                return string.gsub(v, pattern, "")
            end

            local content_with_marks = vim.deepcopy(content)

            -- delete all jump_text marks
            content = vim.tbl_map(delete_marks, content)

            -- Append the annotation in required place
            vim.fn.append(to_place, content)

            -- Place cursor after annotations and start editing
            -- First and last extmarks are needed to know the range of inserted content
            if neogen.configuration.input_after_comment == true then
                -- Creates extmark for the beggining of the content
                neogen.utilities.cursor.create(to_place + 1, start_column)
                -- Creates extmarks for the content
                for i, value in pairs(content_with_marks) do
                    local start = 0
                    local count = 0
                    while true do
                        start = string.find(value, jump_text, start + 1)
                        if not start then
                            break
                        end
                        neogen.utilities.cursor.create(to_place + i, start - count * #jump_text)
                        count = count + 1
                    end
                end

                -- Create extmark to jump back to current location
                local pos = vim.api.nvim_win_get_cursor(0)
                neogen.utilities.cursor.create(pos[1], pos[2] + 2)

                -- Creates extmark for the end of the content
                neogen.utilities.cursor.create(to_place + #content + 1, 0)

                neogen.utilities.cursor.jump({ first_time = true })
            end
        end
    end
end

function neogen.jump_next()
    neogen.utilities.cursor.jump()
end

function neogen.jump_prev()
    neogen.utilities.cursor.jump_prev()
end

function neogen.jumpable(reverse)
    return neogen.utilities.cursor.jumpable(reverse)
end

function neogen.match_commands()
    if vim.bo.filetype == "" then
        return {}
    end

    local language = neogen.configuration.languages[vim.bo.filetype]

    if not language or not language.parent then
        return {}
    end

    return vim.tbl_keys(language.parent)
end

function neogen.generate_command()
    vim.api.nvim_command(
        'command! -nargs=? -complete=customlist,v:lua.neogen.match_commands -range -bar Neogen lua require("neogen").generate({ type = <q-args>})'
    )
end

neogen.setup = function(opts)
    neogen.configuration = vim.tbl_deep_extend("keep", opts or {}, {
        input_after_comment = true, -- bool, If you want to jump with the cursor after annotation
        jump_text = "$1", -- symbol to find for jumping cursor in template
        -- DEFAULT CONFIGURATION
        languages = {
            lua = require("neogen.configurations.lua"),
            python = require("neogen.configurations.python"),
            javascript = require("neogen.configurations.javascript"),
            typescript = require("neogen.configurations.typescript"),
            c = require("neogen.configurations.c").c_config,
            cpp = require("neogen.configurations.c").cpp_config,
            go = require("neogen.configurations.go"),
            java = require("neogen.configurations.java"),
            rust = require("neogen.configurations.rust"),
            cs = require("neogen.configurations.csharp"),
            php = require("neogen.configurations.php"),
        },
    })

    if neogen.configuration.enabled == true then
        neogen.generate_command()
    end
end

return neogen
