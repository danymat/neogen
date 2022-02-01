local i = require("neogen.types.template").item

return {
    { nil, "- $1", { no_results = true, type = { "func", "class" } } },
    { nil, "- $1", { type = { "func", "class" } } },

    { i.Parameter, " @tparam $1|any %s " },
    { i.Return, " @treturn $1|any" },
}
