local i = require("neogen.types.template").item

return {
    { nil, "/**", { no_results = true, type = { "class", "func", "type" } } },
    { nil, " * $1", { no_results = true, type = { "class", "func", "type" } } },
    { nil, " */", { no_results = true, type = { "class", "func", "type" } } },

    { nil, "/**" },
    { nil, " * $1" },
    { nil, " *" },
    { i.Parameter, " * @param %s $1" },
    { i.ClassAttribute, " * @property %s $1" },
    { i.Return, " * @return $1" },
    { i.Throw, " * @throws %s $1" },
    { nil, " */" },
}
