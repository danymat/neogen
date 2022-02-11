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
---@field append? neogen.TemplateConfig.Append custom placement of the annotation
---@field position fun(node: userdata, type: string): number,number Provide an absolute position for the annotation
---   If values are `nil`, use default positioning
---
---@class neogen.TemplateConfig.Append
---@field child_name string Which child node to use for appending the annotation
---@field fallback string Node to fallback if `child_name` is not found
---@field position "'after'"|"'before'" Place the annotation relative to position with `child_name` or `fallback`
---@field disabled? table Disable custom placement for provided types
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

--- Updates a template configuration
---@signature <template_obj>:config(tbl)
---@param tbl neogen.TemplateConfig Override the template with provided config
---@tag neogen-template-api.config()
---@private
neogen_template.config = function(self, tbl)
    self = vim.tbl_extend("force", self, tbl)
    return self
end

--- Add an annotation convention to the template
---@signature <template_obj>:add_annotation(name)
---@param name string The name of the annotation convention
---@tag neogen-template-api.add_annotation()
---@private
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
---@private
neogen_template.add_default_annotation = function(self, name)
    self.annotation_convention = name
    self = self:add_annotation(name)
    return self
end

--- Add a custom annotation convention to the template
---@param name string The name of the annotation convention
---@param annotation table The annotation template (see |neogen-annotation|)
---@param default? boolean Marks the annotation as default one
---@tag neogen-template-api.add_custom_annotation()
---@private
neogen_template.add_custom_annotation = function(self, name, annotation, default)
    if default == true then
        self.annotation_convention = name
    end

    self[name] = annotation
    return self
end

---
--- In this section, you'll learn how to create your own annotation convention
--- First of all, you need to know an annotation template behaves, with an example:
--- >
---  local i = require("neogen.types.template").item
---
---  annotation = {
---      { nil, "- $1", { type = { "class", "func" } } },
---      { nil, "- $1", { no_results = true, type = { "class", "func" } } },
---      { nil, "-@module $1", { no_results = true, type = { "file" } } },
---      { nil, "-@author $1", { no_results = true, type = { "file" } } },
---      { nil, "-@license $1", { no_results = true, type = { "file" } } },
---      { nil, "", { no_results = true, type = { "file" } } },
---      { i.Parameter, "-@param %s $1|any" },
---      { i.Vararg, "-@vararg $1|any" },
---      { i.Return, "-@return $1|any" },
---      { i.ClassName, "-@class $1|any" },
---      { i.Type, "-@type $1" },
---  }
--- <
--- - `local i = require("neogen.types.template").item`
---     Stores every supported node name that you can use for a language.
---     A node name is found with Treesitter during the configuration of a language
---
--- - `{ nil, "- $1", { type = { "class", "func" } } }`
---     Here is an item of a annotation convention.
---     It consists of 2 required fields (first and second), and an optional third field
---
---     - The first field is a `string`, or `table`: this item will be used each time there is this node name.
---         If it is `nil`, then it'll not required a node name.
---         If you need a node name, we recommend using the items from `local i`, like so:
---          `{ i.Type, "-@type $1" },`
---         If it's a `table`, it'll be used for more advanced generation:
---         `{ { i.Parameter, i.Type }, "    %s (%s): $1", { required = "typed_parameters", type = { "func" } } },`
---         Means: if there are `Parameters` and `Types` inside a node called `typed_parameters`,
---           these two nodes will be used in the generated line
---
---     - The second item is a `string`, and is the string that'll be written in output.
---         It'll be formatted with some important fields:
---         - `%s` will use the content from the node name
---         - `$1` will be replaced with a cursor position (so that the user can jump to)
---         Example: `{ i.Parameter, "-@param %s $1|any" },` will result in:
---         `-@param hello ` (will a parameter named `hello`)
---
---     - The third item is a `table` (optional), and are the local options for the line.
---         See below (`neogen.AnnotationLine.Opts`) for more information on what is required
---
--- Now that you know every field, let's see how we could generate a basic annotation for a python function:
--- >
---  # Desired output:
---  def test(param1, param2, param3):
---  """
---  Parameters
---  ----------
---  param1:
---  param2:
---  param3:
---  """
---  pass
--- <
--- Will be very simply created with an convention like so:
---  local i = require("neogen.types.template").item
---
--- >
---  annotation = {
---      { i.Parameter, "%s: $1", { before_first_item = { "Parameters", "----------" } } },
---  }
--- <
--- We recommend you look into the the content of `neogen/templates` for a list of the default annotation conventions.
---
--- Last step, if you want to use your own annotation convention for a language:
---   >
---    require('neogen').setup {
---      languages = {
---        python = {
---          template = {
---            annotation_convention = "my_annotation",
---            my_annotation = annotation
---          }
---      }
---    }
---   <
---@tag neogen-annotation
---@toc_entry How to create/customize an annotation

--- # neogen.AnnotationLine~
---
---@class neogen.AnnotationLine.Opts
---@field no_results boolean If true, will only generate the line if there are no values returned by the configuration
---@field type string[] If specified, will only generate the line for the required types.
--- If not specified, will use this line for all types.
---@field before_first_item string[] If specified, will append these lines before the first found item of the configuration
---@field after_each string If specified, append the line after each found item of the configuration
---@field required string If specified, is used in if the first field of the table is a `table` (example above)

return neogen_template
