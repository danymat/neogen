local notify = require("neogen.utilities.helpers").notify
local conf = require("neogen.config").get()

---
--- To use a snippet engine, pass the option into neogen setup:
--- >
---  require('neogen').setup({
---    snippet_engine = "luasnip",
---    ...
---  })
--- <
--- Some snippet engines come out of the box bundled with neogen:
--- - `"luasnip"` (https://github.com/L3MON4D3/LuaSnip)
--- - `"snippy"` (https://github.com/dcampos/nvim-snippy)
--- - `"vsnip"` (https://github.com/hrsh7th/vim-vsnip)
--- - `"nvim"` (`:h vim.snippet`)
--- - `"mini"` (https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-snippets.md)
---
--- If you want to customize the placeholders, you can use `placeholders_text` option:
--- >
---  require('neogen').setup({
---    placeholders_text = {
---      ['description'] = "[description]",
---    }
---  })
--- <
---
--- # Add support for snippet engines~
---
--- To add support to a snippet engine, go to `lua/neogen/snippet.lua`.
--- There's a table called `snippet.engines` that holds functions that will be called
--- depending of the snippet engine
---
--- Those functions have this signature:
--- `snippet_engine_name = function (snip, pos)` where
--- - `snip` is a lsp styled snippet (in table format)
--- - `pos` is a { row , col } table for placing the snippet
---@tag neogen-snippet-integration
---@toc_entry Use popular snippet engines
local snippet = {}
snippet.engines = {}

--- Converts a template to a lsp-compatible snippet
---@param template string[] the generated annotations to parse
---@param marks table generated marks for the annotations
---@param pos table a tuple of row,col
---@return table resulting snippet lines
---@private
snippet.to_snippet = function(template, marks, pos)
    local offset, ph = {}, {}

    -- Add double $ for template before creating the snippet so that text with $ (such as parameters in php)
    -- are not interpreted as snippet
    for i, str in ipairs(template) do
        template[i] = str:gsub("%$", "$$") -- Escape $
    end

    for i, m in ipairs(marks) do
        local r, col = m.row - pos[1] + 1, m.col
        ph[i] = (m.text and conf.enable_placeholders) and string.format("${%d:%s}", i, m.text) or "$" .. i
        if offset[r] then
            offset[r] = offset[r] + ph[i - 1]:len() + 1
        else
            offset[r] = 0
        end
        local pre = template[r]:sub(1, col + offset[r])
        template[r] = pre .. ph[i] .. template[r]:sub(col + 1 + offset[r])
    end
    return template
end

--- Expand snippet for luasnip engine
---@param snip string the snippet to expand
---@param pos table a tuple of row, col
---@private
snippet.engines.luasnip = function(snip, pos)
    local ok, ls = pcall(require, "luasnip")
    if not ok then
        notify("Luasnip not found, aborting...", vim.log.levels.ERROR)
        return
    end

    local types = require("luasnip.util.types")

    -- Append a new line to create the snippet
    vim.fn.append(pos[1], "")

    -- Convert the snippet to string
    local _snip = table.concat(snip, "\n")

    ls.snip_expand(

        ls.s("", ls.parser.parse_snippet(nil, _snip, { trim_empty = false, dedent = false }), {

            child_ext_opts = {
                -- for highlighting the placeholders
                [types.insertNode] = {
                    -- when outside placeholder, but in snippet
                    passive = { hl_group = conf.placeholders_hl },
                },
            },
            -- prevent mixing styles
            merge_child_ext_opts = true,
        }),
        { pos = pos }
    )
end

--- Expand snippet for snippy engine
---@param snip string the snippet to expand
---@param pos table a tuple of row, col
---@private
snippet.engines.snippy = function(snip, pos)
    local ok, snippy = pcall(require, "snippy")
    if not ok then
        notify("Snippy not found, aborting...", vim.log.levels.ERROR)
        return
    end
    local row, _ = unpack(pos)
    vim.api.nvim_buf_set_lines(0, row, row, true, { "" }) -- snippy will change `row`
    vim.api.nvim_win_set_cursor(0, { row + 1, 0 })        -- `snip` already has indent so we should ignore `col`
    snippy.expand_snippet({ body = snip })
end

--- Expand snippet for vsnip engine
---@param snip string the snippet to expand
---@param pos table a tuple of row, col
---@private
snippet.engines.vsnip = function(snip, pos)
    local ok = vim.g.loaded_vsnip
    if not ok then
        notify("Vsnip not found, aborting...", vim.log.levels.ERROR)
        return
    end
    local row, _ = unpack(pos)
    vim.api.nvim_buf_set_lines(0, row, row, true, { "" }) -- vsnip will change `row`
    vim.api.nvim_win_set_cursor(0, { row + 1, 0 })        -- `snip` already has indent so we should ignore `col`
    snip = table.concat(snip, "\n")                       -- vsnip expects on string instead of a list/table of lines
    vim.fn["vsnip#anonymous"](snip)
end

--- Expand snippet for vim.snippet engine
---@param snip string the snippet to expand
---@param pos table a tuple of row, col
---@private
snippet.engines.nvim = function(snip, pos)
    local row, _ = unpack(pos)
    vim.api.nvim_buf_set_lines(0, row, row, true, { "" })
    vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
    snip = table.concat(snip, "\n")
    vim.snippet.expand(snip)
end

--- Expand snippet for mini.snippets engine
---@param snip string the snippet to expand
---@param pos table a tuple of row, col
---@private
snippet.engines.mini = function(snip, pos)
    -- Check `MiniSnippets` is set up by the user
    if _G.MiniSnippets == nil then
        notify("'mini.snippets' is not set up, aborting...", vim.log.levels.ERROR)
        return
    end

    local row = pos[1]
    vim.api.nvim_buf_set_lines(0, row, row, true, { "" })
    vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
    -- Use user configured `insert` method but fall back to default
    local insert = MiniSnippets.config.expand.insert or MiniSnippets.default_insert
    insert({ body = snip })
end

return snippet
