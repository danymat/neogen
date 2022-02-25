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
    Vararg = "varargs",
    Type = "type",
    ClassAttribute = "attributes",
    HasParameter = "has_parameters",
    HasReturn = "has_return",
    ArbitraryArgs = "arbitrary_args",
    Kwargs = "kwargs",
}

local i = template.item

template.todo_text = {
    [i.Tparam] =         "[TODO:tparam]",
    [i.Parameter] =      "[TODO:parameter]",
    [i.Return] =         "[TODO:return]",
    [i.ReturnTypeHint] = "[TODO:return]",
    [i.ReturnAnonym] =   "[TODO:return]",
    [i.ClassName] =      "[TODO:class]",
    [i.Throw] =          "[TODO:throw]",
    [i.Vararg] =         "[TODO:varargs]",
    [i.Type] =           "[TODO:type]",
    [i.ClassAttribute] = "[TODO:attribute]",
    [i.HasParameter] =   "[TODO:parameter]",
    [i.HasReturn] =      "[TODO:return]",
    [i.ArbitraryArgs] =  "[TODO:args]",
    [i.Kwargs] =         "[TODO:kwargs]",
}

return template
