local ts_utils = require("nvim-treesitter.ts_utils")

local M = {}

M.generate = function ()
    local comment = {}
    local query = [[ 
    (function (parameters) @params)
    (function (return_statement) @return)
    (function_definition (parameters) @params)
    (function_definition (if_statement (return_statement) @return))
    ]]

    -- Try to find the upper function
    local cursor = ts_utils.get_node_at_cursor(0)
    local function_node = cursor
    while function_node ~= nil do
        if function_node:type() == "function_definition" then break end
        if function_node:type() == "function" then break end
        function_node = function_node:parent()
    end
    local line = ts_utils.get_node_range(function_node)

    -- find the starting position in the line function
    local line_content = vim.api.nvim_buf_get_lines(0, line, line+1, false)[1]
    local offset = line_content:match("^%s+") or ""

    local return_comment = offset .. "---@return "
    local param_comment = offset .. "---@param "

    -- Parse and iterate over each found query
    local returned = vim.treesitter.parse_query("lua", query)
    for id, node in returned:iter_captures(function_node) do

        -- Try to add params
        if returned.captures[id] == "params" then 
            local params = ts_utils.get_node_text(node)[1]:sub(2,-2)
            for p in string.gmatch(params, '[^,]+') do
                p = p:gsub("%s+", "") -- remove trailing spaces
                table.insert(comment, param_comment .. p .. " ")
            end
        end

        -- Try to add return statement
        if returned.captures[id] == "return" then
            table.insert(comment, return_comment)
        end
    end

    -- At the end, add description annotation
    table.insert(comment, 1, offset .. "---")

    if #comment == 0 then return end

    -- Write on top of function
    vim.fn.append(line, comment)
    vim.fn.cursor(line+1, #comment[1])
    vim.api.nvim_command('startinsert!')
end

function M.generate_command()
    vim.api.nvim_command('command! -range -bar Neogen lua require("neogen").generate()')
end

M.setup = function(opts)
    local config = opts or {}
    if config.enabled == true then
        M.generate_command()
    end
end

return M
