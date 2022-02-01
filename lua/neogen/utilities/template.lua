---
--- Each filetype has a template configuration.
--- A template configuration is responsible for explicitely adding templates
--- corresponding to annotation conventions,
--- as well as providing custom configurations in order to be precise about
--- how to customize the annotations.
---
--- We exposed some API to help you customize a template, and add your own custom annotations
--- For this, please go to |neogen.template_api|
---
---@type neogen.TemplateConfig
---
--- Default values:
---@tag neogen-template-configuration
---@signature
---@toc_entry Configurations for the template table
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
local neogen_template = {
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

--- # Templates API~
---
--- Welcome to the neogen API section for templates.
---
--- A template is an entity relative to a filetype that holds configurations for how to place
--- annotations.
--- With it, you can add an annotation convention to a filetype, change defaults,
--- and even provide your own annotation convention !
--- I exposed some API's, available after you get a template.
--- Please see |neogen.get_template()| for how to get a template.
---
--- Example:
--- >
---  neogen.get_template("python"):config({ annotation_convention = ... })
--- <
---@tag neogen-template-api
---@toc_entry API to customize templates

--- Updates a template configuration
---@signature <template_obj>:config(tbl)
---@param tbl neogen.TemplateConfig Override the template with provided config
---@tag neogen-template-api.config()
neogen_template.config = function(self, tbl)
    self = vim.tbl_extend("force", self, tbl)
    return self
end

--- Add an annotation convention to the template
---@signature <template_obj>:add_annotation(name)
---@param name string The name of the annotation convention
---@tag neogen-template-api.add_annotation()
neogen_template.add_annotation = function(self, name)
    local ok, _t = pcall(require, "neogen.templates." .. name)

    if not ok then
        return
    end

    self[name] = _t
    return self
end

--- Add an annotation convention to the template and make it the default
---@signature <template_obj>:add_default_annotation(name)
---@param name string The name of the annotation convention
---@tag neogen-template-api.add_default_annotation()
neogen_template.add_default_annotation = function(self, name)
    self.annotation_convention = name
    self = self:add_annotation(name)
    return self
end

-- TODO: add API to create your own annotation convention

return neogen_template
