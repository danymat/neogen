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
    local offset = {}
    for i, m in ipairs(marks) do
        local r, col = m[1] - pos[1] + 1, m[2]
        if offset[r] then
            offset[r] = offset[r] + tostring(i - 1):len() + 1
        else
            offset[r] = 0
        end
        local pre = template[r]:sub(1, col + offset[r])
        template[r] = pre .. "$" .. i .. template[r]:sub(col + 1 + offset[r])
    end
    local indent = template[1]:find('%S')
    if indent > 1 then
        for i, ln in ipairs(template) do
            template[i] = ln:sub(indent)
        end
    end
    return template, indent - 1
end

--- Expand snippet for luasnip engine
---@param snip string the snippet to expand
---@param pos table a tuple of row, col
---@private
snippet.engines.luasnip = function(snip, pos, indent)
    local ok, luasnip = pcall(require, "luasnip")
    if not ok then
        notify("Luasnip not found, aborting...", vim.log.levels.ERROR)
        return
    end
    vim.fn.append(pos[1], string.rep(vim.bo.expandtab and ' ' or '\t', indent))
    luasnip.lsp_expand(table.concat(snip, "\n"), { pos = { pos[1], pos[2] + indent } })
end

return snippet
