neogen.utilities.cursor = {}

local neogen_ns = vim.api.nvim_create_namespace("neogen")

--- Wrapper around set_extmark with 1-based numbering for `line` and `col`, and returns the id of the created extmark
--- @param line string
--- @param col string
--- @return number
neogen.utilities.cursor.create = function(line, col)
    return vim.api.nvim_buf_set_extmark(0, neogen_ns, line - 1, col - 1, {})
end

--- Find next created extmark and goes to it.
--- It removes the extmark afterwards.
--- First jumpable extmark is the one after the extmarks responsible of start/end of annotation
neogen.utilities.cursor.go_next_extmark = function()
    local extm_list = vim.api.nvim_buf_get_extmarks(0, neogen_ns, 0, -1, {})
    if #extm_list ~= 2 then
        local pos = { extm_list[2][2] + 1, extm_list[2][3] }

        vim.api.nvim_win_set_cursor(0, pos)
        if #extm_list ~= 0 then
            vim.api.nvim_buf_del_extmark(0, neogen_ns, extm_list[1][1])
        end
        return true
    else
        return false
    end
end

--- Goes to next extmark and start insert mode.
--- If `opts.first_time` is supplied, will try to go to normal mode before going to extmark
--- @param opts table
neogen.utilities.cursor.jump = function(opts)
    opts = opts or {}

    -- This is weird, the first time nvim goes to insert is not the same as when i'm already on insert mode
    -- that's why i put a first_time flag
    if opts.first_time then
        vim.api.nvim_command("startinsert")
    end

    if neogen.utilities.cursor.go_next_extmark() then
        vim.api.nvim_command("startinsert")
    end
end

--- Delete all active extmarks
neogen.utilities.cursor.del_extmarks = function()
    local extmarks = vim.api.nvim_buf_get_extmarks(0, neogen_ns, 0, -1, {})
    for _, v in pairs(extmarks) do
        vim.api.nvim_buf_del_extmark(0, neogen_ns, v[1])
    end
end

--- Checks if there are still possible jump positions to perform
--- Verifies if the cursor is in the last annotated part
neogen.utilities.cursor.jumpable = function()
    local extm_list = vim.api.nvim_buf_get_extmarks(0, neogen_ns, 0, -1, {})
    if #extm_list == 0 then
        return false
    end
    local cursor = vim.api.nvim_win_get_cursor(0)
    if cursor[1] > extm_list[#extm_list][2] or cursor[1] < extm_list[1][2] then
      return false
    end
    if #extm_list > 2 then
        return true
    else
        return false
    end
end
