local i = require("neogen.types.template").item

return {
    { nil, '"""$1"""', { no_results = true, type = { "class", "func" } } },
    { nil, '"""$1', { no_results = true, type = { "file" } } },
    { nil, "", { no_results = true, type = { "file" } } },
    { nil, "$1", { no_results = true, type = { "file" } } },
    { nil, '"""', { no_results = true, type = { "file" } } },
    { nil, "", { no_results = true, type = { "file" } } },

    { nil, "# $1", { no_results = true, type = { "type" } } },

    { nil, '"""$1' },
    { nil, "" },
    {
        i.Parameter,
        ":param %s: $1",
        { after_each = ":type %s: $1", type = { "func" } },
    },
    {
        { i.Parameter, i.Type },
        ":param %s: $1",
        {
            required = i.Tparam,
            type = { "func" },
        },
    },
    { i.ClassAttribute, ":param %s: $1" },
    { i.Throw, ":raises %s: $1", { type = { "func" } } },
    { i.Return, ":return: $1", { type = { "func" }, after_each = ":rtype: $1" } },
    { i.ReturnTypeHint, ":return: $1", { type = { "func" } } },
    { nil, '"""' },
}
