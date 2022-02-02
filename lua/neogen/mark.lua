local mark = {}

local api = vim.api
local ns = api.nvim_create_namespace("neogen")

mark.start = function(self)
    if self.started then
        mark:stop()
    end
    self.bufnr = api.nvim_get_current_buf()
    self.winid = api.nvim_get_current_win()
    local pos = api.nvim_win_get_cursor(self.winid)
    local row, col = unpack(pos)
    self.last_jump = api.nvim_buf_set_extmark(self.bufnr, ns, row - 1, col, {})
    self.index = 0
    self.ids = {}
    self.started = true
end

mark.get_mark = function(self, i)
    local id = self.ids[i]
    return api.nvim_buf_get_extmark_by_id(self.bufnr, ns, id, {})
end

mark.add_mark = function(self, pos)
    local line, col = unpack(pos)
    local id = api.nvim_buf_set_extmark(self.bufnr, ns, line, col, {})
    table.insert(mark.ids, id)
    return id
end

mark.mark_len = function(self)
    return #self.ids
end

mark.jumpable = function(self, reverse)
    local ret = true
    if reverse then
        ret = self.index ~= 1
    else
        ret = #self.ids ~= self.index
    end
    if ret then
        ret = self.bufnr == api.nvim_get_current_buf() and self.winid == api.nvim_get_current_win()
    end
    return ret
end

mark.jump = function(self, reverse)
    if self.index == 0 or mark:jumpable(reverse) then
        self.index = reverse and self.index - 1 or self.index + 1
        local line, row = unpack(self:get_mark(self.index))
        api.nvim_win_set_cursor(self.winid, {line + 1, row})
    else
        self:stop(true)
    end
end

mark.stop = function(self, should_jump)
    local bufnr = self.bufnr
    if bufnr and bufnr > 0 and api.nvim_buf_is_valid(bufnr) then
        for _, id in ipairs(self.ids) do
            api.nvim_buf_del_extmark(bufnr, ns, id)
        end

        local winid = self.winid
        if should_jump and winid and winid > 0 and api.nvim_win_is_valid(winid) then
            local pos = api.nvim_buf_get_extmark_by_id(self.bufnr, ns, self.last_jump, {})
            local line, col = unpack(pos)
            api.nvim_win_set_cursor(winid, {line + 1, col})
        end
        api.nvim_buf_del_extmark(bufnr, ns, self.last_jump)
    end
    self.bufnr = nil
    self.winid = nil
    self.index = nil
    self.last_jump = nil
    self.started = false
    self.ids = {}
end

return mark