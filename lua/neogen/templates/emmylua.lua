local i = require("neogen.types.template").item

return {
    { nil, "- $1", { type = { "class", "func" } } }, -- add this string only on requested types
    { nil, "- $1", { no_results = true, type = { "class", "func" } } }, -- Shows only when there's no results from the granulator
    { nil, "-@module $1", { no_results = true, type = { "file" } } },
    { nil, "-@author $1", { no_results = true, type = { "file" } } },
    { nil, "-@license $1", { no_results = true, type = { "file" } } },
    { nil, "", { no_results = true, type = { "file" } } },

    { i.Parameter, "-@param %s $1|any" },
    { i.Vararg, "-@vararg $1|any" },
    { i.Return, "-@return $1|any" },
    { i.ClassName, "-@class $1|any" },
    { i.Type, "-@type $1" },
}
