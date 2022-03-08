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
---
--- If you want to customize the placeholders, you can use `placeholders_text` option:
--- >
---  require('neogen').setup({
---    placeholders_text = {
---      ['description'] = "[description]",
---    }
---  })
--- <
---@tag snippet-integration
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
        ls.s("", ls.parser.parse_snippet(nil, _snip), {

            child_ext_opts = {
                -- for highlighting the placeholders
                [types.insertNode] = {
                    -- when inside placeholder
                    active = {
                        hl_group = "DiagnosticHint",
                    },
                    -- when outside placeholder, but in snippet
                    passive = {
                        hl_group = "DiagnosticHint",
                    },
                    -- when outside snippet
                    -- snippet_passive = {
                    --     hl_group = "Todo",
                    -- },
                },
            },
            -- prevent mixing styles
            merge_child_ext_opts = true,
        }),
        { pos = pos }
    )
end

return snippet
