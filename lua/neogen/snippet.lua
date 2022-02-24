local notify = require("neogen.utilities.helpers").notify

---
--- To use a snippet engine, just use neogen api, like this:
--- >
---  :lua require('neogen').generate({ snippet_engine = "luasnip" })
--- <
--- Some snippet engines come out of the box bundled with neogen:
--- - `"luasnip"` (https://github.com/L3MON4D3/LuaSnip)
---@tag snippet-integration
---@toc_entry Use popular snippet engines
local snippet = {}
snippet.engines = {}

--- Converts a template to a lsp-compatible snippet
---@param template string[] the generated annotations to parse
---@param marks table generated marks for the annotations
---@param pos table a tuple of row,col
---@return string resulting snippet
---@private
snippet.to_snippet = function(template, marks, pos)
    for i, m in ipairs(marks) do
        local r, col = m[1] - pos[1] + 1, m[2]
        local pre = template[r]:sub(1, col)
        template[r] = pre .. "$" .. i .. template[r]:sub(col + 1)
    end
    for i, ln in ipairs(template) do
      template[i] = ln:gsub('^%s*', '')
    end
    return template
end

--- Expand snippet for luasnip engine
---@param snip string the snippet to expand
---@param pos table a tuple of row, col
---@private
snippet.engines.luasnip = function(snip, pos)
    local ok, luasnip = pcall(require, "luasnip")
    if not ok then
        notify("Luasnip not found, aborting...", vim.log.levels.ERROR)
        return
    end
    local expanded_snip = "\n" .. table.concat(snip, "\n")
    luasnip.lsp_expand(expanded_snip, { pos = { pos[1] - 1, pos[2] } })
end

return snippet
