local i = require("neogen.types.template").item

return {
    { nil, "# Public: $1", { type = { "func", "class" } } },
    { nil, "# Public: $1", { type = { "class", "func" }, no_results = true } },
    { i.Parameter, "# %s - $1", { before_first_item = { "#" } } },
    { i.Return, "# Returns $1", { before_first_item = { "#" } } },
}
