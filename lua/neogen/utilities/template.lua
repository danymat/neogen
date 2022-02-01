---
--- Each filetype has a template configuration.
--- A template configuration is responsible for explicitely adding templates
--- corresponding to annotation conventions,
--- as well as providing custom configurations in order to be precise about
--- how to customize the annotations.
---
---@type neogen.TemplateConfig
---
--- Default values:
---@tag neogen.template_configuration
---@toc_entry Customize templates for a language
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
local template_configuration = {
    annotation_convention = nil,
    use_default_comment = false,
}

--- # neogen.TemplateConfig~
---
---@class neogen.TemplateConfig see |template_config|
---@field annotation_convention string select which annotation convention to use
---@field use_default_comment boolean Prepend default filetype comment before a annotation
---@field append neogen.TemplateConfig.Append|nil custom placement of the annotation
---@field position fun(node: userdata, type: string): number,number Provide an absolute position for the annotation
---   If values are `nil`, use default positioning
---
---@class neogen.TemplateConfig.Append
---@field child_name string Which child node to use for appending the annotation
---@field fallback string Node to fallback if `child_name` is not found
---@field position "'after'"|"'before'" Place the annotation relative to position with `child_name` or `fallback`
---@field disabled table|nil Disable custom placement for provided types
---
--- For example, to customize the placement for a python annotation, we can use `append`, like so:
---
--- >
---  python = {
---      template = {
---          append = {
---              child_name = "comment", fallback = "block", position = "after"
---          }
---      }
---  }
--- <
---
--- Here, we instruct the generator to place the annotation "after" the "comment" (if not found: "block") node
---
--- Results in:
---
--- >
---  def test():
---      """ """
---      pass
--- <
---
--- Or:
---
--- >
---  def test():
---      # This is a comment
---      """ """
---      pass
--- <
-- TODO: Add section to tell about annotation convention

---Update template configuration
---@param tbl neogen.TemplateConfig
template_configuration.config = function(self, tbl)
    self = vim.tbl_extend("force", self, tbl)
    return self
end

template_configuration.add_template = function(self, name)
    local ok, _t = pcall(require, "neogen.templates." .. name)

    if not ok then
        return
    end

    self[name] = _t
    return self
end

template_configuration.add_default_template = function(self, name)
    self.annotation_convention = name
    self = self:add_template(name)
    return self
end

return template_configuration
