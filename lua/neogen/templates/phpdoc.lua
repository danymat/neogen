local i = require("neogen.types.template").item

return {
    { nil, "/** @var $1 */", { no_results = true, type = { "type" } } },

    { nil, "/**", { no_results = true, type = { "func", "class" } } },
    { nil, " * $1", { no_results = true, type = { "func", "class" } } },
    { nil, " */", { no_results = true, type = { "func", "class" } } },

    { nil, "/**", { type = { "type", "func" } } },
    { nil, " * $1", { type = { "func" } } },
    { nil, " *", { type = { "func" } } },
    { i.Type, " * @var $1", { type = { "type" } } },
    { i.Parameter, " * @param $1 %s $1", { type = { "func" } } },
    { i.Return, " * @return $1", { type = { "func" } } },
    { nil, " */", { type = { "type", "func" } } },
}
