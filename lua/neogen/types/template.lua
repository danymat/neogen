---@class neogen.TemplateConfig
---@field annotation_convention string
---@field use_default_comment boolean
---@field append? neogen.TemplateConfig.Append

---@class neogen.TemplateConfig.Append
---@field position "'after'"|"'before'"
---@field child_name string
---@field fallback string

local template = {}

template.item = {
    Tparam = "tparam",
    Parameter = "parameters",
    Return = "return_statement",
    ReturnTypeHint = "return_type_hint",
    ReturnAnonym = "return_anonym",
    ClassName = "class_name",
    Throw = "throw_statement",
    Vararg = "varargs",
    Type = "type",
    ClassAttribute = "attributes",
    HasParameter = "has_parameters",
    HasReturn = "has_return",
}

return template
