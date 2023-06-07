---@class neogen.Configuration
---@field template neogen.TemplateConfig
---@field parent table
---@field data table

local template = {}

template.item = {
    Tparam = "tparam",
    Parameter = "parameters",
    Return = "return_statement",
    ReturnTypeHint = "return_type_hint",
    ReturnAnonym = "return_anonym",
    ClassName = "class_name",
    Throw = "throw_statement",
    Yield = "expression_statement",
    Vararg = "varargs",
    Type = "type",
    ClassAttribute = "attributes",
    HasParameter = "has_parameters",
    HasReturn = "has_return",
    HasThrow = "has_throw",
    HasYield = "has_yield",
    ArbitraryArgs = "arbitrary_args",
    Kwargs = "kwargs",
}

return template
