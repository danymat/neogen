local i = require("neogen.types.template").item

return {
    { nil, "! $1", { no_results = true, type = { "file" } } },
    { nil, "", { no_results = true, type = { "file" } } },

    { nil, "/ $1", { no_results = true, type = { "func", "class" } } },

    { nil, "/ $1", { type = { "func", "class" } } },
    { nil, "/", { type = { "class", "func" } } },
    { i.Parameter, "/ * `%s`: $1", { type = { "class" } } },
    { i.Parameter, "/ * `%s`: $1", { type = { "func" } } },
}
