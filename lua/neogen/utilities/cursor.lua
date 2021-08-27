neogen.utilities.cursor = {}

local neogen_ns = vim.api.nvim_create_namespace("neogen")

neogen.utilities.cursor.create = function(line, col)
    return vim.api.nvim_buf_set_extmark(0, neogen_ns, line - 1, col - 1, {})
end

neogen.utilities.cursor.go_next_extmark = function()
    local extm_list = vim.api.nvim_buf_get_extmarks(0, neogen_ns, 0, -1, {})
    if #extm_list ~= 0 then
        vim.api.nvim_buf_del_extmark(0, neogen_ns, extm_list[1][1])
    end
    if #extm_list ~= 0 then
        vim.api.nvim_win_set_cursor(0, { extm_list[1][2] + 1, extm_list[1][3] + 1 })
        return
    end
end

neogen.utilities.cursor.go_next_extmark = function()
    local extm_list = vim.api.nvim_buf_get_extmarks(0, neogen_ns, 0, -1, {})
    if #extm_list ~= 0 then
        vim.api.nvim_buf_del_extmark(0, neogen_ns, extm_list[1][1])
        P("remaning marks", #extm_list - 1)
    end
    if #extm_list ~= 0 then
        vim.api.nvim_win_set_cursor(0, { extm_list[1][2] + 1, extm_list[1][3] })
        return true
    else
        return false
    end
end

neogen.utilities.cursor.jump = function()
    if neogen.utilities.cursor.go_next_extmark() then
        vim.api.nvim_command("startinsert!")
    end
end

neogen.utilities.cursor.del_extmarks = function()
    local extmarks = vim.api.nvim_buf_get_extmarks(0, neogen_ns, 0, -1, {})
    for _, v in pairs(extmarks) do
        vim.api.nvim_buf_del_extmark(0, neogen_ns, v[1])
    end
end
