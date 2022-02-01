local i = require("neogen.types.template").item

return {
    { nil, "/**", { no_results = true, type = { "class", "func" } } },
    { nil, " * $1", { no_results = true, type = { "class", "func" } } },
    { nil, " */", { no_results = true, type = { "class", "func" } } },

    { nil, "/**" },
    { nil, " * $1" },
    { nil, " *" },
    { i.Parameter, " * @param %s $1" },
    { i.Return, " * @return $1" },
    { i.Throw, " * @throws $1" },
    { nil, " */" },
}
