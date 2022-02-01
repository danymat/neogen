---@type neogen.TemplateConfig
local template = {
    annotation_convention = nil,
    use_default_comment = false,
}

---Update template configuration
---@param tbl neogen.TemplateConfig
template.config = function(self, tbl)
    self = vim.tbl_extend("force", self, tbl)
    return self
end

template.add_template = function(self, name)
    local ok, _t = pcall(require, "neogen.templates." .. name)

    if not ok then
        return
    end

    self[name] = _t
    return self
end

template.add_default_template = function(self, name)
    self.annotation_convention = name
    self = self:add_template(name)
    return self
end

return template
