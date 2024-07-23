local textmate = require("tests.utils.textmate")
local neogen = require("neogen")

local M = {}

--- Make a docstring for given language and return the `neogen` result.
---@param source string Pseudo-source-code to call. It contains `"|cursor|"` which is the expected user position.
---@param filetype string Buffer filetype.
---@param neogen_opts table? Custom Neogen opts passed during generate command.
---@return string? # The same source code, after calling neogen.
function M.make_docstring(source, filetype, neogen_opts)
    local result = textmate.extract_cursors(source)

    if not result then
        vim.notify(
            string.format("Source\n\n%s\n\nwas not parsable. Does it have a |cursor| defined?", source),
            vim.log.levels.ERROR
        )

        return nil
    end

    local cursors, code = unpack(result)

    local buffer = vim.api.nvim_create_buf(true, true)
    vim.bo[buffer].filetype = filetype
    vim.cmd.buffer(buffer)
    local window = vim.fn.win_getid() -- We just created the buffer so the current window works

    local strict_indexing = false
    vim.api.nvim_buf_set_lines(buffer, 0, -1, strict_indexing, vim.fn.split(code, "\n"))

    -- IMPORTANT: Because we are adding docstrings in the buffer, we must start
    -- from the bottom docstring up. Otherwise the row/column positions of the
    -- next `cursor` in `cursors` will be out of date.
    for index = #cursors, 1, -1 do
        local cursor = cursors[index]
        vim.api.nvim_win_set_cursor(window, cursor)

        neogen_opts = vim.tbl_deep_extend("force", { snippet_engine = "nvim" }, neogen_opts or {})
        neogen.generate(neogen_opts)
    end

    return table.concat(vim.api.nvim_buf_get_lines(buffer, 0, -1, strict_indexing), "\n")
end

return M
