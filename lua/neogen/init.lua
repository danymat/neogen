local ok, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
assert(ok, "neogen requires nvim-treesitter to operate :(")

--- Table of contents:
---@toc
---@text

--- What is Neogen ?
---
--- # Abstract~
---
--- Neogen is an extensible and extremely configurable annotation generator for your favorite languages
---
--- Want to know what the supported languages are ?
--- Check out the up-to-date readme section: https://github.com/danymat/neogen#supported-languages
---
--- # Concept~
---
--- - Create annotations with one keybind, and jump your cursor in the inserted annotation
--- - Defaults for multiple languages and annotation conventions
--- - Extremely customizable and extensible
--- - Written in lua (and uses Tree-sitter)
---@tag neogen
---@toc_entry Neogen's purpose

-- Requires ===================================================================

local neogen = {}

local helpers = require("neogen.utilities.helpers")
local notify = helpers.notify

local cursor = require("neogen.utilities.cursor")

local default_locator = require("neogen.locators.default")
local default_granulator = require("neogen.granulators.default")
local default_generator = require("neogen.generators.default")

local autocmd = require("neogen.utilities.autocmd")

-- Module definition ==========================================================

--- Module setup
---
---@param opts table Config table (see |neogen.configuration|)
---
---@usage `require('neogen').setup({})` (replace `{}` with your `config` table)
---@toc_entry The setup function
neogen.setup = function(opts)
    -- Stores the user configuration globally so that we keep his configs when switching languages
    neogen.user_configuration = opts or {}

    neogen.configuration = vim.tbl_deep_extend("keep", neogen.user_configuration, neogen.configuration)

    if neogen.configuration.enabled == true then
        neogen.generate_command()
    end

    -- Export module
    _G.neogen = neogen

    -- Force configuring current language again when doing `setup` call.
    helpers.switch_language()
end

--- Neogen Usage
---
--- Neogen will use Treesitter parsing to properly generate annotations.
---
--- The basic idea is that Neogen will generate annotation to the type you're in.
--- For example, if you have a csharp function like (note the cursor position):
---
--- >
---  public class HelloWorld
---  {
---      public static void Main(string[] args)
---      {
---          # CURSOR HERE
---          Console.WriteLine("Hello world!");
---          return true;
---      }
---
---      public int someMethod(string str, ref int nm, void* ptr) { return 1; }
---
---  }
--- <
---
--- and you call `:Neogen class`, it will generate the annotation for the upper class:
---
--- >
---  /// <summary>
---  /// ...
---  /// </summary>
---  public class HelloWorld
---  {
--- <
---
--- Currently supported types are `func`, `class`, `type`, `file`.
--- Check out the up-to-date readme section: https://github.com/danymat/neogen#supported-languages
--- To know the supported types for a certain language
---
--- NOTE: calling `:Neogen` without any type is the same as `:Neogen func`
---@tag neogen-usage
---@toc_entry Usage

--- # Basic configurations~
---
--- Neogen provides those defaults, and you can change them to suit your needs
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
---@test # Notes~
---
--- - to configure a language, just add your configurations in the `languages` table
---   For example, for the `lua` lang:
---   >
---    languages = {
---      lua = { -- Configuration here }
---    }
---   <
---
--- - `jump_text` is widely used and will certainly break most language templates.
---   I'm thinking of removing it from defaults so that it can't be modified
---@toc_entry Configure the setup
---@tag neogen-configuration
neogen.configuration = {
    -- Enables Neogen capabilities
    enabled = true,

    -- Go to annotation after insertion, and change to insert mode
    input_after_comment = true,

    -- Symbol to find for jumping cursor in template
    jump_text = "$1",

    -- Configuration for default languages
    languages = {},
}
--minidoc_afterlines_end

-- Basic API ===================================================================

--- The only function required to use Neogen.
---
--- It'll try to find the first parent that matches a certain type.
--- For example, if you are inside a function, and called `generate({ type = "func" })`,
--- Neogen will go until the start of the function and start annotating for you.
---
---@param opts table Options to change default behaviour of generation.
---  - {opts.type} `(string?, default: "func")` Which type we are trying to use for generating annotations.
---    Currently supported: `func`, `class`, `type`, `file`
---@toc_entry Generate annotations
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

    language.locator = language.locator or default_locator
    language.granulator = language.granulator or default_granulator
    language.generator = language.generator or default_generator

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
            cursor.del_extmarks() -- Delete previous extmarks before setting any new ones

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
                cursor.create(to_place + 1, start_column)
                -- Creates extmarks for the content
                for i, value in pairs(content_with_marks) do
                    local start = 0
                    local count = 0
                    while true do
                        start = string.find(value, jump_text, start + 1)
                        if not start then
                            break
                        end
                        cursor.create(to_place + i, start - count * #jump_text)
                        count = count + 1
                    end
                end

                -- Create extmark to jump back to current location
                local pos = vim.api.nvim_win_get_cursor(0)
                local col = pos[2] + 2

                -- If the line we are in is empty, it will throw an error out of bounds.
                if vim.api.nvim_get_current_line() == "" then
                    col = pos[2] + 1
                end

                cursor.create(pos[1], col)

                -- Creates extmark for the end of the content
                cursor.create(to_place + #content + 1, 0)

                cursor.jump({ first_time = true })
            end
        end
    end
end

-- Expose more API  ============================================================

-- Expose match_commands for `:Neogen` completion
neogen.match_commands = helpers.match_commands

-- Required for use with completion engine =====================================

--- Jumps to the next cursor template position
---@private
function neogen.jump_next()
    if neogen.jumpable() then
        cursor.jump()
    end
end

--- Jumps to the next cursor template position
---@private
function neogen.jump_prev()
    if cursor.jumpable(-1) then
        cursor.jump_prev()
    end
end

--- Checks if the cursor can jump backwards or forwards
--- @param reverse number? if `-1`, will try to see if can be jumped backwards
---@private
function neogen.jumpable(reverse)
    return cursor.jumpable(reverse)
end

-- Command and autocommands ====================================================

--- Generates the `:Neogen` command, which calls `neogen.generate()`
---@private
function neogen.generate_command()
    vim.api.nvim_command(
        'command! -nargs=? -complete=customlist,v:lua.neogen.match_commands -range -bar Neogen lua require("neogen").generate({ type = <q-args>})'
    )
end

autocmd.subscribe("BufEnter", function()
    helpers.switch_language()
end)

vim.cmd([[
  augroup ___neogen___
    autocmd!
    autocmd BufEnter * lua require'neogen.utilities.autocmd'.emit('BufEnter')
  augroup END
]])

--- Contribute to Neogen
---
--- *   Want to add a new language?
---     1.  Using the defaults to generate a new language support:
---         https://github.com/danymat/neogen/blob/main/docs/adding-languages.md
---     2.  (advanced) Only if the defaults aren't enough, please see here:
---         https://github.com/danymat/neogen/blob/main/docs/advanced-integration.md
--- *   Want to contribute to an existing language?
---     I guess you can still read the previous links, as they have some valuable knowledge inside.
---     You can go and directly open/edit the configuration file relative to the language you want to contribute to.
---
--- Feel free to submit a PR, I will be happy to help you !
---@tag neogen-develop
---@toc_entry Contributing

return neogen
