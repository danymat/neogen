local i = require("neogen.types.template").item

return {
    { nil, "! $1", { no_results = true, type = { "file" } } },
    { nil, "", { no_results = true, type = { "file" } } },

    { nil, "/ $1", { no_results = true, type = { "func", "class" } } },

    { nil, "/ $1", { type = { "func", "class" } } },
    { nil, "/", { type = { "class", "func" } } },
    { i.Parameter, "/ * `%s`: $1", { type = { "class" } } },
    { i.Tparam, "/ * `%s`: $1", { type = { "func" } } },
    { i.Parameter, "/ * `%s`: $1", { type = { "func" } } },
}
