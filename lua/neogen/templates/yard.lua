local i = require("neogen.types.template").item

return {
    { nil, "# $1", { no_results = true, type = { "class", "func" } } },
    { nil, "# $1", { no_results = true, type = { "type" } } },

    { nil, "# $1" },
    { i.Parameter, "# @param %s [$1] $1", {} },
    { i.Return, "# @return [$1] $1", {} },
}
