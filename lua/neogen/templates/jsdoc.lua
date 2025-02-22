local i = require("neogen.types.template").item

return {
    { nil, "/** $1 */", { no_results = true, type = { "func", "class" } } },
    { nil, "/** @type $1 */", { no_results = true, type = { "type" } } },

    { nil, "/**", { no_results = true, type = { "file" } } },
    { nil, " * @module $1", { no_results = true, type = { "file" } } },
    { nil, " */", { no_results = true, type = { "file" } } },

    { nil, "/**", { type = { "class", "func" } } },
    { i.ClassName, " * @classdesc $1", { before_first_item = { " * ", " * @class" }, type = { "class" } } },
    { i.Parameter, " * @param {$1} %s - $1", { type = { "func" } } },
    {
        { i.Type, i.Parameter },
        " * @param {%s} %s - $1",
        { required = i.Tparam, type = { "func" } },
    },
    { i.Return, " * @returns {$1} - $1", { type = { "func" } } },
    { nil, " */", { type = { "class", "func" } } },

    { nil, "/**", { no_results = true, type = { "property" } } },
    { nil, " * $1", { no_results = true, type = { "property" } } },
    { nil, " */", { no_results = true, type = { "property" } } },
}
