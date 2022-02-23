local notify = require("neogen.utilities.helpers").notify

local snippet = {}
snippet.engines = {}

--- Converts a template to a lsp-compatible snippet
---@param template string[] the generated annotations to parse
---@param marks table generated marks for the annotations
---@param pos table a tuple of row,col
---@return string resulting snippet
snippet.to_snippet = function(template, marks, pos)
    for i, m in ipairs(marks) do
        local r, col = m[1] - pos[1] + 1, m[2]
        local pre = template[r]:sub(1, col)
        template[r] = pre .. "$" .. i .. template[r]:sub(col + 1)
    end
    return template
end

--- Expand snippet for luasnip engine
---@param snip string the snippet to expand
---@param pos table a tuple of row, col
snippet.engines.luasnip = function(snip, pos)
    local ok, luasnip = pcall(require, "luasnip")
    if not ok then
        notify("Luasnip not found, aborting...", vim.log.levels.ERROR)
        return
    end
    luasnip.lsp_expand("\n" .. table.concat(snip, "\n"), { pos = { pos[1] - 1, pos[2] } })
end

return snippet
