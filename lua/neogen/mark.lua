---@class Mark
---@field started boolean
---@field bufnr number
---@field winid number
---@field index number
---@field last_cursor number
---@field ids number[]
---@field range_id number
local mark = {}

local api = vim.api
local ns = api.nvim_create_namespace("neogen")

local function compare_pos(p1, p2)
    return p1[1] == p2[1] and p1[2] - p2[2] or p1[1] - p2[1]
end

--- Start marks creation and get useful informations
---@private
mark.start = function(self)
    if self.started then
        mark:stop()
    end
    self.bufnr = api.nvim_get_current_buf()
    self.winid = api.nvim_get_current_win()
    self.index = 0
    local pos = api.nvim_win_get_cursor(self.winid)
    local row, col = unpack(pos)
    self.last_cursor_id = api.nvim_buf_set_extmark(self.bufnr, ns, row - 1, col, {})
    self.ids = {}
    self.range_id = nil
    self.started = true
end

mark.valid = function(self)
    return self.bufnr == api.nvim_get_current_buf() and self.winid == api.nvim_get_current_win()
end

--- Get a mark specified with i index
---@param i number
---@private
mark.get_mark = function(self, i)
    local id = self.ids[i]
    return api.nvim_buf_get_extmark_by_id(self.bufnr, ns, id, {})
end

--- Add a mark with position
---@param pos table Position as line, col
---@return number the id of the inserted mark
---@private
mark.add_mark = function(self, pos)
    local id = api.nvim_buf_set_extmark(self.bufnr, ns, pos.row, pos.col, {})
    table.insert(mark.ids, id)
    return id
end

--- Get how many marks are created
---@return number
---@private
mark.mark_len = function(self)
    return #self.ids
end

mark.get_range_mark = function(self)
    local d = api.nvim_buf_get_extmark_by_id(self.bufnr, ns, self.range_id, { details = true })
    local row, col, end_row, end_col = d[1], d[2], d[3].end_row, d[3].end_col
    return row, col, end_row, end_col
end

mark.add_range_mark = function(self, range)
    local row, col, end_row, end_col = unpack(range)
    self.range_id = api.nvim_buf_set_extmark(self.bufnr, ns, row, col, { end_row = end_row, end_col = end_col })
end

mark.cursor_in_range = function(self, validated)
    local ret = validated or self:valid()
    if ret and self.range_id then
        local pos = api.nvim_win_get_cursor(self.winid)
        pos[1] = pos[1] - 1
        local row, col, end_row, end_col = self:get_range_mark()
        ret = compare_pos({ row, col }, pos) <= 0 and compare_pos({ end_row, end_col }, pos) >= 0
    end
    return ret
end

--- Verify if the marks can be jumpable
---@param reverse boolean
---@return boolean
---@private
mark.jumpable = function(self, reverse)
    if not self.started then
        return false
    end
    local validated = self:valid()
    if not validated then
        self:stop()
        return validated
    end
    local ret
    if reverse then
        ret = self.index > 0
    else
        ret = #self.ids >= self.index
    end
    if ret then
        ret = self:cursor_in_range(true)
    end

    if not ret then
        self:jump_last_cursor(true)
        self:stop()
    end
    return ret
end

--- Jump to next/previous mark if possible
---@param reverse boolean
---@private
mark.jump = function(self, reverse)
    if self.started then
        self.index = reverse and self.index - 1 or self.index + 1
    end
    if mark:jumpable(reverse) then
        local line, row = unpack(self:get_mark(self.index))
        api.nvim_win_set_cursor(self.winid, { line + 1, row })
    end
end

mark.jump_last_cursor = function(self, validated)
    if self:cursor_in_range(validated) then
        local winid = self.winid
        local pos = api.nvim_buf_get_extmark_by_id(self.bufnr, ns, self.last_cursor_id, {})
        local line, col = unpack(pos)
        api.nvim_win_set_cursor(winid, { line + 1, col })
    end
end

--- Clear marks and stop jumping ability
---@private
mark.stop = function(self)
    local bufnr = self.bufnr
    if bufnr and bufnr > 0 and api.nvim_buf_is_valid(bufnr) then
        for _, id in ipairs(self.ids) do
            api.nvim_buf_del_extmark(bufnr, ns, id)
        end
        api.nvim_buf_del_extmark(bufnr, ns, self.last_cursor_id)
        if self.range_id then
            api.nvim_buf_del_extmark(bufnr, ns, self.range_id)
        end
    end
    self.bufnr = nil
    self.winid = nil
    self.index = nil
    self.last_cursor_id = nil
    self.started = false
    self.ids = {}
    self.range_id = nil
end

return mark
